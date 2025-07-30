.PHONY: help build up down setup logs status clean test sample-data azure-env azure-build azure-test-local azure-logs azure-stop azure-validate

# Default target
help: ## Show this help message
	@echo "MongoDB Kafka Connector Example - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Environment setup
.env:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "Please review and modify .env file as needed"; \
	fi

# Build Docker images
build: ## Build custom Docker images
	@echo "Building custom Kafka Connect image..."
	docker compose build kafka-connect

# Start all services
up: .env ## Start all services with Docker Compose
	@echo "Starting MongoDB Kafka Connector Example..."
	docker compose up -d
	@echo ""
	@echo "Services starting up. Use 'make logs' to monitor progress."
	@echo "Use 'make status' to check service health."

# Stop all services
down: ## Stop all services
	@echo "Stopping all services..."
	docker compose down

# Complete setup process
setup: .env build up ## Complete setup: build, start services, initialize replica set, and setup connector
	@echo "Performing complete setup..."
	@echo "Waiting for services to start..."
	@sleep 30
	@echo "Initializing MongoDB replica set..."
	@docker compose exec -T mongo1 mongosh --file /docker-entrypoint-initdb.d/replica-init.js
	@echo "Waiting for replica set to stabilize..."
	@sleep 20
	@echo "Setting up Kafka Connect MongoDB Source Connector..."
	@./scripts/setup-connector.sh
	@echo ""
	@echo "✅ Setup completed successfully!"
	@echo ""
	@make status

# Setup multiple filtered connectors
setup-multi-connectors: ## Setup multiple connectors with operation filtering (insert, update, delete)
	@echo "Setting up multiple MongoDB Kafka connectors with operation filtering..."
	@./scripts/setup-multi-connectors.sh

# View logs
logs: ## Show logs for all services
	docker compose logs -f

logs-mongo: ## Show MongoDB logs
	docker compose logs -f mongo1 mongo2 mongo3

logs-kafka: ## Show Kafka logs
	docker compose logs -f kafka zookeeper

logs-connect: ## Show Kafka Connect logs
	docker compose logs -f kafka-connect

# Check service status
status: ## Check the status of all services
	@echo "Checking service status..."
	@./scripts/health-check.sh

# Clean up everything
clean: down ## Stop services and remove volumes
	@echo "Cleaning up volumes and networks..."
	docker compose down -v --remove-orphans
	@echo "Pruning unused Docker resources..."
	docker system prune -f

# Run tests
test: ## Run health checks and basic tests
	@echo "Running health checks..."
	@./scripts/health-check.sh
	@echo ""
	@echo "Testing Kafka topics..."
	@docker compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list
	@echo ""
	@echo "Testing Kafka Connect status..."
	@curl -s http://localhost:8083/connectors | jq .

# Insert sample data
sample-data: ## Insert sample data into MongoDB
	@echo "Inserting sample data..."
	@docker compose exec -T mongo1 mongosh --file /tmp/sample-data.js
	@echo "Sample data inserted successfully!"

# TTL (Time To Live) Index Example
ttl-setup: ## Setup TTL indexes for automatic document expiration
	@echo "Setting up TTL indexes..."
	@docker compose exec -T mongo1 mongosh --file /tmp/ttl-setup.js
	@echo "TTL indexes setup completed!"

ttl-sample-data: ## Insert sample data with TTL expiration
	@echo "Inserting TTL sample data..."
	@docker compose exec -T mongo1 mongosh --file /tmp/ttl-sample-data.js
	@echo "TTL sample data inserted!"

ttl-monitor: ## Monitor Change Streams for TTL expiration events
	@echo "Starting TTL Change Stream monitor..."
	@echo "Press Ctrl+C to stop monitoring"
	@docker compose exec -T mongo1 mongosh --file /tmp/ttl-monitor.js

ttl-demo: ttl-setup ttl-sample-data ## Complete TTL demo setup (indexes + sample data)
	@echo ""
	@echo "🚀 TTL Demo is ready!"
	@echo ""
	@echo "📊 What was created:"
	@echo "  - TTL index on sessions.expiresAt (expires immediately when time reached)"
	@echo "  - TTL index on user_tokens.createdAt (expires after 60 seconds)"
	@echo "  - Sample session documents that expire in 30-150 seconds"
	@echo "  - Sample token documents that expire after 60 seconds"
	@echo ""
	@echo "🔍 Next steps:"
	@echo "  1. Monitor TTL events: make ttl-monitor"
	@echo "  2. Watch Kafka topics: make monitor-topics" 
	@echo "  3. Check Kafka UI: http://localhost:8080"
	@echo ""
	@echo "⏰ Note: MongoDB TTL background task runs every 60 seconds"

# Development helpers
dev-setup: setup sample-data ## Complete development setup with sample data
	@echo ""
	@echo "🚀 Development environment is ready!"
	@echo ""
	@echo "📊 Access points:"
	@echo "  - Kafka UI: http://localhost:8080"
	@echo "  - MongoDB Express: http://localhost:8081"
	@echo "  - Kafka Connect API: http://localhost:8083"
	@echo ""
	@echo "🔧 Useful commands:"
	@echo "  - View logs: make logs"
	@echo "  - Check status: make status"
	@echo "  - Insert more data: make sample-data"
	@echo "  - Try TTL example: make ttl-demo"

# Monitor Kafka topics
monitor-topics: ## Monitor Kafka topics for new messages
	@echo "Monitoring Kafka topics (Ctrl+C to stop)..."
	@docker compose exec kafka kafka-console-consumer \
		--bootstrap-server localhost:9092 \
		--topic mongodb.exemplo.users \
		--from-beginning

# Restart specific service
restart-mongo: ## Restart MongoDB services
	docker compose restart mongo1 mongo2 mongo3

restart-kafka: ## Restart Kafka services
	docker compose restart zookeeper kafka

restart-connect: ## Restart Kafka Connect
	docker compose restart kafka-connect

# Show service URLs
urls: ## Show service access URLs
	@echo "🌐 Service URLs:"
	@echo "  - Kafka UI:        http://localhost:8080"
	@echo "  - MongoDB Express: http://localhost:8081"
	@echo "  - Kafka Connect:   http://localhost:8083"
	@echo ""
	@echo "📡 API Endpoints:"
	@echo "  - Kafka Connect Status: curl http://localhost:8083/connectors"
	@echo "  - MongoDB Health:       curl http://localhost:8081"

# Backup and restore
backup: ## Backup MongoDB data
	@echo "Creating MongoDB backup..."
	@mkdir -p backups
	@docker compose exec -T mongo1 mongodump --host mongo1:27017 --out /tmp/backup
	@docker cp mongo1:/tmp/backup ./backups/$(shell date +%Y%m%d_%H%M%S)
	@echo "Backup completed!"

restore: ## Restore MongoDB data (specify BACKUP_DIR=path)
	@if [ -z "$(BACKUP_DIR)" ]; then \
		echo "Please specify BACKUP_DIR=path"; \
		exit 1; \
	fi
	@echo "Restoring MongoDB data from $(BACKUP_DIR)..."
	@docker cp $(BACKUP_DIR) mongo1:/tmp/restore
	@docker compose exec -T mongo1 mongorestore /tmp/restore
	@echo "Restore completed!"

# Production helpers
prod-check: ## Run production readiness checks
	@echo "Running production readiness checks..."
	@./scripts/health-check.sh
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