package middleware

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
)

type userRateLimit struct {
	Count     int       `json:"count"`
	ResetTime time.Time `json:"reset_time"`
}

func getPersistencePath() string {
	return filepath.Join(os.TempDir(), "kap_rate_limits.json")
}

func loadPersistedLimits() map[string]*userRateLimit {
	limits := make(map[string]*userRateLimit)
	path := getPersistencePath()
	data, err := os.ReadFile(path)
	if err != nil {
		return limits
	}
	_ = json.Unmarshal(data, &limits)
	return limits
}

func savePersistedLimits(limits map[string]*userRateLimit) {
	path := getPersistencePath()
	data, err := json.Marshal(limits)
	if err == nil {
		_ = os.WriteFile(path, data, 0600)
	}
}

// AIRateLimiter limits AI requests per user ID to prevent API quota depletion with file persistence.
func AIRateLimiter(maxRequests int, window time.Duration) fiber.Handler {
	var mu sync.Mutex
	userLimits := loadPersistedLimits()

	// Clean up expired limits on startup
	now := time.Now()
	for userID, limit := range userLimits {
		if now.After(limit.ResetTime) {
			delete(userLimits, userID)
		}
	}

	// Background cleanup & persistence goroutine
	go func() {
		ticker := time.NewTicker(1 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			mu.Lock()
			currentNow := time.Now()
			modified := false
			for userID, limit := range userLimits {
				if currentNow.After(limit.ResetTime) {
					delete(userLimits, userID)
					modified = true
				}
			}
			if modified || len(userLimits) > 0 {
				savePersistedLimits(userLimits)
			}
			mu.Unlock()
		}
	}()

	return func(c *fiber.Ctx) error {
		userID, ok := c.Locals("userID").(string)
		if !ok || userID == "" {
			userID = c.IP()
		}

		mu.Lock()
		reqNow := time.Now()
		limit, exists := userLimits[userID]

		if !exists || reqNow.After(limit.ResetTime) {
			userLimits[userID] = &userRateLimit{
				Count:     1,
				ResetTime: reqNow.Add(window),
			}
			savePersistedLimits(userLimits)
			mu.Unlock()
			return c.Next()
		}

		if limit.Count >= maxRequests {
			mu.Unlock()
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error":       "rate_limit_exceeded",
				"message":     "Çok fazla AI isteği gönderdiniz. Lütfen bir süre sonra tekrar deneyin.",
				"retry_after": int(time.Until(limit.ResetTime).Seconds()),
			})
		}

		limit.Count++
		savePersistedLimits(userLimits)
		mu.Unlock()
		return c.Next()
	}
}
