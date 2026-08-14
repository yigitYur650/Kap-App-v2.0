package domain

import (
	"time"
)

// UserAIUsage represents the AI credit usage tracking for a user.
type UserAIUsage struct {
	UserID         string    `json:"user_id"`
	IsPro          bool      `json:"is_pro"`
	FreeDailyLimit int       `json:"free_daily_limit"`
	BonusCredits   int       `json:"bonus_credits"`
	UsedCountToday int       `json:"used_count_today"`
	LastResetDate  string    `json:"last_reset_date"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// AICreditConsumptionResult represents the response from the atomic RPC `consume_ai_credit`.
type AICreditConsumptionResult struct {
	Success          bool   `json:"success"`
	IsPro            bool   `json:"is_pro"`
	RemainingCredits int    `json:"remaining_credits"`
	Reason           string `json:"reason"`
}

// UserAIStatusDTO combines subscription and AI usage details for client UI state.
type UserAIStatusDTO struct {
	UserID           string `json:"user_id"`
	IsPro            bool   `json:"is_pro"`
	RemainingCredits int    `json:"remaining_credits"`
	FreeDailyLimit   int    `json:"free_daily_limit"`
	BonusCredits     int    `json:"bonus_credits"`
	UsedCountToday   int    `json:"used_count_today"`
	ReferralCode     string `json:"referral_code"`
}
