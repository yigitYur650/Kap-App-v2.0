package main

import (
	"fmt"
	"log"

	"kap-app-back/config"
	deliveryHttp "kap-app-back/internal/delivery/http"
	authService "kap-app-back/internal/service"

	"github.com/gofiber/fiber/v2"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Initialize Fiber application
	app := fiber.New(fiber.Config{
		AppName: "Kap-App Backend v2.0",
	})

	// Services
	authSvc := authService.NewAuthService()

	// Handlers
	authHandler := deliveryHttp.NewAuthHandler(authSvc)

	// API Routing Groups
	api := app.Group("/api")
	v1 := api.Group("/v1")
	authGroup := v1.Group("/auth")

	// Register Handler Routes
	authHandler.RegisterRoutes(authGroup)

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"status": "healthy",
		})
	})

	// Start server
	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Server is running on port %s", cfg.Port)
	if err := app.Listen(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
