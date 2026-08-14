package handler

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"kap-app-backend/internal/domain"

	"github.com/gofiber/fiber/v2"
)

type mockSubscriptionRepo struct {
	consumeRes *domain.AICreditConsumptionResult
	claimRes   map[string]interface{}
	recorded   map[string]bool
}

func newMockSubscriptionRepo() *mockSubscriptionRepo {
	return &mockSubscriptionRepo{
		consumeRes: &domain.AICreditConsumptionResult{Success: true, IsPro: false, RemainingCredits: 1},
		claimRes:   map[string]interface{}{"success": true, "reason": "reward_granted"},
		recorded:   make(map[string]bool),
	}
}

func (m *mockSubscriptionRepo) ConsumeAICredit(userID string) (*domain.AICreditConsumptionResult, error) {
	return m.consumeRes, nil
}

func (m *mockSubscriptionRepo) GetUserAIStatus(userID string) (*domain.UserAIStatusDTO, error) {
	return &domain.UserAIStatusDTO{
		UserID:           userID,
		IsPro:            false,
		RemainingCredits: 2,
		FreeDailyLimit:   2,
		BonusCredits:     0,
		UsedCountToday:   0,
		ReferralCode:     "KAP-TEST123",
	}, nil
}

func (m *mockSubscriptionRepo) ClaimReferral(referrerCode, newUserID, deviceHash string) (map[string]interface{}, error) {
	return m.claimRes, nil
}

func (m *mockSubscriptionRepo) GrantUserPro(userID, email string, isPro bool, bonusCredits int) (map[string]interface{}, error) {
	return map[string]interface{}{"success": true, "user_id": userID, "is_pro": isPro}, nil
}

func (m *mockSubscriptionRepo) ProcessRevenueCatWebhook(event *domain.RevenueCatEvent) error {
	return nil
}

func (m *mockSubscriptionRepo) RecordWebhookEvent(eventID, eventType string) (bool, error) {
	if m.recorded[eventID] {
		return false, nil
	}
	m.recorded[eventID] = true
	return true, nil
}

func TestRevenueCatWebhookHandler_Idempotency(t *testing.T) {
	mockRepo := newMockSubscriptionRepo()
	h := NewSubscriptionHandler(mockRepo, "test_secret")

	app := fiber.New()
	app.Post("/webhook", h.RevenueCatWebhookHandler)

	payload := domain.RevenueCatWebhookPayload{
		Event: domain.RevenueCatEvent{
			ID:        "evt_12345",
			Type:      "INITIAL_PURCHASE",
			AppUserID: "user_abc",
		},
	}
	jsonBytes, _ := json.Marshal(payload)

	// First Request: Should process successfully
	req1 := httptest.NewRequest(http.MethodPost, "/webhook", bytes.NewReader(jsonBytes))
	req1.Header.Set("Content-Type", "application/json")
	req1.Header.Set("Authorization", "Bearer test_secret")

	resp1, err := app.Test(req1)
	if err != nil || resp1.StatusCode != http.StatusOK {
		t.Fatalf("Expected status 200, got %d, err: %v", resp1.StatusCode, err)
	}

	// Second Request (Duplicate event): Should be handled idempotently
	req2 := httptest.NewRequest(http.MethodPost, "/webhook", bytes.NewReader(jsonBytes))
	req2.Header.Set("Content-Type", "application/json")
	req2.Header.Set("Authorization", "Bearer test_secret")

	resp2, err := app.Test(req2)
	if err != nil || resp2.StatusCode != http.StatusOK {
		t.Fatalf("Expected status 200 for duplicate event, got %d, err: %v", resp2.StatusCode, err)
	}
}

func TestClaimReferralHandler(t *testing.T) {
	mockRepo := newMockSubscriptionRepo()
	h := NewSubscriptionHandler(mockRepo, "")

	app := fiber.New()
	app.Use(func(c *fiber.Ctx) error {
		c.Locals("userID", "user_new_123")
		return c.Next()
	})
	app.Post("/referral/claim", h.ClaimReferralHandler)

	claimBody := ClaimReferralReq{
		ReferrerCode: "KAP-FRIEND",
		DeviceHash:   "device_hash_xyz",
	}
	jsonBytes, _ := json.Marshal(claimBody)

	req := httptest.NewRequest(http.MethodPost, "/referral/claim", bytes.NewReader(jsonBytes))
	req.Header.Set("Content-Type", "application/json")

	resp, err := app.Test(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		t.Fatalf("Expected status 200, got %d, err: %v", resp.StatusCode, err)
	}
}
