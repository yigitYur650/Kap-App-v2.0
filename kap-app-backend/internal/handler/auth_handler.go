package handler

import (
	"errors"
	"kap-app-backend/internal/domain"
	"kap-app-backend/internal/service"

	"github.com/gofiber/fiber/v2"
)

// AuthHandler handles HTTP requests related to authentication.
type AuthHandler struct {
	authService domain.AuthService
}

// NewAuthHandler creates a new instance of AuthHandler.
func NewAuthHandler(authService domain.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// RegisterRoutes registers auth routes under the provided router group.
func (h *AuthHandler) RegisterRoutes(router fiber.Router) {
	router.Post("/unique-code", h.GenerateCode)
}

// GenerateCodeResponse represents the DTO returned by GenerateCode.
type GenerateCodeResponse struct {
	UniqueCode string `json:"unique_code"`
}

// GenerateCode handles generating a unique community code.
func (h *AuthHandler) GenerateCode(c *fiber.Ctx) error {
	userID, ok := c.Locals("userID").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized: missing user ID in context",
		})
	}

	code, err := h.authService.GenerateUniqueCode(userID)
	if err != nil {
		if errors.Is(err, service.ErrCollisionLimitReached) {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "collision_limit_reached",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to generate unique code",
		})
	}

	return c.Status(fiber.StatusOK).JSON(GenerateCodeResponse{
		UniqueCode: code,
	})
}
