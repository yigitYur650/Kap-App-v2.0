package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// Config holds the application configuration loaded from environment variables.
type Config struct {
	Port                   string
	SupabaseURL            string
	SupabaseServiceRoleKey string
	SupabaseJWTSecret      string
}

// LoadConfig loads application configuration from environment variables and optionally a .env file.
func LoadConfig() *Config {
	// Attempt to load .env file if it exists, but don't fail if it's missing (e.g. in production environment)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, reading configurations directly from environment variables")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default fallback port
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseServiceRoleKey := os.Getenv("SUPABASE_SERVICE_ROLE_KEY")
	supabaseJWTSecret := os.Getenv("SUPABASE_JWT_SECRET")

	return &Config{
		Port:                   port,
		SupabaseURL:            supabaseURL,
		SupabaseServiceRoleKey: supabaseServiceRoleKey,
		SupabaseJWTSecret:      supabaseJWTSecret,
	}
}
