package service

import (
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"strings"

	"kap-app-backend/internal/domain"
)

// ErrCollisionLimitReached is returned when unique code generation fails after maximum retries.
var ErrCollisionLimitReached = errors.New("collision limit reached while generating unique code")

type authService struct {
	userRepo domain.UserRepository
}

// NewAuthService creates a new instance of domain.AuthService.
func NewAuthService(userRepo domain.UserRepository) domain.AuthService {
	return &authService{
		userRepo: userRepo,
	}
}

// Explanatory comment: We exclude easily confused characters (like '0', 'O', '1', 'I', 'L') to make the generated code user-friendly.
const charset = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"

// GenerateUniqueCode generates a secure, readable unique code in the format XXXX-XXXX, checking for collisions up to 5 times.
func (s *authService) GenerateUniqueCode(userID string) (string, error) {
	for attempt := 1; attempt <= 5; attempt++ {
		code, err := s.generateRawCode()
		if err != nil {
			return "", fmt.Errorf("failed to generate raw code on attempt %d: %w", attempt, err)
		}

		exists, err := s.userRepo.IsCodeExists(code)
		if err != nil {
			return "", fmt.Errorf("failed to check code uniqueness on attempt %d: %w", attempt, err)
		}

		if !exists {
			return code, nil
		}
	}

	return "", ErrCollisionLimitReached
}

func (s *authService) generateRawCode() (string, error) {
	var sb strings.Builder
	charsetLen := big.NewInt(int64(len(charset)))

	for i := 0; i < 8; i++ {
		if i == 4 {
			sb.WriteRune('-')
		}
		num, err := rand.Int(rand.Reader, charsetLen)
		if err != nil {
			return "", err
		}
		sb.WriteByte(charset[num.Int64()])
	}

	return sb.String(), nil
}
