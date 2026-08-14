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
	CORSAllowedOrigins     string
	GroqAPIKey             string
	GeminiAPIKey           string
	RevenueCatWebhookSecret string
}

// LoadConfig loads application configuration from environment variables and optionally a .env file.
func LoadConfig() *Config {
	// Attempt to load .env file from current directory or fallback to parent directory
	if err := godotenv.Load(); err != nil {
		if errParent := godotenv.Load("../.env"); errParent != nil {
			log.Println("No .env file found in current or parent directory, reading configurations directly from environment variables")
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // Default fallback port
	}

	supabaseURL := os.Getenv("SUPABASE_URL")
	supabaseServiceRoleKey := os.Getenv("SUPABASE_SERVICE_ROLE_KEY")
	supabaseJWTSecret := os.Getenv("SUPABASE_JWT_SECRET")
	corsAllowedOrigins := os.Getenv("CORS_ALLOWED_ORIGINS")
	if corsAllowedOrigins == "" {
		corsAllowedOrigins = "http://localhost:3000,http://localhost:8080,http://localhost:9000"
	}

	groqAPIKey := os.Getenv("GROQ_API_KEY")
	geminiAPIKey := os.Getenv("GEMINI_API_KEY")
	revCatSecret := os.Getenv("REVENUECAT_WEBHOOK_SECRET")

	return &Config{
		Port:                   port,
		SupabaseURL:            supabaseURL,
		SupabaseServiceRoleKey: supabaseServiceRoleKey,
		SupabaseJWTSecret:      supabaseJWTSecret,
		CORSAllowedOrigins:     corsAllowedOrigins,
		GroqAPIKey:             groqAPIKey,
		GeminiAPIKey:           geminiAPIKey,
		RevenueCatWebhookSecret: revCatSecret,
	}
}
