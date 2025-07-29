#!/bin/bash
# MongoDB Replica Set Initialization Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration with more generous defaults
MONGO_USER=${MONGO_INITDB_ROOT_USERNAME:-admin}
MONGO_PASS=${MONGO_INITDB_ROOT_PASSWORD:-password123}
REPLICA_SET=${MONGO_REPLICA_SET_NAME:-rs0}
MAX_ATTEMPTS=${MONGO_INIT_MAX_ATTEMPTS:-60}  # Increased from 30 to 60
SLEEP_INTERVAL=${MONGO_INIT_SLEEP_INTERVAL:-5}
CONTAINER_CHECK_TIMEOUT=${CONTAINER_CHECK_TIMEOUT:-300}  # 5 minutes for container readiness

# Logging function with timestamp
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

log_success "=== MongoDB Replica Set Initialization ==="

# Function to check Docker container health
check_container_health() {
    local container_name=$1
    local timeout=$2
    
    log_info "Checking Docker container health for $container_name..."
    
    local start_time=$(date +%s)
    local max_time=$((start_time + timeout))
    
    while [ $(date +%s) -lt $max_time ]; do
        if command -v docker >/dev/null 2>&1; then
            local container_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
            local container_running=$(docker inspect --format='{{.State.Running}}' "$container_name" 2>/dev/null || echo "false")
            
            log_info "Container $container_name - Running: $container_running, Health: $container_status"
            
            if [ "$container_running" = "true" ]; then
                if [ "$container_status" = "healthy" ]; then
                    log_success "Container $container_name is healthy"
                    return 0
                elif [ "$container_status" = "starting" ]; then
                    log_info "Container $container_name is still starting, waiting..."
                elif [ "$container_status" = "unknown" ] || [ "$container_status" = "" ]; then
                    log_warning "Container $container_name has no health check or status unknown"
                    # For containers without health checks, just check if they're running
                    return 0
                else
                    log_warning "Container $container_name health status: $container_status"
                fi
            else
                log_error "Container $container_name is not running"
                return 1
            fi
        else
            log_warning "Docker command not available, skipping container health check"
            return 0
        fi
        
        sleep 5
    done
    
    log_error "Timeout waiting for container $container_name to be healthy"
    return 1
}

# Function to check if MongoDB is ready
check_mongo_ready() {
    local host=$1
    local port=$2
    
    log_info "Testing MongoDB connection to ${host}:${port}..."
    
    # First, try a simple network connectivity test
    if command -v nc >/dev/null 2>&1; then
        if ! nc -z "$host" "$port" 2>/dev/null; then
            log_warning "Network connectivity test failed for ${host}:${port}"
            return 1
        fi
        log_info "Network connectivity OK for ${host}:${port}"
    fi
    
    # Then try MongoDB ping command with detailed error output
    local mongo_output
    if mongo_output=$(mongosh --host "${host}:${port}" \
           --username "$MONGO_USER" \
           --password "$MONGO_PASS" \
           --authenticationDatabase admin \
           --eval "db.adminCommand('ping')" \
           --quiet 2>&1); then
        log_success "MongoDB ping successful for ${host}:${port}"
        return 0
    else
        log_warning "MongoDB ping failed for ${host}:${port}. Output: $mongo_output"
        return 1
    fi
}

# Wait for Docker containers to be healthy first
log_info "Checking Docker container health before MongoDB initialization..."

for container in "mongo1" "mongo2" "mongo3"; do
    if ! check_container_health "$container" "$CONTAINER_CHECK_TIMEOUT"; then
        log_error "Container $container failed health check"
        exit 1
    fi
done

log_success "All MongoDB containers are healthy"

# Wait for all MongoDB instances to be ready
log_info "Waiting for MongoDB instances to be ready..."

for host_port in "mongo1:27017" "mongo2:27017" "mongo3:27017"; do
    host=$(echo $host_port | cut -d: -f1)
    port=$(echo $host_port | cut -d: -f2)
    
    log_info "Checking MongoDB readiness for $host_port..."
    
    attempt=1
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        log_info "Attempt $attempt/$MAX_ATTEMPTS for $host_port..."
        
        if check_mongo_ready "$host" "$port"; then
            log_success "$host_port is ready"
            break
        fi
        
        if [ $attempt -eq $MAX_ATTEMPTS ]; then
            log_error "Max attempts reached for $host_port"
            
            # Additional debugging information
            log_error "Debugging information for $host_port:"
            if command -v docker >/dev/null 2>&1; then
                log_info "Container logs for $host:"
                docker logs --tail=20 "$host" 2>&1 || log_error "Failed to get container logs"
                
                log_info "Container inspect for $host:"
                docker inspect "$host" 2>&1 || log_error "Failed to inspect container"
            fi
            
            exit 1
        fi
        
        log_info "Waiting ${SLEEP_INTERVAL}s before next attempt..."
        sleep $SLEEP_INTERVAL
        ((attempt++))
    done
done

# Initialize replica set
log_info "Initializing replica set $REPLICA_SET..."

replica_init_output=$(mongosh --host mongo1:27017 \
       --username "$MONGO_USER" \
       --password "$MONGO_PASS" \
       --authenticationDatabase admin \
       --file /docker-entrypoint-initdb.d/replica-init.js 2>&1)

if [ $? -eq 0 ]; then
    log_success "Replica set initialization script executed successfully"
    log_info "Initialization output: $replica_init_output"
else
    log_error "Replica set initialization failed"
    log_error "Error output: $replica_init_output"
    exit 1
fi

# Verify replica set status
log_info "Verifying replica set status..."

attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    log_info "Verification attempt $attempt/$MAX_ATTEMPTS..."
    
    replica_status_output=$(mongosh --host mongo1:27017 \
              --username "$MONGO_USER" \
              --password "$MONGO_PASS" \
              --authenticationDatabase admin \
              --eval "rs.status()" \
              --quiet 2>&1)
    
    if [ $? -eq 0 ]; then
        log_success "Replica set is healthy"
        log_info "Replica set status check passed"
        break
    fi
    
    if [ $attempt -eq $MAX_ATTEMPTS ]; then
        log_error "Replica set verification failed after $MAX_ATTEMPTS attempts"
        log_error "Last status output: $replica_status_output"
        
        # Try to get more debugging information
        log_info "Attempting to get detailed replica set configuration..."
        mongosh --host mongo1:27017 \
                --username "$MONGO_USER" \
                --password "$MONGO_PASS" \
                --authenticationDatabase admin \
                --eval "rs.conf()" \
                --quiet 2>&1 || log_error "Failed to get replica set configuration"
        
        exit 1
    fi
    
    log_info "Waiting ${SLEEP_INTERVAL}s before next verification attempt..."
    sleep $SLEEP_INTERVAL
    ((attempt++))
done

log_success "✓ MongoDB replica set initialization completed successfully"
log_info "Replica set '$REPLICA_SET' is ready with members: mongo1:27017, mongo2:27017, mongo3:27017"