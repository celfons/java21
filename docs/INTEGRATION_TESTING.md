# MongoDB Kafka Connector - Integration Testing Guide

This document describes the comprehensive integration testing capabilities added to the MongoDB Kafka Connector project.

## Overview

The project now includes two levels of automated testing:

1. **Configuration Tests** - Validate connector configurations, environment variables, and setup scripts
2. **Integration Pipeline Tests** - Test complete data flow from MongoDB to Kafka with local infrastructure

## Testing Workflows

### GitHub Actions CI/CD

The enhanced `.github/workflows/atlas-tests.yml` workflow runs automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Manual trigger via `workflow_dispatch`

The workflow includes three jobs:

1. **Atlas Configuration Tests** - Quick validation of configurations and templates
2. **Integration Pipeline Tests** - Full end-to-end testing with local infrastructure
3. **Test Summary and Validation** - Final reporting and build status determination

### Local Testing

#### Quick Configuration Tests
```bash
# Run mock configuration tests (fast, no Docker required)
make test
```

#### Full Integration Tests
```bash
# Run complete integration tests with local infrastructure
make test-integration

# Run all tests (configuration + integration)
make test-all
```

#### Enhanced Integration Testing
```bash
# Run with custom options
./test-integration-enhanced.sh                # Full test with cleanup
./test-integration-enhanced.sh --no-cleanup   # Keep infrastructure running for inspection
./test-integration-enhanced.sh --help         # Show help
```

## What's Tested

### Configuration Tests (`test-atlas-setup.sh`)
- ✅ Docker Compose structure validation
- ✅ Connector configuration JSON syntax
- ✅ Environment variable placeholders
- ✅ MongoDB connector class validation
- ✅ Setup script syntax validation
- ✅ Environment file structure
- ✅ Dockerfile validation

### Integration Pipeline Tests (`test-integration-enhanced.sh`)
- ✅ Local test infrastructure deployment (MongoDB + Kafka + Kafka Connect)
- ✅ Service health checks and connectivity
- ✅ MongoDB connector plugin availability
- ✅ Connector deployment and status monitoring
- ✅ End-to-end data flow (MongoDB → Kafka)
- ✅ Kafka topic creation and message consumption
- ✅ Environment variable substitution in live environment
- ✅ Multi-connector setup with operation filtering

## Test Infrastructure

The integration tests use local Docker containers to simulate the production environment:

- **MongoDB**: Replica set with authentication
- **Kafka**: Single-node cluster with auto-topic creation
- **Zookeeper**: Required for Kafka
- **Kafka Connect**: Custom image with MongoDB connector plugin

### Environment Variables Used in Tests

```bash
# MongoDB Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123
MONGODB_DATABASE=testdb
MONGO_REPLICA_SET_NAME=rs0

# Kafka Configuration  
KAFKA_BOOTSTRAP_SERVERS=localhost:9092

# Test Connection String (simulates Atlas)
MONGODB_ATLAS_CONNECTION_STRING=mongodb://admin:password123@localhost:27017/testdb?authSource=admin&replicaSet=rs0
```

## Test Data Flow

1. **Infrastructure Setup**: Start MongoDB, Kafka, and Kafka Connect containers
2. **Connectivity Tests**: Verify all services are accessible via APIs
3. **Connector Deployment**: Deploy MongoDB source connector via REST API
4. **Data Insertion**: Insert test documents into MongoDB
5. **Message Validation**: Verify messages appear in Kafka topics
6. **Multi-Connector Testing**: Test operation-specific connectors (insert/update/delete)
7. **Configuration Validation**: Test environment variable substitution

## Expected Outcomes

### Successful Test Run
- All services start and become healthy
- Connector deploys and reaches RUNNING state
- Test data flows from MongoDB to Kafka
- Messages are consumable from Kafka topics
- All configuration templates process correctly

### Common Failure Scenarios

#### Service Health Issues
- **MongoDB**: Replica set initialization failure
- **Kafka**: Zookeeper connectivity problems
- **Kafka Connect**: Plugin loading or configuration errors

#### Connector Issues
- **Deployment**: Invalid configuration or missing environment variables
- **Status**: Connector stuck in FAILED state
- **Data Flow**: No messages appearing in Kafka topics

#### Environment Issues
- **Variables**: Missing or incorrectly formatted environment variables
- **Templates**: JSON syntax errors after substitution
- **Connectivity**: Network issues between containers

## Debugging Failed Tests

### GitHub Actions
1. Check the workflow run logs for specific job failures
2. Look for service health check timeouts
3. Review connector status and error messages
4. Check Docker container logs in the workflow output

### Local Testing
```bash
# Run with preserved infrastructure for debugging
./test-integration-enhanced.sh --no-cleanup

# After test completion, inspect services:
docker ps                                    # Check container status
docker logs kafka-connect-integration-test  # Check connector logs
docker logs mongo1-integration-test         # Check MongoDB logs
docker logs kafka-integration-test          # Check Kafka logs

# Test connectivity manually
curl http://localhost:8083/connectors        # List connectors
curl http://localhost:8083/connector-plugins # List plugins

# Cleanup when done
docker compose -f docker-compose.integration.yml down -v
```

## Benefits

### Development
- **Fast Feedback**: Immediate validation of connector configurations
- **Local Testing**: Full pipeline testing without external dependencies
- **Debugging**: Preserved infrastructure for troubleshooting

### CI/CD
- **Automated Validation**: Every change is tested automatically
- **Build Protection**: Failed tests prevent broken deployments
- **Comprehensive Coverage**: Both configuration and functional testing

### Production Readiness
- **Environment Validation**: Ensures configurations work with real infrastructure
- **Data Flow Assurance**: Validates complete MongoDB → Kafka pipeline
- **Multi-Connector Support**: Tests operation-specific filtering

## Next Steps

After successful testing:

1. **Configure Production Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your MongoDB Atlas and Kafka cluster details
   ```

2. **Deploy to Production**:
   ```bash
   make setup
   ```

3. **Monitor Connector Health**:
   ```bash
   make status
   make health-check
   ```

## Troubleshooting

### Test Timeouts
- Increase timeout values in workflow environment variables
- Check system resources and Docker performance

### Container Issues
- Ensure Docker has sufficient resources allocated
- Check for port conflicts (8083, 9092, 27017)
- Verify Docker Compose version compatibility

### Network Connectivity
- Ensure containers can communicate on Docker networks
- Check firewall settings if running on restricted systems
- Verify DNS resolution within Docker environment

## Contributing

When adding new tests:

1. Add configuration tests to `test-atlas-setup.sh` for quick validation
2. Add integration tests to `test-integration-enhanced.sh` for functional testing
3. Update GitHub Actions workflow if new environment variables are needed
4. Document new test scenarios in this guide