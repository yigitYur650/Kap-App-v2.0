package service

import (
	"os"
	"testing"
)

func TestNewAIEstimate(t *testing.T) {
	groqKey := os.Getenv("GROQ_API_KEY")
	geminiKey := os.Getenv("GEMINI_API_KEY")

	if groqKey == "" && geminiKey == "" {
		t.Skip("Skipping AI test: no env keys configured")
	}

	aiSvc := NewAIService(groqKey, geminiKey)
	res, err := aiSvc.EstimatePrices([]string{"tavuk", "cips"})

	if err != nil {
		t.Fatalf("EstimatePrices error: %v", err)
	}

	t.Logf("NEW AI ESTIMATE RESULT: Total=%.2f TL", res.TotalPrice)
	for _, item := range res.Items {
		t.Logf(" - Item: %s | Price: %.2f TL | Category: %s", item.ItemName, item.EstimatedPrice, item.Category)
	}
}
