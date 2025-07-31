.PHONY: help build up down setup logs status clean test setup-connector setup-multi-connectors azure-env azure-build azure-test-local azure-logs azure-stop azure-validate

# Default target
help: ## Show this help message
	@echo "MongoDB Atlas Kafka Connector Example - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Environment setup
.env:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "⚠️  IMPORTANT: Please configure MongoDB Atlas and Kafka connection strings in .env file"; \
		echo "   - Set MONGODB_ATLAS_CONNECTION_STRING with your Atlas cluster connection string"; \
		echo "   - Set KAFKA_BOOTSTRAP_SERVERS with your external Kafka cluster bootstrap servers"; \
	fi

# Build Docker images
build: ## Build custom Kafka Connect image
	@echo "Building custom Kafka Connect image..."
	docker compose build kafka-connect

# Start services (only Kafka Connect)
up: .env ## Start Kafka Connect service with Docker Compose
	@echo "Starting MongoDB Atlas Kafka Connect..."
	@echo "ℹ️  This will only start Kafka Connect - it connects to external Atlas and Kafka"
	docker compose up -d
	@echo ""
	@echo "Service starting up. Use 'make logs' to monitor progress."
	@echo "Use 'make status' to check service health."

# Stop all services
down: ## Stop all services
	@echo "Stopping all services..."
	docker compose down

# Complete setup process for Atlas
setup: .env build up ## Complete setup: build, start Kafka Connect, and setup Atlas connector
	@echo "Performing Atlas setup..."
	@echo "Waiting for Kafka Connect to start..."
	@sleep 30
	@echo "Setting up MongoDB Atlas Connector..."
	@./scripts/setup-connector.sh
	@echo ""
	@echo "✅ Atlas setup completed successfully!"
	@echo ""
	@make status

# Setup multiple filtered connectors for Atlas
setup-multi-connectors: ## Setup multiple connectors with operation filtering (insert, update, delete)
	@echo "Setting up multiple MongoDB Atlas Kafka connectors with operation filtering..."
	@./scripts/setup-multi-connectors.sh

# Setup single connector for Atlas
setup-connector: ## Setup single MongoDB Atlas connector
	@echo "Setting up MongoDB Atlas connector..."
	@./scripts/setup-connector.sh

# View logs
logs: ## Show logs for Kafka Connect service
	docker compose logs -f kafka-connect

# Check service status
status: ## Check the status of Kafka Connect service
	@echo "Checking Kafka Connect status..."
	@./scripts/health-check-atlas.sh

# Clean up everything
clean: down ## Stop services and remove volumes
	@echo "Cleaning up volumes and networks..."
	docker compose down -v --remove-orphans
	@echo "Pruning unused Docker resources..."
	docker system prune -f

# Run mock tests (no external dependencies)
test: ## Run mock tests for Atlas configuration
	@echo "Running mock tests for Atlas configuration..."
	@./test-atlas-setup.sh

# Run enhanced integration tests with local infrastructure
test-integration: ## Run enhanced integration tests with local infrastructure
	@echo "Running enhanced integration tests..."
	@./test-integration-enhanced.sh

# Run all tests (mock + integration)
test-all: test test-integration ## Run all tests (mock configuration + integration pipeline)
	@echo "All tests completed successfully!"

# Run Atlas health checks
health-check: ## Run Atlas health checks
	@echo "Running Atlas health checks..."
	@./scripts/health-check-atlas.sh

# Development helpers for Atlas
dev-setup: setup setup-connector ## Complete Atlas development setup
	@echo ""
	@echo "🚀 Atlas development environment is ready!"
	@echo ""
	@echo "📊 Access points:"
	@echo "  - Kafka Connect API: http://localhost:8083"
	@echo ""
	@echo "🔧 Useful commands:"
	@echo "  - View logs: make logs"
	@echo "  - Check status: make status"
	@echo "  - Setup multiple connectors: make setup-multi-connectors"
	@echo "  - Health check: make health-check"

# Restart Kafka Connect service
restart-connect: ## Restart Kafka Connect service
	docker compose restart kafka-connect

# Show service URLs
urls: ## Show service access URLs
	@echo "🌐 Service URLs:"
	@echo "  - Kafka Connect:   http://localhost:8083"
	@echo ""
	@echo "📡 API Endpoints:"
	@echo "  - Kafka Connect Status: curl http://localhost:8083/connectors"

# Production helpers for Atlas
prod-check: ## Run production readiness checks for Atlas setup
	@echo "Running Atlas production readiness checks..."
	@./scripts/health-check-atlas.sh
	@echo ""
	@echo "Checking resource usage..."
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Update connector configuration
update-connector: ## Update connector configuration
	@echo "Updating connector configuration..."
	@./scripts/setup-connector.sh
	@echo "Connector updated!"

# Show environment variables
show-env: ## Show current environment configuration
	@echo "Current environment configuration:"
	@cat .env 2>/dev/null || echo "No .env file found. Run 'make .env' to create one."

# Azure deployment helpers
azure-env: ## Create Azure environment template
	@if [ ! -f .env.azure ]; then \
		echo "Creating .env.azure from template..."; \
		cp .env.azure.example .env.azure; \
		echo "⚠️  Please edit .env.azure with your Azure credentials"; \
		echo "⚠️  Do NOT commit .env.azure to version control"; \
	else \
		echo ".env.azure already exists"; \
	fi

azure-build: ## Build image for Azure deployment
	@echo "Building Azure production image..."
	docker build -t kafka-connect-mongodb:azure .

azure-test-local: azure-env azure-build ## Test Azure configuration locally
	@echo "Testing Azure configuration locally..."
	@if [ ! -f .env.azure ]; then \
		echo "❌ .env.azure not found. Run 'make azure-env' first"; \
		exit 1; \
	fi
	docker compose -f docker-compose.azure.yml --env-file .env.azure up -d
	@echo "🚀 Azure configuration running locally"
	@echo "🔗 API: http://localhost:8083"

azure-logs: ## Show logs for Azure local test
	docker compose -f docker-compose.azure.yml logs -f

azure-stop: ## Stop Azure local test
	docker compose -f docker-compose.azure.yml down

azure-validate: ## Validate Azure deployment configuration
	@./scripts/validate-azure.sh