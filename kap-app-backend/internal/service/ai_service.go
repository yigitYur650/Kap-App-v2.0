package service

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"
)

type AIService struct {
	groqKey        string
	geminiKey      string
	client         *http.Client
	marketPriceSvc *MarketPriceService
}

func NewAIService(groqKey, geminiKey string) *AIService {
	return &AIService{
		groqKey:        groqKey,
		geminiKey:      geminiKey,
		client:         &http.Client{Timeout: 20 * time.Second},
		marketPriceSvc: NewMarketPriceService(),
	}
}

type ItemSpecDTO struct {
	ItemName string `json:"item_name"`
	Quantity string `json:"quantity,omitempty"`
	Unit     string `json:"unit,omitempty"`
}

type ProductVariant struct {
	Size  string  `json:"size"`
	Price float64 `json:"price"`
	Store string  `json:"store,omitempty"`
}

type ItemPriceEstimate struct {
	ItemName       string           `json:"item_name"`
	Brand          string           `json:"brand,omitempty"`
	EstimatedPrice float64          `json:"estimated_price"`
	MinPrice       float64          `json:"min_price"`
	MaxPrice       float64          `json:"max_price"`
	Category       string           `json:"category"`
	UnitSpec       string           `json:"unit_spec,omitempty"`
	VariantNote    string           `json:"variant_note,omitempty"`
	SourceMarket   string           `json:"source_market,omitempty"`
	Variants       []ProductVariant `json:"variants,omitempty"`
}

type PriceEstimationResult struct {
	Items      []ItemPriceEstimate `json:"items"`
	TotalPrice float64             `json:"total_price"`
}

