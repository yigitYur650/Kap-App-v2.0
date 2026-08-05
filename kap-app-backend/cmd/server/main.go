package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

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

	// Manual CORS middleware — replaces Fiber's cors.New which has bugs with wildcard origins in preflight.
	// WARNING: In production, replace "*" with explicit origins from cfg.CORSAllowedOrigins.
	app.Use(func(c *fiber.Ctx) error {
		c.Set("Access-Control-Allow-Origin", "*")
		c.Set("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS")
		c.Set("Access-Control-Allow-Headers", "Origin,Content-Type,Authorization,Accept")
		if c.Method() == "OPTIONS" {
			return c.SendStatus(204)
		}
		return c.Next()
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
	versionHandler := handler.NewAppVersionHandler(sbClient)

	// API Routing Groups
	api := app.Group("/api")
	v1 := api.Group("/v1")

	// Public App Update Route
	v1.Get("/app/check-update", versionHandler.CheckUpdateHandler)

	// Protected Auth Routes
	authGroup := v1.Group("/auth", middleware.AuthRequired(cfg.SupabaseJWTSecret, cfg.SupabaseURL))
	authHandler.RegisterRoutes(authGroup)

	// Protected System Admin Routes
	adminGroup := v1.Group("/admin", middleware.AuthRequired(cfg.SupabaseJWTSecret, cfg.SupabaseURL), middleware.AdminRequired(sbClient))
	adminGroup.Post("/app-version", versionHandler.CreateVersionHandler)

	// Protected Routes Group
	protectedGroup := v1.Group("/protected", middleware.AuthRequired(cfg.SupabaseJWTSecret, cfg.SupabaseURL))
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

	// ============================================================
	// Graceful Shutdown: Signal Interception & Lifecycle Management
	// ============================================================
	// The server is started asynchronously in a goroutine so that
	// the main thread can block on signal reception. When a
	// termination signal (SIGINT, SIGTERM, os.Interrupt) arrives,
	// a 10-second graceful shutdown window is initiated to allow
	// all in-flight requests (e.g., unique_code generation with
	// database writes) to complete before the process exits.
	// ============================================================

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("[INFO] Server is starting on port %s", cfg.Port)

	// Channel to capture server startup errors (e.g., port in use)
	serverErr := make(chan error, 1)

	// Start the Fiber server asynchronously
	go func() {
		if err := app.Listen(addr); err != nil {
			serverErr <- err
		}
	}()

	// Set up signal interception: SIGINT (Ctrl+C), SIGTERM (deployment kill), os.Interrupt
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	// Block until either a signal is received or the server fails to start
	select {
	case sig := <-sigChan:
		log.Printf("[INFO] Received signal: %v. Shutting down server gracefully...", sig)
	case err := <-serverErr:
		log.Fatalf("Failed to start server: %v", err)
	}

	// Create a context with a 10-second timeout for the shutdown window.
	// This ensures in-flight requests (unique_code generation, DB writes, etc.)
	// have time to complete before the process exits.
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Initiate graceful shutdown — Fiber stops accepting new requests
	// and waits for active handlers to finish (up to the timeout).
	if err := app.ShutdownWithContext(ctx); err != nil {
		log.Printf("[ERROR] Server shutdown encountered an error: %v", err)
	}

	log.Printf("[INFO] Server stopped completely on port %s", cfg.Port)
}
