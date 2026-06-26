package service

import (
	"errors"
	"regexp"
	"testing"

	"github.com/stretchr/testify/assert"
)

type mockUserRepository struct {
	mockIsCodeExists func(code string) (bool, error)
}

func (m *mockUserRepository) IsCodeExists(code string) (bool, error) {
	return m.mockIsCodeExists(code)
}

func TestGenerateUniqueCode(t *testing.T) {
	mockRepo := &mockUserRepository{
		mockIsCodeExists: func(code string) (bool, error) {
			return false, nil
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
	t.Run("Should succeed after 3 collisions (4th attempt)", func(t *testing.T) {
		calls := 0
		mockRepo := &mockUserRepository{
			mockIsCodeExists: func(code string) (bool, error) {
				calls++
				if calls <= 3 {
					return true, nil // Collision
				}
				return false, nil // Unique
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.NoError(t, err)
		assert.NotEmpty(t, code)
		assert.Equal(t, 4, calls)
	})

	t.Run("Should fail after 5 collisions", func(t *testing.T) {
		calls := 0
		mockRepo := &mockUserRepository{
			mockIsCodeExists: func(code string) (bool, error) {
				calls++
				return true, nil // Always collide
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.ErrorIs(t, err, ErrCollisionLimitReached)
		assert.Empty(t, code)
		assert.Equal(t, 5, calls)
	})

	t.Run("Should abort immediately on repository check error", func(t *testing.T) {
		expectedErr := errors.New("db error")
		mockRepo := &mockUserRepository{
			mockIsCodeExists: func(code string) (bool, error) {
				return false, expectedErr
			},
		}
		svc := NewAuthService(mockRepo)

		code, err := svc.GenerateUniqueCode("test-user-id")
		assert.ErrorContains(t, err, "failed to check code uniqueness on attempt 1")
		assert.Empty(t, code)
	})
}
