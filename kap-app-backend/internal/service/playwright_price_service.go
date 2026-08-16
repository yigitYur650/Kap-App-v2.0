package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type PlaywrightPriceService struct {
	scriptPath string
}

func NewPlaywrightPriceService() *PlaywrightPriceService {
	candidates := []string{
		"scripts/price_scraper.js",
		"../scripts/price_scraper.js",
		"../../scripts/price_scraper.js",
	}

	finalPath := "scripts/price_scraper.js"
	for _, cand := range candidates {
		if abs, err := filepath.Abs(cand); err == nil {
			if _, statErr := os.Stat(abs); statErr == nil {
				finalPath = abs
				break
			}
		}
	}

	log.Printf("[PlaywrightPriceService] Initialized with script path: %s", finalPath)
	return &PlaywrightPriceService{
		scriptPath: finalPath,
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

	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()

	start := time.Now()
	cmd := exec.CommandContext(ctx, "node", s.scriptPath, "--query="+cleanedQuery)
	outputBytes, err := cmd.CombinedOutput()
	duration := time.Since(start)

	if err != nil {
		outputStr := strings.TrimSpace(string(outputBytes))
		log.Printf("[Playwright Scraper] FAILED for '%s' after %v: %v | Output: %s", cleanedQuery, duration, err, outputStr)
		return nil, fmt.Errorf("playwright execution failed after %v: %w (output: %s)", duration, err, outputStr)
	}

	var res struct {
		ItemName       string  `json:"item_name"`
		EstimatedPrice float64 `json:"estimated_price"`
		MinPrice       float64 `json:"min_price"`
		MaxPrice       float64 `json:"max_price"`
		Error          string  `json:"error"`
	}

	if err := json.Unmarshal(outputBytes, &res); err != nil {
		log.Printf("[Playwright Scraper] JSON parse error for '%s' (output: %s): %v", cleanedQuery, string(outputBytes), err)
		return nil, fmt.Errorf("failed to parse playwright output: %w", err)
	}

	if res.Error != "" {
		log.Printf("[Playwright Scraper] Script reported error for '%s': %s", cleanedQuery, res.Error)
		return nil, fmt.Errorf("playwright scraper message: %s", res.Error)
	}

	if res.EstimatedPrice <= 0 {
		log.Printf("[Playwright Scraper] Invalid estimated price (%.2f) for '%s'", res.EstimatedPrice, cleanedQuery)
		return nil, fmt.Errorf("invalid estimated price from playwright scraper")
	}

	log.Printf("[Playwright Scraper] SUCCESS for '%s': %.2f TL (in %v)", cleanedQuery, res.EstimatedPrice, duration)

	category := inferCategoryFromQuery(query)

	return &ItemPriceEstimate{
		ItemName:       query,
		EstimatedPrice: res.EstimatedPrice,
		MinPrice:       res.MinPrice,
		MaxPrice:       res.MaxPrice,
		Category:       category,
	}, nil
}
