#!/bin/bash
# Enhanced Integration Test Script for MongoDB Kafka Connector
# Tests the complete pipeline with local infrastructure to simulate Atlas/external Kafka setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0
CLEANUP_ON_EXIT=true
DOCKER_COMPOSE_FILE="docker-compose.integration.yml"
ENV_FILE=".env.integration"

echo -e "${GREEN}=== Enhanced Integration Test Suite - MongoDB Kafka Connector ===${NC}"
echo "$(date)"
echo

# Function to log test results
log_test() {
    local test_name=$1
    local result=$2
    local message=$3
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS:${NC} $test_name - $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL:${NC} $test_name - $message"
        ((TESTS_FAILED++))
    fi
    
    TEST_RESULTS+=("$result: $test_name - $message")
}

# Function to cleanup
cleanup() {
    if [ "$CLEANUP_ON_EXIT" = true ]; then
        echo -e "${YELLOW}Cleaning up test environment...${NC}"
        docker compose -f "$DOCKER_COMPOSE_FILE" down -v 2>/dev/null || true
        rm -f "$DOCKER_COMPOSE_FILE" "$ENV_FILE" /tmp/integration-*.json /tmp/*-connector.json 2>/dev/null || true
    fi
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Function to create test infrastructure docker-compose
create_test_infrastructure() {
    echo -e "${BLUE}Creating test infrastructure configuration...${NC}"
    
    cat > "$DOCKER_COMPOSE_FILE" << 'EOF'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    hostname: zookeeper
    container_name: zookeeper-integration-test
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    healthcheck:
      test: ["CMD", "bash", "-c", "echo 'ruok' | nc localhost 2181"]
      interval: 10s
      timeout: 5s
      retries: 5

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka
    container_name: kafka-integration-test
    depends_on:
      zookeeper:
        condition: service_healthy
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_METRIC_REPORTERS: io.confluent.metrics.reporter.ConfluentMetricsReporter
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_CONFLUENT_METRICS_REPORTER_BOOTSTRAP_SERVERS: kafka:29092
      KAFKA_CONFLUENT_METRICS_REPORTER_TOPIC_REPLICAS: 1
      KAFKA_CONFLUENT_METRICS_ENABLE: 'true'
      KAFKA_CONFLUENT_SUPPORT_CUSTOMER_ID: anonymous
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
    healthcheck:
      test: ["CMD", "bash", "-c", "kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1"]
      interval: 15s
      timeout: 10s
      retries: 10
    ports:
      - "9092:9092"

  mongo1:
    image: mongo:7.0
    hostname: mongo1
    container_name: mongo1-integration-test
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password123
    command: >
      bash -c "
        mongod --replSet rs0 --bind_ip_all --port 27017 &
        MONGOD_PID=$$!
        sleep 10
        mongosh --host localhost:27017 --username admin --password password123 --authenticationDatabase admin --eval '
          try {
            rs.initiate({
              _id: \"rs0\",
              members: [
                { _id: 0, host: \"mongo1:27017\" }
              ]
            });
            print(\"Replica set initiated successfully\");
          } catch (e) {
            print(\"Replica set already initiated or error:\", e);
          }
        '
        wait $$MONGOD_PID
      "
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')", "--quiet"]
      interval: 10s
      timeout: 5s
      retries: 10
    ports:
      - "27017:27017"

  kafka-connect:
    build:
      context: .
      dockerfile: Dockerfile
    hostname: kafka-connect
    container_name: kafka-connect-integration-test
    depends_on:
      kafka:
        condition: service_healthy
      mongo1:
        condition: service_healthy
    environment:
      CONNECT_BOOTSTRAP_SERVERS: 'kafka:29092'
      CONNECT_REST_ADVERTISED_HOST_NAME: kafka-connect
      CONNECT_REST_PORT: 8083
      CONNECT_GROUP_ID: compose-connect-group
      CONNECT_CONFIG_STORAGE_TOPIC: docker-connect-configs
      CONNECT_OFFSET_STORAGE_TOPIC: docker-connect-offsets
      CONNECT_STATUS_STORAGE_TOPIC: docker-connect-status
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_KEY_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_VALUE_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE: "false"
      CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE: "false"
      CONNECT_INTERNAL_KEY_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_INTERNAL_VALUE_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_INTERNAL_KEY_CONVERTER_SCHEMAS_ENABLE: "false"
      CONNECT_INTERNAL_VALUE_CONVERTER_SCHEMAS_ENABLE: "false"
      CONNECT_PLUGIN_PATH: "/usr/share/java,/usr/share/confluent-hub-components"
      CONNECT_LOG4J_ROOT_LOGLEVEL: INFO
      CONNECT_LOG4J_LOGGERS: "org.apache.kafka.connect.runtime.rest=WARN,org.reflections=ERROR"
    healthcheck:
      test: ["CMD", "bash", "-c", "curl -f http://localhost:8083/ >/dev/null 2>&1 && (curl -f http://localhost:8083/connector-plugins | grep -q mongodb || true)"]
      interval: 30s
      timeout: 15s
      retries: 10
      start_period: 180s
    ports:
      - "8083:8083"
EOF

    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        log_test "Infrastructure Config" "PASS" "Docker Compose configuration created"
    else
        log_test "Infrastructure Config" "FAIL" "Failed to create Docker Compose configuration"
        return 1
    fi
}

# Function to create test environment
create_test_environment() {
    echo -e "${BLUE}Creating integration test environment...${NC}"
    
    cat > "$ENV_FILE" << EOF
COMPOSE_PROJECT_NAME=mongodb-kafka-integration-test
MONGO_REPLICA_SET_NAME=rs0
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123
MONGODB_DATABASE=testdb

# Integration test connection strings (pointing to local containers)
MONGODB_ATLAS_CONNECTION_STRING=mongodb://admin:password123@localhost:27017/testdb?authSource=admin&replicaSet=rs0
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Kafka Connect Configuration for testing
CONNECT_GROUP_ID=compose-connect-group
CONNECT_CONFIG_STORAGE_TOPIC=docker-connect-configs
CONNECT_OFFSET_STORAGE_TOPIC=docker-connect-offsets
CONNECT_STATUS_STORAGE_TOPIC=docker-connect-status
CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=1
CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=1
CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=1
CONNECT_KEY_CONVERTER=org.apache.kafka.connect.json.JsonConverter
CONNECT_VALUE_CONVERTER=org.apache.kafka.connect.json.JsonConverter
CONNECT_LOG_LEVEL=INFO

# Health Check Configuration
HEALTH_CHECK_INTERVAL=30s
HEALTH_CHECK_TIMEOUT=15s
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_START_PERIOD=180s
EOF

    if [ -f "$ENV_FILE" ]; then
        log_test "Environment Config" "PASS" "Integration test environment file created"
        export $(cat "$ENV_FILE" | xargs)
    else
        log_test "Environment Config" "FAIL" "Failed to create environment file"
        return 1
    fi
}

# Function to start infrastructure
start_infrastructure() {
    echo -e "${BLUE}Starting integration test infrastructure...${NC}"
    
    # Start services
    if docker compose -f "$DOCKER_COMPOSE_FILE" up -d; then
        log_test "Infrastructure Start" "PASS" "All services started"
    else
        log_test "Infrastructure Start" "FAIL" "Failed to start services"
        return 1
    fi
    
    # Wait for services to be healthy
    echo "Waiting for services to be healthy..."
    local timeout=600
    local elapsed=0
    local interval=20
    
    while [ $elapsed -lt $timeout ]; do
        kafka_status=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps kafka --format "table {{.Status}}" | tail -n +2 2>/dev/null || echo "not_found")
        mongo_status=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps mongo1 --format "table {{.Status}}" | tail -n +2 2>/dev/null || echo "not_found")
        connect_status=$(docker compose -f "$DOCKER_COMPOSE_FILE" ps kafka-connect --format "table {{.Status}}" | tail -n +2 2>/dev/null || echo "not_found")
        
        echo "Services status: Kafka: $kafka_status | MongoDB: $mongo_status | Connect: $connect_status"
        
        if echo "$kafka_status" | grep -q "healthy" && echo "$mongo_status" | grep -q "healthy" && echo "$connect_status" | grep -q "healthy"; then
            log_test "Infrastructure Health" "PASS" "All services are healthy"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_test "Infrastructure Health" "FAIL" "Services failed to become healthy within timeout"
    return 1
}

# Function to test basic connectivity
test_basic_connectivity() {
    echo -e "${BLUE}Testing basic service connectivity...${NC}"
    
    # Test Kafka Connect REST API
    if curl -s -f http://localhost:8083/ > /dev/null; then
        log_test "Kafka Connect API" "PASS" "REST API responding"
    else
        log_test "Kafka Connect API" "FAIL" "REST API not responding"
        return 1
    fi
    
    # Test MongoDB connector plugin
    if curl -s http://localhost:8083/connector-plugins | grep -q mongodb; then
        log_test "MongoDB Plugin" "PASS" "MongoDB connector plugin available"
    else
        log_test "MongoDB Plugin" "FAIL" "MongoDB connector plugin not found"
    fi
    
    # Test MongoDB connectivity
    if docker exec mongo1-integration-test mongosh --username admin --password password123 --authenticationDatabase admin --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
        log_test "MongoDB Connectivity" "PASS" "MongoDB accessible"
    else
        log_test "MongoDB Connectivity" "FAIL" "MongoDB not accessible"
        return 1
    fi
    
    # Test Kafka
    if docker exec kafka-integration-test kafka-topics --bootstrap-server localhost:9092 --list > /dev/null 2>&1; then
        log_test "Kafka Connectivity" "PASS" "Kafka accessible"
    else
        log_test "Kafka Connectivity" "FAIL" "Kafka not accessible"
        return 1
    fi
}

# Function to test connector deployment
test_connector_deployment() {
    echo -e "${BLUE}Testing connector deployment...${NC}"
    
    # Create a test connector configuration
    cat > /tmp/integration-test-connector.json << 'EOF'
{
  "name": "mongo-source-integration-test",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb://admin:password123@mongo1:27017/testdb?authSource=admin&replicaSet=rs0",
    "database": "testdb",
    "collection": "integration_test",
    "poll.max.batch.size": 1000,
    "poll.await.time.ms": 5000,
    "pipeline": "[{\"$match\": {\"operationType\": \"insert\"}}]",
    "startup.mode": "latest",
    "publish.full.document.only": true,
    "copy.existing": false,
    "topic.prefix": "mongo.testdb",
    "output.format.value": "json",
    "output.format.key": "json",
    "output.json.formatter": "com.mongodb.kafka.connect.source.json.formatter.SimplifiedJson"
  }
}
EOF
    
    # Deploy the connector
    if curl -X POST -H "Content-Type: application/json" -d @/tmp/integration-test-connector.json http://localhost:8083/connectors > /dev/null 2>&1; then
        log_test "Connector Deployment" "PASS" "Connector deployed successfully"
    else
        log_test "Connector Deployment" "FAIL" "Failed to deploy connector"
        return 1
    fi
    
    # Wait for connector to be running
    local timeout=180
    local elapsed=0
    local interval=10
    
    while [ $elapsed -lt $timeout ]; do
        status=$(curl -s http://localhost:8083/connectors/mongo-source-integration-test/status | jq -r ".connector.state" 2>/dev/null || echo "UNKNOWN")
        
        case $status in
            "RUNNING")
                log_test "Connector Status" "PASS" "Connector is running"
                return 0
                ;;
            "FAILED")
                log_test "Connector Status" "FAIL" "Connector failed to start"
                curl -s http://localhost:8083/connectors/mongo-source-integration-test/status | jq . 2>/dev/null || true
                return 1
                ;;
        esac
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_test "Connector Status" "FAIL" "Connector failed to reach running state within timeout"
    return 1
}

# Function to test data flow
test_data_flow() {
    echo -e "${BLUE}Testing end-to-end data flow...${NC}"
    
    # Insert test data into MongoDB
    if docker exec mongo1-integration-test mongosh --username admin --password password123 --authenticationDatabase admin --eval "
      use testdb;
      db.integration_test.insertMany([
        {name: 'Integration Test User 1', email: 'test1@example.com', timestamp: new Date(), testId: 'integration-001'},
        {name: 'Integration Test User 2', email: 'test2@example.com', timestamp: new Date(), testId: 'integration-002'},
        {name: 'Integration Test User 3', email: 'test3@example.com', timestamp: new Date(), testId: 'integration-003'}
      ]);
      print('Test data inserted successfully');
    " > /dev/null 2>&1; then
        log_test "Data Insertion" "PASS" "Test data inserted into MongoDB"
    else
        log_test "Data Insertion" "FAIL" "Failed to insert test data"
        return 1
    fi
    
    # Wait for data to be processed
    sleep 15
    
    # Check if Kafka topic was created
    if docker exec kafka-integration-test kafka-topics --bootstrap-server localhost:9092 --list | grep -q "mongo.testdb"; then
        log_test "Topic Creation" "PASS" "MongoDB topic created in Kafka"
        
        # Try to consume messages
        timeout 30 docker exec kafka-integration-test kafka-console-consumer --bootstrap-server localhost:9092 --topic mongo.testdb.integration_test --from-beginning --timeout-ms 20000 > /tmp/kafka_messages.txt 2>/dev/null || true
        
        if [ -s /tmp/kafka_messages.txt ]; then
            log_test "Message Flow" "PASS" "Messages found in Kafka topic"
        else
            log_test "Message Flow" "FAIL" "No messages found in Kafka topic"
        fi
    else
        log_test "Topic Creation" "FAIL" "MongoDB topic not created in Kafka"
    fi
}

# Function to test environment variable configuration
test_environment_variables() {
    echo -e "${BLUE}Testing environment variable configuration...${NC}"
    
    # Test main connector config substitution
    if envsubst < config/kafka-connect/mongodb-source-connector.json > /tmp/integration-main-connector.json 2>/dev/null; then
        if jq . /tmp/integration-main-connector.json > /dev/null 2>&1; then
            log_test "Main Config Substitution" "PASS" "Environment variables substituted correctly"
        else
            log_test "Main Config Substitution" "FAIL" "Invalid JSON after substitution"
        fi
    else
        log_test "Main Config Substitution" "FAIL" "Failed to substitute environment variables"
    fi
    
    # Test multi-connector configs
    local configs_ok=true
    for connector in connectors/*.json; do
        if envsubst < "$connector" > "/tmp/integration-$(basename "$connector")" 2>/dev/null; then
            if ! jq . "/tmp/integration-$(basename "$connector")" > /dev/null 2>&1; then
                configs_ok=false
                break
            fi
        else
            configs_ok=false
            break
        fi
    done
    
    if [ "$configs_ok" = true ]; then
        log_test "Multi-Connector Substitution" "PASS" "All connector configs processed correctly"
    else
        log_test "Multi-Connector Substitution" "FAIL" "Failed to process some connector configs"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-cleanup)
            CLEANUP_ON_EXIT=false
            shift
            ;;
        --help)
            echo "Usage: $0 [--no-cleanup] [--help]"
            echo "  --no-cleanup  Do not cleanup Docker containers after test"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Run all tests
echo -e "${BLUE}Running enhanced integration tests...${NC}"
echo

# Configuration phase
create_test_infrastructure
echo

create_test_environment
echo

# Infrastructure phase
start_infrastructure
echo

# Testing phase
test_basic_connectivity
echo

test_connector_deployment
echo

test_data_flow
echo

test_environment_variables
echo

# Print summary
echo -e "${BLUE}=== Enhanced Integration Test Summary ===${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All enhanced integration tests passed!${NC}"
    echo -e "${BLUE}MongoDB Kafka Connector pipeline is fully validated${NC}"
    echo
    echo -e "${BLUE}Validated capabilities:${NC}"
    echo "  ✓ MongoDB to Kafka data pipeline"
    echo "  ✓ Connector deployment and management"
    echo "  ✓ Environment variable configuration"
    echo "  ✓ Real-time data change capture"
    echo "  ✓ Kafka topic creation and message flow"
    echo
    if [ "$CLEANUP_ON_EXIT" = false ]; then
        echo -e "${YELLOW}Environment preserved for inspection:${NC}"
        echo "  - Kafka Connect: http://localhost:8083"
        echo "  - MongoDB: localhost:27017"
        echo "  - Kafka: localhost:9092"
        echo "  Run 'docker compose -f $DOCKER_COMPOSE_FILE down -v' to cleanup"
    fi
    exit 0
else
    echo -e "${RED}✗ Some enhanced integration tests failed.${NC}"
    echo -e "${RED}Please review the failed tests above.${NC}"
    exit 1
fi