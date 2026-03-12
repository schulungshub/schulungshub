package config

import (
	"bufio"
	"os"
	"strings"
)

type Config struct {
	DBHost        string
	DBPort        string
	DBUser        string
	DBPass        string
	DBName        string
	Port          string
	SecureCookies bool
	SetupKey      string
}

func Load() *Config {
	loadEnvFile(".env")

	return &Config{
		DBHost:        getEnv("DB_HOST", "127.0.0.1"),
		DBPort:        getEnv("DB_PORT", "3306"),
		DBUser:        getEnv("DB_USER", "root"),
		DBPass:        getEnv("DB_PASS", ""),
		DBName:        getEnv("DB_NAME", "schulungshub"),
		Port:          getEnv("PORT", "8080"),
		SecureCookies: getEnv("SECURE_COOKIES", "true") != "false",
		SetupKey:      getEnv("SETUP_KEY", ""),
	}
}

func (c *Config) DSN() string {
	return c.DBUser + ":" + c.DBPass + "@tcp(" + c.DBHost + ":" + c.DBPort + ")/" + c.DBName + "?parseTime=true&charset=utf8mb4&multiStatements=true"
}

// DSNRoot returns a DSN without database name (for CREATE DATABASE).
func (c *Config) DSNRoot() string {
	return c.DBUser + ":" + c.DBPass + "@tcp(" + c.DBHost + ":" + c.DBPort + ")/?parseTime=true&charset=utf8mb4&multiStatements=true"
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func loadEnvFile(path string) {
	f, err := os.Open(path)
	if err != nil {
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			val := strings.TrimSpace(parts[1])
			if os.Getenv(key) == "" {
				os.Setenv(key, val)
			}
		}
	}
}
