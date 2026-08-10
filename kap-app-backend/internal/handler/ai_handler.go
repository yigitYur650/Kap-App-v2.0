package handler

import (
	"strings"

	"kap-app-backend/internal/service"

	"github.com/gofiber/fiber/v2"
)

type AIHandler struct {
	aiService *service.AIService
}

func NewAIHandler(aiService *service.AIService) *AIHandler {
	return &AIHandler{
		aiService: aiService,
	}
}

type EstimatePricesReq struct {
	Items []service.ItemSpecDTO `json:"items"`
}

// EstimatePricesHandler (POST /api/v1/ai/estimate-prices) calculates estimated prices, categories, unit specs and variant notes.
func (h *AIHandler) EstimatePricesHandler(c *fiber.Ctx) error {
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

	// Limit list size to max 50 items per request and sanitize inputs
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

// ScanReceiptHandler (POST /api/v1/ai/scan-receipt) processes a receipt image in RAM and returns parsed items.
func (h *AIHandler) ScanReceiptHandler(c *fiber.Ctx) error {
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

	// Enforce 10 MB base64 payload size limit
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

func sanitizeInput(input string, maxLen int) string {
	cleaned := strings.ReplaceAll(input, "\n", " ")
	cleaned = strings.ReplaceAll(cleaned, "\r", "")
	cleaned = strings.TrimSpace(cleaned)
	if len(cleaned) > maxLen {
		cleaned = cleaned[:maxLen]
	}
	return cleaned
}
