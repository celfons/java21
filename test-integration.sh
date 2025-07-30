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
timeout 600 bash -c '
    while true; do
        # Check MongoDB health using simple docker compose ps
        mongo1_status=$(docker compose ps mongo1 --format "table {{.Status}}" | tail -n +2)
        mongo2_status=$(docker compose ps mongo2 --format "table {{.Status}}" | tail -n +2)
        mongo3_status=$(docker compose ps mongo3 --format "table {{.Status}}" | tail -n +2)
        
        echo "MongoDB1: $mongo1_status"
        echo "MongoDB2: $mongo2_status" 
        echo "MongoDB3: $mongo3_status"
        
        if echo "$mongo1_status" | grep -q "healthy" && echo "$mongo2_status" | grep -q "healthy" && echo "$mongo3_status" | grep -q "healthy"; then
            echo "All MongoDB containers are healthy!"
            break
        fi
        
        sleep 15
    done
'

# Wait for mongo-init to complete  
log_info "Waiting for mongo-init to complete..."
timeout 600 bash -c '
    while true; do
        mongo_init_status=$(docker compose ps mongo-init --format "table {{.Status}}" 2>/dev/null | tail -n +2 || echo "not_found")
        echo "mongo-init status: $mongo_init_status"
        
        if echo "$mongo_init_status" | grep -q "Exited (0)"; then
            echo "mongo-init completed successfully!"
            break
        elif echo "$mongo_init_status" | grep -q "Exited ([1-9]"; then
            echo "ERROR: mongo-init failed!"
            docker compose logs mongo-init
            exit 1
        fi
        
        echo "Waiting for mongo-init to complete..."
        sleep 10
    done
'

# Additional wait for MongoDB to be ready for authenticated connections
log_info "Verifying MongoDB is ready for authenticated connections..."
timeout 300 bash -c '
    attempt=1
    max_attempts=60
    while [ $attempt -le $max_attempts ]; do
        echo "[$attempt/$max_attempts] Testing MongoDB authenticated connectivity..."
        
        if docker compose exec -T mongo1 mongosh --username admin --password password123 --authenticationDatabase admin --eval "db.adminCommand(\"ping\")" --quiet > /dev/null 2>&1; then
            echo "MongoDB authenticated connectivity confirmed!"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            echo "ERROR: MongoDB authenticated connectivity failed after $max_attempts attempts"
            exit 1
        fi
        
        echo "Waiting 5s before retry..."
        sleep 5
        ((attempt++))
    done
'

# Check Kafka Connect
log_info "Waiting for Kafka Connect to be healthy..."
timeout 600 bash -c '
    while true; do
        connect_status=$(docker compose ps kafka-connect --format "table {{.Status}}" | tail -n +2)
        echo "Kafka Connect: $connect_status"
        
        if echo "$connect_status" | grep -q "healthy"; then
            echo "Kafka Connect is ready!"
            break
        fi
        
        sleep 20
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
if docker compose exec -T mongo1 mongosh --username admin --password password123 --authenticationDatabase admin --eval "db.adminCommand('ping')" --quiet > /dev/null; then
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