package repository

import (
	"errors"
	"testing"

	"kap-app-backend/pkg/supabase"

	"github.com/stretchr/testify/assert"
)

type mockSupabaseClient struct {
	mockCheckCodeExists func(code string) (bool, error)
	mockInsertCode      func(userID, code string) error
}

func (m *mockSupabaseClient) CheckCodeExists(code string) (bool, error) {
	return m.mockCheckCodeExists(code)
}

func (m *mockSupabaseClient) InsertCode(userID, code string) error {
	if m.mockInsertCode != nil {
		return m.mockInsertCode(userID, code)
	}
	return nil
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

func TestInsertUserWithCode(t *testing.T) {
	t.Run("Should succeed when code is unique", func(t *testing.T) {
		mockClient := &mockSupabaseClient{
			mockInsertCode: func(userID, code string) error {
				assert.Equal(t, "user-123", userID)
				assert.Equal(t, "ABCD-1234", code)
				return nil
			},
		}
		repo := NewSupabaseUserRepository(mockClient)
		err := repo.InsertUserWithCode("user-123", "ABCD-1234")
		assert.NoError(t, err)
	})

	t.Run("Should return error when code already exists", func(t *testing.T) {
		mockClient := &mockSupabaseClient{
			mockInsertCode: func(userID, code string) error {
				return &supabase.PostgresError{
					Code:    "23505",
					Message: `duplicate key value violates unique constraint "users_unique_code_key"`,
				}
			},
		}
		repo := NewSupabaseUserRepository(mockClient)
		err := repo.InsertUserWithCode("user-123", "ABCD-1234")
		assert.Error(t, err)
		assert.True(t, supabase.IsUniqueViolation(err))
	})

	t.Run("Should return generic error on network failure", func(t *testing.T) {
		expectedErr := errors.New("network timeout")
		mockClient := &mockSupabaseClient{
			mockInsertCode: func(userID, code string) error {
				return expectedErr
			},
		}
		repo := NewSupabaseUserRepository(mockClient)
		err := repo.InsertUserWithCode("user-123", "ABCD-1234")
		assert.ErrorIs(t, err, expectedErr)
	})
}

// Verify NewSupabaseUserRepository accepts *supabase.Client (compile-time check)
func TestNewSupabaseUserRepository_AcceptsSupabaseClient(t *testing.T) {
	client, err := supabase.NewClient("https://test.supabase.co", "test-key")
	assert.NoError(t, err)

	repo := NewSupabaseUserRepository(client)
	assert.NotNil(t, repo)
}
