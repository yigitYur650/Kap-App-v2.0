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
	groqKey   string
	geminiKey string
	client    *http.Client
}

func NewAIService(groqKey, geminiKey string) *AIService {
	return &AIService{
		groqKey:   groqKey,
		geminiKey: geminiKey,
		client:    &http.Client{Timeout: 20 * time.Second},
	}
}

type ItemPriceEstimate struct {
	ItemName       string  `json:"item_name"`
	EstimatedPrice float64 `json:"estimated_price"`
	MinPrice       float64 `json:"min_price"`
	MaxPrice       float64 `json:"max_price"`
	Category       string  `json:"category"`
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

// EstimatePrices returns estimated Turkish Lira price ranges and categories for a list of items.
func (s *AIService) EstimatePrices(items []string) (*PriceEstimationResult, error) {
	if len(items) == 0 {
		return &PriceEstimationResult{Items: []ItemPriceEstimate{}, TotalPrice: 0}, nil
	}

	prompt := fmt.Sprintf(`Sen Türkiye market fiyatlarını bilen uzman bir asistansın. 
Aşağıdaki alışveriş listesindeki ürünlerin güncel ortalama Türkiye market fiyatlarını (TL), tahmini min-max aralığını ve reyon kategorisini çıkar.
Kategoriler yalnızca şunlar olabilir: "Meyve & Sebze", "Süt & Kahvaltılık", "Temel Gıda", "Atıştırmalık", "İçecek", "Temizlik", "Genel".

Ürünler: %s

Yalnızca aşağıdaki JSON formatında yanıt ver, başka hiçbir açıklama yazma:
{
  "items": [
    {
      "item_name": "ürün adı",
      "estimated_price": 35.0,
      "min_price": 25.0,
      "max_price": 45.0,
      "category": "Meyve & Sebze"
    }
  ]
}`, strings.Join(items, ", "))

	respJSON, err := s.queryGroqOrGeminiText(prompt)
	if err != nil {
		return nil, err
	}

	var res PriceEstimationResult
	if err := json.Unmarshal([]byte(respJSON), &res); err != nil {
		// Attempt to extract JSON substring if extra text returned
		start := strings.Index(respJSON, "{")
		end := strings.LastIndex(respJSON, "}")
		if start >= 0 && end > start {
			if errJson := json.Unmarshal([]byte(respJSON[start:end+1]), &res); errJson == nil {
				s.calculateTotal(&res)
				return &res, nil
			}
		}
		return nil, fmt.Errorf("AI response parse error: %w", err)
	}

	s.calculateTotal(&res)
	return &res, nil
}

func (s *AIService) calculateTotal(res *PriceEstimationResult) {
	var total float64
	for i := range res.Items {
		// Outlier check: Keep price bounds reasonable (max 10000 TL per single item)
		if res.Items[i].EstimatedPrice > 10000 {
			res.Items[i].EstimatedPrice = 100
		}
		total += res.Items[i].EstimatedPrice
	}
	res.TotalPrice = total
}

// ScanReceipt processes an in-memory base64 image of a grocery receipt via Gemini Vision API.
func (s *AIService) ScanReceipt(base64Image string) (*ReceiptScanResult, error) {
	// Strip header if data URI scheme is present
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
	// Try Groq API first if key configured
	if s.groqKey != "" {
		res, err := s.queryGroq(prompt)
		if err == nil && res != "" {
			return res, nil
		}
		log.Printf("[AI Service] Groq query warning: %v. Falling back to Gemini...", err)
	}

	// Fallback to Gemini 2.0 Flash text query if Groq unavailable or key missing
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

// Unused helper for unused warnings
var _ = base64.StdEncoding
