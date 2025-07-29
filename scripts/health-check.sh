#!/bin/bash
# Health Check Script for MongoDB Kafka Connector Example

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
# Configuration
MONGO_USER=${MONGO_INITDB_ROOT_USERNAME:-admin}
MONGO_PASS=${MONGO_INITDB_ROOT_PASSWORD:-password123}
HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-30}

SERVICES=(
    "mongo1:27017:MongoDB Primary"
    "mongo2:27017:MongoDB Secondary 1"
    "mongo3:27017:MongoDB Secondary 2"
    "zookeeper:2181:Zookeeper"
    "kafka:9092:Kafka Broker"
    "kafka-connect:8083:Kafka Connect"
    "kafka-ui:8080:Kafka UI"
    "mongo-express:8081:MongoDB Express"
)

echo -e "${GREEN}=== Health Check - MongoDB Kafka Connector Example ===${NC}"
echo "$(date)"
echo

# Function to check service health
check_service() {
    local service_info=$1
    local host_port=$(echo "$service_info" | cut -d: -f1-2)
    local service_name=$(echo "$service_info" | cut -d: -f3)
    local host=$(echo "$host_port" | cut -d: -f1)
    local port=$(echo "$host_port" | cut -d: -f2)
    
    echo -n "Checking $service_name ($host_port)... "
    
    case $port in
        27017)
            # MongoDB health check with authentication
            if timeout $HEALTH_CHECK_TIMEOUT mongosh --host "$host_port" \
                --username "$MONGO_USER" \
                --password "$MONGO_PASS" \
                --authenticationDatabase admin \
                --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Healthy${NC}"
                return 0
            else
                echo -e "${RED}✗ Unhealthy${NC}"
                return 1
            fi
            ;;
        2181)
            # Zookeeper health check
            if echo ruok | nc "$host" "$port" 2>/dev/null | grep -q imok; then
                echo -e "${GREEN}✓ Healthy${NC}"
                return 0
            else
                echo -e "${RED}✗ Unhealthy${NC}"
                return 1
            fi
            ;;
        9092)
            # Kafka health check
            if kafka-broker-api-versions --bootstrap-server "$host_port" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Healthy${NC}"
                return 0
            else
                echo -e "${RED}✗ Unhealthy${NC}"
                return 1
            fi
            ;;
        8083|8080|8081)
            # HTTP service health check
            if curl -s -f "http://$host_port" > /dev/null 2>&1 || curl -s -f "http://$host_port/health" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Healthy${NC}"
                return 0
            else
                echo -e "${RED}✗ Unhealthy${NC}"
                return 1
            fi
            ;;
        *)
            # Generic TCP port check
            if nc -z "$host" "$port" 2>/dev/null; then
                echo -e "${GREEN}✓ Healthy${NC}"
                return 0
            else
                echo -e "${RED}✗ Unhealthy${NC}"
                return 1
            fi
            ;;
    esac
}

# Function to check MongoDB replica set status
check_mongodb_replica_set() {
    echo -e "${BLUE}=== MongoDB Replica Set Status ===${NC}"
    
    if timeout $HEALTH_CHECK_TIMEOUT mongosh --host mongo1:27017 \
        --username "$MONGO_USER" \
        --password "$MONGO_PASS" \
        --authenticationDatabase admin \
        --eval "rs.status()" --quiet 2>/dev/null; then
        echo -e "${GREEN}✓ Replica set is operational${NC}"
    else
        echo -e "${RED}✗ Replica set check failed${NC}"
        return 1
    fi
    echo
}

# Function to check Kafka topics
check_kafka_topics() {
    echo -e "${BLUE}=== Kafka Topics ===${NC}"
    
    if kafka-topics --bootstrap-server kafka:9092 --list 2>/dev/null; then
        echo -e "${GREEN}✓ Kafka topics listed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to list Kafka topics${NC}"
        return 1
    fi
    echo
}

# Function to check Kafka Connect connectors
check_kafka_connectors() {
    echo -e "${BLUE}=== Kafka Connect Connectors ===${NC}"
    
    if curl -s -f http://kafka-connect:8083/connectors 2>/dev/null; then
        echo -e "${GREEN}✓ Kafka Connect API accessible${NC}"
        
        # List active connectors
        local connectors=$(curl -s http://kafka-connect:8083/connectors 2>/dev/null)
        if [ "$connectors" != "[]" ]; then
            echo "Active connectors:"
            echo "$connectors" | jq -r '.[]' | while read connector; do
                local status=$(curl -s "http://kafka-connect:8083/connectors/$connector/status" 2>/dev/null | jq -r '.connector.state')
                echo "  - $connector: $status"
            done
        else
            echo -e "${YELLOW}No connectors configured${NC}"
        fi
    else
        echo -e "${RED}✗ Kafka Connect API not accessible${NC}"
        return 1
    fi
    echo
}

# Function to check Docker containers
check_docker_containers() {
    echo -e "${BLUE}=== Docker Containers Status ===${NC}"
    
    if command -v docker > /dev/null 2>&1; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mongo|kafka|zookeeper)"
    else
        echo -e "${YELLOW}Docker command not available${NC}"
    fi
    echo
}

# Main health check
main() {
    local failed_services=0
    
    echo -e "${BLUE}=== Service Health Check ===${NC}"
    
    for service in "${SERVICES[@]}"; do
        if ! check_service "$service"; then
            ((failed_services++))
        fi
    done
    
    echo
    
    # Additional checks
    check_mongodb_replica_set || ((failed_services++))
    check_kafka_topics || true  # Don't fail on this as topics might not exist yet
    check_kafka_connectors || true  # Don't fail on this as connectors might not be set up yet
    check_docker_containers
    
    # Summary
    echo -e "${BLUE}=== Health Check Summary ===${NC}"
    
    if [ $failed_services -eq 0 ]; then
        echo -e "${GREEN}✓ All critical services are healthy${NC}"
        exit 0
    else
        echo -e "${RED}✗ $failed_services service(s) failed health check${NC}"
        exit 1
    fi
}

# Run health check
main