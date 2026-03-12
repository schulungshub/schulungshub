package api

import (
	"database/sql"
	"net/http"
	"strconv"
	"strings"

	"schulungshub/auth"
)

type UsersAPI struct {
	DB *sql.DB
}

type userRow struct {
	ID                 int            `json:"id"`
	DeptID             int            `json:"dept_id"`
	Username           string         `json:"username"`
	DisplayName        string         `json:"display_name"`
	Initials           sql.NullString `json:"-"`
	Role               string         `json:"role"`
	Active             bool           `json:"active"`
	RfidHash           sql.NullString `json:"-"`
	CreatedAt          sql.NullTime   `json:"-"`
	CreatedBy          sql.NullInt64  `json:"-"`
	MustChangePassword bool           `json:"must_change_password"`
	Theme              sql.NullString `json:"-"`
	Age                sql.NullInt64  `json:"-"`
	Birthdate          sql.NullString `json:"-"`
	LanguageLevel      int            `json:"language_level"`
	HasTraining        bool           `json:"has_training"`
	MeasureStart       sql.NullString `json:"-"`
	MotorikLevel       int            `json:"motorik_level"`
}

type userJSON struct {
	ID                 int     `json:"id"`
	DeptID             int     `json:"dept_id"`
	Username           string  `json:"username"`
	DisplayName        string  `json:"display_name"`
	Initials           string  `json:"initials"`
	Role               string  `json:"role"`
	Active             bool    `json:"active"`
	RfidHash           string  `json:"rfid_hash,omitempty"`
	CreatedAt          string  `json:"created_at,omitempty"`
	CreatedBy          *int    `json:"created_by,omitempty"`
	MustChangePassword bool    `json:"must_change_password"`
	Theme              string  `json:"theme,omitempty"`
	Age                *int    `json:"age,omitempty"`
	Birthdate          string  `json:"birthdate,omitempty"`
	LanguageLevel      int     `json:"language_level"`
	HasTraining        bool    `json:"has_training"`
	MeasureStart       string  `json:"measure_start,omitempty"`
	MotorikLevel       int     `json:"motorik_level"`
}

func rowToJSON(u userRow) userJSON {
	j := userJSON{
		ID: u.ID, DeptID: u.DeptID, Username: u.Username,
		DisplayName: u.DisplayName, Role: u.Role, Active: u.Active,
		MustChangePassword: u.MustChangePassword,
		LanguageLevel: u.LanguageLevel, HasTraining: u.HasTraining,
		MotorikLevel: u.MotorikLevel,
	}
	if u.Initials.Valid { j.Initials = u.Initials.String }
	if u.RfidHash.Valid { j.RfidHash = u.RfidHash.String }
	if u.CreatedAt.Valid { j.CreatedAt = u.CreatedAt.Time.Format(tsFormat) }
	if u.CreatedBy.Valid { v := int(u.CreatedBy.Int64); j.CreatedBy = &v }
	if u.Theme.Valid { j.Theme = u.Theme.String }
	if u.Age.Valid { v := int(u.Age.Int64); j.Age = &v }
	if u.Birthdate.Valid { j.Birthdate = u.Birthdate.String }
	if u.MeasureStart.Valid { j.MeasureStart = u.MeasureStart.String }
	return j
}

func (a *UsersAPI) List(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)

	var rows *sql.Rows
	var err error

	if sess.Role == "trainee" {
		rows, err = a.DB.Query(
			`SELECT id, dept_id, username, display_name, initials, role, active,
			        rfid_hash, created_at, created_by, must_change_password, theme,
			        age, birthdate, language_level, has_training, measure_start, motorik_level
			 FROM users WHERE id = ? AND dept_id = ?`, sess.UserID, sess.DeptID)
	} else {
		rows, err = a.DB.Query(
			`SELECT id, dept_id, username, display_name, initials, role, active,
			        rfid_hash, created_at, created_by, must_change_password, theme,
			        age, birthdate, language_level, has_training, measure_start, motorik_level
			 FROM users WHERE dept_id = ?`, sess.DeptID)
	}
	if err != nil {
		internalError(w, err)
		return
	}
	defer rows.Close()

	var users []userJSON
	for rows.Next() {
		var u userRow
		err := rows.Scan(&u.ID, &u.DeptID, &u.Username, &u.DisplayName, &u.Initials,
			&u.Role, &u.Active, &u.RfidHash, &u.CreatedAt, &u.CreatedBy,
			&u.MustChangePassword, &u.Theme, &u.Age, &u.Birthdate,
			&u.LanguageLevel, &u.HasTraining, &u.MeasureStart, &u.MotorikLevel)
		if err != nil {
			internalError(w, err)
			return
		}
		users = append(users, rowToJSON(u))
	}
	if users == nil {
		users = []userJSON{}
	}
	writeJSON(w, users)
}

