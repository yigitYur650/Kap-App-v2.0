# ============================================================
# KAP-APP v2.0 — Go Backend Production Dockerfile
# Multi-stage build for minimal image size and maximum speed
# ============================================================

# Step 1: Build stage (using golang:alpine for latest Go 1.24+ compatibility)
FROM golang:alpine AS builder

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

# Step 2: Final runtime stage with Node.js & Chromium for Playwright scraper support
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata nodejs npm chromium nss freetype harfbuzz ttf-freefont \
    && addgroup -S appgroup && adduser -S appuser -G appgroup

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /home/appuser/

# Copy binary from builder and assign ownership
COPY --from=builder --chown=appuser:appgroup /app/server .
COPY --from=builder --chown=appuser:appgroup /app/package.json /app/package-lock.json* ./
COPY --from=builder --chown=appuser:appgroup /app/scripts ./scripts

RUN npm install --only=production

USER appuser

# Expose port
EXPOSE 8080

# Run the Go binary
CMD ["./server"]
