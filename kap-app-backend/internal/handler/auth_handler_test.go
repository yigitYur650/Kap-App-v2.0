package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"kap-app-backend/internal/service"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
)

// mockAuthService implements domain.AuthService for testing.
type mockAuthService struct {
	mockGenerateUniqueCode func(userID string) (string, error)
}

func (m *mockAuthService) GenerateUniqueCode(userID string) (string, error) {
	return m.mockGenerateUniqueCode(userID)
}

// buildTestApp creates a Fiber app with the auth handler registered.
// The injectUserID flag controls whether the userID local is pre-set (simulating the auth middleware).
func buildTestApp(svc *mockAuthService, injectUserID bool) *fiber.App {
	app := fiber.New()
	h := NewAuthHandler(svc)

	app.Post("/auth/unique-code", func(c *fiber.Ctx) error {
		if injectUserID {
			c.Locals("userID", "test-user-id-123")
		}
		// Delegate to the actual handler under test
		return h.GenerateCode(c)
	})

	return app
}

func TestGenerateCode(t *testing.T) {
	t.Run("Should return 200 and unique_code on success", func(t *testing.T) {
		svc := &mockAuthService{
			mockGenerateUniqueCode: func(userID string) (string, error) {
				assert.Equal(t, "test-user-id-123", userID)
				return "ABCD-EFGH", nil
			},
		}
		app := buildTestApp(svc, true)

		req := httptest.NewRequest(http.MethodPost, "/auth/unique-code", nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusOK, resp.StatusCode)

		var body GenerateCodeResponse
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Equal(t, "ABCD-EFGH", body.UniqueCode)
	})

	t.Run("Should return 401 when userID is missing from context (middleware bypassed)", func(t *testing.T) {
		// No service call expected when auth check fails
		svc := &mockAuthService{
			mockGenerateUniqueCode: func(userID string) (string, error) {
				t.Fatal("GenerateUniqueCode should NOT be called when userID is missing")
				return "", nil
			},
		}
		app := buildTestApp(svc, false) // injectUserID = false

		req := httptest.NewRequest(http.MethodPost, "/auth/unique-code", nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Unauthorized")
	})

	t.Run("Should return 500 when ErrCollisionLimitReached is returned", func(t *testing.T) {
		svc := &mockAuthService{
			mockGenerateUniqueCode: func(userID string) (string, error) {
				return "", service.ErrCollisionLimitReached
			},
		}
		app := buildTestApp(svc, true)

		req := httptest.NewRequest(http.MethodPost, "/auth/unique-code", nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusInternalServerError, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "collision_limit_reached")
	})

	t.Run("Should return 500 on any generic service error", func(t *testing.T) {
		svc := &mockAuthService{
			mockGenerateUniqueCode: func(userID string) (string, error) {
				return "", errors.New("unexpected database error")
			},
		}
		app := buildTestApp(svc, true)

		req := httptest.NewRequest(http.MethodPost, "/auth/unique-code", nil)
		resp, err := app.Test(req)
		assert.NoError(t, err)
		assert.Equal(t, http.StatusInternalServerError, resp.StatusCode)

		var body map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&body)
		assert.NoError(t, err)
		assert.Contains(t, body["error"], "Failed to generate unique code")
	})
}
