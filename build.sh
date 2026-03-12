#!/bin/bash
set -e

cd "$(dirname "$0")"

# Read and increment build number (increments on every run, success or fail)
BUILD_FILE=".build_number"
BUILD=$(cat "$BUILD_FILE" 2>/dev/null || echo "0")
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILD_FILE"

VERSION="0.1.${BUILD}"
echo "=== Building SchulungsHub Server v${VERSION} ==="

# Update version in main.go
sed -i '' "s/const version = \".*\"/const version = \"${VERSION}\"/" main.go

# Get dependencies
go mod tidy

# Build for Linux (server target)
echo "Building linux/amd64..."
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o schulungshub-server .

# Also build local (macOS) for testing
echo "Building darwin/arm64..."
go build -ldflags="-s -w" -o schulungshub-server-local .

echo ""
echo "=== v${VERSION} (Build #${BUILD}) ==="
echo "  Linux:  schulungshub-server"
echo "  macOS:  schulungshub-server-local"
echo ""
