package repository

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"kap-app-backend/internal/domain"
	"kap-app-backend/pkg/supabase"
)

type SubscriptionRepository interface {
	ConsumeAICredit(userID string) (*domain.AICreditConsumptionResult, error)
	GetUserAIStatus(userID string) (*domain.UserAIStatusDTO, error)
	ClaimReferral(referrerCode, newUserID, deviceHash string) (map[string]interface{}, error)
	ProcessRevenueCatWebhook(event *domain.RevenueCatEvent) error
	RecordWebhookEvent(eventID, eventType string) (bool, error)
}

type supabaseSubscriptionRepository struct {
	client *supabase.Client
}

func NewSubscriptionRepository(client *supabase.Client) SubscriptionRepository {
	return &supabaseSubscriptionRepository{
		client: client,
	}
}

func (r *supabaseSubscriptionRepository) ConsumeAICredit(userID string) (*domain.AICreditConsumptionResult, error) {
	payload := map[string]string{
		"p_user_id": userID,
	}
	var res domain.AICreditConsumptionResult
	err := r.client.CallRPC("consume_ai_credit", payload, &res)
	if err != nil {
		return nil, fmt.Errorf("failed to consume AI credit: %w", err)
	}
	return &res, nil
}

func (r *supabaseSubscriptionRepository) GetUserAIStatus(userID string) (*domain.UserAIStatusDTO, error) {
	// Fetch AI usage
	usageURL := fmt.Sprintf("%s/rest/v1/user_ai_usage?user_id=eq.%s&select=*", r.client.URL, url.QueryEscape(userID))
	req, err := http.NewRequest(http.MethodGet, usageURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("apikey", r.client.ServiceRoleKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))

	resp, err := r.client.HTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var usages []domain.UserAIUsage
	if err := json.NewDecoder(resp.Body).Decode(&usages); err != nil {
		return nil, err
	}

	var isPro bool
	var freeLimit int = 2
	var bonus int = 0
	var usedToday int = 0

	if len(usages) > 0 {
		u := usages[0]
		isPro = u.IsPro
		freeLimit = u.FreeDailyLimit
		bonus = u.BonusCredits
		usedToday = u.UsedCountToday
	}

	remaining := 0
	if isPro {
		remaining = 999999
	} else {
		remDaily := freeLimit - usedToday
		if remDaily < 0 {
			remDaily = 0
		}
		remaining = remDaily + bonus
	}

	// Fetch or generate referral code via RPC
	var refCode string
	_ = r.client.CallRPC("get_or_create_referral_code", map[string]string{"p_user_id": userID}, &refCode)

	return &domain.UserAIStatusDTO{
		UserID:           userID,
		IsPro:            isPro,
		RemainingCredits: remaining,
		FreeDailyLimit:   freeLimit,
		BonusCredits:     bonus,
		UsedCountToday:   usedToday,
		ReferralCode:     refCode,
	}, nil
}

func (r *supabaseSubscriptionRepository) ClaimReferral(referrerCode, newUserID, deviceHash string) (map[string]interface{}, error) {
	payload := map[string]string{
		"p_referrer_code": referrerCode,
		"p_new_user_id":   newUserID,
		"p_device_hash":   deviceHash,
	}
	var res map[string]interface{}
	err := r.client.CallRPC("claim_referral_reward", payload, &res)
	if err != nil {
		return nil, fmt.Errorf("failed to claim referral reward: %w", err)
	}
	return res, nil
}

func (r *supabaseSubscriptionRepository) RecordWebhookEvent(eventID, eventType string) (bool, error) {
	return r.client.RecordWebhookEvent(eventID, eventType)
}

func (r *supabaseSubscriptionRepository) ProcessRevenueCatWebhook(event *domain.RevenueCatEvent) error {
	if event == nil || event.AppUserID == "" {
		return fmt.Errorf("invalid webhook payload")
	}

	userID := event.AppUserID
	eventType := strings.ToUpper(event.Type)

	isPro := false
	subStatus := "expired"

	switch eventType {
	case "INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION":
		isPro = true
		subStatus = "active"
	case "CANCELLATION":
		// Subscription is cancelled but might still be valid until expiration
		subStatus = "cancelled"
		if event.ExpirationAtMs > 0 && event.ExpirationAtMs > (http.DefaultClient.Timeout.Milliseconds()) {
			isPro = true
		}
	case "EXPIRATION":
		isPro = false
		subStatus = "expired"
	default:
		// Product change / test event
		isPro = true
		subStatus = "active"
	}

	// Update user_subscriptions table via REST API
	subURL := fmt.Sprintf("%s/rest/v1/user_subscriptions", r.client.URL)
	subBody := map[string]interface{}{
		"user_id":                 userID,
		"status":                  subStatus,
		"store":                   event.Store,
		"product_id":              event.ProductID,
		"original_transaction_id": event.OriginalTransactionID,
		"updated_at":              "now()",
	}
	jsonBytes, _ := json.Marshal(subBody)

	req, _ := http.NewRequest(http.MethodPost, subURL, bytes.NewReader(jsonBytes))
	req.Header.Set("apikey", r.client.ServiceRoleKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Prefer", "resolution=merge-duplicates")

	resp, err := r.client.HTTPClient.Do(req)
	if err == nil {
		resp.Body.Close()
	}

	// Update user_ai_usage is_pro column
	usageURL := fmt.Sprintf("%s/rest/v1/user_ai_usage?user_id=eq.%s", r.client.URL, url.QueryEscape(userID))
	usageBody := map[string]interface{}{
		"is_pro":     isPro,
		"updated_at": "now()",
	}
	jsonBytesUsage, _ := json.Marshal(usageBody)

	reqUsage, _ := http.NewRequest(http.MethodPatch, usageURL, bytes.NewReader(jsonBytesUsage))
	reqUsage.Header.Set("apikey", r.client.ServiceRoleKey)
	reqUsage.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))
	reqUsage.Header.Set("Content-Type", "application/json")

	respUsage, errUsage := r.client.HTTPClient.Do(reqUsage)
	if errUsage == nil {
		respUsage.Body.Close()
	}

	return nil
}
