#!/bin/bash

# AirSense Backend Build Script
# Usage: ./build.sh [dev|prod|test|clean|docker|release]

set -e  # Exit on any error

# Configuration
APP_NAME="airsense-be"
VERSION=$(git describe --tags 2>/dev/null || echo "v0.1.0")
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DIR="./bin"
DIST_DIR="./dist"
GO_VERSION=$(go version | awk '{print $3}')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
AirSense Backend Build Script

Usage: $0 [OPTION]

Options:
  dev       Build for development (default)
  prod      Build for production with optimizations
  test      Run tests and build
  clean     Clean build artifacts
  docker    Build Docker image
  release   Build release for multiple platforms
  help      Show this help message

Environment variables:
  GOOS      Target operating system (linux, darwin, windows)
  GOARCH    Target architecture (amd64, arm64)
  CGO_ENABLED Whether to use CGO (0 or 1)

Examples:
  $0 dev          # Build for development
  $0 prod         # Build production binary
  $0 docker       # Build Docker image
  $0 release      # Build for multiple platforms
  GOOS=linux $0 prod  # Build Linux production binary
EOF
}

# Check if Go is installed
check_go() {
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed or not in PATH"
        exit 1
    fi
    
    log_info "Using Go version: $GO_VERSION"
}

# Clean build artifacts
clean() {
    log_info "Cleaning build artifacts..."
    
    # Remove build directories
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    
    # Remove temporary files
    find . -name "*.test" -delete
    find . -name "*.out" -delete
    find . -name "coverage.html" -delete
    
    # Clean Go cache
    go clean -cache -testcache -modcache
    
    log_success "Clean completed"
}

# Run tests
run_tests() {
    log_info "Running tests..."
    
    # Run unit tests
    if ! go test -v -race -short ./...; then
        log_error "Tests failed"
        exit 1
    fi
    
    # Run tests with coverage
    log_info "Generating test coverage..."
    go test -v -race -coverprofile=coverage.out ./...
    go tool cover -html=coverage.out -o coverage.html
    
    log_success "Tests completed successfully"
}

# Build for development
build_dev() {
    log_info "Building for development..."
    
    mkdir -p "$BUILD_DIR"
    
    LDFLAGS="-X main.version=$VERSION -X main.commit=$COMMIT_HASH -X main.buildTime=$BUILD_TIME"
    
    if ! go build -v -ldflags="$LDFLAGS" -o "$BUILD_DIR/$APP_NAME" ./cmd/server; then
        log_error "Build failed"
        exit 1
    fi
    
    chmod +x "$BUILD_DIR/$APP_NAME"
    
    log_success "Development build completed: $BUILD_DIR/$APP_NAME"
}

# Build for production
build_prod() {
    log_info "Building for production..."
    
    local OS="${GOOS:-$(go env GOOS)}"
    local ARCH="${GOARCH:-$(go env GOARCH)}"
    
    mkdir -p "$BUILD_DIR"
    
    LDFLAGS="-s -w -X main.version=$VERSION -X main.commit=$COMMIT_HASH -X main.buildTime=$BUILD_TIME"
    
    export CGO_ENABLED=0
    
    log_info "Building for $OS/$ARCH..."
    
    if ! GOOS=$OS GOARCH=$ARCH go build \
        -v \
        -ldflags="$LDFLAGS" \
        -a \
        -installsuffix cgo \
        -o "$BUILD_DIR/${APP_NAME}-${OS}-${ARCH}" \
        ./cmd/server; then
        log_error "Production build failed"
        exit 1
    fi
    
    # Create a symlink for the current platform
    if [ "$OS" = "$(go env GOOS)" ] && [ "$ARCH" = "$(go env GOARCH)" ]; then
        ln -sf "${APP_NAME}-${OS}-${ARCH}" "$BUILD_DIR/$APP_NAME"
    fi
    
    log_success "Production build completed: $BUILD_DIR/${APP_NAME}-${OS}-${ARCH}"
}

