#!/bin/bash
# Health Check Script for Kafka Connect (Atlas Configuration)
# Updated for MongoDB Atlas and external Kafka setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-30}
KAFKA_CONNECT_URL=${KAFKA_CONNECT_URL:-http://localhost:8083}

echo -e "${GREEN}=== Health Check - Kafka Connect (Atlas Configuration) ===${NC}"
echo "$(date)"
echo

# Function to check Kafka Connect health
check_kafka_connect() {
    echo -n "Checking Kafka Connect (localhost:8083)... "
    
    if timeout $HEALTH_CHECK_TIMEOUT curl -s -f "$KAFKA_CONNECT_URL/" > /dev/null; then
        echo -e "${GREEN}✓ Healthy${NC}"
        
        # Check if MongoDB connector plugin is available
        echo -n "Checking MongoDB connector plugin... "
        if curl -s "$KAFKA_CONNECT_URL/connector-plugins" | grep -q mongodb; then
            echo -e "${GREEN}✓ Available${NC}"
        else
            echo -e "${YELLOW}⚠ Not found${NC}"
        fi
        
        # List available connectors
        echo -n "Checking active connectors... "
        CONNECTORS=$(curl -s "$KAFKA_CONNECT_URL/connectors" 2>/dev/null || echo "[]")
        CONNECTOR_COUNT=$(echo "$CONNECTORS" | jq length 2>/dev/null || echo "0")
        
        if [ "$CONNECTOR_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓ $CONNECTOR_COUNT active${NC}"
            echo -e "${BLUE}Active connectors:${NC}"
            echo "$CONNECTORS" | jq -r '.[]' | sed 's/^/  - /'
        else
            echo -e "${YELLOW}⚠ No active connectors${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}✗ Unhealthy${NC}"
        return 1
    fi
}

# Function to validate environment variables
check_environment_vars() {
    echo -e "${BLUE}=== Environment Variables Check ===${NC}"
    
    if [ -n "$MONGODB_ATLAS_CONNECTION_STRING" ]; then
        # Mask the connection string for security
        MASKED_CONNECTION=$(echo "$MONGODB_ATLAS_CONNECTION_STRING" | sed 's/\/\/[^@]*@/\/\/***:***@/')
        echo -e "MongoDB Atlas Connection: ${GREEN}✓ Set${NC} ($MASKED_CONNECTION)"
    else
        echo -e "MongoDB Atlas Connection: ${YELLOW}⚠ Not set${NC}"
    fi
    
    if [ -n "$KAFKA_BOOTSTRAP_SERVERS" ]; then
        echo -e "Kafka Bootstrap Servers: ${GREEN}✓ Set${NC} ($KAFKA_BOOTSTRAP_SERVERS)"
    else
        echo -e "Kafka Bootstrap Servers: ${YELLOW}⚠ Not set${NC}"
    fi
    
    if [ -n "$MONGODB_DATABASE" ]; then
        echo -e "MongoDB Database: ${GREEN}✓ Set${NC} ($MONGODB_DATABASE)"
    else
        echo -e "MongoDB Database: ${YELLOW}⚠ Not set${NC}"
    fi
    
    echo
}

# Function to check external connectivity (if possible)
check_external_connectivity() {
    echo -e "${BLUE}=== External Connectivity Check ===${NC}"
    
    # Test if we can resolve external hostnames (basic connectivity test)
    echo -n "Testing external DNS resolution... "
    if timeout 10 nslookup google.com > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Working${NC}"
        
        # If MongoDB Atlas connection string is set, try to parse and test basic connectivity
        if [ -n "$MONGODB_ATLAS_CONNECTION_STRING" ]; then
            echo -n "Testing MongoDB Atlas connectivity (DNS)... "
            # Extract hostname from connection string
            ATLAS_HOST=$(echo "$MONGODB_ATLAS_CONNECTION_STRING" | sed -n 's/.*@\([^/]*\).*/\1/p' | cut -d'?' -f1)
            if [ -n "$ATLAS_HOST" ] && timeout 10 nslookup "$ATLAS_HOST" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ DNS resolves${NC}"
            else
                echo -e "${YELLOW}⚠ DNS resolution failed or connection string format issue${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ DNS resolution failed${NC}"
    fi
    
    echo
}

# Main health check execution
echo -e "${BLUE}=== Service Health Check ===${NC}"

if check_kafka_connect; then
    echo -e "${GREEN}✓ Kafka Connect is healthy${NC}"
    KAFKA_CONNECT_HEALTHY=true
else
    echo -e "${RED}✗ Kafka Connect is unhealthy${NC}"
    KAFKA_CONNECT_HEALTHY=false
fi

echo

# Check environment variables
check_environment_vars

# Check external connectivity
check_external_connectivity

# Summary
echo -e "${BLUE}=== Health Check Summary ===${NC}"

if [ "$KAFKA_CONNECT_HEALTHY" = true ]; then
    echo -e "${GREEN}✓ Overall Status: HEALTHY${NC}"
    echo -e "${BLUE}Kafka Connect is running and ready to accept connector configurations${NC}"
    
    if [ -n "$MONGODB_ATLAS_CONNECTION_STRING" ] && [ -n "$KAFKA_BOOTSTRAP_SERVERS" ]; then
        echo -e "${GREEN}✓ Required environment variables are set${NC}"
        echo -e "${BLUE}Ready to setup MongoDB Atlas connectors${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Required environment variables not set${NC}"
        echo -e "${YELLOW}Please set MONGODB_ATLAS_CONNECTION_STRING and KAFKA_BOOTSTRAP_SERVERS${NC}"
    fi
else
    echo -e "${RED}✗ Overall Status: UNHEALTHY${NC}"
    echo -e "${RED}Kafka Connect is not responding${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Set required environment variables (if not already set)"
echo "  2. Run: ./scripts/setup-connector.sh"
echo "  3. Run: ./scripts/setup-multi-connectors.sh (for operation-specific connectors)"