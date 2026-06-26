package supabase

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Client wraps HTTP-based access to the Supabase REST API using the service role key.
type Client struct {
	URL            string
	ServiceRoleKey string
	HTTPClient     *http.Client
}

// NewClient initializes a new Supabase admin client wrapper.
func NewClient(url, serviceRoleKey string) (*Client, error) {
	if url == "" {
		return nil, errors.New("supabase URL cannot be empty")
	}
	if serviceRoleKey == "" {
		return nil, errors.New("supabase service role key cannot be empty")
	}

	return &Client{
		URL:            url,
		ServiceRoleKey: serviceRoleKey,
		HTTPClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}, nil
}

// CheckCodeExists queries public.users REST endpoint via Supabase API to check if a code is taken.
func (c *Client) CheckCodeExists(code string) (bool, error) {
	reqURL := fmt.Sprintf("%s/rest/v1/users?unique_code=eq.%s&select=id", c.URL, code)
	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return false, fmt.Errorf("failed to create check request: %w", err)
	}

	req.Header.Set("apikey", c.ServiceRoleKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.ServiceRoleKey))

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return false, fmt.Errorf("failed to execute check request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return false, fmt.Errorf("supabase API returned status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var results []map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&results); err != nil {
		return false, fmt.Errorf("failed to decode check response: %w", err)
	}

	return len(results) > 0, nil
}