type ReceiptItem struct {
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

type ReceiptScanResult struct {
	StoreName string        `json:"store_name"`
	Date      string        `json:"date"`
	Total     float64       `json:"total"`
	Items     []ReceiptItem `json:"items"`
}

// EstimatePrices returns estimated Turkish Lira price ranges, unit specs, variant notes & categories.
func (s *AIService) EstimatePrices(items []ItemSpecDTO) (*PriceEstimationResult, error) {
	if len(items) == 0 {
		return &PriceEstimationResult{Items: []ItemPriceEstimate{}, TotalPrice: 0}, nil
	}

	var formattedItems []string
	for _, spec := range items {
		str := spec.ItemName
		if spec.Quantity != "" || spec.Unit != "" {
			str += fmt.Sprintf(" (Miktar: %s %s)", spec.Quantity, spec.Unit)
		}
		formattedItems = append(formattedItems, str)
	}

	prompt := fmt.Sprintf(`Sen 2026 yılı GÜNCEL Türkiye'nin en yaygın zincir marketi MİGROS ve BİM/A101 tekil raf etiket fiyatlarını %%100 TUTARLI VE KESİN bilen uzman asistansın.

GÜNCEL TEK REFERANS MARKET (MİGROS & BİM/A101) RAF FİYATI STANDARTLARI (2026):
- 1L Tam Yağlı Süt (Sütaş/Pınar/İçim/Dost): 39.50 TL (Migros / BİM Raf Fiyatı)
- Somun Taze Ekmek (200g): 12.50 TL (Fırın / BİM)
- Coca-Cola / Pepsi 1.5L Pet: 55.00 TL (Migros / A101) [330ml Kutu: 32.50 TL, 2.5L: 70.00 TL]
- 1 Paket Cips (Lay's/Ruffles/Doritos 130g): 45.00 TL (Migros)
- 15'li L Boy Yumurta: 89.50 TL (A101 / BİM)
- 1 kg Piliç / Tavuk Göğüs: 195.00 TL (BİM / Migros)
- 500g Tam Yağlı Beyaz Peynir: 145.00 TL (Migros / BİM)
- 1 kg Dana Kıyma: 520.00 TL (Migros)
- 500g Makarna (Filiz/Nuh’un Ankara/Barilla): 22.50 TL (Migros)
- 1L Ayçiçek Yağı (Yudum/Sole/Orkide): 75.00 TL (BİM / A101)
- 1 kg Rize Çay (Çaykur): 195.00 TL (Migros)

Aşağıdaki ürünlerin tekil referans market (Migros / BİM) raf etiket fiyatını (estimated_price), marka adını (brand), referans marketini (source_market: Migros veya BİM) ve varsa boyut varyantlarını çıkar.

Ürünler: %s

Yalnızca aşağıdaki JSON formatında yanıt ver:
{
  "items": [
    {
      "item_name": "ürün adı",
      "brand": "Coca-Cola",
      "estimated_price": 55.0,
      "min_price": 32.5,
      "max_price": 70.0,
      "category": "İçecek",
      "unit_spec": "1.5L Pet (Migros)",
      "variant_note": "330ml Kutu: 32.50 TL, 2.5L: 70.00 TL",
      "source_market": "Migros",
      "variants": [
        { "size": "330 ml Kutu", "price": 32.5, "store": "A101" },
        { "size": "1 L Pet", "price": 45.0, "store": "BİM" },
        { "size": "1.5 L Pet", "price": 55.0, "store": "Migros" },
        { "size": "2.5 L Pet", "price": 70.0, "store": "CarrefourSA" }
      ]
    }
  ]
}`, strings.Join(formattedItems, ", "))

	respJSON, err := s.queryGroqOrGeminiText(prompt)
	if err != nil {
		// Fallback to live market scraper if Groq is offline
		var liveEstimates []ItemPriceEstimate
		for _, itemSpec := range items {
			query := itemSpec.ItemName
			if est, err := s.marketPriceSvc.FetchLiveMarketPrice(query); err == nil && est != nil && est.EstimatedPrice > 0 {
				est.ItemName = itemSpec.ItemName
				liveEstimates = append(liveEstimates, *est)
			}
		}
		if len(liveEstimates) > 0 {
			res := &PriceEstimationResult{Items: liveEstimates}
			s.calculateTotal(res)
			return res, nil
		}
		return nil, err
	}

	var aiRes PriceEstimationResult
	if err := json.Unmarshal([]byte(respJSON), &aiRes); err != nil {
		start := strings.Index(respJSON, "{")
		end := strings.LastIndex(respJSON, "}")
		if start >= 0 && end > start {
			_ = json.Unmarshal([]byte(respJSON[start:end+1]), &aiRes)
		}
	}

	res := &PriceEstimationResult{Items: aiRes.Items}
	s.calculateTotal(res)
	return res, nil
}

func (s *AIService) calculateTotal(res *PriceEstimationResult) {
	var total float64
	for i := range res.Items {
		if res.Items[i].EstimatedPrice > 10000 {
			res.Items[i].EstimatedPrice = 100
		}
		total += res.Items[i].EstimatedPrice
	}
	res.TotalPrice = total
}

// ScanReceipt processes an in-memory base64 image of a grocery receipt via Gemini Vision API.
func (s *AIService) ScanReceipt(base64Image string) (*ReceiptScanResult, error) {
	if idx := strings.Index(base64Image, ","); idx != -1 {
		base64Image = base64Image[idx+1:]
	}

	if s.geminiKey == "" {
		return nil, fmt.Errorf("GEMINI_API_KEY is not configured")
	}

	prompt := `Bu bir market fişi görselidir. Fiş üzerindeki mağaza adını, tarihini, toplam tutarı ve ürün kalemleri ile fiyatlarını çıkar.
Kişisel verileri (Kredi kartı no, isim vb.) KESİNLİKLE DİKKATE ALMA.

Yalnızca aşağıdaki JSON formatında yanıt ver, başka hiçbir açıklama yazma:
{
  "store_name": "Market Adı",
  "date": "YYYY-MM-DD",
  "total": 150.50,
  "items": [
    {
      "name": "Ürün Adı",
      "price": 45.00
    }
  ]
}`

	reqBody := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{"text": prompt},
					{
						"inline_data": map[string]string{
							"mime_type": "image/jpeg",
							"data":      base64Image,
						},
					},
				},
			},
		},
	}

	jsonBytes, _ := json.Marshal(reqBody)

	// Try vision-capable Gemini models in sequence (prioritizing current 2026 model aliases)
	candidateModels := []string{"gemini-flash-latest", "gemini-3.6-flash", "gemini-flash-lite-latest", "gemini-2.0-flash"}
	var lastErr error
	var isQuotaError bool

	for _, model := range candidateModels {
		url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, s.geminiKey)
		req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
		if err != nil {
			lastErr = err
			continue
		}
		req.Header.Set("Content-Type", "application/json")

		resp, err := s.client.Do(req)
		if err != nil {
			lastErr = err
			continue
		}

		bodyBytes, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			bodyStr := string(bodyBytes)
			log.Printf("[AI Service] Gemini model %s failed (status=%d): %s", model, resp.StatusCode, bodyStr)
			if resp.StatusCode == http.StatusTooManyRequests || strings.Contains(bodyStr, "Quota exceeded") || strings.Contains(bodyStr, "429") {
				isQuotaError = true
			}
			lastErr = fmt.Errorf("gemini vision error status=%d", resp.StatusCode)
			continue
		}

		var geminiResp struct {
			Candidates []struct {
				Content struct {
					Parts []struct {
						Text string `json:"text"`
					} `json:"parts"`
				} `json:"content"`
			} `json:"candidates"`
		}

		if err := json.Unmarshal(bodyBytes, &geminiResp); err != nil || len(geminiResp.Candidates) == 0 {
			lastErr = fmt.Errorf("invalid gemini response format")
			continue
		}

		rawText := geminiResp.Candidates[0].Content.Parts[0].Text
		start := strings.Index(rawText, "{")
		end := strings.LastIndex(rawText, "}")
		if start < 0 || end <= start {
			lastErr = fmt.Errorf("no json structure found in receipt scan response")
			continue
		}

		var scanRes ReceiptScanResult
		if err := json.Unmarshal([]byte(rawText[start:end+1]), &scanRes); err != nil {
			lastErr = fmt.Errorf("failed to parse receipt json: %w", err)
			continue
		}

		return &scanRes, nil
	}

	if isQuotaError {
		return nil, fmt.Errorf("Gemini AI ücretsiz kullanım kotasına ulaşıldı (HTTP 429). Lütfen 1 dakika bekleyip tekrar deneyin veya yeni bir API anahtarı ekleyin.")
	}

	if lastErr != nil {
		return nil, fmt.Errorf("Fiş okunamadı: %v", lastErr)
	}

	return nil, fmt.Errorf("Fiş okuma servisi şu anda yanıt vermiyor. Lütfen tekrar deneyin.")
}

