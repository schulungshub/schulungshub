-- SchulungsHub Server – MySQL Schema
-- Erstellt aus SQLite data.db + dept_id Multi-Mandant

CREATE DATABASE IF NOT EXISTS schulungshub
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE schulungshub;

-- ============================================================
-- Abteilungen (Mandanten)
-- ============================================================

CREATE TABLE departments (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  slug        VARCHAR(50) NOT NULL UNIQUE,
  features    JSON NOT NULL DEFAULT ('{}'),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- Meta (Key-Value pro Abteilung)
-- ============================================================

CREATE TABLE meta (
  dept_id     INT NOT NULL,
  `key`       VARCHAR(50) NOT NULL,
  value       TEXT,
  PRIMARY KEY (dept_id, `key`),
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Users
-- ============================================================

CREATE TABLE users (
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

-- ============================================================
-- Sessions (Server-seitig)
-- ============================================================

CREATE TABLE sessions (
  token       VARCHAR(64) PRIMARY KEY,
  user_id     INT NOT NULL,
  dept_id     INT NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at  TIMESTAMP NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Machines
-- ============================================================

CREATE TABLE machines (
  id          VARCHAR(50) PRIMARY KEY,
  dept_id     INT NOT NULL,
  label       VARCHAR(100) NOT NULL,
  position    INT DEFAULT 0,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Content Sections (flache Tabelle, Baum via parent_id)
-- ============================================================

CREATE TABLE content_sections (
  id          VARCHAR(50) PRIMARY KEY,
  dept_id     INT NOT NULL,
  title       VARCHAR(200) NOT NULL,
  position    INT DEFAULT 0,
  content_md  MEDIUMTEXT,
  parent_id   VARCHAR(50),
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Section Confirmations
-- ============================================================

CREATE TABLE section_confirmations (
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

-- ============================================================
-- Learning Goals
-- ============================================================

CREATE TABLE learning_goals (
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

-- ============================================================
-- Evaluations (append-only)
-- ============================================================

CREATE TABLE evaluations (
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

-- ============================================================
-- Trainee Meta (1:1 zu User)
-- ============================================================

CREATE TABLE trainee_meta (
  trainee_id  INT PRIMARY KEY,
  dept_id     INT NOT NULL,
  feedback    TEXT,
  conclusion  TEXT,
  next_steps  TEXT,
  FOREIGN KEY (trainee_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (dept_id) REFERENCES departments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- Attendance
-- ============================================================

CREATE TABLE attendance (
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

-- ============================================================
-- Exam Questions
-- ============================================================

CREATE TABLE exam_questions (
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

-- ============================================================
-- Exam Results
-- ============================================================

CREATE TABLE exam_results (
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

-- ============================================================
-- Indizes
-- ============================================================

CREATE INDEX idx_users_dept ON users(dept_id);
CREATE INDEX idx_users_role ON users(dept_id, role);
CREATE INDEX idx_evaluations_trainee ON evaluations(dept_id, trainee_id);
CREATE INDEX idx_evaluations_goal ON evaluations(goal_id);
CREATE INDEX idx_attendance_trainee ON attendance(dept_id, trainee_id);
CREATE UNIQUE INDEX unique_attendance ON attendance(dept_id, trainee_id, date);
CREATE INDEX idx_goals_machine ON learning_goals(dept_id, machine_id);
CREATE INDEX idx_content_parent ON content_sections(dept_id, parent_id);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);
CREATE INDEX idx_exam_results_trainee ON exam_results(dept_id, trainee_id);
