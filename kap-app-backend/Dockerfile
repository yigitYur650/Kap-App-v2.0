# ============================================================
# KAP-APP v2.0 — Go Backend Production Dockerfile
# Multi-stage build for minimal image size and maximum speed
# ============================================================

# Step 1: Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install git and ca-certificates
RUN apk add --no-cache git ca-certificates

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy application source code
COPY . .

# Build lightweight, statically-linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server ./cmd/server/main.go

# Step 2: Final runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/server .

# Expose port (Cloud providers set PORT environment variable dynamically)
EXPOSE 8080

# Run the Go binary
CMD ["./server"]
