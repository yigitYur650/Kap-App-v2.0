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
	"sync"
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

func sanitizeForPrompt(input string) string {
	input = strings.TrimSpace(input)
	var sb strings.Builder
	for _, r := range input {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') ||
			r == ' ' || r == '.' || r == ',' || r == ';' || r == ':' || r == '-' || r == '/' || r == '(' || r == ')' || r == '%' ||
			r == 'ç' || r == 'Ç' || r == 'ğ' || r == 'Ğ' || r == 'ı' || r == 'İ' || r == 'ö' || r == 'Ö' || r == 'ş' || r == 'Ş' || r == 'ü' || r == 'Ü' {
			sb.WriteRune(r)
		}
	}
	cleaned := sb.String()
	for strings.Contains(cleaned, "  ") {
		cleaned = strings.ReplaceAll(cleaned, "  ", " ")
	}
	return strings.TrimSpace(cleaned)
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
	Items       []ItemPriceEstimate `json:"items"`
	TotalPrice  float64             `json:"total_price"`
	PipelineLog []string            `json:"pipeline_log,omitempty"`
}

type ShoppingRecommendation struct {
	Category      string `json:"category"`                 // health, savings, recipe, missing, storage
	Title         string `json:"title"`                    // Başlık
	Description   string `json:"description"`              // Detay
	Icon          string `json:"icon"`                     // Emoji (🥗, 💰, 🍳, ⚠️, 🌱)
	SuggestedItem string `json:"suggested_item,omitempty"` // Öneri ürünü (Örn: Ispanak)
}

