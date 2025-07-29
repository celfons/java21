#!/bin/bash
# Kafka Connect MongoDB Source Connector Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONNECT_URL=${CONNECT_URL:-http://localhost:8083}
CONNECTOR_CONFIG=${CONNECTOR_CONFIG:-config/kafka-connect/mongodb-source-connector.json}
MAX_ATTEMPTS=30
SLEEP_INTERVAL=10

echo -e "${GREEN}=== Kafka Connect MongoDB Source Connector Setup ===${NC}"

# Function to check if Kafka Connect is ready
check_kafka_connect_ready() {
    curl -s -f "$CONNECT_URL/connectors" > /dev/null 2>&1
}

# Function to check if connector exists
check_connector_exists() {
    local connector_name=$1
    curl -s -f "$CONNECT_URL/connectors/$connector_name" > /dev/null 2>&1
}

# Function to get connector status
get_connector_status() {
    local connector_name=$1
    curl -s "$CONNECT_URL/connectors/$connector_name/status" 2>/dev/null | jq -r '.connector.state' 2>/dev/null || echo "UNKNOWN"
}

# Wait for Kafka Connect to be ready
echo -e "${YELLOW}Waiting for Kafka Connect to be ready...${NC}"

attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    if check_kafka_connect_ready; then
        echo -e "${GREEN}✓ Kafka Connect is ready${NC}"
        break
    fi
    
    if [ $attempt -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}✗ Kafka Connect failed to become ready${NC}"
        exit 1
    fi
    
    echo "Attempt $attempt/$MAX_ATTEMPTS - Waiting for Kafka Connect..."
    sleep $SLEEP_INTERVAL
    ((attempt++))
done

# Check available plugins
echo -e "${BLUE}Available Kafka Connect plugins:${NC}"
curl -s "$CONNECT_URL/connector-plugins" | jq -r '.[] | select(.class | contains("mongodb")) | .class'

# Read connector configuration
if [ ! -f "$CONNECTOR_CONFIG" ]; then
    echo -e "${RED}✗ Connector configuration file not found: $CONNECTOR_CONFIG${NC}"
    exit 1
fi

CONNECTOR_NAME=$(jq -r '.name' "$CONNECTOR_CONFIG")

# Check if connector already exists
if check_connector_exists "$CONNECTOR_NAME"; then
    echo -e "${YELLOW}Connector '$CONNECTOR_NAME' already exists${NC}"
    
    # Get current status
    STATUS=$(get_connector_status "$CONNECTOR_NAME")
    echo -e "${BLUE}Current status: $STATUS${NC}"
    
    # Ask if user wants to delete and recreate
    read -p "Do you want to delete and recreate the connector? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting existing connector...${NC}"
        curl -X DELETE "$CONNECT_URL/connectors/$CONNECTOR_NAME"
        echo -e "${GREEN}✓ Connector deleted${NC}"
        sleep 5
    else
        echo -e "${BLUE}Keeping existing connector${NC}"
        exit 0
    fi
fi

# Create connector
echo -e "${YELLOW}Creating MongoDB Source Connector...${NC}"

RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d @"$CONNECTOR_CONFIG" \
    "$CONNECT_URL/connectors")

if echo "$RESPONSE" | jq -e '.name' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connector created successfully${NC}"
    echo -e "${BLUE}Connector name: $(echo "$RESPONSE" | jq -r '.name')${NC}"
else
    echo -e "${RED}✗ Failed to create connector${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

# Wait for connector to be running
echo -e "${YELLOW}Waiting for connector to be running...${NC}"

attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    STATUS=$(get_connector_status "$CONNECTOR_NAME")
    
    case $STATUS in
        "RUNNING")
            echo -e "${GREEN}✓ Connector is running${NC}"
            break
            ;;
        "FAILED")
            echo -e "${RED}✗ Connector failed to start${NC}"
            curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME/status" | jq .
            exit 1
            ;;
        *)
            if [ $attempt -eq $MAX_ATTEMPTS ]; then
                echo -e "${RED}✗ Connector failed to reach running state${NC}"
                curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME/status" | jq .
                exit 1
            fi
            echo "Attempt $attempt/$MAX_ATTEMPTS - Status: $STATUS"
            sleep $SLEEP_INTERVAL
            ((attempt++))
            ;;
    esac
done

# Show connector details
echo -e "${BLUE}=== Connector Status ===${NC}"
curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME/status" | jq .

echo -e "${BLUE}=== Connector Configuration ===${NC}"
curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME/config" | jq .

echo -e "${GREEN}✓ MongoDB Source Connector setup completed successfully${NC}"
echo -e "${BLUE}Monitor connector: $CONNECT_URL/connectors/$CONNECTOR_NAME/status${NC}"