func (a *UsersAPI) Create(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	var req struct {
		Username    string `json:"username"`
		DisplayName string `json:"display_name"`
		Initials    string `json:"initials"`
		Role        string `json:"role"`
		Password    string `json:"password"`
		Age         *int   `json:"age"`
		LanguageLevel int  `json:"language_level"`
		HasTraining bool   `json:"has_training"`
		MotorikLevel int   `json:"motorik_level"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		http.Error(w, "password hash error", http.StatusInternalServerError)
		return
	}

	result, err := a.DB.Exec(
		`INSERT INTO users (dept_id, username, display_name, initials, role, password_hash,
		                     age, language_level, has_training, motorik_level, created_by)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		sess.DeptID, req.Username, req.DisplayName, req.Initials, req.Role, hash,
		req.Age, req.LanguageLevel, req.HasTraining, req.MotorikLevel, sess.UserID,
	)
	if err != nil {
		if strings.Contains(err.Error(), "Duplicate") {
			http.Error(w, "username already exists", http.StatusConflict)
			return
		}
		internalError(w, err)
		return
	}

	id, _ := result.LastInsertId()
	writeJSON(w, map[string]int64{"id": id})
}

func (a *UsersAPI) Update(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	idStr := strings.TrimPrefix(r.URL.Path, "/api/users/")

	// Handle sub-routes
	parts := strings.Split(idStr, "/")
	if len(parts) < 1 {
		http.Error(w, "missing user id", http.StatusBadRequest)
		return
	}

	userID, err := strconv.Atoi(parts[0])
	if err != nil {
		http.Error(w, "invalid user id", http.StatusBadRequest)
		return
	}

	// Sub-routes: /api/users/:id/password, /api/users/:id/rfid, /api/users/:id/theme
	if len(parts) == 2 {
		switch parts[1] {
		case "password":
			a.changePassword(w, r, sess, userID)
		case "rfid":
			a.changeRfid(w, r, sess, userID)
		case "theme":
			a.changeTheme(w, r, sess, userID)
		default:
			http.Error(w, "not found", http.StatusNotFound)
		}
		return
	}

	// Only admin can update other users
	if sess.Role != "admin" && sess.UserID != userID {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	var req map[string]any
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}

	allowed := map[string]bool{
		"display_name": true, "initials": true, "role": true, "active": true,
		"age": true, "birthdate": true, "language_level": true,
		"has_training": true, "measure_start": true, "motorik_level": true,
	}

	var sets []string
	var args []any
	for k, v := range req {
		if !allowed[k] {
			continue
		}
		sets = append(sets, k+" = ?")
		args = append(args, v)
	}
	if len(sets) == 0 {
		http.Error(w, "no valid fields", http.StatusBadRequest)
		return
	}

	args = append(args, userID, sess.DeptID)
	_, err = a.DB.Exec(
		"UPDATE users SET "+strings.Join(sets, ", ")+" WHERE id = ? AND dept_id = ?",
		args...,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *UsersAPI) Delete(w http.ResponseWriter, r *http.Request) {
	sess := GetSession(r)
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}

	idStr := strings.TrimPrefix(r.URL.Path, "/api/users/")
	userID, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "invalid user id", http.StatusBadRequest)
		return
	}

	// Soft delete
	_, err = a.DB.Exec("UPDATE users SET active = 0 WHERE id = ? AND dept_id = ?", userID, sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *UsersAPI) changePassword(w http.ResponseWriter, r *http.Request, sess *auth.Session, userID int) {
	// Admin can change any, user can change own
	if sess.Role != "admin" && sess.UserID != userID {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		Password           string `json:"password"`
		MustChangePassword bool   `json:"must_change_password"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	hash, err := auth.HashPassword(req.Password)
	if err != nil {
		http.Error(w, "hash error", http.StatusInternalServerError)
		return
	}
	_, err = a.DB.Exec(
		"UPDATE users SET password_hash = ?, must_change_password = ? WHERE id = ? AND dept_id = ?",
		hash, req.MustChangePassword, userID, sess.DeptID,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *UsersAPI) changeRfid(w http.ResponseWriter, r *http.Request, sess *auth.Session, userID int) {
	if sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		RfidHash string `json:"rfid_hash"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec(
		"UPDATE users SET rfid_hash = ? WHERE id = ? AND dept_id = ?",
		req.RfidHash, userID, sess.DeptID,
	)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (a *UsersAPI) changeTheme(w http.ResponseWriter, r *http.Request, sess *auth.Session, userID int) {
	if sess.UserID != userID && sess.Role != "admin" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	var req struct {
		Theme string `json:"theme"`
	}
	if err := decodeJSON(r, &req); err != nil {
		http.Error(w, "invalid request", http.StatusBadRequest)
		return
	}
	_, err := a.DB.Exec("UPDATE users SET theme = ? WHERE id = ? AND dept_id = ?", req.Theme, userID, sess.DeptID)
	if err != nil {
		internalError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
