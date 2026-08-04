package supabase

import (
	"errors"
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

func TestIsUniqueViolation(t *testing.T) {
	t.Run("Should return true for 23505 PostgresError", func(t *testing.T) {
		err := &PostgresError{
			Code:    "23505",
			Message: `duplicate key value violates unique constraint`,
		}
		assert.True(t, IsUniqueViolation(err))
	})

	t.Run("Should return false for non-23505 PostgresError", func(t *testing.T) {
		err := &PostgresError{
			Code:    "42703",
			Message: "column does not exist",
		}
		assert.False(t, IsUniqueViolation(err))
	})

	t.Run("Should return false for generic error", func(t *testing.T) {
		err := errors.New("network timeout")
		assert.False(t, IsUniqueViolation(err))
	})

	t.Run("Should return false for nil", func(t *testing.T) {
		assert.False(t, IsUniqueViolation(nil))
	})
}
