package integration

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/stretchr/testify/assert"
)

func buildTestAppWithCORS() *fiber.App {
	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins:     "http://localhost:3000, http://localhost:8080, http://localhost:49825, http://localhost:5000",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
		AllowMethods:     "GET, POST, PUT, PATCH, DELETE, OPTIONS",
		AllowCredentials: true,
	}))

	app.Post("/api/v1/auth/unique-code", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	app.Get("/protected/user", func(c *fiber.Ctx) error {
		return c.SendStatus(fiber.StatusOK)
	})

	return app
}

func TestCORS_PreflightAndAllowedOrigins(t *testing.T) {
	app := buildTestAppWithCORS()

	// 1. Simulate browser preflight OPTIONS request
	req := httptest.NewRequest("OPTIONS", "/api/v1/auth/unique-code", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "POST")
	req.Header.Set("Access-Control-Request-Headers", "Content-Type, Authorization")

	resp, err := app.Test(req)
	assert.NoError(t, err)
	assert.True(t, resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusNoContent)
	assert.Equal(t, "http://localhost:3000", resp.Header.Get("Access-Control-Allow-Origin"))
	assert.Equal(t, "true", resp.Header.Get("Access-Control-Allow-Credentials"))

	// 2. Simulate standard cross-origin request (e.g. POST)
	req2 := httptest.NewRequest("POST", "/api/v1/auth/unique-code", nil)
	req2.Header.Set("Origin", "http://localhost:3000")

	resp2, err := app.Test(req2)
	assert.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp2.StatusCode)
	assert.Equal(t, "http://localhost:3000", resp2.Header.Get("Access-Control-Allow-Origin"))
	assert.Equal(t, "true", resp2.Header.Get("Access-Control-Allow-Credentials"))
}

func TestCORS_AllAllowedOrigins(t *testing.T) {
	app := buildTestAppWithCORS()
	allowedOrigins := []string{
		"http://localhost:3000",
		"http://localhost:8080",
		"http://localhost:49825",
		"http://localhost:5000",
	}

	for _, origin := range allowedOrigins {
		t.Run("Origin_"+origin, func(t *testing.T) {
			req := httptest.NewRequest("OPTIONS", "/api/v1/auth/unique-code", nil)
			req.Header.Set("Origin", origin)
			req.Header.Set("Access-Control-Request-Method", "POST")

			resp, err := app.Test(req)
			assert.NoError(t, err)
			assert.Equal(t, origin, resp.Header.Get("Access-Control-Allow-Origin"),
				"Origin %s should be allowed", origin)
			assert.Equal(t, "true", resp.Header.Get("Access-Control-Allow-Credentials"))
		})
	}
}

func TestCORS_DisallowedOrigin(t *testing.T) {
	app := buildTestAppWithCORS()
	disallowedOrigins := []string{
		"http://evil-site.com",
		"https://phishing-page.com",
		"http://localhost:9999",
		"http://192.168.1.1:8080",
	}

	for _, origin := range disallowedOrigins {
		t.Run("Origin_"+origin, func(t *testing.T) {
			req := httptest.NewRequest("OPTIONS", "/api/v1/auth/unique-code", nil)
			req.Header.Set("Origin", origin)
			req.Header.Set("Access-Control-Request-Method", "POST")

			resp, err := app.Test(req)
			assert.NoError(t, err)
			assert.NotEqual(t, origin, resp.Header.Get("Access-Control-Allow-Origin"),
				"Origin %s should NOT be allowed", origin)
		})
	}
}

func TestCORS_OPTIONS_DoesNotRequireAuth(t *testing.T) {
	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins:     "http://localhost:3000",
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization",
		AllowMethods:     "GET, POST, PUT, PATCH, DELETE, OPTIONS",
		AllowCredentials: true,
	}))

	// Simulate a protected route (no actual auth middleware, just check OPTIONS bypass)
	app.Post("/api/v1/auth/unique-code", func(c *fiber.Ctx) error {
		// Simulate auth check: if this is reached without Authorization header, fail
		authHeader := c.Get("Authorization")
		if authHeader == "" && c.Method() != http.MethodOptions {
			return c.SendStatus(fiber.StatusUnauthorized)
		}
		return c.SendStatus(fiber.StatusOK)
	})

	// OPTIONS without Authorization header should still pass (preflight)
	req := httptest.NewRequest("OPTIONS", "/api/v1/auth/unique-code", nil)
	req.Header.Set("Origin", "http://localhost:3000")
	req.Header.Set("Access-Control-Request-Method", "POST")

	resp, err := app.Test(req)
	assert.NoError(t, err)
	assert.True(t, resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusNoContent)
	assert.Equal(t, "http://localhost:3000", resp.Header.Get("Access-Control-Allow-Origin"))
}
