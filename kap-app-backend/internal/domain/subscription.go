package domain

import (
	"time"
)

// UserSubscription represents a user's subscription record.
type UserSubscription struct {
	ID                    string     `json:"id"`
	UserID                string     `json:"user_id"`
	Status                string     `json:"status"` // active, expired, cancelled, trial, free
	Store                 string     `json:"store"`  // app_store, play_store, manual, referral
	ProductID             string     `json:"product_id"`
	OriginalTransactionID string     `json:"original_transaction_id"`
	ExpiresAt             *time.Time `json:"expires_at,omitempty"`
	CreatedAt             time.Time  `json:"created_at"`
	UpdatedAt             time.Time  `json:"updated_at"`
}

// ReferralCode represents a user's unique referral code.
type ReferralCode struct {
	UserID    string    `json:"user_id"`
	Code      string    `json:"code"`
	CreatedAt time.Time `json:"created_at"`
}

// ReferralLog represents a recorded referral reward event.
type ReferralLog struct {
	ID            string    `json:"id"`
	ReferrerID    string    `json:"referrer_id"`
	ReferredID    string    `json:"referred_id"`
	RewardClaimed bool      `json:"reward_claimed"`
	RewardType    string    `json:"reward_type"`
	DeviceHash    string    `json:"device_hash"`
	CreatedAt     time.Time `json:"created_at"`
}

// RevenueCatEvent represents the payload sent by RevenueCat Webhook v1/v2.
type RevenueCatEvent struct {
	ID                    string `json:"id"`
	Type                  string `json:"type"`
	AppUserID             string `json:"app_user_id"`
	OriginalAppUserID     string `json:"original_app_user_id"`
	ProductID             string `json:"product_id"`
	PurchasedAtMs         int64  `json:"purchased_at_ms"`
	ExpirationAtMs        int64  `json:"expiration_at_ms"`
	Store                 string `json:"store"`
	Environment           string `json:"environment"`
	OriginalTransactionID string `json:"original_transaction_id"`
}

type RevenueCatWebhookPayload struct {
	Event RevenueCatEvent `json:"event"`
}
