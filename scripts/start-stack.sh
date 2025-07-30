#!/bin/bash
# Enhanced startup script for MongoDB Kafka Connector Stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/startup-$(date +%Y%m%d-%H%M%S).log"
COMPOSE_PROJECT_NAME="mongodb-kafka-example"

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}INFO:${NC} $1"
}

log_success() {
    log "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    log "${YELLOW}WARNING:${NC} $1"
}

log_error() {
    log "${RED}ERROR:${NC} $1"
}

# Function to cleanup on exit
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "Script failed. Logs available at: $LOG_FILE"
        log_info "To view recent logs: tail -50 $LOG_FILE"
        log_info "To stop all services: docker compose down"
    fi
}

trap cleanup EXIT

log_success "=== MongoDB Kafka Connector Stack Startup ==="
log_info "Log file: $LOG_FILE"

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    log_error "Docker Compose is not available"
    exit 1
fi

log_success "Prerequisites check passed"

# Check if .env file exists
if [ ! -f .env ]; then
    log_warning ".env file not found, creating from .env.example"
    cp .env.example .env
fi

# Clean up any existing containers
log_info "Cleaning up any existing containers..."
docker compose down --remove-orphans --volumes 2>/dev/null || true

# Pull images
log_info "Pulling latest images..."
docker compose pull

# Build custom images
log_info "Building custom Kafka Connect image..."
docker compose build kafka-connect

# Start services in stages for better dependency management
log_info "=== Stage 1: Starting MongoDB Replica Set ==="
docker compose up -d mongo1 mongo2 mongo3

# Wait for MongoDB instances to be healthy
log_info "Waiting for MongoDB instances to be healthy..."
timeout 300 bash -c 'until [ "$(docker compose ps mongo1 --format="{{.Health}}")" = "healthy" ]; do echo "Waiting for mongo1..."; sleep 10; done'
timeout 300 bash -c 'until [ "$(docker compose ps mongo2 --format="{{.Health}}")" = "healthy" ]; do echo "Waiting for mongo2..."; sleep 10; done'
timeout 300 bash -c 'until [ "$(docker compose ps mongo3 --format="{{.Health}}")" = "healthy" ]; do echo "Waiting for mongo3..."; sleep 10; done'

log_success "MongoDB instances are healthy"

# Initialize replica set
log_info "=== Stage 2: Initializing MongoDB Replica Set ==="
docker compose up mongo-init

# Check if replica set initialization was successful
if [ $? -eq 0 ]; then
    log_success "MongoDB replica set initialized successfully"
else
    log_error "MongoDB replica set initialization failed"
    exit 1
fi

# Start Kafka infrastructure
log_info "=== Stage 3: Starting Kafka Infrastructure ==="
docker compose up -d zookeeper

# Wait for Zookeeper
log_info "Waiting for Zookeeper to be healthy..."
timeout 120 bash -c 'until [ "$(docker compose ps zookeeper --format="{{.Health}}")" = "healthy" ]; do echo "Waiting for zookeeper..."; sleep 10; done'

log_success "Zookeeper is healthy"

# Start Kafka
docker compose up -d kafka

# Wait for Kafka
log_info "Waiting for Kafka to be healthy..."
timeout 180 bash -c 'until [ "$(docker compose ps kafka --format="{{.Health}}")" = "healthy" ]; do echo "Waiting for kafka..."; sleep 10; done'

log_success "Kafka is healthy"

# Start Kafka Connect
log_info "=== Stage 4: Starting Kafka Connect ==="
docker compose up -d kafka-connect

# Wait for Kafka Connect
log_info "Waiting for Kafka Connect to be healthy..."
timeout 300 bash -c 'until [ "$(docker compose ps kafka-connect --format="{{.Health}}")" = "healthy" ]; do echo "Waiting for kafka-connect..."; sleep 15; done'

log_success "Kafka Connect is healthy"

# Start UI services
log_info "=== Stage 5: Starting UI Services ==="
docker compose up -d kafka-ui mongo-express

# Wait for UI services
log_info "Waiting for UI services to be ready..."
sleep 30

# Final status check
log_info "=== Final Status Check ==="
log_info "Container status:"
docker compose ps

# Check service health
log_info "Service health check:"
healthy_services=0
total_services=0

for service in mongo1 mongo2 mongo3 zookeeper kafka kafka-connect kafka-ui mongo-express; do
    total_services=$((total_services + 1))
    health_status=$(docker compose ps "$service" --format="{{.Health}}" 2>/dev/null || echo "unknown")
    
    if [ "$health_status" = "healthy" ]; then
        log_success "$service: healthy"
        healthy_services=$((healthy_services + 1))
    elif [ "$health_status" = "starting" ]; then
        log_warning "$service: still starting"
    else
        log_error "$service: $health_status"
    fi
done

# Summary
log_info "=== Startup Summary ==="
log_info "Healthy services: $healthy_services/$total_services"

if [ $healthy_services -eq $total_services ]; then
    log_success "✓ All services are healthy!"
    
    log_info "=== Service URLs ==="
    log_info "MongoDB Express: http://localhost:8081 (admin/admin)"
    log_info "Kafka UI: http://localhost:8080"
    log_info "Kafka Connect REST API: http://localhost:8083"
    log_info "MongoDB Replica Set: mongodb://admin:password123@localhost:27017,localhost:27018,localhost:27019/?authSource=admin&replicaSet=rs0"
    
    log_info "=== Next Steps ==="
    log_info "1. Check service logs: docker compose logs -f [service_name]"
    log_info "2. Run health check: ./scripts/health-check.sh"
    log_info "3. Set up connectors: ./scripts/setup-connector.sh"
    
else
    log_warning "Some services are not healthy yet. They may still be starting up."
    log_info "Run 'docker compose ps' to check current status"
    log_info "Run 'docker compose logs [service_name]' to check logs"
fi

log_success "Stack startup completed. Logs saved to: $LOG_FILE"