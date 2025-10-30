# Makefile for AirSense Backend

# Configuration
APP_NAME = airsense-be
VERSION = $(shell git describe --tags 2>/dev/null || echo "v0.1.0")
COMMIT_HASH = $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME = $(shell date -u '+%Y-%m-%d_%H:%M:%S')
BUILD_DIR = ./bin
DIST_DIR = ./dist

# Go parameters
GOCMD = go
GOBUILD = $(GOCMD) build
GOTEST = $(GOCMD) test
GOCLEAN = $(GOCMD) clean
GOGET = $(GOCMD) get
GOMOD = $(GOCMD) mod

# LDFlags
LDFLAGS = -s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT_HASH) -X main.buildTime=$(BUILD_TIME)

.PHONY: all build build-dev build-prod test clean lint docker help

all: test build

## Development
build-dev: ## Build for development
	@echo "Building for development..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) -v -ldflags="$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME) ./cmd/server
	@chmod +x $(BUILD_DIR)/$(APP_NAME)
	@echo "Build complete: $(BUILD_DIR)/$(APP_NAME)"

build: build-dev ## Alias for build-dev

## Production
build-prod: ## Build for production
	@echo "Building for production..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 $(GOBUILD) -v -ldflags="$(LDFLAGS)" -a -installsuffix cgo -o $(BUILD_DIR)/$(APP_NAME) ./cmd/server
	@echo "Production build complete: $(BUILD_DIR)/$(APP_NAME)"

## Testing
test: ## Run tests
	@echo "Running tests..."
	$(GOTEST) -v -race -short ./...
	$(GOTEST) -v -race -coverprofile=coverage.out ./...
	@echo "Tests completed"

test-coverage: test ## Run tests with coverage report
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

## Code Quality
lint: ## Run linter
	@echo "Running linter..."
	@which golangci-lint > /dev/null || (echo "Installing golangci-lint..." && \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.54.2)
	golangci-lint run ./...

fmt: ## Format code
	@echo "Formatting code..."
	$(GOCMD) fmt ./...
	@which goimports > /dev/null && find . -name "*.go" -exec goimports -w {} \; || true
	@echo "Formatting complete"

audit: ## Security audit
	@echo "Running security audit..."
	$(GOMOD) download
	$(GOCMD) list -json -m all | $(GOCMD) run golang.org/x/vuln/cmd/govulncheck@latest

## Docker
docker: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t $(APP_NAME):$(VERSION) -t $(APP_NAME):latest .
	@echo "Docker image built: $(APP_NAME):$(VERSION), $(APP_NAME):latest"

docker-run: docker ## Build and run Docker container
	@echo "Running Docker container..."
	docker run -p 8080:8080 --env-file .env $(APP_NAME):latest

## Release
release: ## Build release for multiple platforms
	@echo "Building releases..."
	@mkdir -p $(DIST_DIR)
	@$(MAKE) build-release-platform GOOS=linux GOARCH=amd64
	@$(MAKE) build-release-platform GOOS=linux GOARCH=arm64
	@$(MAKE) build-release-platform GOOS=darwin GOARCH=amd64
	@$(MAKE) build-release-platform GOOS=darwin GOARCH=arm64
	@$(MAKE) build-release-platform GOOS=windows GOARCH=amd64 EXT=.exe
	@echo "Release builds complete"

build-release-platform:
	@echo "Building $(GOOS)/$(GOARCH)..."
	@CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) $(GOBUILD) -ldflags="$(LDFLAGS)" -o $(DIST_DIR)/$(APP_NAME)-$(VERSION)-$(GOOS)-$(GOARCH)$(EXT) ./cmd/server
	@cd $(DIST_DIR) && \
	if [ "$(GOOS)" = "windows" ]; then \
		zip $(APP_NAME)-$(VERSION)-$(GOOS)-$(GOARCH).zip $(APP_NAME)-$(VERSION)-$(GOOS)-$(GOARCH)$(EXT); \
	else \
		tar -czf $(APP_NAME)-$(VERSION)-$(GOOS)-$(GOARCH).tar.gz $(APP_NAME)-$(VERSION)-$(GOOS)-$(GOARCH)$(EXT); \
	fi
	@echo "Built $(GOOS)/$(GOARCH)"

## Cleanup
clean: ## Clean build artifacts
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@find . -name "*.test" -delete
	@find . -name "*.out" -delete
	@find . -name "coverage.html" -delete
	@$(GOCLEAN) -cache -testcache -modcache
	@echo "Clean complete"

## Dependencies
deps: ## Download dependencies
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) verify
	@echo "Dependencies downloaded"

tidy: ## Tidy dependencies
	@echo "Tidying dependencies..."
	$(GOMOD) tidy
	@echo "Dependencies tidied"

## Help
help: ## Show this help
	@echo "AirSense Backend Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)