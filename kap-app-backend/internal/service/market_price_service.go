package service

import (
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type MarketPriceService struct {
	client        *http.Client
	playwrightSvc *PlaywrightPriceService
	cacheSvc      *PriceCacheService
}

func NewMarketPriceService() *MarketPriceService {
	return &MarketPriceService{
		client:        &http.Client{Timeout: 8 * time.Second},
		playwrightSvc: NewPlaywrightPriceService(),
		cacheSvc:      NewPriceCacheService(24 * time.Hour),
	}
}

var userAgents = []string{
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
	"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
}

// FetchLiveMarketPrice queries live Turkish grocery prices with sub-10ms cache lookup, primary Playwright web scraper, and HTTP scraper fallback.
func (s *MarketPriceService) FetchLiveMarketPrice(productName string) (*ItemPriceEstimate, error) {
	cleanName := strings.TrimSpace(productName)
	if cleanName == "" {
		return nil, fmt.Errorf("empty product name")
	}

	// 1. Fast path: Check 24-hour in-memory cache
	if cached, hit := s.cacheSvc.Get(cleanName); hit && cached != nil {
		return cached, nil
	}

	// 2. Primary Scraper: Playwright Headless Browser Scraper
	if s.playwrightSvc != nil {
		if pwEst, pwErr := s.playwrightSvc.FetchLivePrice(cleanName); pwErr == nil && pwEst != nil && pwEst.EstimatedPrice > 0 {
			s.cacheSvc.Set(cleanName, *pwEst)
			return pwEst, nil
		}
	}

	// 3. Secondary Fallback Scraper: HTTP scraper path
	est, err := s.fetchFromAkakce(cleanName)
	if err == nil && est != nil && est.EstimatedPrice > 0 {
		s.cacheSvc.Set(cleanName, *est)
		return est, nil
	}

	return nil, fmt.Errorf("could not fetch live price for %s", cleanName)
}

func (s *MarketPriceService) fetchFromAkakce(query string) (*ItemPriceEstimate, error) {
	normalized := normalizeQuery(query)
	searchTerm := normalized + " fiyati"
	searchURL := fmt.Sprintf("https://www.akakce.com/arama/?q=%s", url.QueryEscape(searchTerm))

	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	randomUA := userAgents[rand.Intn(len(userAgents))]
	req.Header.Set("User-Agent", randomUA)
	req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
	req.Header.Set("Accept-Language", "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("akakce status=%d", resp.StatusCode)
	}

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	bodyStr := string(bodyBytes)

	// Regex search for Turkish Lira price patterns (e.g. 145,50 TL or 38,00 TL)
	re := regexp.MustCompile(`(\d{1,4}(?:[.,]\d{1,2})?)\s*(?:<[^>]+>)*\s*(?:TL|₺)`)
	matches := re.FindAllStringSubmatch(bodyStr, -1)

	var validPrices []float64
	for _, m := range matches {
		if len(m) > 1 {
			raw := strings.ReplaceAll(m[1], ",", ".")
			if val, err := strconv.ParseFloat(raw, 64); err == nil && val >= 5.0 && val <= 3000.0 {
				validPrices = append(validPrices, val)
			}
		}
	}

	if len(validPrices) == 0 {
		return nil, fmt.Errorf("no price matches found on akakce for %s", query)
	}

	var sum float64
	minP := validPrices[0]
	maxP := validPrices[0]

	for _, p := range validPrices {
		if p < minP {
			minP = p
		}
		if p > maxP {
			maxP = p
		}
		sum += p
	}

	avgPrice := sum / float64(len(validPrices))
	category := inferCategoryFromQuery(query)

	return &ItemPriceEstimate{
		ItemName:       query,
		EstimatedPrice: roundTwoDecimals(avgPrice),
		MinPrice:       roundTwoDecimals(minP),
		MaxPrice:       roundTwoDecimals(maxP),
		Category:       category,
	}, nil
}

func normalizeQuery(q string) string {
	r := strings.NewReplacer(
		"ç", "c", "Ç", "C",
		"ğ", "g", "Ğ", "G",
		"ı", "i", "İ", "I",
		"ö", "o", "Ö", "O",
		"ş", "s", "Ş", "S",
		"ü", "u", "Ü", "U",
	)
	return r.Replace(q)
}

func inferCategoryFromQuery(query string) string {
	q := strings.ToLower(query)
	switch {
	case strings.Contains(q, "süt"), strings.Contains(q, "peynir"), strings.Contains(q, "yoğurt"), strings.Contains(q, "yumurta"), strings.Contains(q, "tereyağı"), strings.Contains(q, "sut"), strings.Contains(q, "yogurt"):
		return "Süt & Kahvaltılık"
	case strings.Contains(q, "domates"), strings.Contains(q, "salatalık"), strings.Contains(q, "elma"), strings.Contains(q, "muz"), strings.Contains(q, "patates"), strings.Contains(q, "soğan"), strings.Contains(q, "biber"), strings.Contains(q, "salatalik"), strings.Contains(q, "sogan"):
		return "Meyve & Sebze"
	case strings.Contains(q, "tavuk"), strings.Contains(q, "et"), strings.Contains(q, "kıyma"), strings.Contains(q, "kiyma"), strings.Contains(q, "makarna"), strings.Contains(q, "pirinç"), strings.Contains(q, "pirinc"), strings.Contains(q, "un"), strings.Contains(q, "yağ"), strings.Contains(q, "yag"), strings.Contains(q, "salça"), strings.Contains(q, "salca"), strings.Contains(q, "ekmek"):
		return "Temel Gıda"
	case strings.Contains(q, "cips"), strings.Contains(q, "çikolata"), strings.Contains(q, "cikolata"), strings.Contains(q, "bisküvi"), strings.Contains(q, "biskuvi"), strings.Contains(q, "gofret"):
		return "Atıştırmalık"
	case strings.Contains(q, "su"), strings.Contains(q, "kola"), strings.Contains(q, "soda"), strings.Contains(q, "çay"), strings.Contains(q, "cay"), strings.Contains(q, "kahve"), strings.Contains(q, "meyve suyu"):
		return "İçecek"
	case strings.Contains(q, "deterjan"), strings.Contains(q, "sabun"), strings.Contains(q, "şampuan"), strings.Contains(q, "sampuan"), strings.Contains(q, "peçete"), strings.Contains(q, "pecete"), strings.Contains(q, "kağıt"), strings.Contains(q, "kagit"):
		return "Temizlik"
	default:
		return "Genel"
	}
}

func roundTwoDecimals(val float64) float64 {
	return float64(int(val*100+0.5)) / 100.0
}
