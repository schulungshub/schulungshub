package auth

import (
	"net"
	"net/http"
	"sync"
	"time"
)

const (
	maxAttempts  = 5
	windowPeriod = 5 * time.Minute
	lockoutPeriod = 5 * time.Minute
)

type loginAttempt struct {
	count     int
	firstSeen time.Time
	lockedUntil time.Time
}

var (
	loginAttempts = make(map[string]*loginAttempt)
	loginMu       sync.Mutex
)

// CheckRateLimit returns true if the IP is allowed to proceed, false if blocked.
func CheckRateLimit(r *http.Request) bool {
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		ip = r.RemoteAddr
	}
	// Respect X-Forwarded-For from trusted reverse proxy
	if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
		ip = fwd
	}

	loginMu.Lock()
	defer loginMu.Unlock()

	now := time.Now()
	a, ok := loginAttempts[ip]
	if !ok {
		loginAttempts[ip] = &loginAttempt{count: 1, firstSeen: now}
		return true
	}

	// Still locked out?
	if now.Before(a.lockedUntil) {
		return false
	}

	// Reset window if expired
	if now.Sub(a.firstSeen) > windowPeriod {
		a.count = 1
		a.firstSeen = now
		a.lockedUntil = time.Time{}
		return true
	}

	a.count++
	if a.count > maxAttempts {
		a.lockedUntil = now.Add(lockoutPeriod)
		return false
	}
	return true
}

// ResetRateLimit clears the counter for an IP after a successful login.
func ResetRateLimit(r *http.Request) {
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		ip = r.RemoteAddr
	}
	if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
		ip = fwd
	}

	loginMu.Lock()
	delete(loginAttempts, ip)
	loginMu.Unlock()
}
