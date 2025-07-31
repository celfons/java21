#!/bin/bash
# Mock Test Suite for MongoDB Atlas Kafka Connect
# Tests connector configuration and setup without requiring actual Atlas/Kafka instances

# Note: Don't use 'set -e' here as we expect some commands to fail during testing

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

echo -e "${GREEN}=== Mock Test Suite - MongoDB Atlas Kafka Connect ===${NC}"
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

# Test 1: Validate Docker Compose file structure
test_docker_compose_structure() {
    echo -e "${BLUE}Testing Docker Compose structure...${NC}"
    
    if [ ! -f "docker-compose.yml" ]; then
        log_test "Docker Compose File" "FAIL" "docker-compose.yml not found"
        return
    fi
    
    # Check if file contains only kafka-connect service
    if grep -q "kafka-connect:" docker-compose.yml; then
        log_test "Kafka Connect Service" "PASS" "kafka-connect service found in docker-compose.yml"
    else
        log_test "Kafka Connect Service" "FAIL" "kafka-connect service not found"
        return
    fi
    
    # Check that local MongoDB and Kafka services are removed
    if ! grep -q "mongo1:" docker-compose.yml && ! grep -q "kafka:" docker-compose.yml && ! grep -q "zookeeper:" docker-compose.yml; then
        log_test "Local Services Removal" "PASS" "Local MongoDB and Kafka services properly removed"
    else
        log_test "Local Services Removal" "FAIL" "Local MongoDB/Kafka services still present"
    fi
    
    # Check for required environment variables in docker-compose
    if grep -q "MONGODB_ATLAS_CONNECTION_STRING" docker-compose.yml && grep -q "KAFKA_BOOTSTRAP_SERVERS" docker-compose.yml; then
        log_test "Environment Variables" "PASS" "Required environment variables referenced in docker-compose.yml"
    else
        log_test "Environment Variables" "FAIL" "Required environment variables not found in docker-compose.yml"
    fi
}

# Test 2: Validate connector configurations
test_connector_configurations() {
    echo -e "${BLUE}Testing connector configurations...${NC}"
    
    local config_files=(
        "config/kafka-connect/mongodb-source-connector.json"
        "connectors/mongo-insert-connector.json"
        "connectors/mongo-update-connector.json"
        "connectors/mongo-delete-connector.json"
    )
    
    for config_file in "${config_files[@]}"; do
        if [ ! -f "$config_file" ]; then
            log_test "Config File Exists: $(basename "$config_file")" "FAIL" "File not found: $config_file"
            continue
        fi
        
        # Validate JSON syntax
        if jq . "$config_file" > /dev/null 2>&1; then
            log_test "JSON Syntax: $(basename "$config_file")" "PASS" "Valid JSON syntax"
        else
            log_test "JSON Syntax: $(basename "$config_file")" "FAIL" "Invalid JSON syntax"
            continue
        fi
        
        # Check for environment variable placeholders
        if grep -q '\${MONGODB_ATLAS_CONNECTION_STRING}' "$config_file" && grep -q '\${MONGODB_DATABASE}' "$config_file"; then
            log_test "Environment Variables: $(basename "$config_file")" "PASS" "Uses environment variable placeholders"
        else
            log_test "Environment Variables: $(basename "$config_file")" "FAIL" "Missing environment variable placeholders"
        fi
        
        # Check for MongoDB connector class
        if grep -q "com.mongodb.kafka.connect.MongoSourceConnector" "$config_file"; then
            log_test "Connector Class: $(basename "$config_file")" "PASS" "Uses correct MongoDB connector class"
        else
            log_test "Connector Class: $(basename "$config_file")" "FAIL" "Missing or incorrect connector class"
        fi
    done
}

# Test 3: Validate environment configuration
test_environment_configuration() {
    echo -e "${BLUE}Testing environment configuration...${NC}"
    
    if [ ! -f ".env.example" ]; then
        log_test "Environment Example" "FAIL" ".env.example file not found"
        return
    fi
    
    # Check for required variables in .env.example
    local required_vars=(
        "MONGODB_ATLAS_CONNECTION_STRING"
        "KAFKA_BOOTSTRAP_SERVERS"
        "MONGODB_DATABASE"
    )
    
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" .env.example; then
            log_test "Env Variable: $var" "PASS" "Found in .env.example"
        else
            log_test "Env Variable: $var" "FAIL" "Missing from .env.example"
        fi
    done
    
    # Check that old local variables are removed
    local old_vars=(
        "MONGO_INITDB_ROOT_USERNAME"
        "KAFKA_BROKER_ID"
        "ZOOKEEPER_CLIENT_PORT"
    )
    
    local old_vars_removed=true
    for var in "${old_vars[@]}"; do
        if grep -q "^$var=" .env.example; then
            old_vars_removed=false
            break
        fi
    done
    
    if [ "$old_vars_removed" = true ]; then
        log_test "Old Variables Cleanup" "PASS" "Old local setup variables removed from .env.example"
    else
        log_test "Old Variables Cleanup" "FAIL" "Old local setup variables still present in .env.example"
    fi
}

