package service

import (
	"strings"
	"sync"
	"time"
)

type cachedPriceEntry struct {
	estimate  ItemPriceEstimate
	expiresAt time.Time
}

type PriceCacheService struct {
	mu    sync.RWMutex
	items map[string]cachedPriceEntry
	ttl   time.Duration
}

func NewPriceCacheService(ttl time.Duration) *PriceCacheService {
	if ttl <= 0 {
		ttl = 24 * time.Hour
	}
	return &PriceCacheService{
		items: make(map[string]cachedPriceEntry),
		ttl:   ttl,
	}
}

func (c *PriceCacheService) Get(query string) (*ItemPriceEstimate, bool) {
	key := strings.ToLower(strings.TrimSpace(query))
	if key == "" {
		return nil, false
	}

	c.mu.RLock()
	entry, exists := c.items[key]
	c.mu.RUnlock()

	if !exists {
		return nil, false
	}

	if time.Now().After(entry.expiresAt) {
		// Clean up expired entry asynchronously
		go c.Delete(key)
		return nil, false
	}

	return &entry.estimate, true
}

func (c *PriceCacheService) Set(query string, estimate ItemPriceEstimate) {
	key := strings.ToLower(strings.TrimSpace(query))
	if key == "" || estimate.EstimatedPrice <= 0 {
		return
	}

	c.mu.Lock()
	c.items[key] = cachedPriceEntry{
		estimate:  estimate,
		expiresAt: time.Now().Add(c.ttl),
	}
	c.mu.Unlock()
}

func (c *PriceCacheService) Delete(query string) {
	key := strings.ToLower(strings.TrimSpace(query))
	c.mu.Lock()
	delete(c.items, key)
	c.mu.Unlock()
}
