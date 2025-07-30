# Container Health and Startup Improvements

This document describes the improvements made to fix container restart loops and ensure all services reach healthy status.

## Issues Fixed

### 1. MongoDB Health Check Issues
- **Problem**: Health checks were failing because they didn't include authentication parameters
- **Solution**: Updated health checks to use proper MongoDB authentication
- **Changes**: Modified `docker-compose.yml` health check commands for all MongoDB containers

### 2. Replica Set Initialization Timing
- **Problem**: Replica set initialization was unreliable due to timing issues
- **Solution**: Added dedicated `mongo-init` service to ensure proper sequencing
- **Changes**: 
  - Added `mongo-init` service with proper dependencies
  - Enhanced `replica-init.js` with better error handling and status checking
  - Increased timeouts and retry counts

### 3. Kafka Connect Health Checks
- **Problem**: Health checks only verified REST API availability, not connector functionality
- **Solution**: Enhanced health checks to verify MongoDB connector plugin availability
- **Changes**: 
  - Updated Dockerfile with better connector installation and health checks
  - Added enhanced startup script with better logging
  - Increased start period and retry counts for Kafka Connect

### 4. Dependency Sequencing
- **Problem**: Services were starting without proper dependency order
- **Solution**: Improved dependency chain and added initialization service
- **Changes**:
  - Kafka Connect now depends on `mongo-init` completion
  - UI services depend on their respective backend services being healthy

### 5. Logging and Debugging
- **Problem**: Limited visibility into startup issues
- **Solution**: Added comprehensive logging and debugging capabilities
- **Changes**:
  - Created `start-stack.sh` for staged startup with detailed logging
  - Created `validate-setup.sh` for comprehensive system validation
  - Enhanced health check scripts with better error reporting

## New Scripts

### `scripts/start-stack.sh`
Enhanced startup script that:
- Starts services in proper order (MongoDB → Kafka → Kafka Connect → UIs)
- Provides detailed logging and status updates
- Waits for each service to be healthy before proceeding
- Includes error handling and cleanup

### `scripts/validate-setup.sh`
Comprehensive validation script that:
- Tests all service health status
- Validates MongoDB replica set configuration
- Verifies Kafka cluster functionality
- Tests Kafka Connect plugin availability
- Performs end-to-end data flow test
- Checks inter-service connectivity

## Configuration Improvements

### Health Check Timeouts
Updated to more generous values:
- `HEALTH_CHECK_TIMEOUT`: 10s → 15s
- `HEALTH_CHECK_RETRIES`: 3 → 5
- Start periods increased for complex services

### MongoDB Authentication
All MongoDB health checks now include:
- Username and password from environment variables
- Proper authentication database specification
- Quiet mode to reduce log noise

### Kafka Connect Improvements
- Enhanced health check to verify MongoDB connector plugin
- Increased start period from 120s to 180s
- Added 10 retries instead of 3
- Better error handling in Dockerfile

## Usage

### Quick Start
```bash
# Start the entire stack with enhanced logging
./scripts/start-stack.sh

# Validate the setup
./scripts/validate-setup.sh
```

### Manual Start
```bash
# Standard docker compose start (with improvements)
docker compose up -d

# Check service health
docker compose ps
```

### Debugging
```bash
# View service logs
docker compose logs -f [service_name]

# Check individual service health
docker compose ps [service_name]

# Run health check script
./scripts/health-check.sh
```

## Expected Startup Sequence

1. **MongoDB containers** (mongo1, mongo2, mongo3) start and become healthy
2. **mongo-init** runs to initialize replica set and completes
3. **Zookeeper** starts and becomes healthy  
4. **Kafka** starts and becomes healthy
5. **Kafka Connect** starts, loads plugins, and becomes healthy
6. **UI services** (kafka-ui, mongo-express) start

Total expected startup time: 5-10 minutes depending on system resources.

## Monitoring

All services include proper health checks that can be monitored with:
```bash
# Overall status
docker compose ps

# Detailed health status
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"

# Service logs
docker compose logs -f
```

## Troubleshooting

### If containers keep restarting:
1. Check logs: `docker compose logs [service_name]`
2. Verify health checks: `docker compose ps`
3. Run validation script: `./scripts/validate-setup.sh`
4. Check resource availability (CPU, memory, disk)

### If health checks fail:
1. Increase timeout values in `.env` file
2. Check network connectivity between containers
3. Verify authentication credentials
4. Review service-specific logs for errors

### If replica set initialization fails:
1. Check MongoDB container logs: `docker compose logs mongo1 mongo2 mongo3`
2. Manually run initialization: `docker compose up mongo-init`
3. Verify all MongoDB containers are healthy before initialization

## Environment Variables

Key variables for tuning startup behavior:
```bash
# Health check configuration
HEALTH_CHECK_INTERVAL=30s
HEALTH_CHECK_TIMEOUT=15s
HEALTH_CHECK_RETRIES=5

# MongoDB initialization
MONGO_INIT_MAX_ATTEMPTS=60
MONGO_INIT_SLEEP_INTERVAL=5
CONTAINER_CHECK_TIMEOUT=300
```

These improvements ensure reliable startup and eliminate restart loops by addressing root causes rather than just symptoms.