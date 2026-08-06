package handler

import (
	"bytes"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"kap-app-backend/pkg/supabase"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// AppVersionHandler manages app version check and admin release endpoints.
type AppVersionHandler struct {
	sbClient *supabase.Client
}

// NewAppVersionHandler creates a new handler for app versioning and OTA updates.
func NewAppVersionHandler(sbClient *supabase.Client) *AppVersionHandler {
	return &AppVersionHandler{
		sbClient: sbClient,
	}
}

// CheckUpdateHandler (GET /api/v1/app/check-update) returns the latest released app version.
func (h *AppVersionHandler) CheckUpdateHandler(c *fiber.Ctx) error {
	latest, err := h.sbClient.GetLatestAppVersion()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	if latest == nil {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"has_update": false,
			"latest":     nil,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"has_update": true,
		"latest":     latest,
	})
}

// CreateVersionHandler (POST /api/v1/admin/app-version) allows system admins to release a new version.
func (h *AppVersionHandler) CreateVersionHandler(c *fiber.Ctx) error {
	userID, _ := c.Locals("userID").(string)

	var req supabase.AppVersion
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_request_payload",
		})
	}

	if req.VersionCode <= 0 || req.VersionName == "" || req.APKURL == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "version_code, version_name and apk_url are required",
		})
	}

	req.CreatedBy = userID

	if err := h.sbClient.CreateAppVersion(&req); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "version_published_successfully",
		"version": req,
	})
}

// DeleteVersionHandler (DELETE /api/v1/admin/app-version/:id) allows system admins to cancel/delete a released version.
func (h *AppVersionHandler) DeleteVersionHandler(c *fiber.Ctx) error {
	id := c.Params("id")
	if id == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "version_id_required",
		})
	}

	if err := h.sbClient.DeleteAppVersion(id); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "version_deleted_successfully",
	})
}

type PushNotificationReq struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

// SendPushNotificationHandler (POST /api/v1/admin/push-notification) sends an instant FCM HTTP v1 push broadcast to all devices.
func (h *AppVersionHandler) SendPushNotificationHandler(c *fiber.Ctx) error {
	var req PushNotificationReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	if req.Title == "" || req.Body == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "title and body are required",
		})
	}

	// 1. Generate Google OAuth2 Token from Service Account JSON
	accessToken, projectID, err := getFCMv1AccessToken("service-account.json")
	if err != nil {
		log.Printf("[FCM v1 OAuth2 Error] %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": fmt.Sprintf("service_account_error: %v", err),
		})
	}

	// 2. Dispatch FCM HTTP v1 API payload
	fcmURL := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", projectID)
	payload := map[string]interface{}{
		"message": map[string]interface{}{
			"topic": "all_users",
			"notification": map[string]string{
				"title": req.Title,
				"body":  req.Body,
			},
			"android": map[string]interface{}{
				"priority": "HIGH",
				"notification": map[string]string{
					"sound":      "default",
					"channel_id": "kap_app_admin_channel_v2",
				},
			},
			"data": map[string]string{
				"title":        req.Title,
				"body":         req.Body,
				"click_action": "FLUTTER_NOTIFICATION_CLICK",
			},
		},
	}

	jsonBytes, _ := json.Marshal(payload)
	httpReq, err := http.NewRequest("POST", fcmURL, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+accessToken)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		log.Printf("[FCM v1 HTTP Request Error] %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(resp.Body)
	log.Printf("[FCM HTTP v1 Result] status=%d body=%s", resp.StatusCode, string(respBytes))

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "push_notification_dispatched_successfully",
		"status":  resp.StatusCode,
		"result":  string(respBytes),
	})
}

func getFCMv1AccessToken(serviceAccountPath string) (string, string, error) {
	var data []byte
	var err error

	envJSON := os.Getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
	if envJSON != "" {
		trimmed := strings.TrimSpace(envJSON)
		if strings.HasPrefix(trimmed, "{") {
			// Raw JSON string
			cleaned := strings.ReplaceAll(trimmed, "\\n", "\n")
			data = []byte(cleaned)
		} else {
			// Base64 encoded string
			decoded, b64err := base64.StdEncoding.DecodeString(trimmed)
			if b64err == nil && len(decoded) > 0 {
				data = decoded
			} else {
				cleaned := strings.ReplaceAll(trimmed, "\\n", "\n")
				data = []byte(cleaned)
			}
		}
	} else {
		data, err = os.ReadFile(serviceAccountPath)
		if err != nil {
			return "", "", fmt.Errorf("failed to read service account file: %w", err)
		}
	}

	var sa struct {
		ProjectID   string `json:"project_id"`
		ClientEmail string `json:"client_email"`
		PrivateKey  string `json:"private_key"`
	}
	if err := json.Unmarshal(data, &sa); err != nil {
		return "", "", fmt.Errorf("failed to parse service account JSON: %w", err)
	}

	pkPem := strings.ReplaceAll(sa.PrivateKey, "\\n", "\n")
	pkPem = strings.ReplaceAll(pkPem, "\r\n", "\n")
	pkPem = strings.TrimSpace(pkPem)

	block, _ := pem.Decode([]byte(pkPem))
	if block == nil {
		if !strings.HasSuffix(pkPem, "\n") {
			pkPem += "\n"
		}
		block, _ = pem.Decode([]byte(pkPem))
		if block == nil {
			return "", "", errors.New("failed to decode private key PEM")
		}
	}

	parsedKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		parsedKey, err = x509.ParsePKCS1PrivateKey(block.Bytes)
		if err != nil {
			return "", "", fmt.Errorf("failed to parse RSA private key: %w", err)
		}
	}

	rsaKey, ok := parsedKey.(*rsa.PrivateKey)
	if !ok {
		return "", "", errors.New("parsed key is not an RSA private key")
	}

	now := time.Now().Unix()
	claims := jwt.MapClaims{
		"iss":   sa.ClientEmail,
		"sub":   sa.ClientEmail,
		"aud":   "https://oauth2.googleapis.com/token",
		"iat":   now,
		"exp":   now + 3600,
		"scope": "https://www.googleapis.com/auth/firebase.messaging",
	}

	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	signedJWT, err := token.SignedString(rsaKey)
	if err != nil {
		return "", "", fmt.Errorf("failed to sign JWT: %w", err)
	}

	resp, err := http.PostForm("https://oauth2.googleapis.com/token", url.Values{
		"grant_type": {"urn:ietf:params:oauth:grant-type:jwt-bearer"},
		"assertion":  {signedJWT},
	})
	if err != nil {
		return "", "", fmt.Errorf("failed to request OAuth2 token: %w", err)
	}
	defer resp.Body.Close()

	var tokenResp struct {
		AccessToken string `json:"access_token"`
		Error       string `json:"error"`
		ErrorDesc   string `json:"error_description"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&tokenResp); err != nil {
		return "", "", fmt.Errorf("failed to decode OAuth2 response: %w", err)
	}

	if tokenResp.AccessToken == "" {
		return "", "", fmt.Errorf("OAuth2 error: %s - %s", tokenResp.Error, tokenResp.ErrorDesc)
	}

	return tokenResp.AccessToken, sa.ProjectID, nil
}
