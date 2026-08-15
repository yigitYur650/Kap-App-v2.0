package handler

import (
	"log"
	"strings"

	"kap-app-backend/internal/domain"
	"kap-app-backend/internal/repository"

	"github.com/gofiber/fiber/v2"
)

type SubscriptionHandler struct {
	subRepo       repository.SubscriptionRepository
	webhookSecret string
}

func NewSubscriptionHandler(subRepo repository.SubscriptionRepository, webhookSecret string) *SubscriptionHandler {
	return &SubscriptionHandler{
		subRepo:       subRepo,
		webhookSecret: webhookSecret,
	}
}

// GetStatusHandler (GET /api/v1/subscriptions/status) returns current user subscription and AI quota status.
func (h *SubscriptionHandler) GetStatusHandler(c *fiber.Ctx) error {
	userID, ok := c.Locals("userID").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "unauthorized",
		})
	}

	status, err := h.subRepo.GetUserAIStatus(userID)
	if err != nil || status == nil {
		status = &domain.UserAIStatusDTO{
			UserID:           userID,
			IsPro:            false,
			RemainingCredits: 2,
			FreeDailyLimit:   2,
			BonusCredits:     0,
			UsedCountToday:   0,
			ReferralCode:     "KAP-FREE",
		}
	}

	return c.Status(fiber.StatusOK).JSON(status)
}

type ClaimReferralReq struct {
	ReferrerCode string `json:"referrer_code"`
	DeviceHash   string `json:"device_hash"`
}

// ClaimReferralHandler (POST /api/v1/referral/claim) processes referral reward claim.
func (h *SubscriptionHandler) ClaimReferralHandler(c *fiber.Ctx) error {
	userID, ok := c.Locals("userID").(string)
	if !ok || userID == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "unauthorized",
		})
	}

	var req ClaimReferralReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	if strings.TrimSpace(req.ReferrerCode) == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "referrer_code_required",
		})
	}

	if strings.TrimSpace(req.DeviceHash) == "" {
		req.DeviceHash = "unknown_device_hash"
	}

	res, err := h.subRepo.ClaimReferral(req.ReferrerCode, userID, req.DeviceHash)
	if err != nil {
		log.Printf("[SubscriptionHandler] ClaimReferral error: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "referral_claim_failed",
		})
	}

	success, _ := res["success"].(bool)
	if !success {
		return c.Status(fiber.StatusBadRequest).JSON(res)
	}

	return c.Status(fiber.StatusOK).JSON(res)
}

// RevenueCatWebhookHandler (POST /api/v1/subscriptions/webhook) handles webhooks from RevenueCat.
func (h *SubscriptionHandler) RevenueCatWebhookHandler(c *fiber.Ctx) error {
	// Secret Header Check
	if h.webhookSecret == "" {
		log.Printf("[WARN] RevenueCat webhook secret not configured, rejecting request")
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "webhook_not_configured",
		})
	}

	authHeader := c.Get("Authorization")
	expectedHeader := "Bearer " + h.webhookSecret
	if authHeader != expectedHeader && authHeader != h.webhookSecret {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "unauthorized_webhook",
		})
	}

	var payload domain.RevenueCatWebhookPayload
	if err := c.BodyParser(&payload); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	event := payload.Event
	if event.ID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "missing_event_id",
		})
	}

	// Idempotency check: record event ID
	isNew, err := h.subRepo.RecordWebhookEvent(event.ID, event.Type)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "failed_to_process_idempotency",
		})
	}

	if !isNew {
		// Already processed event — return 200 OK without re-processing
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status": "event_already_processed",
		})
	}

	if err := h.subRepo.ProcessRevenueCatWebhook(&event); err != nil {
		log.Printf("[SubscriptionHandler] ProcessRevenueCatWebhook error: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "webhook_processing_failed",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"status": "ok"})
}

type GrantUserProReq struct {
	UserID         string `json:"user_id"`
	UserEmail      string `json:"user_email"`
	IsPro          bool   `json:"is_pro"`
	DurationMonths int    `json:"duration_months"`
}

// GrantUserProHandler (POST /api/v1/admin/user-pro) allows admins to grant/revoke Pro status.
func (h *SubscriptionHandler) GrantUserProHandler(c *fiber.Ctx) error {
	var req GrantUserProReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	targetUserID := strings.TrimSpace(req.UserID)
	email := strings.TrimSpace(req.UserEmail)

	if targetUserID == "" && email == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "user_id or user_email is required",
		})
	}

	res, err := h.subRepo.GrantUserPro(targetUserID, email, req.IsPro, req.DurationMonths)
	if err != nil {
		log.Printf("[SubscriptionHandler] GrantUserPro error: %v", err)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "grant_pro_failed",
		})
	}

	return c.Status(fiber.StatusOK).JSON(res)
}
