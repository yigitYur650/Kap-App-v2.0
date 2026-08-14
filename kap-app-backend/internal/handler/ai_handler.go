package handler

import (
	"log"
	"strings"

	"kap-app-backend/internal/repository"
	"kap-app-backend/internal/service"

	"github.com/gofiber/fiber/v2"
)

type AIHandler struct {
	aiService *service.AIService
	subRepo   repository.SubscriptionRepository
}

func NewAIHandler(aiService *service.AIService, subRepo repository.SubscriptionRepository) *AIHandler {
	return &AIHandler{
		aiService: aiService,
		subRepo:   subRepo,
	}
}

type EstimatePricesReq struct {
	Items []service.ItemSpecDTO `json:"items"`
}

// EstimatePricesHandler (POST /api/v1/ai/estimate-prices) calculates estimated prices.
func (h *AIHandler) EstimatePricesHandler(c *fiber.Ctx) error {
	userID, _ := c.Locals("userID").(string)

	if userID != "" && h.subRepo != nil {
		creditRes, err := h.subRepo.ConsumeAICredit(userID)
		if err != nil {
			log.Printf("[AIHandler] Quota check warning (non-blocking): %v", err)
		} else if creditRes != nil && !creditRes.Success {
			log.Printf("[AIHandler] User %s daily AI quota reached", userID)
			return c.Status(fiber.StatusPaymentRequired).JSON(fiber.Map{
				"error":   "ai_quota_exceeded",
				"message": "Günlük ücretsiz AI kullanım hakkınız bitti. Mağazadan Pro üyelik alabilir veya ekstra hak kazanabilirsiniz.",
				"result":  creditRes,
			})
		}
	}

	var req EstimatePricesReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	if len(req.Items) == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "items array is required and cannot be empty",
		})
	}

	if len(req.Items) > 50 {
		req.Items = req.Items[:50]
	}

	for i := range req.Items {
		req.Items[i].ItemName = sanitizeInput(req.Items[i].ItemName, 100)
		req.Items[i].Quantity = sanitizeInput(req.Items[i].Quantity, 30)
		req.Items[i].Unit = sanitizeInput(req.Items[i].Unit, 30)
	}

	res, err := h.aiService.EstimatePrices(req.Items)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(res)
}

type ScanReceiptReq struct {
	Base64Image string `json:"base64_image"`
}

// ScanReceiptHandler (POST /api/v1/ai/scan-receipt) processes a receipt image.
func (h *AIHandler) ScanReceiptHandler(c *fiber.Ctx) error {
	userID, _ := c.Locals("userID").(string)

	if userID != "" && h.subRepo != nil {
		creditRes, err := h.subRepo.ConsumeAICredit(userID)
		if err != nil {
			log.Printf("[AIHandler] Quota check warning (non-blocking): %v", err)
		} else if creditRes != nil && !creditRes.Success {
			log.Printf("[AIHandler] User %s daily AI quota reached", userID)
			return c.Status(fiber.StatusPaymentRequired).JSON(fiber.Map{
				"error":   "ai_quota_exceeded",
				"message": "Günlük ücretsiz AI kullanım hakkınız bitti. Mağazadan Pro üyelik alabilir veya ekstra hak kazanabilirsiniz.",
				"result":  creditRes,
			})
		}
	}

	var req ScanReceiptReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	if req.Base64Image == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "base64_image is required",
		})
	}

	if len(req.Base64Image) > 10*1024*1024 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "image payload exceeds 10MB limit",
		})
	}

	res, err := h.aiService.ScanReceipt(req.Base64Image)
	if err != nil {
		status := fiber.StatusInternalServerError
		errStr := err.Error()
		if strings.Contains(errStr, "429") || strings.Contains(strings.ToLower(errStr), "kotasına ulaşıldı") {
			status = fiber.StatusTooManyRequests
		}
		return c.Status(status).JSON(fiber.Map{
			"error": errStr,
		})
	}

	return c.Status(fiber.StatusOK).JSON(res)
}

type AIRecommendationReq struct {
	Items   []service.ItemSpecDTO          `json:"items"`
	Profile *service.UserHealthProfileDTO `json:"health_profile"`
}

// GetShoppingRecommendationsHandler (POST /api/v1/ai/recommendations)
func (h *AIHandler) GetShoppingRecommendationsHandler(c *fiber.Ctx) error {
	userID, _ := c.Locals("userID").(string)

	if userID != "" && h.subRepo != nil {
		creditRes, err := h.subRepo.ConsumeAICredit(userID)
		if err != nil {
			log.Printf("[AIHandler] Quota check warning (non-blocking): %v", err)
		} else if creditRes != nil && !creditRes.Success {
			log.Printf("[AIHandler] User %s daily AI quota reached", userID)
			return c.Status(fiber.StatusPaymentRequired).JSON(fiber.Map{
				"error":   "ai_quota_exceeded",
				"message": "Günlük ücretsiz AI kullanım hakkınız bitti. Mağazadan Pro üyelik alabilir veya ekstra hak kazanabilirsiniz.",
				"result":  creditRes,
			})
		}
	}

	var req AIRecommendationReq
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "invalid_payload",
		})
	}

	res, err := h.aiService.GetShoppingRecommendations(req.Items, req.Profile)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(res)
}

func sanitizeInput(val string, maxLen int) string {
	val = strings.TrimSpace(val)
	if len(val) > maxLen {
		return val[:maxLen]
	}
	return val
}
