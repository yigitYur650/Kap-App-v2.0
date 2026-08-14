package repository

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"kap-app-backend/internal/domain"
	"kap-app-backend/pkg/supabase"
)

type SubscriptionRepository interface {
	ConsumeAICredit(userID string) (*domain.AICreditConsumptionResult, error)
	GetUserAIStatus(userID string) (*domain.UserAIStatusDTO, error)
	ClaimReferral(referrerCode, newUserID, deviceHash string) (map[string]interface{}, error)
	GrantUserPro(userID, email string, isPro bool, durationMonths int) (map[string]interface{}, error)
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
		return &domain.AICreditConsumptionResult{
			Success:          true,
			IsPro:            false,
			RemainingCredits: 2,
			Reason:           "fallback_allow",
		}, nil
	}
	return &res, nil
}

func (r *supabaseSubscriptionRepository) GetUserAIStatus(userID string) (*domain.UserAIStatusDTO, error) {
	defaultDTO := &domain.UserAIStatusDTO{
		UserID:           userID,
		IsPro:            false,
		RemainingCredits: 2,
		FreeDailyLimit:   2,
		BonusCredits:     0,
		UsedCountToday:   0,
		ReferralCode:     "KAP-FREE",
	}

	// Fetch AI usage with graceful fallback
	usageURL := fmt.Sprintf("%s/rest/v1/user_ai_usage?user_id=eq.%s&select=*", r.client.URL, url.QueryEscape(userID))
	req, err := http.NewRequest(http.MethodGet, usageURL, nil)
	if err != nil {
		return defaultDTO, nil
	}
	req.Header.Set("apikey", r.client.ServiceRoleKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))

	resp, err := r.client.HTTPClient.Do(req)
	if err != nil {
		return defaultDTO, nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return defaultDTO, nil
	}

	var usages []domain.UserAIUsage
	if err := json.NewDecoder(resp.Body).Decode(&usages); err != nil || len(usages) == 0 {
		return defaultDTO, nil
	}

	u := usages[0]
	isPro := u.IsPro
	freeLimit := u.FreeDailyLimit
	bonus := u.BonusCredits
	usedToday := u.UsedCountToday

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

	var refCode string
	_ = r.client.CallRPC("get_or_create_referral_code", map[string]string{"p_user_id": userID}, &refCode)
	if refCode == "" {
		refCode = "KAP-FREE"
	}

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
		return map[string]interface{}{"success": false, "reason": "database_error"}, nil
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
		subStatus = "cancelled"
		if event.ExpirationAtMs > 0 && event.ExpirationAtMs > (http.DefaultClient.Timeout.Milliseconds()) {
			isPro = true
		}
	case "EXPIRATION":
		isPro = false
		subStatus = "expired"
	default:
		isPro = true
		subStatus = "active"
	}

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

