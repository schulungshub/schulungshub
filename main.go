package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"

	"schulungshub/api"
	"schulungshub/auth"
	"schulungshub/config"
)

// statusWriter wraps ResponseWriter to capture the HTTP status code.
type statusWriter struct {
	http.ResponseWriter
	status int
}

func (sw *statusWriter) WriteHeader(code int) {
	sw.status = code
	sw.ResponseWriter.WriteHeader(code)
}

// requestLogger logs method, path, status and duration for all /api/ requests.
// Also recovers from panics so the server keeps running and the client gets a 500.
func requestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w, status: http.StatusOK}

		defer func() {
			if rec := recover(); rec != nil {
				log.Printf("PANIC: %v — %s %s", rec, r.Method, r.URL.Path)
				http.Error(sw, "internal server error", http.StatusInternalServerError)
			}
		}()

		next.ServeHTTP(sw, r)
		if strings.HasPrefix(r.URL.Path, "/api/") {
			ip := r.RemoteAddr
			if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
				ip = fwd
			}
			log.Printf("%s %s %s %d %s", ip, r.Method, r.URL.Path, sw.status, time.Since(start).Round(time.Millisecond))
		}
	})
}

const version = "0.1.35"

// autoMigrate creates the database and tables if they don't exist.
func autoMigrate(cfg *config.Config) {
	rootDB, err := sql.Open("mysql", cfg.DSNRoot())
	if err != nil {
		log.Fatal("DB connection failed (migrate):", err)
	}
	defer rootDB.Close()

	_, err = rootDB.Exec("CREATE DATABASE IF NOT EXISTS `" + cfg.DBName + "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
	if err != nil {
		log.Fatal("Cannot create database:", err)
	}

	db, err := sql.Open("mysql", cfg.DSN())
	if err != nil {
		log.Fatal("DB connection failed (migrate):", err)
	}
	defer db.Close()

	schema := `
CREATE TABLE IF NOT EXISTS departments (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  slug        VARCHAR(50) NOT NULL UNIQUE,
  features    JSON NOT NULL DEFAULT ('{}'),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS meta (
  dept_id     INT NOT NULL,
  ` + "`key`" + `       VARCHAR(50) NOT NULL,
  value       TEXT,
  PRIMARY KEY (dept_id, ` + "`key`" + `),
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS users (
  id                  INT AUTO_INCREMENT PRIMARY KEY,
  dept_id             INT NOT NULL,
  username            VARCHAR(50) NOT NULL,
  display_name        VARCHAR(100) NOT NULL,
  initials            VARCHAR(10),
  role                ENUM('admin','trainer','trainee') NOT NULL DEFAULT 'trainee',
  active              TINYINT NOT NULL DEFAULT 1,
  password_hash       VARCHAR(255),
  rfid_hash           VARCHAR(255),
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by          INT,
  must_change_password TINYINT DEFAULT 0,
  theme               VARCHAR(20),
  age                 INT,
  birthdate           DATE,
  language_level      INT DEFAULT 3,
  has_training        TINYINT DEFAULT 0,
  measure_start       DATE,
  motorik_level       INT DEFAULT 2,
  UNIQUE (dept_id, username),
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS sessions (
  token       VARCHAR(64) PRIMARY KEY,
  user_id     INT NOT NULL,
  dept_id     INT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at  TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS machines (
  id          VARCHAR(50) PRIMARY KEY,
  dept_id     INT NOT NULL,
  label       VARCHAR(100) NOT NULL,
  position    INT DEFAULT 0,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS content_sections (
  id          VARCHAR(50) PRIMARY KEY,
  dept_id     INT NOT NULL,
  title       VARCHAR(200) NOT NULL,
  position    INT DEFAULT 0,
  content_md  MEDIUMTEXT,
  parent_id   VARCHAR(50),
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS section_confirmations (
  section_id            VARCHAR(50) NOT NULL,
  trainee_id            INT NOT NULL,
  dept_id               INT NOT NULL,
  trainer_id            INT,
  trainer_confirmed_at  TIMESTAMP NULL,
  trainee_confirmed_at  TIMESTAMP NULL,
  PRIMARY KEY (section_id, trainee_id),
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE,
  FOREIGN KEY (trainee_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (section_id) REFERENCES content_sections(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS learning_goals (
  id          VARCHAR(50) PRIMARY KEY,
  dept_id     INT NOT NULL,
  machine_id  VARCHAR(50),
  phase       VARCHAR(10),
  title       VARCHAR(200) NOT NULL,
  weight      DECIMAL(3,1) DEFAULT 1.0,
  position    INT DEFAULT 0,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS evaluations (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  dept_id       INT NOT NULL,
  trainee_id    INT NOT NULL,
  goal_id       VARCHAR(50) NOT NULL,
  score         INT NOT NULL,
  error_rate    DECIMAL(5,2),
  comment       TEXT,
  action        TEXT,
  evaluated_by  INT NOT NULL,
  evaluated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE,
  FOREIGN KEY (trainee_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (goal_id) REFERENCES learning_goals(id) ON DELETE CASCADE,
  FOREIGN KEY (evaluated_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trainee_meta (
  trainee_id  INT PRIMARY KEY,
  dept_id     INT NOT NULL,
  feedback    TEXT,
  conclusion  TEXT,
  next_steps  TEXT,
  FOREIGN KEY (trainee_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS attendance (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  dept_id     INT NOT NULL,
  trainee_id  INT NOT NULL,
  machine_id  VARCHAR(50),
  date        DATE NOT NULL,
  hours       DECIMAL(4,1) DEFAULT 8.0,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE,
  FOREIGN KEY (trainee_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam_questions (
  id              VARCHAR(50) PRIMARY KEY,
  dept_id         INT NOT NULL,
  section_id      VARCHAR(50),
  machine_id      VARCHAR(50),
  phase           VARCHAR(10),
  type            ENUM('single','image','truefalse') NOT NULL DEFAULT 'single',
  question        TEXT NOT NULL,
  options         JSON NOT NULL,
  explanation     TEXT,
  question_image  MEDIUMTEXT,
  difficulty      INT DEFAULT 1,
  created_by      INT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE,
  FOREIGN KEY (section_id) REFERENCES content_sections(id) ON DELETE SET NULL,
  FOREIGN KEY (machine_id) REFERENCES machines(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam_results (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  dept_id     INT NOT NULL,
  trainee_id  INT NOT NULL,
  score       INT NOT NULL,
  total       INT NOT NULL,
  passed      TINYINT NOT NULL,
  answers     JSON,
  started_at  TIMESTAMP NULL,
  finished_at TIMESTAMP NULL,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE,
  FOREIGN KEY (trainee_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;
`
	if _, err := db.Exec(schema); err != nil {
		log.Fatal("Auto-migrate failed:", err)
	}

	// Create indexes (ignore errors if they already exist)
	indexes := []string{
		"CREATE INDEX idx_users_dept ON users(dept_id)",
		"CREATE INDEX idx_users_role ON users(dept_id, role)",
		"CREATE INDEX idx_evaluations_trainee ON evaluations(dept_id, trainee_id)",
		"CREATE INDEX idx_evaluations_goal ON evaluations(goal_id)",
		"CREATE INDEX idx_attendance_trainee ON attendance(dept_id, trainee_id)",
		"CREATE UNIQUE INDEX unique_attendance ON attendance(dept_id, trainee_id, date)",
		"CREATE INDEX idx_goals_machine ON learning_goals(dept_id, machine_id)",
		"CREATE INDEX idx_content_parent ON content_sections(dept_id, parent_id)",
		"CREATE INDEX idx_sessions_expires ON sessions(expires_at)",
		"CREATE INDEX idx_exam_results_trainee ON exam_results(dept_id, trainee_id)",
	}
	for _, idx := range indexes {
		db.Exec(idx) // ignore "Duplicate key name" errors
	}

	log.Println("Database schema OK")
}

func main() {
	// Setup logging: stdout + server_DATUM.log
	if err := os.MkdirAll("logs", 0755); err != nil {
		log.Fatal("Cannot create logs dir:", err)
	}
	logPath := fmt.Sprintf("logs/server_%s.log", time.Now().Format("2006-01-02"))
	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal("Cannot open log file:", err)
	}
	defer logFile.Close()
	log.SetOutput(io.MultiWriter(os.Stdout, logFile))
	log.SetFlags(log.Ldate | log.Ltime)

	cfg := config.Load()

	autoMigrate(cfg)

	db, err := sql.Open("mysql", cfg.DSN())
	if err != nil {
		log.Fatal("DB connection failed:", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		log.Fatal("DB ping failed:", err)
	}
	log.Println("Connected to MySQL:", cfg.DBName)

	// Clean expired sessions periodically
	go func() {
		for {
			auth.CleanExpiredSessions(db)
			time.Sleep(10 * time.Minute)
		}
	}()

	// Handlers
	authHandler := &auth.Handler{DB: db, SecureCookies: cfg.SecureCookies, SetupKey: cfg.SetupKey}
	usersAPI := &api.UsersAPI{DB: db}
	dataAPI := &api.DataAPI{DB: db}
	examAPI := &api.ExamAPI{DB: db}
	exportAPI := &api.ExportAPI{DB: db}

	// Limit request body to 2MB for all API endpoints
	limitBody := func(h http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			r.Body = http.MaxBytesReader(w, r.Body, 2<<20)
			h(w, r)
		}
	}

	// Auth + body limit combined
	protected := func(h http.HandlerFunc) http.HandlerFunc {
		return limitBody(api.RequireAuth(db, h))
	}

	// Router
	mux := http.NewServeMux()

	// Auth (public)
	mux.HandleFunc("/api/auth/login", limitBody(authHandler.Login))
	mux.HandleFunc("/api/auth/logout", authHandler.Logout)
	mux.HandleFunc("/api/auth/me", authHandler.Me)
	mux.HandleFunc("/api/auth/departments", authHandler.Departments)
	mux.HandleFunc("/api/auth/login-users", authHandler.LoginUsers)
	mux.HandleFunc("/api/auth/rfid-login", limitBody(authHandler.RfidLogin))
	mux.HandleFunc("/api/setup/department", limitBody(authHandler.SetupDepartment))

	// Version (public)
	mux.HandleFunc("/api/version", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"version": version})
	})

	// Users
	mux.HandleFunc("/api/users", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			usersAPI.List(w, r)
		case http.MethodPost:
			usersAPI.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))
	mux.HandleFunc("/api/users/", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			usersAPI.Update(w, r)
		case http.MethodDelete:
			usersAPI.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Machines
	mux.HandleFunc("/api/machines", protected(dataAPI.Machines))

	// Meta
	mux.HandleFunc("/api/meta", protected(dataAPI.MetaList))
	mux.HandleFunc("/api/meta/", protected(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPut {
			dataAPI.MetaSet(w, r)
		} else {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Content
	mux.HandleFunc("/api/content", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			dataAPI.ContentList(w, r)
		case http.MethodPost:
			dataAPI.ContentCreate(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))
	mux.HandleFunc("/api/content/", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			dataAPI.ContentUpdate(w, r)
		case http.MethodDelete:
			dataAPI.ContentDelete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Goals
	mux.HandleFunc("/api/goals", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			dataAPI.GoalsList(w, r)
		case http.MethodPost:
			dataAPI.GoalsCreate(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))
	mux.HandleFunc("/api/goals/", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodPut:
			dataAPI.GoalsUpdate(w, r)
		case http.MethodDelete:
			dataAPI.GoalsDelete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Evaluations
	mux.HandleFunc("/api/evaluations", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			dataAPI.EvaluationsList(w, r)
		case http.MethodPost:
			dataAPI.EvaluationsCreate(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Attendance
	mux.HandleFunc("/api/attendance", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			dataAPI.AttendanceList(w, r)
		case http.MethodPost:
			dataAPI.AttendanceCreate(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))
	mux.HandleFunc("/api/attendance/", protected(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodDelete {
			dataAPI.AttendanceDelete(w, r)
		}
	}))

	// Trainee Meta
	mux.HandleFunc("/api/trainee-meta/", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			dataAPI.TraineeMetaGet(w, r)
		case http.MethodPut:
			dataAPI.TraineeMetaSet(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Section Confirmations
	mux.HandleFunc("/api/confirmations", protected(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			dataAPI.ConfirmationsList(w, r)
		case http.MethodPost:
			dataAPI.ConfirmationsSet(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	}))

	// Search
	mux.HandleFunc("/api/search", protected(dataAPI.Search))

	// Exam
	mux.HandleFunc("/api/exam/", protected(examAPI.Route))

	// Export
	mux.HandleFunc("/api/export", protected(exportAPI.Export))

	// Static files (web-v4/)
	fs := http.FileServer(http.Dir("web-v4"))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Don't serve directory listings
		if strings.HasSuffix(r.URL.Path, "/") && r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		fs.ServeHTTP(w, r)
	})

	addr := ":" + cfg.Port
	log.Printf("SchulungsHub Server v%s listening on %s (log: %s)", version, addr, logPath)
	log.Fatal(http.ListenAndServe(addr, requestLogger(mux)))
}
