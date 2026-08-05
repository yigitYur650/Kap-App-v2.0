package handler

import (
	"kap-app-backend/pkg/supabase"

	"github.com/gofiber/fiber/v2"
)

// AppVersionHandler manages app version check and admin release endpoints.
type AppVersionHandler struct {
	sbClient *supabase.Client
}

// NewAppVersionHandler creates a new handler for app versioning and OTA updates.
func NewAppVersionHandler(sbClient *supabase.Client) *AppVersionHandler {
	return &AppVersionHandler{
		sbClient: sbClient,
	}
}

// CheckUpdateHandler (GET /api/v1/app/check-update) returns the latest released app version.
func (h *AppVersionHandler) CheckUpdateHandler(c *fiber.Ctx) error {
	latest, err := h.sbClient.GetLatestAppVersion()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	if latest == nil {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"has_update": false,
			"latest":     nil,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"has_update": true,
		"latest":     latest,
	})
}

// CreateVersionHandler (POST /api/v1/admin/app-version) allows system admins to release a new version.
func (h *AppVersionHandler) CreateVersionHandler(c *fiber.Ctx) error {
	userID, _ := c.Locals("userID").(string)

	var req supabase.AppVersion
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_request_payload",
		})
	}

	if req.VersionCode <= 0 || req.VersionName == "" || req.APKURL == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "version_code, version_name and apk_url are required",
		})
	}

	req.CreatedBy = userID

	if err := h.sbClient.CreateAppVersion(&req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "version_published_successfully",
		"version": req,
	})
}

// DeleteVersionHandler (DELETE /api/v1/admin/app-version/:id) allows system admins to cancel/delete a released version.
func (h *AppVersionHandler) DeleteVersionHandler(c *fiber.Ctx) error {
	id := c.Params("id")
	if id == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "version_id_required",
		})
	}

	if err := h.sbClient.DeleteAppVersion(id); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "version_deleted_successfully",
	})
}
