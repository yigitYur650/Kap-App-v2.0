package handler

import (
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
	Items []string `json:"items"`
}

// EstimatePricesHandler (POST /api/v1/ai/estimate-prices) calculates estimated prices and categories.
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

	// Limit list size to max 50 items per request
	if len(req.Items) > 50 {
		req.Items = req.Items[:50]
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
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(res)
}
