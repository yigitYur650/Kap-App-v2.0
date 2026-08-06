package middleware

import (
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
)

type userRateLimit struct {
	count     int
	resetTime time.Time
}

// AIRateLimiter limits AI requests per user ID to prevent API quota depletion.
// maxRequests: max requests allowed within window
// window: duration of rate limit window (e.g. 1 hour)
func AIRateLimiter(maxRequests int, window time.Duration) fiber.Handler {
	var mu sync.Mutex
	userLimits := make(map[string]*userRateLimit)

	// Background cleanup goroutine for stale rate limit entries
	go func() {
		for {
			time.Sleep(window)
			mu.Lock()
			now := time.Now()
			for userID, limit := range userLimits {
				if now.After(limit.resetTime) {
					delete(userLimits, userID)
				}
			}
			mu.Unlock()
		}
	}()

	return func(c *fiber.Ctx) error {
		userID, ok := c.Locals("userID").(string)
		if !ok || userID == "" {
			userID = c.IP() // Fallback to IP if userID not present
		}

		mu.Lock()
		now := time.Now()
		limit, exists := userLimits[userID]

		if !exists || now.After(limit.resetTime) {
			userLimits[userID] = &userRateLimit{
				count:     1,
				resetTime: now.Add(window),
			}
			mu.Unlock()
			return c.Next()
		}

		if limit.count >= maxRequests {
			mu.Unlock()
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error":       "rate_limit_exceeded",
				"message":     "Çok fazla AI isteği gönderdiniz. Lütfen bir süre sonra tekrar deneyin.",
				"retry_after": int(time.Until(limit.resetTime).Seconds()),
			})
		}

		limit.count++
		mu.Unlock()
		return c.Next()
	}
}
