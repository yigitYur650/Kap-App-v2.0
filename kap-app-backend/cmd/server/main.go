package main

import (
	"fmt"
	"log"

	"kap-app-backend/config"
	"kap-app-backend/internal/handler"
	"kap-app-backend/internal/middleware"
	"kap-app-backend/internal/repository"
	authService "kap-app-backend/internal/service"
	"kap-app-backend/pkg/supabase"

	"github.com/gofiber/fiber/v2"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Initialize Fiber application
	app := fiber.New(fiber.Config{
		AppName: "Kap-App Backend v2.0",
	})

	// Supabase Client
	sbClient, err := supabase.NewClient(cfg.SupabaseURL, cfg.SupabaseServiceRoleKey)
	if err != nil {
		log.Fatalf("Failed to initialize Supabase Client: %v", err)
	}

	// Repositories
	userRepo := repository.NewSupabaseUserRepository(sbClient)

	// Services
	authSvc := authService.NewAuthService(userRepo)

	// Handlers
	authHandler := handler.NewAuthHandler(authSvc)

	// API Routing Groups
	api := app.Group("/api")
	v1 := api.Group("/v1")

	// Protected Auth Routes
	authGroup := v1.Group("/auth", middleware.AuthRequired(cfg.SupabaseJWTSecret))
	authHandler.RegisterRoutes(authGroup)

	// Protected Routes Group
	protectedGroup := v1.Group("/protected", middleware.AuthRequired(cfg.SupabaseJWTSecret))
	protectedGroup.Get("/user", func(c *fiber.Ctx) error {
		userID := c.Locals("userID")
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"userID": userID,
		})
	})

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status": "ok",
		})
	})

	// Start server
	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Server is running on port %s", cfg.Port)
	if err := app.Listen(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
