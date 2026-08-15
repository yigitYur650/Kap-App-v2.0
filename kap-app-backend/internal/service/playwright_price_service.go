package service

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
	"time"
)

type PlaywrightPriceService struct {
	scriptPath string
}

func NewPlaywrightPriceService() *PlaywrightPriceService {
	absPath, _ := filepath.Abs("scripts/price_scraper.js")
	return &PlaywrightPriceService{
		scriptPath: absPath,
	}
}

func (s *PlaywrightPriceService) FetchLivePrice(query string) (*ItemPriceEstimate, error) {
	cleanedQuery := sanitizeForPrompt(query)
	runes := []rune(cleanedQuery)
	if len(runes) > 200 {
		cleanedQuery = string(runes[:200])
	}
	if cleanedQuery == "" {
		return nil, fmt.Errorf("invalid or empty search query")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 7*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "node", s.scriptPath, "--query="+cleanedQuery)
	outputBytes, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("playwright execution failed: %w", err)
	}

	var res struct {
		ItemName       string  `json:"item_name"`
		EstimatedPrice float64 `json:"estimated_price"`
		MinPrice       float64 `json:"min_price"`
		MaxPrice       float64 `json:"max_price"`
		Error          string  `json:"error"`
	}

	if err := json.Unmarshal(outputBytes, &res); err != nil {
		return nil, fmt.Errorf("failed to parse playwright output: %w", err)
	}

	if res.Error != "" {
		return nil, fmt.Errorf("playwright scraper message: %s", res.Error)
	}

	if res.EstimatedPrice <= 0 {
		return nil, fmt.Errorf("invalid estimated price from playwright scraper")
	}

	category := inferCategoryFromQuery(query)

	return &ItemPriceEstimate{
		ItemName:       query,
		EstimatedPrice: res.EstimatedPrice,
		MinPrice:       res.MinPrice,
		MaxPrice:       res.MaxPrice,
		Category:       category,
	}, nil
}
