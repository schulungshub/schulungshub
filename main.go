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

const version = "0.1.34"

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
