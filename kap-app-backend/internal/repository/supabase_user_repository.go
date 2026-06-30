package repository

import (
	"kap-app-backend/internal/domain"
)

// codeExistsChecker abstracts the Supabase client for testability.
type codeExistsChecker interface {
	CheckCodeExists(code string) (bool, error)
}

type supabaseUserRepository struct {
	client codeExistsChecker
}

// NewSupabaseUserRepository creates a new UserRepository using Supabase REST API client.
func NewSupabaseUserRepository(client codeExistsChecker) domain.UserRepository {
	return &supabaseUserRepository{
		client: client,
	}
}

func (r *supabaseUserRepository) IsCodeExists(code string) (bool, error) {
	return r.client.CheckCodeExists(code)
}
