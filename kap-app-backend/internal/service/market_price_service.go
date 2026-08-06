package service

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type MarketPriceService struct {
	client *http.Client
}

func NewMarketPriceService() *MarketPriceService {
	return &MarketPriceService{
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

type MigrosSearchResponse struct {
	Data struct {
		StoreProductInfos []struct {
			Name  string  `json:"name"`
			Price float64 `json:"price"`
		} `json:"storeProductInfos"`
	} `json:"data"`
}

// FetchLiveMarketPrice queries live Turkish grocery prices from public market endpoints.
func (s *MarketPriceService) FetchLiveMarketPrice(productName string) (*ItemPriceEstimate, error) {
	cleanName := strings.TrimSpace(productName)
	if cleanName == "" {
		return nil, fmt.Errorf("empty product name")
	}

	// 1. Try Migros Public API Endpoint
	est, err := s.fetchFromMigros(cleanName)
	if err == nil && est != nil && est.EstimatedPrice > 0 {
		return est, nil
	}

	// 2. Fallback to DuckDuckGo HTML Search for Turkish market price parsing
	estSearch, errSearch := s.fetchFromWebSearch(cleanName)
	if errSearch == nil && estSearch != nil && estSearch.EstimatedPrice > 0 {
		return estSearch, nil
	}

	return nil, fmt.Errorf("could not fetch live price for %s", cleanName)
}

func (s *MarketPriceService) fetchFromMigros(query string) (*ItemPriceEstimate, error) {
	reqURL := fmt.Sprintf("https://www.migros.com.tr/hemen/api/v1/search/products?q=%s", url.QueryEscape(query))
	req, err := http.NewRequest("GET", reqURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("migros status=%d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var migrosResp MigrosSearchResponse
	if err := json.Unmarshal(body, &migrosResp); err != nil {
		return nil, err
	}

	products := migrosResp.Data.StoreProductInfos
	if len(products) == 0 {
		return nil, fmt.Errorf("no products found on migros for query: %s", query)
	}

	var minP, maxP, totalP float64
	minP = products[0].Price / 100.0 // Migros API sends price in Kuruş (cents)
	maxP = minP
	count := 0

	for _, p := range products {
		priceTL := p.Price / 100.0
		if priceTL <= 0 {
			continue
		}
		if priceTL < minP {
			minP = priceTL
		}
		if priceTL > maxP {
			maxP = priceTL
		}
		totalP += priceTL
		count++
		if count >= 5 {
			break // Sample top 5 items
		}
	}

	if count == 0 {
		return nil, fmt.Errorf("no valid prices found")
	}

	avgPrice := totalP / float64(count)
	category := inferCategoryFromQuery(query)

	return &ItemPriceEstimate{
		ItemName:       query,
		EstimatedPrice: roundTwoDecimals(avgPrice),
		MinPrice:       roundTwoDecimals(minP),
		MaxPrice:       roundTwoDecimals(maxP),
		Category:       category,
	}, nil
}

func (s *MarketPriceService) fetchFromWebSearch(query string) (*ItemPriceEstimate, error) {
	searchURL := fmt.Sprintf("https://html.duckduckgo.com/html/?q=%s", url.QueryEscape(query+" fiyatı TL A101 BİM Migros 2026"))
	req, err := http.NewRequest("GET", searchURL, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// Regex search for Turkish Lira price patterns (e.g. 39,90 TL or 45.50 TL)
	re := regexp.MustCompile(`(\d{1,4}(?:[.,]\d{2})?)\s*(?:TL|₺)`)
	matches := re.FindAllStringSubmatch(string(body), -1)

	var prices []float64
	for _, m := range matches {
		if len(m) > 1 {
			raw := strings.ReplaceAll(m[1], ",", ".")
			if val, err := strconv.ParseFloat(raw, 64); err == nil && val > 5 && val < 5000 {
				prices = append(prices, val)
			}
		}
	}

	if len(prices) == 0 {
		return nil, fmt.Errorf("no price matches found in web search")
	}

	var sum, minP, maxP float64
	minP = prices[0]
	maxP = prices[0]

	for _, p := range prices {
		if p < minP {
			minP = p
		}
		if p > maxP {
			maxP = p
		}
		sum += p
	}

	avgPrice := sum / float64(len(prices))
	category := inferCategoryFromQuery(query)

	return &ItemPriceEstimate{
		ItemName:       query,
		EstimatedPrice: roundTwoDecimals(avgPrice),
		MinPrice:       roundTwoDecimals(minP),
		MaxPrice:       roundTwoDecimals(maxP),
		Category:       category,
	}, nil
}

func inferCategoryFromQuery(query string) string {
	q := strings.ToLower(query)
	switch {
	case strings.Contains(q, "süt"), strings.Contains(q, "peynir"), strings.Contains(q, "yoğurt"), strings.Contains(q, "yumurta"), strings.Contains(q, "tereyağı"):
		return "Süt & Kahvaltılık"
	case strings.Contains(q, "domates"), strings.Contains(q, "salatalık"), strings.Contains(q, "elma"), strings.Contains(q, "muz"), strings.Contains(q, "patates"), strings.Contains(q, "soğan"), strings.Contains(q, "biber"):
		return "Meyve & Sebze"
	case strings.Contains(q, "makarna"), strings.Contains(q, "pirinç"), strings.Contains(q, "un"), strings.Contains(q, "yağ"), strings.Contains(q, "salça"), strings.Contains(q, "ekmek"):
		return "Temel Gıda"
	case strings.Contains(q, "cips"), strings.Contains(q, "çikolata"), strings.Contains(q, "bisküvi"), strings.Contains(q, "gofret"):
		return "Atıştırmalık"
	case strings.Contains(q, "su"), strings.Contains(q, "kola"), strings.Contains(q, "soda"), strings.Contains(q, "çay"), strings.Contains(q, "kahve"), strings.Contains(q, "meyve suyu"):
		return "İçecek"
	case strings.Contains(q, "deterjan"), strings.Contains(q, "sabun"), strings.Contains(q, "şampuan"), strings.Contains(q, "peçete"), strings.Contains(q, "kağıt"):
		return "Temizlik"
	default:
		return "Genel"
	}
}

func roundTwoDecimals(val float64) float64 {
	return float64(int(val*100+0.5)) / 100.0
}
