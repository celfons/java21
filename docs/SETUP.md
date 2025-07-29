# Detailed Setup Guide

This guide provides comprehensive instructions for setting up and configuring the MongoDB Kafka Connector example.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Service Details](#service-details)
- [Advanced Configuration](#advanced-configuration)
- [Production Deployment](#production-deployment)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows with WSL2
- **RAM**: Minimum 8GB, recommended 16GB
- **CPU**: 4+ cores recommended
- **Disk Space**: 10GB+ available
- **Network**: Ports 27017-27019, 2181, 8080-8083, 9092 must be available

### Software Requirements

```bash
# Docker and Docker Compose
docker --version          # >= 20.0
docker-compose --version  # >= 1.28

# Optional tools for debugging
curl --version
jq --version
nc --version  # netcat
```

### Install Required Tools

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y docker.io docker-compose curl jq netcat-openbsd
sudo usermod -aG docker $USER
# Re-login or run: newgrp docker
```

#### macOS
```bash
# Install Docker Desktop from https://docker.com
brew install curl jq netcat
```

#### Windows (WSL2)
```bash
# Install Docker Desktop with WSL2 backend
# In WSL2 terminal:
sudo apt update
sudo apt install -y curl jq netcat-openbsd
```

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/celfons/mongodb-kafka-connector-example.git
cd mongodb-kafka-connector-example
```

### Step 2: Environment Configuration

```bash
# Create environment file
cp .env.example .env

# Edit configuration (optional)
nano .env
```

### Step 3: Build and Deploy

#### Quick Setup (Recommended)
```bash
make dev-setup
```

#### Manual Setup
```bash
# Build custom images
make build

# Start services
make up

# Wait for services to start (30-60 seconds)
sleep 60

# Initialize MongoDB replica set
docker-compose exec mongo1 mongosh --file /docker-entrypoint-initdb.d/replica-init.js

# Setup Kafka Connect connector
./scripts/setup-connector.sh

# Insert sample data
make sample-data
```

### Step 4: Verification

```bash
# Check service health
make status

# View service logs
make logs

# Test Kafka topics
make monitor-topics
```

## Configuration

### Environment Variables

#### MongoDB Configuration
```bash
# Authentication
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123

# Replica Set
MONGO_REPLICA_SET_NAME=rs0
MONGO_DATABASE=exemplo
```

#### Kafka Configuration
```bash
# Broker Settings
KAFKA_BROKER_ID=1
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092
KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092

# Zookeeper
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
```

#### Kafka Connect Configuration
```bash
# Cluster Settings
CONNECT_BOOTSTRAP_SERVERS=kafka:9092
CONNECT_GROUP_ID=connect-cluster

# Storage Topics
CONNECT_CONFIG_STORAGE_TOPIC=connect-configs
CONNECT_OFFSET_STORAGE_TOPIC=connect-offsets
CONNECT_STATUS_STORAGE_TOPIC=connect-status

# Replication Factors (use 3+ in production)
CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR=1
CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR=1
CONNECT_STATUS_STORAGE_REPLICATION_FACTOR=1
```

### Service Ports

| Service | Internal Port | External Port | Description |
|---------|---------------|---------------|-------------|
| mongo1 | 27017 | 27017 | MongoDB Primary |
| mongo2 | 27017 | 27018 | MongoDB Secondary |
| mongo3 | 27017 | 27019 | MongoDB Secondary |
| zookeeper | 2181 | 2181 | Zookeeper |
| kafka | 9092 | 9092 | Kafka Broker |
| kafka-connect | 8083 | 8083 | Kafka Connect REST API |
| kafka-ui | 8080 | 8080 | Kafka UI |
| mongo-express | 8081 | 8081 | MongoDB Admin UI |

## Service Details

### MongoDB Replica Set

The setup includes a 3-node MongoDB replica set for high availability:

- **mongo1**: Primary node (priority 2)
- **mongo2**: Secondary node (priority 1)
- **mongo3**: Secondary node (priority 1)

#### Replica Set Commands
```bash
# Connect to primary
docker-compose exec mongo1 mongosh

# Check replica set status
rs.status()

# Check replica set configuration
rs.conf()

# Check oplog status
db.getReplicationInfo()
```

### Kafka Cluster

Single-node Kafka setup with Zookeeper:

#### Kafka Commands
```bash
# List topics
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Create topic
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --create --topic test-topic --partitions 3 --replication-factor 1

# Consume messages
docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic mongodb.exemplo.users --from-beginning

# Produce messages
docker-compose exec kafka kafka-console-producer --bootstrap-server localhost:9092 --topic test-topic
```

### Kafka Connect

Custom Docker image with MongoDB Source Connector plugin:

#### Connector Management
```bash
# List connectors
curl http://localhost:8083/connectors

# Get connector status
curl http://localhost:8083/connectors/mongodb-source-connector/status

# Delete connector
curl -X DELETE http://localhost:8083/connectors/mongodb-source-connector

# Update connector
curl -X PUT -H "Content-Type: application/json" -d @config/kafka-connect/mongodb-source-connector.json http://localhost:8083/connectors/mongodb-source-connector/config
```

## Advanced Configuration

### Custom Connector Configuration

Edit `config/kafka-connect/mongodb-source-connector.json`:

```json
{
  "name": "mongodb-source-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb://admin:password123@mongo1:27017,mongo2:27017,mongo3:27017/?authSource=admin&replicaSet=rs0",
    "database": "exemplo",
    "collection": "users",
    "topic.prefix": "mongodb",
    "pipeline": "[{\"$match\":{\"operationType\":{\"$in\":[\"insert\",\"update\",\"delete\"]}}}]",
    "change.stream.full.document": "updateLookup",
    "startup.mode": "latest"
  }
}
```

### Database Filtering

To monitor specific collections:

```json
{
  "collection": "users,products,orders"
}
```

To monitor all collections:
```json
{
  "collection": ""
}
```

### Change Stream Pipeline

Filter specific operations:
```json
{
  "pipeline": "[{\"$match\":{\"operationType\":{\"$in\":[\"insert\",\"update\"]}}}]"
}
```

## Production Deployment

### Security Hardening

#### 1. MongoDB Security
```bash
# Create dedicated user
use exemplo
db.createUser({
  user: "kafka-connector",
  pwd: "secure-password",
  roles: ["read"]
})
```

#### 2. Network Security
```yaml
# docker-compose.yml
networks:
  kafka-mongodb-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

#### 3. TLS/SSL Configuration
```bash
# Generate certificates
openssl req -new -x509 -keyout kafka-server-key.pem -out kafka-server-cert.pem -days 365
```

### Resource Optimization

#### Memory Allocation
```yaml
# docker-compose.yml
services:
  kafka:
    environment:
      KAFKA_HEAP_OPTS: "-Xmx2G -Xms2G"
  
  kafka-connect:
    environment:
      KAFKA_HEAP_OPTS: "-Xmx1G -Xms1G"
```

#### JVM Tuning
```bash
# For high-throughput scenarios
KAFKA_JVM_PERFORMANCE_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35"
```

### High Availability Setup

#### Multiple Kafka Brokers
```yaml
kafka-2:
  image: confluentinc/cp-kafka:7.4.0
  environment:
    KAFKA_BROKER_ID: 2
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9093
```

#### Replica Set Scaling
```bash
# Add new replica set member
rs.add("mongo4:27017")
```

### Monitoring and Alerting

#### Prometheus Integration
```yaml
kafka-exporter:
  image: danielqsj/kafka-exporter
  command: --kafka.server=kafka:9092
  ports:
    - "9308:9308"
```

#### Health Check Automation
```bash
# Add to crontab
*/5 * * * * /path/to/scripts/health-check.sh >> /var/log/health-check.log 2>&1
```

## Monitoring and Maintenance

### Daily Maintenance

```bash
# Check service health
make status

# Monitor resource usage
docker stats

# Check disk usage
df -h
docker system df
```

### Weekly Maintenance

```bash
# Backup MongoDB
make backup

# Clean Docker system
docker system prune -f

# Update connector configuration if needed
make update-connector
```

### Log Management

```bash
# View logs by service
make logs-mongo
make logs-kafka
make logs-connect

# Archive old logs
docker-compose logs --since 24h kafka > kafka-$(date +%Y%m%d).log
```

### Performance Tuning

#### MongoDB Optimization
```javascript
// Create efficient indexes
db.users.createIndex({ "email": 1 })
db.products.createIndex({ "sku": 1 })
db.orders.createIndex({ "userId": 1, "createdAt": -1 })
```

#### Kafka Optimization
```bash
# Increase partition count for high throughput
kafka-topics --bootstrap-server localhost:9092 --alter --topic mongodb.exemplo.users --partitions 6
```

## Troubleshooting

### Common Issues

#### Services Won't Start
```bash
# Check port conflicts
netstat -tulpn | grep -E '(27017|9092|8083)'

# Check Docker resources
docker system df
docker system prune -f
```

#### Replica Set Issues
```bash
# Re-initialize replica set
docker-compose exec mongo1 mongosh --eval "rs.reconfig(config, {force: true})"
```

#### Connector Issues
```bash
# Check connector logs
docker-compose logs kafka-connect

# Restart connector
curl -X POST http://localhost:8083/connectors/mongodb-source-connector/restart
```

For more troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).