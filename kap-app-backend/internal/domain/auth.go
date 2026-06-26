package domain

// UserRepository defines database access operations for users.
type UserRepository interface {
	// IsCodeExists checks if a unique_code already exists in the users table.
	IsCodeExists(code string) (bool, error)
}

// AuthService defines the business logic contract for authentication and user management.
type AuthService interface {
	// GenerateUniqueCode generates a random, cryptographically secure, and highly readable unique code, retrying on collision.
	GenerateUniqueCode(userID string) (string, error)
}
