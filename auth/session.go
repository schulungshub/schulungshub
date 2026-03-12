package auth

import (
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"net/http"
	"time"
)

const (
	sessionCookie  = "schulungshub_session"
	sessionExpiry  = 12 * time.Hour
	tokenLength    = 32
)

type Session struct {
	Token   string
	UserID  int
	DeptID  int
	Role    string
}

func GenerateToken() (string, error) {
	b := make([]byte, tokenLength)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func CreateSession(db *sql.DB, userID, deptID int) (string, error) {
	token, err := GenerateToken()
	if err != nil {
		return "", err
	}
	expires := time.Now().Add(sessionExpiry)
	_, err = db.Exec(
		"INSERT INTO sessions (token, user_id, dept_id, created_at, expires_at) VALUES (?, ?, ?, NOW(), ?)",
		token, userID, deptID, expires,
	)
	if err != nil {
		return "", err
	}
	return token, nil
}

func GetSession(db *sql.DB, token string) (*Session, error) {
	var s Session
	s.Token = token
	err := db.QueryRow(
		`SELECT s.user_id, s.dept_id, u.role
		 FROM sessions s
		 JOIN users u ON u.id = s.user_id
		 WHERE s.token = ? AND s.expires_at > NOW()`,
		token,
	).Scan(&s.UserID, &s.DeptID, &s.Role)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func DeleteSession(db *sql.DB, token string) error {
	_, err := db.Exec("DELETE FROM sessions WHERE token = ?", token)
	return err
}

func CleanExpiredSessions(db *sql.DB) {
	db.Exec("DELETE FROM sessions WHERE expires_at < NOW()")
}

func SetSessionCookie(w http.ResponseWriter, token string, secure bool) {
	http.SetCookie(w, &http.Cookie{
		Name:     sessionCookie,
		Value:    token,
		Path:     "/",
		HttpOnly: true,
		Secure:   secure,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   int(sessionExpiry.Seconds()),
	})
}

func ClearSessionCookie(w http.ResponseWriter) {
	http.SetCookie(w, &http.Cookie{
		Name:     sessionCookie,
		Value:    "",
		Path:     "/",
		HttpOnly: true,
		MaxAge:   -1,
	})
}

func GetTokenFromRequest(r *http.Request) string {
	c, err := r.Cookie(sessionCookie)
	if err != nil {
		return ""
	}
	return c.Value
}
