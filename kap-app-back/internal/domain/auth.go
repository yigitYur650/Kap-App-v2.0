package domain

// AuthService defines the business logic contract for authentication and user management.
type AuthService interface {
	// GenerateUniqueCode generates a random, cryptographically secure, and highly readable unique code.
	GenerateUniqueCode() (string, error)
}
