package middleware

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// ============================================================
// JWKCache: Thread-Safe, TTL-Based Public Key Cache
// ============================================================
// This cache stores ECDSA public keys fetched from Supabase's
// JWKS endpoint. It uses a read-write lock (sync.RWMutex) to
// allow concurrent reads without contention, and serializes
// writes only when the cache is expired or a key is missing.
//
// TTL defaults to 1 hour. If the remote JWKS fetch fails when
// the cache is expired, stale keys are served for an additional
// 5-minute grace period to prevent transient network blips from
// blocking authentication.
// ============================================================

// JWKCache holds the in-memory cache of JWKS public keys with TTL management.
type JWKCache struct {
	mu          sync.RWMutex
	keys        map[string]*ecdsa.PublicKey
	expiresAt   time.Time
	ttl         time.Duration
	supabaseURL string
}

// NewJWKCache creates a new JWK cache with the given TTL and Supabase URL.
// Default TTL of 1 hour is used if ttl is zero.
func NewJWKCache(supabaseURL string, ttl time.Duration) *JWKCache {
	if ttl <= 0 {
		ttl = 1 * time.Hour
	}
	return &JWKCache{
		keys:        make(map[string]*ecdsa.PublicKey),
		expiresAt:   time.Now(), // Expired on creation — first access fetches
		ttl:         ttl,
		supabaseURL: strings.TrimSuffix(supabaseURL, "/"),
	}
}

// getKey retrieves a public key by its Key ID (kid).
// It implements the following strategy:
//  1. Acquire RLock — if cache is valid (not expired) and key exists, return immediately.
//  2. If expired or missing, release RLock, acquire full Lock, attempt remote fetch.
//  3. If remote fetch fails AND cache is expired but not beyond the stale grace period,
//     serve the stale keys for up to 5 extra minutes.
//  4. If the key genuinely doesn't exist (even after fetch), return an error.
func (c *JWKCache) getKey(kid string) (*ecdsa.PublicKey, error) {
	// --- Fast path: read-lock check ---
	c.mu.RLock()
	if time.Now().Before(c.expiresAt) {
		if key, exists := c.keys[kid]; exists {
			c.mu.RUnlock()
			return key, nil
		}
	}
	c.mu.RUnlock()

	// --- Slow path: acquire write lock and fetch ---
	c.mu.Lock()
	defer c.mu.Unlock()

	// Double-check under write lock (another goroutine may have refreshed)
	if time.Now().Before(c.expiresAt) {
		if key, exists := c.keys[kid]; exists {
			return key, nil
		}
		return nil, fmt.Errorf("key ID %s not found in JWKS (cache valid but key missing)", kid)
	}

	// Cache is expired — attempt remote fetch
	err := c.refreshLocked()
	if err != nil {
		// --- Stale fallback: serve old keys for up to 5 extra minutes ---
		// This prevents transient network blips from causing mass 401 errors.
		staleDeadline := c.expiresAt.Add(5 * time.Minute)
		if time.Now().Before(staleDeadline) && len(c.keys) > 0 {
			log.Printf("[WARN] JWKS fetch failed, serving stale keys for up to 5 more minutes: %v", err)
			if key, exists := c.keys[kid]; exists {
				return key, nil
			}
			return nil, fmt.Errorf("key ID %s not found in stale JWKS cache", kid)
		}
		return nil, fmt.Errorf("failed to refresh JWKS cache and stale keys expired: %w", err)
	}

	// Look up the requested key from the refreshed cache
	if key, exists := c.keys[kid]; exists {
		return key, nil
	}
	return nil, fmt.Errorf("key ID %s not found in refreshed JWKS", kid)
}

