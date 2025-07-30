#!/bin/bash
# Integration test script for MongoDB Kafka Connector

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MongoDB Kafka Connector Integration Test ===${NC}"
echo "$(date)"
echo

# Function to log with timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
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

# Clean start
log_info "Stopping any existing containers..."
docker compose down -v || true

# Start services
log_info "Starting MongoDB Kafka Connector services..."
docker compose up -d

# Wait for services to be healthy
log_info "Waiting for core services to be healthy..."
timeout 300 bash -c '
    while true; do
        # Check MongoDB health
        mongo_health=$(docker compose ps mongo1 --format json | jq -r ".[0].Health // \"unknown\"")
        # Check Kafka health
        kafka_health=$(docker compose ps kafka --format json | jq -r ".[0].Health // \"unknown\"")
        # Check mongo-init completion
        mongo_init_state=$(docker compose ps mongo-init --format json | jq -r ".[0].State // \"unknown\"")
        
        echo "MongoDB: $mongo_health, Kafka: $kafka_health, mongo-init: $mongo_init_state"
        
        if [ "$mongo_health" = "healthy" ] && [ "$kafka_health" = "healthy" ] && [ "$mongo_init_state" = "exited" ]; then
            echo "Core services are ready!"
            break
        fi
        
        sleep 10
    done
'

# Check Kafka Connect
log_info "Waiting for Kafka Connect to be healthy..."
timeout 300 bash -c '
    while true; do
        connect_health=$(docker compose ps kafka-connect --format json | jq -r ".[0].Health // \"unknown\"")
        echo "Kafka Connect: $connect_health"
        
        if [ "$connect_health" = "healthy" ]; then
            echo "Kafka Connect is ready!"
            break
        fi
        
        sleep 15
    done
'

# Test basic functionality
log_info "Testing basic Kafka Connect functionality..."

# Check if REST API is responding
if curl -s -f http://localhost:8083/ > /dev/null; then
    log_success "Kafka Connect REST API is responding"
else
    log_error "Kafka Connect REST API is not responding"
    exit 1
fi

# Check connectors endpoint
if curl -s -f http://localhost:8083/connectors > /dev/null; then
    log_success "Connectors endpoint is accessible"
else
    log_error "Connectors endpoint is not accessible"
    exit 1
fi

# Check connector plugins
if curl -s http://localhost:8083/connector-plugins | grep -q mongodb; then
    log_success "MongoDB connector plugin is available"
else
    log_warning "MongoDB connector plugin not found"
fi

# Test MongoDB connectivity
log_info "Testing MongoDB connectivity..."
if docker compose exec -T mongo1 mongosh --eval "db.adminCommand('ping')" --quiet > /dev/null; then
    log_success "MongoDB is accessible"
else
    log_error "MongoDB is not accessible"
    exit 1
fi

# Test Kafka
log_info "Testing Kafka..."
if docker compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list > /dev/null; then
    log_success "Kafka is accessible"
else
    log_error "Kafka is not accessible"
    exit 1
fi

log_success "All integration tests passed!"
log_info "Services are ready for connector setup"

echo ""
log_info "Service endpoints:"
echo "  - Kafka UI: http://localhost:8080"
echo "  - MongoDB Express: http://localhost:8081"
echo "  - Kafka Connect API: http://localhost:8083"
echo ""
log_info "Next steps:"
echo "  - Run: ./scripts/setup-connector.sh"
echo "  - Run: make sample-data"
echo "  - Monitor with: make monitor-topics"