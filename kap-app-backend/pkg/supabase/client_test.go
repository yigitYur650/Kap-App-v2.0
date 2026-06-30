package supabase

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNewClient_Validation(t *testing.T) {
	t.Run("Empty URL should return error", func(t *testing.T) {
		client, err := NewClient("", "valid-key")
		assert.Error(t, err)
		assert.Nil(t, client)
		assert.Contains(t, err.Error(), "supabase URL cannot be empty")
	})

	t.Run("Empty service role key should return error", func(t *testing.T) {
		client, err := NewClient("https://test.supabase.co", "")
		assert.Error(t, err)
		assert.Nil(t, client)
		assert.Contains(t, err.Error(), "supabase service role key cannot be empty")
	})

	t.Run("Valid parameters should return client", func(t *testing.T) {
		client, err := NewClient("https://test.supabase.co", "valid-key")
		assert.NoError(t, err)
		assert.NotNil(t, client)
		assert.Equal(t, "https://test.supabase.co", client.URL)
		assert.Equal(t, "valid-key", client.ServiceRoleKey)
		assert.NotNil(t, client.HTTPClient)
	})
}

func TestNewClient_DefaultTimeout(t *testing.T) {
	client, err := NewClient("https://test.supabase.co", "valid-key")
	assert.NoError(t, err)
	assert.NotNil(t, client)
	assert.Equal(t, int64(10), client.HTTPClient.Timeout.Milliseconds()/1000,
		"Default timeout should be 10 seconds")
}
