#!/bin/bash
# MongoDB Replica Set Initialization Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MONGO_USER=${MONGO_INITDB_ROOT_USERNAME:-admin}
MONGO_PASS=${MONGO_INITDB_ROOT_PASSWORD:-password123}
REPLICA_SET=${MONGO_REPLICA_SET_NAME:-rs0}
MAX_ATTEMPTS=30
SLEEP_INTERVAL=5

echo -e "${GREEN}=== MongoDB Replica Set Initialization ===${NC}"

# Function to check if MongoDB is ready
check_mongo_ready() {
    local host=$1
    local port=$2
    
    mongosh --host "${host}:${port}" \
           --username "$MONGO_USER" \
           --password "$MONGO_PASS" \
           --authenticationDatabase admin \
           --eval "db.adminCommand('ping')" \
           --quiet > /dev/null 2>&1
}

# Wait for all MongoDB instances to be ready
echo -e "${YELLOW}Waiting for MongoDB instances to be ready...${NC}"

for host_port in "mongo1:27017" "mongo2:27017" "mongo3:27017"; do
    host=$(echo $host_port | cut -d: -f1)
    port=$(echo $host_port | cut -d: -f2)
    
    echo -n "Checking $host_port... "
    
    attempt=1
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        if check_mongo_ready "$host" "$port"; then
            echo -e "${GREEN}Ready${NC}"
            break
        fi
        
        if [ $attempt -eq $MAX_ATTEMPTS ]; then
            echo -e "${RED}Failed - Max attempts reached${NC}"
            exit 1
        fi
        
        sleep $SLEEP_INTERVAL
        ((attempt++))
    done
done

# Initialize replica set
echo -e "${YELLOW}Initializing replica set...${NC}"

mongosh --host mongo1:27017 \
       --username "$MONGO_USER" \
       --password "$MONGO_PASS" \
       --authenticationDatabase admin \
       --file /docker-entrypoint-initdb.d/replica-init.js

# Verify replica set status
echo -e "${YELLOW}Verifying replica set status...${NC}"

attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    if mongosh --host mongo1:27017 \
              --username "$MONGO_USER" \
              --password "$MONGO_PASS" \
              --authenticationDatabase admin \
              --eval "rs.status()" \
              --quiet > /dev/null 2>&1; then
        echo -e "${GREEN}Replica set is healthy${NC}"
        break
    fi
    
    if [ $attempt -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}Replica set verification failed${NC}"
        exit 1
    fi
    
    echo "Attempt $attempt/$MAX_ATTEMPTS - Waiting for replica set..."
    sleep $SLEEP_INTERVAL
    ((attempt++))
done

echo -e "${GREEN}✓ MongoDB replica set initialization completed successfully${NC}"