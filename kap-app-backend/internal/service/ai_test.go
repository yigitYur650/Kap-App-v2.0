package service

import (
	"os"
	"testing"
)

func TestItemSpecEstimate(t *testing.T) {
	groqKey := os.Getenv("GROQ_API_KEY")
	geminiKey := os.Getenv("GEMINI_API_KEY")

	if groqKey == "" && geminiKey == "" {
		t.Skip("Skipping AI test: no env keys configured")
	}

	aiSvc := NewAIService(groqKey, geminiKey)
	items := []ItemSpecDTO{
		{ItemName: "üçgen peynir", Quantity: "8'li", Unit: "kutu"},
		{ItemName: "üçgen peynir", Quantity: "24'lü", Unit: "kutu"},
		{ItemName: "tavuk", Quantity: "1", Unit: "kg"},
	}

	res, err := aiSvc.EstimatePrices(items)
	if err != nil {
		t.Fatalf("EstimatePrices error: %v", err)
	}

	t.Logf("NEW AI ESTIMATE RESULT: Total=%.2f TL", res.TotalPrice)
	for _, item := range res.Items {
		t.Logf(" - Item: %s | Price: %.2f TL | UnitSpec: %s | VariantNote: %s", item.ItemName, item.EstimatedPrice, item.UnitSpec, item.VariantNote)
	}
}

func TestPipelineOrder(t *testing.T) {
	// Initialize AIService without API keys to test fallback chain down to baseline
	aiSvc := NewAIService("", "")
	items := []ItemSpecDTO{
		{ItemName: "süt", Quantity: "1", Unit: "L"},
		{ItemName: "ekmek", Quantity: "2", Unit: "adet"},
	}

	res, err := aiSvc.EstimatePrices(items)
	if err != nil {
		t.Fatalf("EstimatePrices failed: %v", err)
	}

	if len(res.Items) != 2 {
		t.Fatalf("Expected 2 estimated items, got %d", len(res.Items))
	}

	for _, item := range res.Items {
		if item.EstimatedPrice <= 0 {
			t.Errorf("Item %s has invalid price: %.2f", item.ItemName, item.EstimatedPrice)
		}
		t.Logf("[Pipeline Test] Item: %s | Price: %.2f TL | Source: %s", item.ItemName, item.EstimatedPrice, item.SourceMarket)
	}
}
