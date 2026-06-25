package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// Config holds the application configuration loaded from environment variables.
type Config struct {
	Port string
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

	return &Config{
		Port: port,
	}
}
