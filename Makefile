.PHONY: all build build-server build-cli release clean run stop test

# Default: build everything
all: build

# Build both server and CLI
build: build-server build-cli

# Build the Vapor server
build-server:
	cd server && swift build

# Build the Rust CLI
build-cli:
	cd cli && cargo build

# Build release binaries
release:
	cd server && swift build --configuration release
	cd cli && cargo build --release

# Clean all build artifacts
clean:
	rm -rf server/.build
	cd cli && cargo clean

# Run the server (development)
run:
	cd server && swift run

# Run the server (release)
run-release:
	cd server && ./.build/release/apple-ml-vapor

# Stop the server
stop:
	pkill -f apple-ml-vapor || true

# Install CLI to /usr/local/bin
install-cli: release
	cp cli/target/release/apple-ml /usr/local/bin/

# Test endpoints
test:
	@echo "Testing health..."
	@curl -s http://localhost:8080/health && echo ""
	@echo "Testing version..."
	@curl -s http://localhost:8080/version
	@echo ""
