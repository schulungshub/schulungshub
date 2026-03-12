package auth

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"strings"
)

func internalError(w http.ResponseWriter, err error) {
	log.Printf("ERROR: %v", err)
	http.Error(w, "internal server error", http.StatusInternalServerError)
}

type loginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
	DeptSlug string `json:"dept"`
}

type loginResponse struct {
	ID          int             `json:"id"`
	Username    string          `json:"username"`
	DisplayName string          `json:"display_name"`
	Role        string          `json:"role"`
	DeptID      int             `json:"dept_id"`
	DeptName    string          `json:"dept_name"`
	Features    json.RawMessage `json:"features"`
}

type Handler struct {
	DB            *sql.DB
	SecureCookies bool
	SetupKey      string
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if !CheckRateLimit(r) {
		http.Error(w, "too many requests", http.StatusTooManyRequests)
		return
	}

	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	// Find department
	var deptID int
	var deptName string
	var featuresRaw []byte
	err := h.DB.QueryRow(
		"SELECT id, name, features FROM departments WHERE slug = ?", req.DeptSlug,
	).Scan(&deptID, &deptName, &featuresRaw)
	if err != nil {
		http.Error(w, "department not found", http.StatusUnauthorized)
		return
	}

	// Find user
	var userID int
	var username, displayName, role, passwordHash string
	var active bool
	err = h.DB.QueryRow(
		`SELECT id, username, display_name, role, password_hash, active
		 FROM users WHERE username = ? AND dept_id = ?`,
		req.Username, deptID,
	).Scan(&userID, &username, &displayName, &role, &passwordHash, &active)
	if err != nil || !active {
		http.Error(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	// Verify password
	if !VerifyPassword(req.Password, passwordHash) {
		http.Error(w, "invalid credentials", http.StatusUnauthorized)
		return
	}

	// Create session
	token, err := CreateSession(h.DB, userID, deptID)
	if err != nil {
		http.Error(w, "session error", http.StatusInternalServerError)
		return
	}

	ResetRateLimit(r)
	SetSessionCookie(w, token, h.SecureCookies)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(loginResponse{
		ID:          userID,
		Username:    username,
		DisplayName: displayName,
		Role:        role,
		DeptID:      deptID,
		DeptName:    deptName,
		Features:    json.RawMessage(featuresRaw),
	})
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	token := GetTokenFromRequest(r)
	if token != "" {
		DeleteSession(h.DB, token)
	}
	ClearSessionCookie(w)
	w.WriteHeader(http.StatusNoContent)
}

// GET /api/auth/departments (public)
func (h *Handler) Departments(w http.ResponseWriter, r *http.Request) {
	rows, err := h.DB.Query("SELECT id, name, slug FROM departments ORDER BY name")
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var depts []map[string]any
	for rows.Next() {
		var id int
		var name, slug string
		if err := rows.Scan(&id, &name, &slug); err != nil {
			internalError(w, err)
			return
		}
		depts = append(depts, map[string]any{"id": id, "name": name, "slug": slug})
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if depts == nil {
		depts = []map[string]any{}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(depts)
}

// GET /api/auth/login-users?dept=slug (public – only display_name + username)
func (h *Handler) LoginUsers(w http.ResponseWriter, r *http.Request) {
	deptSlug := r.URL.Query().Get("dept")
	if deptSlug == "" {
		http.Error(w, "dept parameter required", http.StatusBadRequest)
		return
	}

	var deptID int
	err := h.DB.QueryRow("SELECT id FROM departments WHERE slug = ?", deptSlug).Scan(&deptID)
	if err != nil {
		http.Error(w, "department not found", http.StatusNotFound)
		return
	}

	rows, err := h.DB.Query(
		"SELECT username, display_name FROM users WHERE dept_id = ? AND active = 1 ORDER BY display_name",
		deptID)
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var users []map[string]string
	for rows.Next() {
		var username, displayName string
		if err := rows.Scan(&username, &displayName); err != nil {
			internalError(w, err)
			return
		}
		users = append(users, map[string]string{"username": username, "display_name": displayName})
	}
	if err := rows.Err(); err != nil {
		internalError(w, err)
		return
	}
	if users == nil {
		users = []map[string]string{}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// POST /api/auth/rfid-login (public)
func (h *Handler) RfidLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if !CheckRateLimit(r) {
		http.Error(w, "too many requests", http.StatusTooManyRequests)
		return
	}

	var req struct {
		RfidTag  string `json:"rfid_tag"`
		DeptSlug string `json:"dept"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	var deptID int
	var deptName string
	var featuresRaw []byte
	err := h.DB.QueryRow("SELECT id, name, features FROM departments WHERE slug = ?", req.DeptSlug).Scan(&deptID, &deptName, &featuresRaw)
	if err != nil {
		http.Error(w, "department not found", http.StatusUnauthorized)
		return
	}

	// Hash the raw tag with SHA-256 (same as frontend)
	rawTag := strings.TrimSpace(req.RfidTag)
	hash := sha256.Sum256([]byte(rawTag))
	rfidHash := hex.EncodeToString(hash[:])

	// Find user by SHA-256 hashed RFID tag
	var userID int
	var username, displayName, role string
	var active bool
	err = h.DB.QueryRow(
		`SELECT id, username, display_name, role, active
		 FROM users WHERE rfid_hash = ? AND dept_id = ?`,
		rfidHash, deptID,
	).Scan(&userID, &username, &displayName, &role, &active)
	if err != nil || !active {
		http.Error(w, "RFID not recognized", http.StatusUnauthorized)
		return
	}

	token, err := CreateSession(h.DB, userID, deptID)
	if err != nil {
		http.Error(w, "session error", http.StatusInternalServerError)
		return
	}

	ResetRateLimit(r)
	SetSessionCookie(w, token, h.SecureCookies)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(loginResponse{
		ID: userID, Username: username, DisplayName: displayName,
		Role: role, DeptID: deptID, DeptName: deptName,
		Features: json.RawMessage(featuresRaw),
	})
}

func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	token := GetTokenFromRequest(r)
	if token == "" {
		http.Error(w, "not authenticated", http.StatusUnauthorized)
		return
	}

	sess, err := GetSession(h.DB, token)
	if err != nil {
		ClearSessionCookie(w)
		http.Error(w, "not authenticated", http.StatusUnauthorized)
		return
	}

	var resp loginResponse
	var featuresRaw []byte
	err = h.DB.QueryRow(
		`SELECT u.id, u.username, u.display_name, u.role, u.dept_id, d.name, d.features
		 FROM users u JOIN departments d ON d.id = u.dept_id
		 WHERE u.id = ?`, sess.UserID,
	).Scan(&resp.ID, &resp.Username, &resp.DisplayName, &resp.Role, &resp.DeptID, &resp.DeptName, &featuresRaw)
	if err != nil {
		http.Error(w, "user not found", http.StatusInternalServerError)
		return
	}
	resp.Features = json.RawMessage(featuresRaw)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// POST /api/setup/department
// Protected by X-Setup-Key header. Creates a new department + first admin user.
func (h *Handler) SetupDepartment(w http.ResponseWriter, r *http.Request) {
	if h.SetupKey == "" || r.Header.Get("X-Setup-Key") != h.SetupKey {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		DeptName     string `json:"dept_name"`
		DeptSlug     string `json:"dept_slug"`
		AdminUser    string `json:"admin_user"`
		AdminName    string `json:"admin_name"`
		AdminPass    string `json:"admin_pass"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid JSON", http.StatusBadRequest)
		return
	}
	if req.DeptName == "" || req.DeptSlug == "" || req.AdminUser == "" || req.AdminPass == "" {
		http.Error(w, "dept_name, dept_slug, admin_user, admin_pass required", http.StatusBadRequest)
		return
	}
	if req.AdminName == "" {
		req.AdminName = req.AdminUser
	}

	features := `{"feature_exams":true,"feature_attendance":true,"feature_evaluations":true,"feature_content_edit":true,"feature_trainee_profiles":true}`
	res, err := h.DB.Exec(
		"INSERT INTO departments (name, slug, features) VALUES (?, ?, ?)",
		req.DeptName, req.DeptSlug, features,
	)
	if err != nil {
		if strings.Contains(err.Error(), "Duplicate") {
			http.Error(w, "department slug already exists", http.StatusConflict)
		} else {
			internalError(w, err)
		}
		return
	}
	deptID, _ := res.LastInsertId()

	hash, err := HashPassword(req.AdminPass)
	if err != nil {
		internalError(w, err)
		return
	}
	_, err = h.DB.Exec(
		`INSERT INTO users (dept_id, username, display_name, role, password_hash, active)
		 VALUES (?, ?, ?, 'admin', ?, 1)`,
		deptID, req.AdminUser, req.AdminName, hash,
	)
	if err != nil {
		internalError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"ok":      true,
		"dept_id": deptID,
		"dept":    req.DeptSlug,
		"admin":   req.AdminUser,
	})
}
