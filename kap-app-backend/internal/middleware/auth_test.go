package middleware

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
)

func generateTestToken(secret string, claims jwt.MapClaims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func TestAuthRequired(t *testing.T) {
	secret := "test_jwt_secret_key_12345"
	app := fiber.New()

	// Register a dummy protected endpoint
	app.Get("/protected", AuthRequired(secret), func(c *fiber.Ctx) error {
		userID := c.Locals("userID")
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"userID": userID,
		})
	})

	t.Run("Valid token should pass and set userID in context", func(t *testing.T) {
		expectedUserID := "user-uuid-12345"
		token, err := generateTestToken(secret, jwt.MapClaims{
			"sub": expectedUserID,
			"exp": time.Now().Add(time.Hour).Unix(),
		})
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/protected", nil)
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Equal(t, expectedUserID, body["userID"])
	})

	t.Run("Missing Authorization header should return 401", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/protected", nil)

		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Missing authorization header")
	})

	t.Run("Malformed Authorization header (no Bearer) should return 401", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/protected", nil)
		req.Header.Set("Authorization", "Basic credentials123")

		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Invalid authorization header format")
	})

	t.Run("Token signed with invalid secret should return 401", func(t *testing.T) {
		wrongSecret := "wrong_secret_key"
		token, err := generateTestToken(wrongSecret, jwt.MapClaims{
			"sub": "some-user-id",
			"exp": time.Now().Add(time.Hour).Unix(),
		})
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/protected", nil)
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Invalid or expired authorization token")
	})

	t.Run("Expired token should return 401", func(t *testing.T) {
		token, err := generateTestToken(secret, jwt.MapClaims{
			"sub": "some-user-id",
			"exp": time.Now().Add(-time.Hour).Unix(), // Expired 1 hour ago
		})
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/protected", nil)
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Invalid or expired authorization token")
	})

	t.Run("Token missing sub claim should return 401", func(t *testing.T) {
		token, err := generateTestToken(secret, jwt.MapClaims{
			"exp": time.Now().Add(time.Hour).Unix(),
		})
		assert.NoError(t, err)

		req := httptest.NewRequest("GET", "/protected", nil)
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", token))

		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Missing subject (sub) claim in token")
	})
}
