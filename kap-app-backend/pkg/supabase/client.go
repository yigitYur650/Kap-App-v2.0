package supabase

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
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

// PostgresError represents an error returned by the Supabase/PostgREST API.
type PostgresError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Details string `json:"details"`
}

func (e *PostgresError) Error() string {
	return fmt.Sprintf("Postgres error [%s]: %s", e.Code, e.Message)
}

// IsUniqueViolation checks if the error is a PostgreSQL unique constraint violation (23505).
func IsUniqueViolation(err error) bool {
	var pgErr *PostgresError
	if errors.As(err, &pgErr) {
		return pgErr.Code == "23505"
	}
	return false
}

// CheckCodeExists queries public.users REST endpoint via Supabase API to check if a code is taken.
func (c *Client) CheckCodeExists(code string) (bool, error) {
	reqURL := fmt.Sprintf("%s/rest/v1/users?unique_code=eq.%s&select=id", c.URL, url.QueryEscape(code))
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

// InsertCode atomically sets the unique_code for an existing user via the Supabase REST API.
// If the unique_code is already taken by another user, the API returns a 409 conflict
// which is parsed into a PostgresError with code "23505" (unique_violation).
func (c *Client) InsertCode(userID, code string) error {
	// PATCH /rest/v1/users?id=eq.{userID} with body {"unique_code": "{code}"}
	reqURL := fmt.Sprintf("%s/rest/v1/users?id=eq.%s", c.URL, url.QueryEscape(userID))

	body := map[string]string{
		"unique_code": code,
	}
	jsonBody, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("failed to marshal insert body: %w", err)
	}

	req, err := http.NewRequest(http.MethodPatch, reqURL, bytes.NewReader(jsonBody))
	if err != nil {
		return fmt.Errorf("failed to create insert request: %w", err)
	}

	req.Header.Set("apikey", c.ServiceRoleKey)
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.ServiceRoleKey))
	req.Header.Set("Content-Type", "application/json")
	// Use the service role key's "Prefer: return=minimal" header to avoid response body
	req.Header.Set("Prefer", "return=minimal")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to execute insert request: %w", err)
	}
	defer resp.Body.Close()

	// Success: 200 OK or 204 No Content
	if resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusNoContent {
		return nil
	}

	// Read error response body
	respBody, _ := io.ReadAll(resp.Body)

	// 409 Conflict — unique constraint violation (code already taken)
	if resp.StatusCode == http.StatusConflict {
		var pgErr PostgresError
		if err := json.Unmarshal(respBody, &pgErr); err == nil && pgErr.Code == "23505" {
			return &pgErr
		}
	}

	// Try to parse generic PostgREST error
	// PostgREST wraps errors in a JSON array: [{"code":"23505","message":"...","details":"..."}]
	var pgErrs []PostgresError
	if err := json.Unmarshal(respBody, &pgErrs); err == nil && len(pgErrs) > 0 {
		// Check if any of the errors contain unique_code constraint details
		for _, pgErr := range pgErrs {
			if pgErr.Code == "23505" && strings.Contains(pgErr.Details, "unique_code") {
				return &pgErr
			}
		}
		return fmt.Errorf("supabase API error: %s", pgErrs[0].Message)
	}

	return fmt.Errorf("supabase API returned status %d: %s", resp.StatusCode, string(respBody))
}
