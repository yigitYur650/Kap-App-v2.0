package config

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLoadConfig_DefaultPort(t *testing.T) {
	// Ensure PORT env is unset
	os.Unsetenv("PORT")
	os.Unsetenv("SUPABASE_URL")
	os.Unsetenv("SUPABASE_SERVICE_ROLE_KEY")
	os.Unsetenv("SUPABASE_JWT_SECRET")

	cfg := LoadConfig()
	assert.Equal(t, "8080", cfg.Port, "Default port should be 8080")
}

func TestLoadConfig_CustomPort(t *testing.T) {
	os.Setenv("PORT", "9090")
	os.Setenv("SUPABASE_URL", "https://test.supabase.co")
	os.Setenv("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key")
	os.Setenv("SUPABASE_JWT_SECRET", "test-jwt-secret")
	defer os.Unsetenv("PORT")
	defer os.Unsetenv("SUPABASE_URL")
	defer os.Unsetenv("SUPABASE_SERVICE_ROLE_KEY")
	defer os.Unsetenv("SUPABASE_JWT_SECRET")

	cfg := LoadConfig()
	assert.Equal(t, "9090", cfg.Port)
	assert.Equal(t, "https://test.supabase.co", cfg.SupabaseURL)
	assert.Equal(t, "test-service-role-key", cfg.SupabaseServiceRoleKey)
	assert.Equal(t, "test-jwt-secret", cfg.SupabaseJWTSecret)
}
