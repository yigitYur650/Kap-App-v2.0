package repository

import (
	"testing"

	"kap-app-backend/pkg/supabase"

	"github.com/stretchr/testify/assert"
)

type mockSupabaseClient struct {
	mockCheckCodeExists func(code string) (bool, error)
}

func (m *mockSupabaseClient) CheckCodeExists(code string) (bool, error) {
	return m.mockCheckCodeExists(code)
}

func TestIsCodeExists(t *testing.T) {
	t.Run("Should return true when code exists", func(t *testing.T) {
		mockClient := &mockSupabaseClient{
			mockCheckCodeExists: func(code string) (bool, error) {
				assert.Equal(t, "ABCD-1234", code)
				return true, nil
			},
		}
		repo := NewSupabaseUserRepository(mockClient)
		exists, err := repo.IsCodeExists("ABCD-1234")
		assert.NoError(t, err)
		assert.True(t, exists)
	})

	t.Run("Should return false when code does not exist", func(t *testing.T) {
		mockClient := &mockSupabaseClient{
			mockCheckCodeExists: func(code string) (bool, error) {
				return false, nil
			},
		}
		repo := NewSupabaseUserRepository(mockClient)
		exists, err := repo.IsCodeExists("NONEXIST")
		assert.NoError(t, err)
		assert.False(t, exists)
	})
}

// Verify NewSupabaseUserRepository accepts *supabase.Client (compile-time check)
func TestNewSupabaseUserRepository_AcceptsSupabaseClient(t *testing.T) {
	client, err := supabase.NewClient("https://test.supabase.co", "test-key")
	assert.NoError(t, err)

	repo := NewSupabaseUserRepository(client)
	assert.NotNil(t, repo)
}
