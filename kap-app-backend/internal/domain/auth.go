package domain

// UserRepository defines database access operations for users.
type UserRepository interface {
	// IsCodeExists checks if a unique_code already exists in the users table.
	IsCodeExists(code string) (bool, error)

	// InsertUserWithCode atomically sets the unique_code for a given user.
	// Returns a PostgresError with code "23505" (unique_violation) if the code
	// is already taken by another user, allowing the caller to retry.
	InsertUserWithCode(userID, code string) error
}

// AuthService defines the business logic contract for authentication and user management.
type AuthService interface {
	// GenerateUniqueCode generates a random, cryptographically secure, and highly readable
	// unique code in the format XXXX-XXXX. It atomically generates AND inserts the code
	// into the database, retrying up to 5 times on unique constraint violations.
	// This eliminates the race window between "check if code exists" and "insert code".
	GenerateUniqueCode(userID string) (string, error)
}
