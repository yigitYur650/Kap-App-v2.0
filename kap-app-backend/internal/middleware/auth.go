package middleware

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// JWK represents a single JSON Web Key from Supabase.
type JWK struct {
	Alg string   `json:"alg"`
	Crv string   `json:"crv"`
	Kid string   `json:"kid"`
	Kty string   `json:"kty"`
	X   string   `json:"x"`
	Y   string   `json:"y"`
}

// JWKS represents the JSON Web Key Set returned by Supabase.
type JWKS struct {
	Keys []JWK `json:"keys"`
}

var (
	jwkCache = make(map[string]*ecdsa.PublicKey)
	jwkMutex sync.RWMutex
)

// fetchPublicKey fetches the public key from the Supabase JWKS endpoint and parses it.
func fetchPublicKey(supabaseURL, kid string) (*ecdsa.PublicKey, error) {
	// 1. Read from cache under read-lock
	jwkMutex.RLock()
	pubKey, exists := jwkCache[kid]
	jwkMutex.RUnlock()
	if exists {
		return pubKey, nil
	}

	// 2. Lock for writing and fetch from network
	jwkMutex.Lock()
	defer jwkMutex.Unlock()

	// Double check under write lock to avoid duplicate fetch
	if pubKey, exists = jwkCache[kid]; exists {
		return pubKey, nil
	}

	url := fmt.Sprintf("%s/auth/v1/.well-known/jwks.json", strings.TrimSuffix(supabaseURL, "/"))
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWKS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("JWKS request returned status %d", resp.StatusCode)
	}

	var jwks JWKS
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("failed to decode JWKS JSON: %w", err)
	}

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

			parsedKey := &ecdsa.PublicKey{
				Curve: elliptic.P256(),
				X:     new(big.Int).SetBytes(xBytes),
				Y:     new(big.Int).SetBytes(yBytes),
			}
			jwkCache[key.Kid] = parsedKey
		}
	}

	pubKey, exists = jwkCache[kid]
	if !exists {
		return nil, fmt.Errorf("key ID %s not found in JWKS", kid)
	}

	return pubKey, nil
}

// AuthRequired returns a Fiber middleware that enforces Supabase JWT verification.
func AuthRequired(jwtSecret string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Bypass authentication for preflight OPTIONS requests
		if c.Method() == "OPTIONS" {
			return c.Next()
		}

		authHeader := c.Get("Authorization")
		if authHeader == "" {
			fmt.Printf("[DEBUG] Missing Authorization header. All headers received: %v\n", c.GetReqHeaders())
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

				supabaseURL := os.Getenv("SUPABASE_URL")
				if supabaseURL == "" {
					return nil, fmt.Errorf("SUPABASE_URL env var is not set")
				}

				return fetchPublicKey(supabaseURL, kid)
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
			fmt.Printf("[DEBUG] JWT verification failed: %v (secret length: %d)\n", err, len(jwtSecret))
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
