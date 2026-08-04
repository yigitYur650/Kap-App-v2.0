package service

import (
	"errors"
	"regexp"
	"testing"

	"kap-app-backend/pkg/supabase"

	"github.com/stretchr/testify/assert"
)

// mockUserRepository implements domain.UserRepository for testing.
// It provides configurable behavior for IsCodeExists and InsertUserWithCode.
type mockUserRepository struct {
	mockIsCodeExists       func(code string) (bool, error)
	mockInsertUserWithCode func(userID, code string) error
}

func (m *mockUserRepository) IsCodeExists(code string) (bool, error) {
	if m.mockIsCodeExists != nil {
		return m.mockIsCodeExists(code)
	}
	return false, nil
}

func (m *mockUserRepository) InsertUserWithCode(userID, code string) error {
	if m.mockInsertUserWithCode != nil {
		return m.mockInsertUserWithCode(userID, code)
	}
	return nil
}

func TestGenerateUniqueCode(t *testing.T) {
	mockRepo := &mockUserRepository{
		mockInsertUserWithCode: func(userID, code string) error {
			// Always succeed on first attempt
			return nil
		},
	}
	svc := NewAuthService(mockRepo)

	// Compile the expected regex pattern: 4 uppercase/numeric chars, a hyphen, 4 uppercase/numeric chars.
	// Note: We exclude confusing characters (0, O, 1, I, L)
	pattern := `^[A-Z2-9]{4}-[A-Z2-9]{4}$`
	regex, err := regexp.Compile(pattern)
	assert.NoError(t, err)

	// Run multiple times to verify format and exclusion of confusing characters
	runs := 100
	for i := 0; i < runs; i++ {
		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.NoError(t, err)

		// Verify formatting matches regex
		assert.Regexp(t, regex, code)

		// Verify confusing characters are excluded
		confusingChars := []string{"0", "O", "1", "I", "L"}
		for _, char := range confusingChars {
			assert.NotContains(t, code, char)
		}
	}
}

func TestGenerateUniqueCode_Collisions(t *testing.T) {
	t.Run("Should succeed on 1st attempt (no collision)", func(t *testing.T) {
		calls := 0
		mockRepo := &mockUserRepository{
			mockInsertUserWithCode: func(userID, code string) error {
				calls++
				return nil // Success
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.NoError(t, err)
		assert.NotEmpty(t, code)
		assert.Equal(t, 1, calls)
	})

	t.Run("Should succeed on 2nd attempt after 1 collision (23505)", func(t *testing.T) {
		calls := 0
		mockRepo := &mockUserRepository{
			mockInsertUserWithCode: func(userID, code string) error {
				calls++
				if calls <= 1 {
					// Simulate PostgreSQL unique constraint violation (code 23505)
					return &supabase.PostgresError{
						Code:    "23505",
						Message: `duplicate key value violates unique constraint "users_unique_code_key"`,
						Details: `Key (unique_code)=(` + code + `) already exists.`,
					}
				}
				return nil // Success on 2nd attempt
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.NoError(t, err)
		assert.NotEmpty(t, code)
		assert.Equal(t, 2, calls)
	})

	t.Run("Should fail after 5 consecutive collisions (23505)", func(t *testing.T) {
		calls := 0
		mockRepo := &mockUserRepository{
			mockInsertUserWithCode: func(userID, code string) error {
				calls++
				// Always collide — simulate unique constraint violation
				return &supabase.PostgresError{
					Code:    "23505",
					Message: `duplicate key value violates unique constraint "users_unique_code_key"`,
					Details: `Key (unique_code)=(` + code + `) already exists.`,
				}
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.ErrorIs(t, err, ErrCollisionLimitReached)
		assert.Empty(t, code)
		assert.Equal(t, 5, calls)
	})

	t.Run("Should abort immediately on non-23505 error", func(t *testing.T) {
		expectedErr := errors.New("network timeout")
		mockRepo := &mockUserRepository{
			mockInsertUserWithCode: func(userID, code string) error {
				return expectedErr
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.ErrorContains(t, err, "failed to insert unique code on attempt 1")
		assert.Empty(t, code)
	})
}
