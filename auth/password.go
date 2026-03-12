package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"fmt"
	"strconv"
	"strings"

	"golang.org/x/crypto/pbkdf2"
)

const (
	pbkdfIterations = 120000
	pbkdfKeyLen     = 32
)

// HashPassword creates a PBKDF2-SHA256 hash compatible with the existing frontend format.
// Format: pbkdf2_sha256$iterations$salt_hex$hash_hex
func HashPassword(password string) (string, error) {
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	saltHex := hex.EncodeToString(salt)
	dk := pbkdf2.Key([]byte(password), salt, pbkdfIterations, pbkdfKeyLen, sha256.New)
	hashHex := hex.EncodeToString(dk)
	return fmt.Sprintf("pbkdf2_sha256$%d$%s$%s", pbkdfIterations, saltHex, hashHex), nil
}

// VerifyPassword checks a password against a stored PBKDF2-SHA256 hash.
func VerifyPassword(password, stored string) bool {
	parts := strings.Split(stored, "$")
	if len(parts) != 4 || parts[0] != "pbkdf2_sha256" {
		return false
	}
	iterations, err := strconv.Atoi(parts[1])
	if err != nil {
		return false
	}
	salt, err := hex.DecodeString(parts[2])
	if err != nil {
		return false
	}
	expected, err := hex.DecodeString(parts[3])
	if err != nil {
		return false
	}
	dk := pbkdf2.Key([]byte(password), salt, iterations, len(expected), sha256.New)
	return subtle.ConstantTimeCompare(dk, expected) == 1
}
