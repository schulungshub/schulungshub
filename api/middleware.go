package api

import (
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"

	"schulungshub/auth"
)

type contextKey string

const (
	sessionKey contextKey = "session"
	tsFormat              = "2006-01-02 15:04:05"
)

// RequireAuth middleware checks for valid session.
func RequireAuth(db *sql.DB, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token := auth.GetTokenFromRequest(r)
		if token == "" {
			http.Error(w, "not authenticated", http.StatusUnauthorized)
			return
		}
		sess, err := auth.GetSession(db, token)
		if err != nil {
			auth.ClearSessionCookie(w)
			http.Error(w, "not authenticated", http.StatusUnauthorized)
			return
		}
		ctx := context.WithValue(r.Context(), sessionKey, sess)
		next(w, r.WithContext(ctx))
	}
}

// RequireRole middleware checks for minimum role level.
func RequireRole(roles []string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		sess := GetSession(r)
		if sess == nil {
			http.Error(w, "not authenticated", http.StatusUnauthorized)
			return
		}
		for _, role := range roles {
			if sess.Role == role {
				next(w, r)
				return
			}
		}
		http.Error(w, "forbidden", http.StatusForbidden)
	}
}

func GetSession(r *http.Request) *auth.Session {
	sess, _ := r.Context().Value(sessionKey).(*auth.Session)
	return sess
}

// internalError logs the real error and returns a generic 500 to the client.
// Prevents leaking DB internals (table names, column names, query structure).
func internalError(w http.ResponseWriter, err error) {
	log.Printf("ERROR: %v", err)
	http.Error(w, "internal server error", http.StatusInternalServerError)
}

func writeJSON(w http.ResponseWriter, data any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func decodeJSON(r *http.Request, v any) error {
	return json.NewDecoder(r.Body).Decode(v)
}