# Build Docker image
build_docker() {
    log_info "Building Docker image..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    local IMAGE_NAME="${APP_NAME}:${VERSION}"
    local IMAGE_LATEST="${APP_NAME}:latest"
    
    # Build the image
    if ! docker build -t "$IMAGE_NAME" -t "$IMAGE_LATEST" .; then
        log_error "Docker build failed"
        exit 1
    fi
    
    log_success "Docker image built: $IMAGE_NAME, $IMAGE_LATEST"
    
    # Show image information
    log_info "Docker image details:"
    docker images | grep "$APP_NAME"
}

# Build release for multiple platforms
build_release() {
    log_info "Building releases for multiple platforms..."
    
    mkdir -p "$DIST_DIR"
    
    # Platforms to build for
    PLATFORMS=(
        "linux amd64"
        "linux arm64"
        "darwin amd64"
        "darwin arm64"
        "windows amd64 .exe"
    )
    
    LDFLAGS="-s -w -X main.version=$VERSION -X main.commit=$COMMIT_HASH -X main.buildTime=$BUILD_TIME"
    
    for platform in "${PLATFORMS[@]}"; do
        local os=$(echo $platform | awk '{print $1}')
        local arch=$(echo $platform | awk '{print $2}')
        local ext=$(echo $platform | awk '{print $3}')
        
        if [ -z "$ext" ]; then
            ext=""
        fi
        
        local output_name="${APP_NAME}-${VERSION}-${os}-${arch}${ext}"
        
        log_info "Building $output_name..."
        
        if GOOS=$os GOARCH=$arch CGO_ENABLED=0 \
            go build \
            -ldflags="$LDFLAGS" \
            -o "$DIST_DIR/$output_name" \
            ./cmd/server; then
            
            # Create archive
            if [ "$os" = "windows" ]; then
                zip -j "$DIST_DIR/${output_name%.exe}.zip" "$DIST_DIR/$output_name"
            else
                tar -czf "$DIST_DIR/$output_name.tar.gz" -C "$DIST_DIR" "$output_name"
            fi
            
            log_success "Built $output_name"
        else
            log_error "Failed to build $output_name"
        fi
    done
    
    # Create checksums
    log_info "Generating checksums..."
    cd "$DIST_DIR"
    shasum -a 256 *.* > "sha256sums.txt"
    cd - > /dev/null
    
    log_success "Release builds completed in $DIST_DIR/"
}

# Lint code
run_lint() {
    log_info "Running linter..."
    
    # Install golangci-lint if not present
    if ! command -v golangci-lint &> /dev/null; then
        log_warning "golangci-lint not found, installing..."
        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.54.2
    fi
    
    if ! golangci-lint run ./...; then
        log_error "Linting failed"
        exit 1
    fi
    
    log_success "Linting completed"
}

# Security audit
run_audit() {
    log_info "Running security audit..."
    
    # Check for vulnerabilities in dependencies
    if ! go mod download; then
        log_error "Failed to download dependencies"
        exit 1
    fi
    
    if ! go list -json -m all | go run golang.org/x/vuln/cmd/govulncheck@latest; then
        log_warning "Vulnerability check completed with issues"
    else
        log_success "Security audit completed"
    fi
}

# Format code
run_format() {
    log_info "Formatting code..."
    
    # Format Go code
    go fmt ./...
    
    # Check if imports are properly arranged
    if command -v goimports &> /dev/null; then
        find . -name "*.go" -exec goimports -w {} \;
    fi
    
    log_success "Code formatting completed"
}

# Main function
main() {
    local command=${1:-"dev"}
    
    check_go
    
    case $command in
        dev|development)
            run_tests
            build_dev
            ;;
        prod|production)
            run_tests
            run_lint
            build_prod
            ;;
        test)
            run_tests
            ;;
        clean)
            clean
            ;;
        docker)
            build_docker
            ;;
        release)
            run_tests
            run_lint
            build_release
            ;;
        lint)
            run_lint
            ;;
        audit)
            run_audit
            ;;
        format)
            run_format
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"