// refreshLocked fetches the latest JWKS from Supabase and rebuilds the cache.
// MUST be called with c.mu write lock held.
func (c *JWKCache) refreshLocked() error {
	url := fmt.Sprintf("%s/auth/v1/.well-known/jwks.json", c.supabaseURL)
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return fmt.Errorf("failed to fetch JWKS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("JWKS request returned status %d", resp.StatusCode)
	}

	var jwks struct {
		Keys []struct {
			Alg string `json:"alg"`
			Crv string `json:"crv"`
			Kid string `json:"kid"`
			Kty string `json:"kty"`
			X   string `json:"x"`
			Y   string `json:"y"`
		} `json:"keys"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return fmt.Errorf("failed to decode JWKS JSON: %w", err)
	}

	// Rebuild the key map from scratch (atomic replacement)
	newKeys := make(map[string]*ecdsa.PublicKey, len(jwks.Keys))
	for _, key := range jwks.Keys {
		if key.Kty == "EC" && key.Crv == "P-256" {
			xBytes, err := base64.RawURLEncoding.DecodeString(key.X)
			if err != nil {
				continue
			}
			yBytes, err := base64.RawURLEncoding.DecodeString(key.Y)
			if err != nil {
				continue
			}
			newKeys[key.Kid] = &ecdsa.PublicKey{
				Curve: elliptic.P256(),
				X:     new(big.Int).SetBytes(xBytes),
				Y:     new(big.Int).SetBytes(yBytes),
			}
		}
	}

	if len(newKeys) == 0 {
		return fmt.Errorf("no valid P-256 keys found in JWKS response")
	}

	c.keys = newKeys
	c.expiresAt = time.Now().Add(c.ttl)

	log.Printf("[INFO] JWKS cache refreshed: %d key(s) loaded, next refresh at %s",
		len(newKeys), c.expiresAt.Format(time.RFC3339))

	return nil
}

// --- Global singleton cache (lazily initialized) ---
var globalJWKCache *JWKCache
var globalJWKCacheOnce sync.Once

// getGlobalJWKCache returns the singleton JWK cache, creating it if needed.
func getGlobalJWKCache(supabaseURL string) *JWKCache {
	globalJWKCacheOnce.Do(func() {
		globalJWKCache = NewJWKCache(supabaseURL, 1*time.Hour)
	})
	return globalJWKCache
}

// getPublicKey is a convenience wrapper around JWKCache.getKey.
func getPublicKey(supabaseURL, kid string) (*ecdsa.PublicKey, error) {
	cache := getGlobalJWKCache(supabaseURL)
	return cache.getKey(kid)
}

// ============================================================
// AuthRequired: Fiber Middleware for Supabase JWT Verification
// ============================================================

// AuthRequired returns a Fiber middleware that enforces Supabase JWT verification.
// The jwtSecret parameter is used for HS256 (legacy/symmetric) tokens.
// The supabaseURL parameter is used for ES256 (asymmetric) tokens to fetch JWKS.
func AuthRequired(jwtSecret string, supabaseURL string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Bypass authentication for preflight OPTIONS requests
		if c.Method() == "OPTIONS" {
			return c.Next()
		}

		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing authorization header",
			})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid authorization header format",
			})
		}

		tokenString := parts[1]

		token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
			// Check if token algorithm is ES256 (Asymmetric P-256)
			if t.Method.Alg() == "ES256" {
				kid, _ := t.Header["kid"].(string)
				if kid == "" {
					return nil, fmt.Errorf("missing kid in ES256 token header")
				}

				if supabaseURL == "" {
					return nil, fmt.Errorf("SUPABASE_URL env var is not set")
				}

				return getPublicKey(supabaseURL, kid)
			}

			// Validate signing method is HMAC for HS256 (Symmetric)
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
			}

			decodedSecret, err := base64.StdEncoding.DecodeString(jwtSecret)
			if err != nil {
				// Fallback to raw secret bytes for non-base64 keys (like in unit tests)
				decodedSecret = []byte(jwtSecret)
			}
			return decodedSecret, nil
		})

		if err != nil || !token.Valid {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid or expired authorization token",
			})
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Failed to parse token claims",
			})
		}

		sub, ok := claims["sub"].(string)
		if !ok || sub == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing subject (sub) claim in token",
			})
		}

		// Inject user ID into context locals
		c.Locals("userID", sub)

		return c.Next()
	}
}
