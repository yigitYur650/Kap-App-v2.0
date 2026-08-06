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

type ItemPriceEstimate struct {
	ItemName       string  `json:"item_name"`
	EstimatedPrice float64 `json:"estimated_price"`
	MinPrice       float64 `json:"min_price"`
	MaxPrice       float64 `json:"max_price"`
	Category       string  `json:"category"`
	UnitSpec       string  `json:"unit_spec,omitempty"`
	VariantNote    string  `json:"variant_note,omitempty"`
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

	var liveEstimates []ItemPriceEstimate
	var unhandledSpecs []ItemSpecDTO

	for _, itemSpec := range items {
		query := itemSpec.ItemName
		if itemSpec.Quantity != "" {
			query += " " + itemSpec.Quantity
		}
		if itemSpec.Unit != "" {
			query += " " + itemSpec.Unit
		}

		if est, err := s.marketPriceSvc.FetchLiveMarketPrice(query); err == nil && est != nil && est.EstimatedPrice > 0 {
			est.ItemName = itemSpec.ItemName
			liveEstimates = append(liveEstimates, *est)
		} else {
			unhandledSpecs = append(unhandledSpecs, itemSpec)
		}
	}

	if len(unhandledSpecs) == 0 {
		res := &PriceEstimationResult{Items: liveEstimates}
		s.calculateTotal(res)
		return res, nil
	}

	var formattedItems []string
	for _, spec := range unhandledSpecs {
		str := spec.ItemName
		if spec.Quantity != "" || spec.Unit != "" {
			str += fmt.Sprintf(" (Miktar: %s %s)", spec.Quantity, spec.Unit)
		}
		formattedItems = append(formattedItems, str)
	}

	prompt := fmt.Sprintf(`Sen 2026 yılı GÜNCEL Türkiye zincir market (BİM, A101, Migros, Carrefour) en son etiket fiyatlarını %%100 GERÇEKÇİ bilen uzman asistansın.

2026 YILI GÜNCEL TÜRKİYE MARKET ETİKET FİYAT BASAMAKLARI:
- 1 kg Tavuk / Piliç Göğüs: 180 - 220 TL (Bütün Piliç 1 kg: 95 - 110 TL)
- 1 Paket Cips (Büyük Boy Lay's/Ruffles/Doritos 130g): 35 - 55 TL
- Üçgen Peynir (8'li Kutu 100g): 35 - 45 TL (24'lü Aile Boyu Kutu: 95 - 120 TL)
- 1L Tam Yağlı Süt: 38 - 50 TL
- 15li Yumurta (L Boy): 75 - 110 TL
- Somun Ekmek (200g): 12 - 15 TL
- 500g Beyaz Peynir / Kaşar: 120 - 180 TL
- 1 kg Kıyma / Dana Et: 450 - 650 TL
- 1 kg Domates: 35 - 60 TL
- 1 kg Salatalık: 30 - 55 TL
- 500g Makarna: 18 - 30 TL
- 1L Ayçiçek Yağı: 65 - 90 TL
- 1 kg Çay: 160 - 240 TL
- Bulaşık Deterjanı: 55 - 95 TL
- 12li Tuvalet Kağıdı: 120 - 190 TL

Aşağıdaki ürünlerin 2026 etiket fiyatını (TL), paket boyutu tanımını (unit_spec) ve farklı paket boyutu/varyant varsa ipucu notunu (variant_note) çıkar.
Miktar girilmediyse standart tekli küçük paketi (Örn: 8'li / 1 kg) kabul et.

Ürünler: %s

Yalnızca aşağıdaki JSON formatında yanıt ver:
{
  "items": [
    {
      "item_name": "ürün adı",
      "estimated_price": 35.0,
      "min_price": 30.0,
      "max_price": 45.0,
      "category": "Süt & Kahvaltılık",
      "unit_spec": "8'li Standart Kutu (100g)",
      "variant_note": "24'lü Aile Boyu ise ~95 TL"
    }
  ]
}`, strings.Join(formattedItems, ", "))

	respJSON, err := s.queryGroqOrGeminiText(prompt)
	if err != nil {
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

	combinedItems := append(liveEstimates, aiRes.Items...)
	res := &PriceEstimationResult{Items: combinedItems}
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

	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s", s.geminiKey)

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
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("gemini vision error status=%d body=%s", resp.StatusCode, string(bodyBytes))
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
		return nil, fmt.Errorf("invalid gemini response: %w", err)
	}

	rawText := geminiResp.Candidates[0].Content.Parts[0].Text
	start := strings.Index(rawText, "{")
	end := strings.LastIndex(rawText, "}")
	if start < 0 || end <= start {
		return nil, fmt.Errorf("no json structure found in receipt scan response")
	}

	var scanRes ReceiptScanResult
	if err := json.Unmarshal([]byte(rawText[start:end+1]), &scanRes); err != nil {
		return nil, fmt.Errorf("failed to parse receipt json: %w", err)
	}

	return &scanRes, nil
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
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s", s.geminiKey)
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
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("gemini api status=%d body=%s", resp.StatusCode, string(bodyBytes))
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
		return "", fmt.Errorf("invalid gemini response")
	}

	return geminiResp.Candidates[0].Content.Parts[0].Text, nil
}

var _ = base64.StdEncoding
