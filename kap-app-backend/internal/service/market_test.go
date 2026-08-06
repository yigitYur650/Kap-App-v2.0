package service

import (
	"testing"
	"time"
)

func TestLiveMarketFetching(t *testing.T) {
	svc := NewMarketPriceService()

	items := []string{"tavuk", "cips", "süt"}
	for _, item := range items {
		est, err := svc.FetchLiveMarketPrice(item)
		if err != nil {
			t.Logf("FAIL for %s: %v", item, err)
		} else {
			t.Logf("SUCCESS [%s]: Price=%.2f TL (Min=%.2f TL, Max=%.2f TL, Cat=%s)", item, est.EstimatedPrice, est.MinPrice, est.MaxPrice, est.Category)
		}
		time.Sleep(500 * time.Millisecond)
	}
}