func (r *supabaseSubscriptionRepository) GrantUserPro(userID, email string, isPro bool, durationMonths int) (map[string]interface{}, error) {
	targetID := strings.TrimSpace(userID)
	inputEmail := strings.TrimSpace(strings.ToLower(email))

	// 1. Check if input is directly a UUID
	if targetID == "" && len(inputEmail) == 36 && strings.Contains(inputEmail, "-") {
		targetID = inputEmail
	}
	if targetID == "" && len(userID) == 36 && strings.Contains(userID, "-") {
		targetID = userID
	}

	// 2. Search in Supabase Auth Admin Users API
	if targetID == "" && inputEmail != "" {
		authURL := fmt.Sprintf("%s/auth/v1/admin/users", r.client.URL)
		reqAuth, err := http.NewRequest(http.MethodGet, authURL, nil)
		if err == nil {
			reqAuth.Header.Set("apikey", r.client.ServiceRoleKey)
			reqAuth.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))
			respAuth, errDo := r.client.HTTPClient.Do(reqAuth)
			if errDo == nil && respAuth.StatusCode == http.StatusOK {
				var authRes struct {
					Users []struct {
						ID    string `json:"id"`
						Email string `json:"email"`
					} `json:"users"`
				}
				if errDec := json.NewDecoder(respAuth.Body).Decode(&authRes); errDec == nil {
					for _, u := range authRes.Users {
						if strings.EqualFold(strings.TrimSpace(u.Email), inputEmail) {
							targetID = u.ID
							break
						}
					}
				}
				respAuth.Body.Close()
			}
		}
	}

	// 3. Fallback: Search in profiles table
	if targetID == "" && inputEmail != "" {
		profileURL := fmt.Sprintf("%s/rest/v1/profiles?email=eq.%s&select=id", r.client.URL, url.QueryEscape(inputEmail))
		reqProf, err := http.NewRequest(http.MethodGet, profileURL, nil)
		if err == nil {
			reqProf.Header.Set("apikey", r.client.ServiceRoleKey)
			reqProf.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))
			respProf, errDo := r.client.HTTPClient.Do(reqProf)
			if errDo == nil && respProf.StatusCode == http.StatusOK {
				var profiles []struct {
					ID string `json:"id"`
				}
				_ = json.NewDecoder(respProf.Body).Decode(&profiles)
				respProf.Body.Close()
				if len(profiles) > 0 {
					targetID = profiles[0].ID
				}
			}
		}
	}

	if targetID == "" {
		return nil, fmt.Errorf("kullanıcı '%s' veritabanında bulunamadı. Lütfen kullanıcının UUID bilgisini girin.", email)
	}

	var expiresAt *time.Time
	durationText := "Sınırsız (Ömür Boyu)"

	if isPro && durationMonths > 0 {
		exp := time.Now().AddDate(0, durationMonths, 0)
		expiresAt = &exp
		durationText = fmt.Sprintf("%d Ay", durationMonths)
	}

	usageURL := fmt.Sprintf("%s/rest/v1/user_ai_usage", r.client.URL)
	usageBody := map[string]interface{}{
		"user_id":    targetID,
		"is_pro":     isPro,
		"updated_at": "now()",
	}
	if expiresAt != nil {
		usageBody["expires_at"] = expiresAt.Format(time.RFC3339)
	}
	jsonBytesUsage, _ := json.Marshal(usageBody)

	reqUsage, _ := http.NewRequest(http.MethodPost, usageURL, bytes.NewReader(jsonBytesUsage))
	reqUsage.Header.Set("apikey", r.client.ServiceRoleKey)
	reqUsage.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))
	reqUsage.Header.Set("Content-Type", "application/json")
	reqUsage.Header.Set("Prefer", "resolution=merge-duplicates")

	respUsage, errUsage := r.client.HTTPClient.Do(reqUsage)
	if errUsage == nil {
		respUsage.Body.Close()
	}

	statusStr := "expired"
	if isPro {
		statusStr = "active"
	}
	subURL := fmt.Sprintf("%s/rest/v1/user_subscriptions", r.client.URL)
	subBody := map[string]interface{}{
		"user_id":    targetID,
		"status":     statusStr,
		"store":      "admin_granted",
		"updated_at": "now()",
	}
	if expiresAt != nil {
		subBody["expires_at"] = expiresAt.Format(time.RFC3339)
	}
	jsonBytesSub, _ := json.Marshal(subBody)

	reqSub, _ := http.NewRequest(http.MethodPost, subURL, bytes.NewReader(jsonBytesSub))
	reqSub.Header.Set("apikey", r.client.ServiceRoleKey)
	reqSub.Header.Set("Authorization", fmt.Sprintf("Bearer %s", r.client.ServiceRoleKey))
	reqSub.Header.Set("Content-Type", "application/json")
	reqSub.Header.Set("Prefer", "resolution=merge-duplicates")

	respSub, errSub := r.client.HTTPClient.Do(reqSub)
	if errSub == nil {
		respSub.Body.Close()
	}

	return map[string]interface{}{
		"success":         true,
		"user_id":         targetID,
		"is_pro":          isPro,
		"duration_text":   durationText,
		"duration_months": durationMonths,
		"message":         fmt.Sprintf("Kullanıcıya %s Pro üyelik tanımlandı.", durationText),
	}, nil
}
