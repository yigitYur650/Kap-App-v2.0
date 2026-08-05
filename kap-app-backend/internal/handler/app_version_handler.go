package handler

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"time"

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

type PushNotificationReq struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

// SendPushNotificationHandler (POST /api/v1/admin/push-notification) sends an instant FCM push broadcast to all devices.
func (h *AppVersionHandler) SendPushNotificationHandler(c *fiber.Ctx) error {
	var req PushNotificationReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	if req.Title == "" || req.Body == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "title and body are required",
		})
	}

	// Dispatch server-to-server FCM push to Google FCM
	fcmKey := "AIzaSyBFsCBCnESnkgw3LoYHqzZWBIZ1dE4-J-I"
	payload := map[string]interface{}{
		"to":       "/topics/all_users",
		"priority": "high",
		"notification": map[string]string{
			"title": req.Title,
			"body":  req.Body,
			"sound": "default",
		},
		"data": map[string]string{
			"title":        req.Title,
			"body":         req.Body,
			"click_action": "FLUTTER_NOTIFICATION_CLICK",
		},
	}

	jsonBytes, _ := json.Marshal(payload)
	httpReq, err := http.NewRequest("POST", "https://fcm.googleapis.com/fcm/send", bytes.NewBuffer(jsonBytes))
	if err == nil {
		httpReq.Header.Set("Content-Type", "application/json")
		httpReq.Header.Set("Authorization", "key="+fcmKey)

		client := &http.Client{Timeout: 10 * time.Second}
		resp, err := client.Do(httpReq)
		if err == nil {
			defer resp.Body.Close()
			bodyBytes, _ := io.ReadAll(resp.Body)
			log.Printf("[FCM Server-to-Server Result] status=%d body=%s", resp.StatusCode, string(bodyBytes))
		} else {
			log.Printf("[FCM Server-to-Server Error] %v", err)
		}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "push_notification_dispatched_successfully",
	})
}