type ShoppingRecommendationsResult struct {
	Recommendations []ShoppingRecommendation `json:"recommendations"`
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

var turkishBaselinePrices = map[string]ItemPriceEstimate{
	"ekmek":   {ItemName: "Ekmek", EstimatedPrice: 12.50, MinPrice: 10.0, MaxPrice: 15.0, Category: "Unlu Mamul", UnitSpec: "200g Somun", SourceMarket: "BİM / Fırın", Brand: "Halk Fırın"},
	"süt":     {ItemName: "Süt", EstimatedPrice: 39.50, MinPrice: 35.0, MaxPrice: 48.0, Category: "Süt Ürünleri", UnitSpec: "1L Tam Yağlı Pet/Kutu", SourceMarket: "Migros", Brand: "Sütaş"},
	"yumurta": {ItemName: "Yumurta", EstimatedPrice: 89.50, MinPrice: 75.0, MaxPrice: 110.0, Category: "Kahvaltılık", UnitSpec: "15'li L Boy Kutu", SourceMarket: "A101 / BİM", Brand: "Köyüm"},
	"kola":    {ItemName: "Kola", EstimatedPrice: 55.00, MinPrice: 32.5, MaxPrice: 70.0, Category: "İçecek", UnitSpec: "1.5L Pet", SourceMarket: "Migros", Brand: "Coca-Cola"},
	"tavuk":   {ItemName: "Tavuk Göğüs", EstimatedPrice: 195.00, MinPrice: 160.0, MaxPrice: 220.0, Category: "Et & Piliç", UnitSpec: "1 kg Paket", SourceMarket: "BİM", Brand: "Erpiliç"},
	"kıyma":   {ItemName: "Dana Kıyma", EstimatedPrice: 520.00, MinPrice: 450.0, MaxPrice: 600.0, Category: "Et & Piliç", UnitSpec: "1 kg Taze Kıyma", SourceMarket: "Migros", Brand: "Uzman Kasap"},
	"peynir":  {ItemName: "Beyaz Peynir", EstimatedPrice: 145.00, MinPrice: 120.0, MaxPrice: 180.0, Category: "Kahvaltılık", UnitSpec: "500g Tam Yağlı", SourceMarket: "Migros", Brand: "Sütaş"},
	"cips":    {ItemName: "Cips", EstimatedPrice: 45.00, MinPrice: 35.0, MaxPrice: 55.0, Category: "Atıştırmalık", UnitSpec: "130g Parti Boy", SourceMarket: "Migros", Brand: "Lay's"},
	"yağ":     {ItemName: "Ayçiçek Yağı", EstimatedPrice: 75.00, MinPrice: 65.0, MaxPrice: 90.0, Category: "Temel Gıda", UnitSpec: "1L Pet", SourceMarket: "BİM", Brand: "Sole"},
	"makarna": {ItemName: "Makarna", EstimatedPrice: 22.50, MinPrice: 18.0, MaxPrice: 30.0, Category: "Temel Gıda", UnitSpec: "500g Paket", SourceMarket: "Migros", Brand: "Filiz"},
	"çay":     {ItemName: "Çay", EstimatedPrice: 195.00, MinPrice: 160.0, MaxPrice: 240.0, Category: "İçecek", UnitSpec: "1 kg Rize Çayı", SourceMarket: "Migros", Brand: "Çaykur"},
	"su":      {ItemName: "Su 5L", EstimatedPrice: 28.50, MinPrice: 20.0, MaxPrice: 35.0, Category: "İçecek", UnitSpec: "5L Pet", SourceMarket: "BİM", Brand: "Erikli"},
}

func getBaselinePrice(itemName string) ItemPriceEstimate {
	lower := strings.ToLower(itemName)
	for key, val := range turkishBaselinePrices {
		if strings.Contains(lower, key) {
			val.ItemName = itemName
			return val
		}
	}
	return ItemPriceEstimate{
		ItemName:       itemName,
		EstimatedPrice: 45.0,
		MinPrice:       35.0,
		MaxPrice:       60.0,
		Category:       "Genel",
		UnitSpec:       "1 Adet Standard",
		SourceMarket:   "Migros / BİM",
		Brand:          "Standart",
	}
}

// EstimatePrices returns estimated Turkish Lira price ranges using a multi-stage pipeline: Playwright Live Scraper -> Groq AI -> Gemini AI -> Baseline Standard.
func (s *AIService) EstimatePrices(items []ItemSpecDTO) (*PriceEstimationResult, error) {
	if len(items) == 0 {
		return &PriceEstimationResult{Items: []ItemPriceEstimate{}, TotalPrice: 0}, nil
	}

	var finalItems []ItemPriceEstimate
	var unresolvedSpecs []ItemSpecDTO
	var pipelineLogs []string
	var pipelineMu sync.Mutex

	appendLog := func(msg string) {
		pipelineMu.Lock()
		pipelineLogs = append(pipelineLogs, msg)
		pipelineMu.Unlock()
		log.Println(msg)
	}

	// Stage 1: Primary Source — Playwright Live Targeted Web Scraper (2-Worker Concurrency Pool)
	if s.marketPriceSvc != nil {
		var wg sync.WaitGroup
		var mu sync.Mutex
		sem := make(chan struct{}, 2) // Max 2 concurrent Playwright browser workers for low CPU RAM usage

		for _, spec := range items {
			cleanName := sanitizeForPrompt(spec.ItemName)
			if cleanName == "" {
				continue
			}

			wg.Add(1)
			go func(itemSpec ItemSpecDTO, query string) {
				defer wg.Done()
				sem <- struct{}{}        // Acquire worker slot
				defer func() { <-sem }() // Release worker slot

				pwEst, pwErr := s.marketPriceSvc.FetchLiveMarketPrice(query)

				mu.Lock()
				defer mu.Unlock()
				if pwErr == nil && pwEst != nil && pwEst.EstimatedPrice > 0 {
					pwEst.ItemName = itemSpec.ItemName
					if itemSpec.Quantity != "" || itemSpec.Unit != "" {
						pwEst.UnitSpec = fmt.Sprintf("%s %s (Canlı Market)", itemSpec.Quantity, itemSpec.Unit)
					}
					pwEst.SourceMarket = "Canlı Web Taraması (Playwright)"
					finalItems = append(finalItems, *pwEst)
					appendLog(fmt.Sprintf("[STAGE 1 PLAYWRIGHT SUCCESS] '%s' -> %.2f TL (Source: %s)", itemSpec.ItemName, pwEst.EstimatedPrice, pwEst.SourceMarket))
				} else {
					appendLog(fmt.Sprintf("[STAGE 1 PLAYWRIGHT FAILED] '%s' -> Error: %v (Passing to Stage 2: Groq AI)", itemSpec.ItemName, pwErr))
					unresolvedSpecs = append(unresolvedSpecs, itemSpec)
				}
			}(spec, cleanName)
		}
		wg.Wait()
	} else {
		unresolvedSpecs = items
	}

	// Stage 2 & Stage 3: AI Failover Pipeline — Groq (Primary AI) -> Gemini (Backup AI)
	if len(unresolvedSpecs) > 0 {
		var unresolvedNames []string
		for _, u := range unresolvedSpecs {
			unresolvedNames = append(unresolvedNames, u.ItemName)
		}
		appendLog(fmt.Sprintf("[STAGE 2 GROQ AI] Starting AI estimation for %d unresolved items: %v", len(unresolvedSpecs), unresolvedNames))

		var formattedItems []string
		for _, spec := range unresolvedSpecs {
			cleanName := sanitizeForPrompt(spec.ItemName)
			cleanQty := sanitizeForPrompt(spec.Quantity)
			cleanUnit := sanitizeForPrompt(spec.Unit)
			str := cleanName
			if cleanQty != "" || cleanUnit != "" {
				str += fmt.Sprintf(" (Miktar: %s %s)", cleanQty, cleanUnit)
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

ÇOK ÖNEMLİ KURAL: İstenen HER ürün için YALNIZCA 1 ADET nesne oluştur. Aynı ürün için birden fazla market seçeneği ekleme.

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
		if err == nil && respJSON != "" {
			var aiRes PriceEstimationResult
			if unerr := json.Unmarshal([]byte(respJSON), &aiRes); unerr != nil {
				start := strings.Index(respJSON, "{")
				end := strings.LastIndex(respJSON, "}")
				if start >= 0 && end > start {
					_ = json.Unmarshal([]byte(respJSON[start:end+1]), &aiRes)
				}
			}

			seen := make(map[string]bool)
			for _, item := range aiRes.Items {
				if item.ItemName != "" && !seen[item.ItemName] && item.EstimatedPrice > 0 {
					seen[item.ItemName] = true
					finalItems = append(finalItems, item)
					appendLog(fmt.Sprintf("[STAGE 2 AI SUCCESS] '%s' -> %.2f TL (Source: %s)", item.ItemName, item.EstimatedPrice, item.SourceMarket))
				}
			}
		} else {
			appendLog(fmt.Sprintf("[STAGE 2 & 3 AI FAILED] Error: %v -> Passing to Stage 4 Baseline", err))
		}
	}

	// Stage 4: Safety Baseline Fallback — Ensure EVERY requested item has a price
	for _, spec := range items {
		found := false
		for _, fi := range finalItems {
			if strings.EqualFold(fi.ItemName, spec.ItemName) || strings.Contains(strings.ToLower(fi.ItemName), strings.ToLower(spec.ItemName)) {
				found = true
				break
			}
		}
		if !found {
			baseEst := getBaselinePrice(spec.ItemName)
			appendLog(fmt.Sprintf("[STAGE 4 BASELINE FALLBACK] '%s' -> %.2f TL (Source: %s)", spec.ItemName, baseEst.EstimatedPrice, baseEst.SourceMarket))
			finalItems = append(finalItems, baseEst)
		}
	}

	res := &PriceEstimationResult{
		Items:       finalItems,
		PipelineLog: pipelineLogs,
	}
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

	// Try vision-capable Gemini models in sequence
	candidateModels := []string{"gemini-flash-latest", "gemini-3.6-flash", "gemini-flash-lite-latest", "gemini-2.0-flash"}
	var lastErr error
	var isQuotaError bool

	for _, model := range candidateModels {
		url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent", model)
		req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
		if err != nil {
			lastErr = err
			continue
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("x-goog-api-key", s.geminiKey)

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
			lastErr = fmt.Errorf("gemini status=%d", resp.StatusCode)
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

		if err := json.Unmarshal(bodyBytes, &geminiResp); err != nil || len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
			lastErr = fmt.Errorf("invalid gemini response format")
			continue
		}

		rawText := geminiResp.Candidates[0].Content.Parts[0].Text
		start := strings.Index(rawText, "{")
		end := strings.LastIndex(rawText, "}")
		if start < 0 || end <= start {
			lastErr = fmt.Errorf("json bounds not found in gemini text")
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

	var messages []map[string]string
	parts := strings.SplitN(prompt, "\n\nKULLANICI GİRDİSİ / ÜRÜNLER:\n", 2)
	if len(parts) == 2 {
		messages = []map[string]string{
			{"role": "system", "content": parts[0]},
			{"role": "user", "content": parts[1]},
		}
	} else {
		messages = []map[string]string{
			{"role": "user", "content": prompt},
		}
	}

	reqBody := map[string]interface{}{
		"model":       "llama-3.3-70b-versatile",
		"messages":    messages,
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
		url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent", model)
		req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
		if err != nil {
			lastErr = err
			continue
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("x-goog-api-key", s.geminiKey)

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

type UserHealthProfileDTO struct {
	Weight         float64 `json:"weight,omitempty"`
	Height         float64 `json:"height,omitempty"`
	Age            int     `json:"age,omitempty"`
	Gender         string  `json:"gender,omitempty"`
	ActivityLevel  string  `json:"activity_level,omitempty"`
	Goal           string  `json:"goal,omitempty"`
	BMR            int     `json:"bmr,omitempty"`
	TDEE           int     `json:"tdee,omitempty"`
	TargetCalories int     `json:"target_calories,omitempty"`
	ProteinGrams   int     `json:"protein_grams,omitempty"`
	CarbGrams      int     `json:"carb_grams,omitempty"`
	FatGrams       int     `json:"fat_grams,omitempty"`
}

func (s *AIService) GetShoppingRecommendations(items []ItemSpecDTO, profile *UserHealthProfileDTO) (*ShoppingRecommendationsResult, error) {
	if len(items) == 0 {
		return &ShoppingRecommendationsResult{
			Recommendations: []ShoppingRecommendation{
				{
					Category:      "health",
					Title:         "Alışveriş Listeniz Boş",
					Description:   "Alışveriş listenize ürün eklediğinizde kişiselleştirilmiş beslenme, bütçe tasarrufu ve tarif tüyoları burada görünecektir.",
					Icon:          "💡",
					SuggestedItem: "Taze Meyve",
				},
			},
		}, nil
	}

	var names []string
	for _, item := range items {
		cleanName := sanitizeForPrompt(item.ItemName)
		if cleanName != "" {
			names = append(names, cleanName)
		}
	}

	profileContext := ""
	if profile != nil && profile.Weight > 0 {
		goalText := "Form Koruma"
		if profile.Goal == "lose" {
			goalText = "Kilo Verme (Kalori Açığı)"
		} else if profile.Goal == "gain" {
			goalText = "Kilo Alma / Hacim (Kalori Fazlası)"
		}

		profileContext = fmt.Sprintf(`

KULLANICININ KİŞİSEL FITNESS & BESLENME PROFİLİ:
- Kilo: %.1f kg, Boy: %.0f cm, Yaş: %d, Cinsiyet: %s
- Beslenme Hedefi: %s
- Günlük Hedef Kalori Limiti: %d kcal (Bazal Metabolizma: %d, Harcanan TDEE: %d)
- Günlük Hedef Makrolar: Protein: %dg, Karbonhidrat: %dg, Yağ: %dg

LÜTFEN KULLANICININ SEPETİNDEKİ ÜRÜNLERİ BU KİŞİSEL SAĞLIK BİLGİLERİ VE HEDEFLERİYLE BİREBİR EŞLEŞTİREREK ÖZEL İPUÇLARI ÜRET! (Örneğin kilo verme hedefindeyse yüksek kalorili gıdalar yerine hafif alternatifler veya protein ihtiyacına göre tamamlama önerileri sun).`,
			profile.Weight, profile.Height, profile.Age, profile.Gender,
			goalText, profile.TargetCalories, profile.BMR, profile.TDEE,
			profile.ProteinGrams, profile.CarbGrams, profile.FatGrams,
		)
	}

	prompt := fmt.Sprintf(`Sen uzman bir diyetisyen, kişisel fitness antrenörü ve yaratıcı bir şefsin.
Kullanıcının evindeki/sepetindeki aşağıdaki mevcut malzemeleri incele:
Malzeme Listesi: %s
%s

Lütfen bu malzemeleri kullanarak pişirilebilecek GERÇEKÇİ, PRATİK VE LEZZETLİ Türkçe yemek tarifleri ve beslenme tüyoları üret. Özellikle "recipe" kategorisinde bu malzemeleri harmanlayan nefis yemek fikirleri ver.
Lütfen aşağıdaki kategorilerden en az 3-4 tavsiye üret:
1. "recipe": Evdeki Malzemelerle Nefis Yemek Tarifi (Örn: Bu ürünlerle pişirilebilecek adım adım lezzetli ve sağlıklı yemek fikri)
2. "health": Dengeli Beslenme & Fitness İpucu (Kullanıcının makro ve kalori hedeflerine uygun sepet/malzeme tavsiyesi)
3. "savings": Bütçe & İsraf Önleme Tüyosu (Gramaj avantajı veya evdeki malzemeleri değerlendirme fikri)
4. "missing": Eksik Tamamlayıcı Malzeme Uyarısı (Tarifi mükemmelleştirecek ama listede eksik olan malzeme)
5. "storage": Tazelik Saklama Tüyosu

ÖNEMLİ: Tarif veya öneride eksik olan 1 tamamlayıcı malzeme varsa, suggested_item alanına doğrudan alışveriş listesine eklenebilecek net 1-2 kelimelik ürün adı yaz (Örn: "Yoğurt", "Sıvı Yağ", "Domates Salçası").

Yalnızca aşağıdaki JSON formatında yanıt ver:
{
  "recommendations": [
    {
      "category": "recipe",
      "title": "🍳 Evdeki Malzemelerle: Fırın Tavuklu Sebze",
      "description": "Evdeki patates, domates ve tavuk göğsü ile harika bir fırın yemeği hazırlayabilirsiniz. Sosu için biraz zeytinyağı ve kekik ekleyin.",
      "icon": "🍳",
      "suggested_item": "Zeytinyağı"
    },
    {
      "category": "health",
      "title": "🥗 Yüksek Proteinli Öğün Fikri",
      "description": "Evdeki yumurta ve peynir ile yüksek proteinli nefis bir omlet pişirerek günlük protein ihtiyacınızı destekleyin.",
      "icon": "🥗",
      "suggested_item": "Maydanoz"
    }
  ]
}`, strings.Join(names, ", "), profileContext)

	respJSON, err := s.queryGroqOrGeminiText(prompt)
	if err != nil || respJSON == "" {
		// Fail-safe default recommendations
		return &ShoppingRecommendationsResult{
			Recommendations: []ShoppingRecommendation{
				{
					Category:      "health",
					Title:         "Taze Yeşillik Ekleme İpucu",
					Description:   "Haftalık alışveriş listenize taze yeşillik ve meyve ekleyerek dengeli beslenmeyi destekleyebilirsiniz.",
					Icon:          "🥗",
					SuggestedItem: "Yeşillik Paket",
				},
				{
					Category:      "savings",
					Title:         "Bütçe İpucu",
					Description:   "Sık tüketilen temel gıdaları (Un, Şeker, Bakliyat) koli veya büyük boy paketlerde tercih edebilirsiniz.",
					Icon:          "💰",
					SuggestedItem: "5kg Un",
				},
			},
		}, nil
	}

	var result ShoppingRecommendationsResult
	if err := json.Unmarshal([]byte(respJSON), &result); err != nil {
		start := strings.Index(respJSON, "{")
		end := strings.LastIndex(respJSON, "}")
		if start >= 0 && end > start {
			_ = json.Unmarshal([]byte(respJSON[start:end+1]), &result)
		}
	}

	if len(result.Recommendations) == 0 {
		result.Recommendations = []ShoppingRecommendation{
			{
				Category:      "health",
				Title:         "Dengeli Sepet Önerisi",
				Description:   "Sepetinizdeki ürünlerin yanına taze meyve ve sebze ekleyerek vitamin dengesini artırabilirsiniz.",
				Icon:          "🥗",
				SuggestedItem: "Meyve Tabağı",
			},
		}
	}

	return &result, nil
}

var _ = base64.StdEncoding
