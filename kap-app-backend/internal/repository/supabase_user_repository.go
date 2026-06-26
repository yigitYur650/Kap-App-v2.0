package repository

import (
	"kap-app-backend/internal/domain"
	"kap-app-backend/pkg/supabase"
)

type supabaseUserRepository struct {
	client *supabase.Client
}

// NewSupabaseUserRepository creates a new UserRepository using Supabase REST API client.
func NewSupabaseUserRepository(client *supabase.Client) domain.UserRepository {
	return &supabaseUserRepository{
		client: client,
	}
}

func (r *supabaseUserRepository) IsCodeExists(code string) (bool, error) {
	return r.client.CheckCodeExists(code)
}
