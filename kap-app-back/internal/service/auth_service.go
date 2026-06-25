package service

import (
	"crypto/rand"
	"math/big"
	"strings"

	"kap-app-back/internal/domain"
)

type authService struct{}

// NewAuthService creates a new instance of domain.AuthService.
func NewAuthService() domain.AuthService {
	return &authService{}
}

// Explanatory comment: We exclude easily confused characters (like '0', 'O', '1', 'I') to make the generated code user-friendly.
const charset = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

// GenerateUniqueCode generates a secure, readable unique code in the format XXXX-XXXX.
func (s *authService) GenerateUniqueCode() (string, error) {
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