func (s *AIService) queryGroqOrGeminiText(prompt string) (string, error) {
	if s.groqKey != "" {
		res, err := s.queryGroq(prompt)
		if err == nil && res != "" {
			return res, nil
		}
		log.Printf("[AI Service] Groq query warning: %v. Falling back to Gemini...", err)
	}

	if s.geminiKey != "" {
		return s.queryGeminiText(prompt)
	}

	return "", fmt.Errorf("neither GROQ_API_KEY nor GEMINI_API_KEY is configured")
}

func (s *AIService) queryGroq(prompt string) (string, error) {
	url := "https://api.groq.com/openai/v1/chat/completions"
	reqBody := map[string]interface{}{
		"model": "llama-3.3-70b-versatile",
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
		"temperature": 0.2,
	}

	jsonBytes, _ := json.Marshal(reqBody)
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.groqKey)

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("groq api status=%d body=%s", resp.StatusCode, string(bodyBytes))
	}

	var groqResp struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.Unmarshal(bodyBytes, &groqResp); err != nil || len(groqResp.Choices) == 0 {
		return "", fmt.Errorf("invalid groq response")
	}

	return groqResp.Choices[0].Message.Content, nil
}

func (s *AIService) queryGeminiText(prompt string) (string, error) {
	reqBody := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]string{
					{"text": prompt},
				},
			},
		},
	}

	jsonBytes, _ := json.Marshal(reqBody)
	candidateModels := []string{"gemini-flash-latest", "gemini-3.6-flash", "gemini-flash-lite-latest", "gemini-2.0-flash"}
	var lastErr error

	for _, model := range candidateModels {
		url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, s.geminiKey)
		req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
		if err != nil {
			lastErr = err
			continue
		}
		req.Header.Set("Content-Type", "application/json")

		resp, err := s.client.Do(req)
		if err != nil {
			lastErr = err
			continue
		}

		bodyBytes, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			lastErr = fmt.Errorf("gemini api model %s status=%d", model, resp.StatusCode)
			continue
		}

		var geminiResp struct {
			Candidates []struct {
				Content struct {
					Parts []struct {
						Text string `json:"text"`
					} `json:"parts"`
				} `json:"content"`
			} `json:"candidates"`
		}

		if err := json.Unmarshal(bodyBytes, &geminiResp); err != nil || len(geminiResp.Candidates) == 0 {
			lastErr = fmt.Errorf("invalid gemini response from model %s", model)
			continue
		}

		return geminiResp.Candidates[0].Content.Parts[0].Text, nil
	}

	return "", fmt.Errorf("gemini text query failed: %v", lastErr)
}

var _ = base64.StdEncoding
