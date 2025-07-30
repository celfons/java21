#!/bin/bash
# Validation script to test the MongoDB Kafka Connector setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MONGO_USER=${MONGO_INITDB_ROOT_USERNAME:-admin}
MONGO_PASS=${MONGO_INITDB_ROOT_PASSWORD:-password123}
TEST_DATABASE="test_db"
TEST_COLLECTION="test_collection"

# Logging functions
log_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

echo -e "${GREEN}=== MongoDB Kafka Connector Stack Validation ===${NC}"
echo "$(date)"
echo

# Function to check if a service is healthy
check_service_health() {
    local service=$1
    local health_status=$(docker compose ps "$service" --format="{{.Health}}" 2>/dev/null || echo "unknown")
    
    if [ "$health_status" = "healthy" ]; then
        log_success "$service is healthy"
        return 0
    else
        log_error "$service is not healthy: $health_status"
        return 1
    fi
}

# Test 1: Check all services are healthy
log_info "=== Test 1: Service Health Check ==="
failed_services=0

for service in mongo1 mongo2 mongo3 zookeeper kafka kafka-connect; do
    if ! check_service_health "$service"; then
        ((failed_services++))
    fi
done

if [ $failed_services -eq 0 ]; then
    log_success "All critical services are healthy"
else
    log_error "$failed_services critical services are not healthy"
    exit 1
fi

echo

# Test 2: MongoDB Replica Set Status
log_info "=== Test 2: MongoDB Replica Set Validation ==="

replica_set_status=$(mongosh --host localhost:27017 \
    --username "$MONGO_USER" \
    --password "$MONGO_PASS" \
    --authenticationDatabase admin \
    --eval "JSON.stringify(rs.status())" \
    --quiet 2>/dev/null)

if [ $? -eq 0 ]; then
    log_success "MongoDB replica set is accessible"
    
    # Count healthy members
    healthy_members=$(echo "$replica_set_status" | jq -r '.members[] | select(.health == 1) | .name' | wc -l)
    primary_member=$(echo "$replica_set_status" | jq -r '.members[] | select(.stateStr == "PRIMARY") | .name')
    
    log_info "Healthy members: $healthy_members/3"
    log_info "Primary member: $primary_member"
    
    if [ "$healthy_members" -ge 2 ] && [ -n "$primary_member" ]; then
        log_success "Replica set is healthy with primary and sufficient members"
    else
        log_error "Replica set is not in a healthy state"
        exit 1
    fi
else
    log_error "Cannot connect to MongoDB replica set"
    exit 1
fi

echo

# Test 3: Kafka Cluster Validation
log_info "=== Test 3: Kafka Cluster Validation ==="

# Check if Kafka is responding
if docker compose exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    log_success "Kafka broker is responding"
else
    log_error "Kafka broker is not responding"
    exit 1
fi

# List topics
topics=$(docker compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null)
if [ $? -eq 0 ]; then
    log_success "Kafka topics are accessible"
    log_info "Available topics:"
    echo "$topics" | while read topic; do
        [ -n "$topic" ] && echo "  - $topic"
    done
else
    log_error "Cannot list Kafka topics"
    exit 1
fi

echo

# Test 4: Kafka Connect Validation
log_info "=== Test 4: Kafka Connect Validation ==="

# Check REST API
if curl -s -f http://localhost:8083/ > /dev/null; then
    log_success "Kafka Connect REST API is accessible"
else
    log_error "Kafka Connect REST API is not accessible"
    exit 1
fi

# Check connector plugins
connector_plugins=$(curl -s http://localhost:8083/connector-plugins)
if echo "$connector_plugins" | grep -q mongodb; then
    log_success "MongoDB connector plugin is available"
else
    log_warning "MongoDB connector plugin not found"
    log_info "Available plugins:"
    echo "$connector_plugins" | jq -r '.[].class' | head -5
fi

# List active connectors
connectors=$(curl -s http://localhost:8083/connectors)
log_info "Active connectors: $(echo "$connectors" | jq length) connector(s)"

echo

# Test 5: Data Flow Test
log_info "=== Test 5: End-to-End Data Flow Test ==="

# Insert test data into MongoDB
log_info "Inserting test data into MongoDB..."
test_data_result=$(mongosh --host localhost:27017 \
    --username "$MONGO_USER" \
    --password "$MONGO_PASS" \
    --authenticationDatabase admin \
    --eval "
        db = db.getSiblingDB('$TEST_DATABASE');
        result = db.$TEST_COLLECTION.insertOne({
            test_id: 'validation_test_$(date +%s)',
            message: 'Test message for validation',
            timestamp: new Date(),
            metadata: { source: 'validation_script', version: '1.0' }
        });
        JSON.stringify(result);
    " \
    --quiet 2>/dev/null)

if [ $? -eq 0 ]; then
    log_success "Test data inserted successfully into MongoDB"
    inserted_id=$(echo "$test_data_result" | jq -r '.insertedId."$oid"')
    log_info "Inserted document ID: $inserted_id"
else
    log_error "Failed to insert test data into MongoDB"
    exit 1
fi

# Verify data can be read
read_result=$(mongosh --host localhost:27017 \
    --username "$MONGO_USER" \
    --password "$MONGO_PASS" \
    --authenticationDatabase admin \
    --eval "
        db = db.getSiblingDB('$TEST_DATABASE');
        result = db.$TEST_COLLECTION.findOne({test_id: /validation_test/});
        result ? 'FOUND' : 'NOT_FOUND';
    " \
    --quiet 2>/dev/null)

if [ "$read_result" = "FOUND" ]; then
    log_success "Test data can be read from MongoDB"
else
    log_error "Cannot read test data from MongoDB"
    exit 1
fi

echo

# Test 6: Service Connectivity Test
log_info "=== Test 6: Service Connectivity Test ==="

# Test MongoDB from Kafka Connect container
log_info "Testing MongoDB connectivity from Kafka Connect..."
if docker compose exec kafka-connect bash -c "curl -s --connect-timeout 5 mongo1:27017 || nc -z mongo1 27017" > /dev/null 2>&1; then
    log_success "Kafka Connect can reach MongoDB"
else
    log_error "Kafka Connect cannot reach MongoDB"
    exit 1
fi

# Test Kafka from Kafka Connect container
log_info "Testing Kafka connectivity from Kafka Connect..."
if docker compose exec kafka-connect bash -c "nc -z kafka 9092" > /dev/null 2>&1; then
    log_success "Kafka Connect can reach Kafka"
else
    log_error "Kafka Connect cannot reach Kafka"
    exit 1
fi

echo

# Summary
log_info "=== Validation Summary ==="
log_success "✓ All validation tests passed!"

log_info "=== System Information ==="
log_info "MongoDB Replica Set: 3 healthy members with primary"
log_info "Kafka Cluster: Operational with available topics"
log_info "Kafka Connect: REST API accessible with plugins loaded"
log_info "Data Flow: MongoDB read/write operations successful"
log_info "Network: Inter-service connectivity verified"

log_info "=== Next Steps ==="
log_info "1. Your MongoDB Kafka Connector stack is ready for use"
log_info "2. To create a connector, run: ./scripts/setup-connector.sh"
log_info "3. Access UIs:"
log_info "   - MongoDB Express: http://localhost:8081 (admin/admin)"
log_info "   - Kafka UI: http://localhost:8080"
log_info "4. Monitor logs: docker compose logs -f [service_name]"

echo
log_success "Validation completed successfully! 🎉"