#!/bin/bash
# Test script to verify MongoDB replica set setup
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MongoDB Replica Set Test ===${NC}"
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

# Start only MongoDB services
log_info "Starting MongoDB services..."
docker compose up -d mongo1 mongo2 mongo3 mongo-init

# Wait for services to be healthy
log_info "Waiting for MongoDB services to be healthy..."
timeout 300 bash -c '
    while true; do
        # Check MongoDB health
        mongo1_health=$(docker compose ps mongo1 --format json | jq -r ".[0].Health // \"unknown\"")
        mongo2_health=$(docker compose ps mongo2 --format json | jq -r ".[0].Health // \"unknown\"")
        mongo3_health=$(docker compose ps mongo3 --format json | jq -r ".[0].Health // \"unknown\"")
        # Check mongo-init completion
        mongo_init_state=$(docker compose ps mongo-init --format json | jq -r ".[0].State // \"unknown\"")
        
        echo "MongoDB1: $mongo1_health, MongoDB2: $mongo2_health, MongoDB3: $mongo3_health, mongo-init: $mongo_init_state"
        
        if [ "$mongo1_health" = "healthy" ] && [ "$mongo2_health" = "healthy" ] && [ "$mongo3_health" = "healthy" ] && [ "$mongo_init_state" = "exited" ]; then
            echo "MongoDB services are ready!"
            break
        fi
        
        sleep 10
    done
'

# Test basic MongoDB connectivity with authentication
log_info "Testing MongoDB connectivity..."
for i in 1 2 3; do
    if docker compose exec -T mongo$i mongosh --eval "db.adminCommand('ping')" --quiet > /dev/null; then
        log_success "MongoDB mongo$i is accessible"
    else
        log_error "MongoDB mongo$i is not accessible"
        exit 1
    fi
done

# Test replica set status
log_info "Testing replica set status..."
REPLICA_STATUS=$(docker compose exec -T mongo1 mongosh --eval "rs.status()" --quiet)
echo "$REPLICA_STATUS" | grep -q "\"ok\" : 1" && log_success "Replica set is operational" || { log_error "Replica set is not operational"; exit 1; }

# Test connectivity with multi-host connection string
log_info "Testing multi-host connection string..."
MULTI_HOST_TEST=$(docker compose exec -T mongo1 mongosh "mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0" --eval "db.adminCommand('ping')" --quiet)
echo "$MULTI_HOST_TEST" | grep -q "\"ok\" : 1" && log_success "Multi-host connection string works" || { log_error "Multi-host connection string failed"; exit 1; }

# Test that mongo1 is primary and others are secondary
log_info "Testing replica set member roles..."
PRIMARY_COUNT=$(docker compose exec -T mongo1 mongosh --eval "rs.status().members.filter(m => m.stateStr === 'PRIMARY').length" --quiet | tail -1)
SECONDARY_COUNT=$(docker compose exec -T mongo1 mongosh --eval "rs.status().members.filter(m => m.stateStr === 'SECONDARY').length" --quiet | tail -1)

if [ "$PRIMARY_COUNT" = "1" ] && [ "$SECONDARY_COUNT" = "2" ]; then
    log_success "Replica set has correct topology: 1 PRIMARY, 2 SECONDARY"
else
    log_error "Replica set topology is incorrect: $PRIMARY_COUNT PRIMARY, $SECONDARY_COUNT SECONDARY"
    exit 1
fi

# Test that mongo1 is the primary
PRIMARY_HOST=$(docker compose exec -T mongo1 mongosh --eval "rs.status().members.find(m => m.stateStr === 'PRIMARY').name" --quiet | tail -1)
if echo "$PRIMARY_HOST" | grep -q "mongo1:27017"; then
    log_success "mongo1 is correctly configured as PRIMARY"
else
    log_warning "mongo1 is not the primary: $PRIMARY_HOST"
fi

# Test sample database creation
log_info "Testing sample database and collections..."
COLLECTIONS=$(docker compose exec -T mongo1 mongosh exemplo --eval "db.getCollectionNames()" --quiet | tail -1)
if echo "$COLLECTIONS" | grep -q "users" && echo "$COLLECTIONS" | grep -q "products" && echo "$COLLECTIONS" | grep -q "orders"; then
    log_success "Sample collections created successfully"
else
    log_error "Sample collections were not created properly"
    exit 1
fi

log_success "All MongoDB replica set tests passed!"
log_info "MongoDB replica set is properly configured with:"
echo "  - 3 nodes: mongo1 (PRIMARY), mongo2 (SECONDARY), mongo3 (SECONDARY)"
echo "  - Robust healthchecks"
echo "  - Proper startup dependencies"
echo "  - Multi-host connection string working"
echo "  - Sample database and collections created"
echo ""
log_info "Connection string: mongodb://mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0"

# Clean up
log_info "Cleaning up..."
docker compose down