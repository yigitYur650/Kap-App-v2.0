package http

import (
	"kap-app-back/internal/domain"

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
	router.Post("/generate-code", h.GenerateCode)
}

// GenerateCodeResponse represents the DTO returned by GenerateCode.
type GenerateCodeResponse struct {
	UniqueCode string `json:"unique_code"`
}

// GenerateCode handles generating a unique community code.
func (h *AuthHandler) GenerateCode(c *fiber.Ctx) error {
	code, err := h.authService.GenerateUniqueCode()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to generate unique code",
		})
	}

	return c.Status(fiber.StatusOK).JSON(GenerateCodeResponse{
		UniqueCode: code,
	})
}
