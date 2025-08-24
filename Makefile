# Makefile for Rinha de Backend 2025
.PHONY: help build-jvm build-native docker-jvm docker-native up down load-test clean

# Default target
help:
	@echo "Available targets:"
	@echo "  build-jvm      - Build JVM JAR"
	@echo "  build-native   - Build GraalVM native binary"
	@echo "  docker-jvm     - Build Docker image with JVM"
	@echo "  docker-native  - Build Docker image with native binary"
	@echo "  up            - Start infrastructure (Redis, HAProxy, app)"
	@echo "  down          - Stop infrastructure"
	@echo "  load-test     - Run load test against the application"
	@echo "  clean         - Clean build artifacts"

# Build JVM JAR
build-jvm:
	@echo "Building JVM JAR..."
	./mvnw clean package -DskipTests

# Build GraalVM native binary
build-native:
	@echo "Building GraalVM native binary..."
	./mvnw clean -Pnative native:compile

# Build Docker image with JVM
docker-jvm: build-jvm
	@echo "Building Docker image with JVM..."
	docker build -f Dockerfile.jvm -t rinha-jvm:latest .

# Build Docker image with native binary
docker-native: build-native
	@echo "Building Docker image with native binary..."
	docker build -f Dockerfile -t rinha-native:latest .

# Start infrastructure
up:
	@echo "Starting infrastructure..."
	docker-compose up -d

# Stop infrastructure
down:
	@echo "Stopping infrastructure..."
	docker-compose down

# Run load test
load-test:
	@echo "Running load test..."
	@if command -v wrk >/dev/null 2>&1; then \
		echo "Testing POST /payments..."; \
		echo 'wrk -t4 -c100 -d30s -s scripts/load-test.lua http://localhost:8080/payments'; \
		wrk -t4 -c100 -d30s -s scripts/load-test.lua http://localhost:8080/payments || true; \
		echo "Testing GET /payments-summary..."; \
		wrk -t4 -c100 -d15s http://localhost:8080/payments-summary; \
	else \
		echo "wrk not found. Install wrk for load testing."; \
		echo "Alternative: curl -X POST http://localhost:8080/payments -H 'Content-Type: application/json' -d '{\"correlationId\":\"$(uuidgen)\",\"amount\":100.50}'"; \
	fi

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	./mvnw clean
	docker system prune -f --volumes