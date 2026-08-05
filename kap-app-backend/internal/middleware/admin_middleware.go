package middleware

import (
	"kap-app-backend/pkg/supabase"

	"github.com/gofiber/fiber/v2"
)

// AdminRequired checks if the authenticated user (from AuthRequired middleware) is listed in system_admins table.
func AdminRequired(sbClient *supabase.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userID, ok := c.Locals("userID").(string)
		if !ok || userID == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "unauthorized_user_id_missing",
			})
		}

		isAdmin, err := sbClient.IsSystemAdmin(userID)
		if err != nil || !isAdmin {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "forbidden_system_admin_access_required",
			})
		}

		return c.Next()
	}
}