# Test 4: Validate setup scripts
test_setup_scripts() {
    echo -e "${BLUE}Testing setup scripts...${NC}"
    
    local scripts=(
        "scripts/setup-connector.sh"
        "scripts/setup-multi-connectors.sh"
        "scripts/health-check-atlas.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ ! -f "$script" ]; then
            log_test "Script Exists: $(basename "$script")" "FAIL" "Script not found: $script"
            continue
        fi
        
        if [ -x "$script" ]; then
            log_test "Script Executable: $(basename "$script")" "PASS" "Script is executable"
        else
            log_test "Script Executable: $(basename "$script")" "FAIL" "Script is not executable"
        fi
        
        # Check for environment variable validation in scripts
        if grep -q "MONGODB_ATLAS_CONNECTION_STRING" "$script" && grep -q "KAFKA_BOOTSTRAP_SERVERS" "$script"; then
            log_test "Script Env Check: $(basename "$script")" "PASS" "Script validates required environment variables"
        else
            log_test "Script Env Check: $(basename "$script")" "FAIL" "Script missing environment variable validation"
        fi
    done
}

# Test 5: Validate file cleanup (removed local setup files)
test_file_cleanup() {
    echo -e "${BLUE}Testing file cleanup...${NC}"
    
    # Files that should be removed or made obsolete
    local obsolete_files=(
        "scripts/init-replica.sh"
        "config/mongodb/replica-init.js"
        "scripts/sample-data.js"
    )
    
    local cleanup_good=true
    for file in "${obsolete_files[@]}"; do
        if [ -f "$file" ]; then
            log_test "File Cleanup: $(basename "$file")" "FAIL" "Obsolete file still present: $file"
            cleanup_good=false
        fi
    done
    
    if [ "$cleanup_good" = true ]; then
        log_test "Overall File Cleanup" "PASS" "Obsolete local setup files properly removed"
    fi
}

# Test 6: Validate Dockerfile for external connectivity
test_dockerfile() {
    echo -e "${BLUE}Testing Dockerfile...${NC}"
    
    if [ ! -f "Dockerfile" ]; then
        log_test "Dockerfile Exists" "FAIL" "Dockerfile not found"
        return
    fi
    
    # Check if Dockerfile installs MongoDB connector
    if grep -q "mongodb/kafka-connect-mongodb" Dockerfile; then
        log_test "MongoDB Connector Plugin" "PASS" "Dockerfile installs MongoDB connector plugin"
    else
        log_test "MongoDB Connector Plugin" "FAIL" "Dockerfile missing MongoDB connector plugin installation"
    fi
    
    # Check base image
    if grep -q "confluentinc/cp-kafka-connect" Dockerfile; then
        log_test "Base Image" "PASS" "Uses correct Kafka Connect base image"
    else
        log_test "Base Image" "FAIL" "Missing or incorrect base image"
    fi
}

# Test 7: Mock connector setup test
test_mock_connector_setup() {
    echo -e "${BLUE}Testing mock connector setup...${NC}"
    
    # Create temporary environment file for testing
    local temp_env="/tmp/test.env"
    cat > "$temp_env" << EOF
MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://testuser:testpass@cluster.example.mongodb.net/testdb?retryWrites=true&w=majority
KAFKA_BOOTSTRAP_SERVERS=kafka1.example.com:9092,kafka2.example.com:9092
MONGODB_DATABASE=testdb
EOF
    
    # Source the environment
    export MONGODB_ATLAS_CONNECTION_STRING="mongodb+srv://testuser:testpass@cluster.example.mongodb.net/testdb?retryWrites=true&w=majority"
    export KAFKA_BOOTSTRAP_SERVERS="kafka1.example.com:9092,kafka2.example.com:9092"
    export MONGODB_DATABASE="testdb"
    
    # Test environment variable substitution
    if [ -f "config/kafka-connect/mongodb-source-connector.json" ]; then
        local temp_config="/tmp/test-connector.json"
        envsubst < "config/kafka-connect/mongodb-source-connector.json" > "$temp_config"
        
        if grep -q "mongodb+srv://testuser:testpass@cluster.example.mongodb.net/testdb" "$temp_config"; then
            log_test "Environment Substitution" "PASS" "Environment variables properly substituted in connector config"
        else
            log_test "Environment Substitution" "FAIL" "Environment variable substitution failed"
        fi
        
        # Validate substituted JSON
        if jq . "$temp_config" > /dev/null 2>&1; then
            log_test "Substituted JSON Validity" "PASS" "Substituted connector config is valid JSON"
        else
            log_test "Substituted JSON Validity" "FAIL" "Substituted connector config has invalid JSON"
        fi
        
        rm -f "$temp_config"
    else
        log_test "Connector Config Template" "FAIL" "Connector configuration template not found"
    fi
    
    rm -f "$temp_env"
}

# Run all tests
echo -e "${BLUE}Running all tests...${NC}"
echo

test_docker_compose_structure
echo

test_connector_configurations
echo

test_environment_configuration
echo

test_setup_scripts
echo

test_file_cleanup
echo

test_dockerfile
echo

test_mock_connector_setup
echo

# Print summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! MongoDB Atlas configuration is ready.${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Set up MongoDB Atlas cluster and get connection string"
    echo "  2. Set up external Kafka cluster and get bootstrap servers"
    echo "  3. Configure environment variables in .env file"
    echo "  4. Run: docker compose up -d"
    echo "  5. Run: ./scripts/setup-connector.sh"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please fix the issues above before proceeding.${NC}"
    exit 1
fi