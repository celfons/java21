# MongoDB Atlas Integration Guide

This guide shows how to integrate the Kafka Connect setup with MongoDB Atlas, MongoDB's cloud service.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Atlas Setup](#atlas-setup)
- [Configuration](#configuration)
- [Connection Methods](#connection-methods)
- [Security](#security)
- [Performance Optimization](#performance-optimization)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### MongoDB Atlas Account

1. **Create Account**: Sign up at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. **Create Organization**: Set up your organization
3. **Create Project**: Create a new project for this integration

### Required Access

- **Atlas Admin** or **Project Owner** permissions
- **Database Access** permissions to create users
- **Network Access** permissions to configure IP whitelist

## Atlas Setup

### 1. Create Cluster

```bash
# Using Atlas CLI (optional)
atlas clusters create myCluster --provider AWS --region US_EAST_1 --tier M10

# Or use the web interface:
# 1. Click "Build a Cluster"
# 2. Choose cloud provider and region
# 3. Select cluster tier (M10+ recommended for production)
# 4. Configure additional settings
# 5. Click "Create Cluster"
```

### 2. Configure Database Access

#### Create Database User

1. Navigate to **Database Access** in Atlas
2. Click **Add New Database User**
3. Choose **Password** authentication
4. Configure user:
   ```
   Username: kafka-connector
   Password: [generate secure password]
   Database User Privileges: 
     - Built-in Role: readAnyDatabase
     - Or custom role with read access to specific databases
   ```

#### Custom Role for Change Streams (Recommended)

```javascript
// In Atlas or mongosh
use admin
db.createRole({
  role: "changeStreamReader",
  privileges: [
    {
      resource: { db: "", collection: "" },
      actions: ["find", "changeStream"]
    },
    {
      resource: { db: "config", collection: "shards" },
      actions: ["find"]
    }
  ],
  roles: []
})

// Assign role to user
db.createUser({
  user: "kafka-connector",
  pwd: "secure-password",
  roles: [
    { role: "changeStreamReader", db: "admin" },
    { role: "read", db: "exemplo" }
  ]
})
```

### 3. Configure Network Access

#### IP Whitelist Options

**Option 1: Specific IP (Recommended)**
```bash
# Add your server's public IP
# Get public IP: curl ifconfig.me
# Add to Atlas Network Access: <YOUR_PUBLIC_IP>/32
```

**Option 2: Allow All (Development Only)**
```bash
# ⚠️ NOT recommended for production
# Add to Atlas Network Access: 0.0.0.0/0
```

**Option 3: VPC Peering (Production)**
```bash
# Set up VPC peering for secure connection
# Follow Atlas VPC Peering documentation
```

### 4. Get Connection String

1. Navigate to **Clusters** in Atlas
2. Click **Connect** on your cluster
3. Choose **Connect your application**
4. Select **Driver version** and copy connection string
5. Replace `<password>` and `<dbname>` with actual values

Example connection string:
```
mongodb+srv://kafka-connector:<password>@cluster0.abc123.mongodb.net/exemplo?retryWrites=true&w=majority
```

## Configuration

### 1. Update Environment Variables

Create or update `.env` file:

```bash
# Copy example environment
cp .env.example .env

# Edit .env file
nano .env
```

Add Atlas configuration:
```bash
# MongoDB Atlas Configuration
ATLAS_CONNECTION_STRING=mongodb+srv://kafka-connector:your-password@cluster0.abc123.mongodb.net/exemplo?retryWrites=true&w=majority
ATLAS_USERNAME=kafka-connector
ATLAS_PASSWORD=your-secure-password
ATLAS_DATABASE=exemplo

# Use Atlas instead of local MongoDB
USE_ATLAS=true
```

### 2. Update Connector Configuration

Create Atlas-specific connector configuration:

```bash
cp config/kafka-connect/mongodb-source-connector.json config/kafka-connect/mongodb-atlas-connector.json
```

Edit `config/kafka-connect/mongodb-atlas-connector.json`:

```json
{
  "name": "mongodb-atlas-source-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "tasks.max": "1",
    "connection.uri": "mongodb+srv://kafka-connector:your-password@cluster0.abc123.mongodb.net/?retryWrites=true&w=majority",
    "database": "exemplo",
    "collection": "",
    "topic.prefix": "atlas.mongodb",
    "topic.suffix": "",
    "topic.separator": ".",
    "poll.max.batch.size": "1000",
    "poll.await.time.ms": "5000",
    "pipeline": "[]",
    "batch.size": "0",
    "change.stream.full.document": "updateLookup",
    "startup.mode": "latest",
    "output.format.value": "json",
    "output.format.key": "json",
    "output.json.formatter": "com.mongodb.kafka.connect.source.json.formatter.SimplifiedJson",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "errors.tolerance": "all",
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "errors.deadletterqueue.topic.name": "atlas-mongodb-dlq",
    "errors.deadletterqueue.topic.replication.factor": "1",
    "errors.deadletterqueue.context.headers.enable": "true"
  }
}
```

### 3. Update Docker Compose (Optional)

For Atlas-only setup, create `docker-compose.atlas.yml`:

```yaml
version: '3.8'

services:
  # Remove MongoDB services for Atlas-only setup
  # Keep only Kafka infrastructure and Kafka Connect

  # Zookeeper for Kafka coordination
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    container_name: zookeeper
    restart: unless-stopped
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    networks:
      - kafka-network

  # Kafka Broker
  kafka:
    image: confluentinc/cp-kafka:7.4.0
    container_name: kafka
    restart: unless-stopped
    depends_on:
      - zookeeper
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
    ports:
      - "9092:9092"
    networks:
      - kafka-network

  # Kafka Connect with MongoDB Source Connector
  kafka-connect:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: kafka-connect
    restart: unless-stopped
    depends_on:
      - kafka
    environment:
      CONNECT_BOOTSTRAP_SERVERS: kafka:9092
      CONNECT_REST_ADVERTISED_HOST_NAME: kafka-connect
      CONNECT_REST_PORT: 8083
      CONNECT_GROUP_ID: atlas-connect-cluster
      CONNECT_CONFIG_STORAGE_TOPIC: atlas-connect-configs
      CONNECT_OFFSET_STORAGE_TOPIC: atlas-connect-offsets
      CONNECT_STATUS_STORAGE_TOPIC: atlas-connect-status
      CONNECT_CONFIG_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_OFFSET_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_STATUS_STORAGE_REPLICATION_FACTOR: 1
      CONNECT_KEY_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_VALUE_CONVERTER: org.apache.kafka.connect.json.JsonConverter
      CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE: "false"
      CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE: "false"
      CONNECT_PLUGIN_PATH: "/usr/share/java,/usr/share/confluent-hub-components"
    ports:
      - "8083:8083"
    networks:
      - kafka-network

  # Kafka UI for monitoring
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    restart: unless-stopped
    depends_on:
      - kafka
    environment:
      KAFKA_CLUSTERS_0_NAME: atlas-local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
      KAFKA_CLUSTERS_0_KAFKACONNECT_0_NAME: atlas-connect
      KAFKA_CLUSTERS_0_KAFKACONNECT_0_ADDRESS: http://kafka-connect:8083
    ports:
      - "8080:8080"
    networks:
      - kafka-network

networks:
  kafka-network:
    driver: bridge
```

## Connection Methods

### Method 1: Standard Connection String

Basic connection with username/password:

```json
{
  "connection.uri": "mongodb+srv://username:password@cluster0.abc123.mongodb.net/database?retryWrites=true&w=majority"
}
```

### Method 2: X.509 Certificate Authentication

For enhanced security:

1. **Generate Certificate** in Atlas
2. **Download Certificate** files
3. **Configure Connector**:

```json
{
  "connection.uri": "mongodb+srv://cluster0.abc123.mongodb.net/database?authSource=$external&authMechanism=MONGODB-X509&retryWrites=true&w=majority",
  "connection.ssl.enabled": "true",
  "connection.ssl.client.cert.path": "/path/to/client.pem",
  "connection.ssl.ca.cert.path": "/path/to/ca.pem"
}
```

### Method 3: AWS IAM Authentication

For AWS-hosted deployments:

```json
{
  "connection.uri": "mongodb+srv://cluster0.abc123.mongodb.net/database?authSource=$external&authMechanism=MONGODB-AWS&retryWrites=true&w=majority"
}
```

## Security

### 1. Network Security

#### VPC Peering (Recommended)
```bash
# Set up VPC peering between your infrastructure and Atlas
# Follow Atlas documentation for VPC setup
```

#### Private Endpoints
```bash
# Use Atlas Private Endpoints for secure connectivity
# Available in M10+ clusters
```

### 2. Authentication

#### SCRAM-SHA-256 (Default)
```javascript
// Create dedicated user for Kafka Connect
use admin
db.createUser({
  user: "kafka-connector",
  pwd: "secure-password",
  roles: [
    { role: "read", db: "exemplo" },
    { role: "read", db: "config" }
  ],
  mechanisms: ["SCRAM-SHA-256"]
})
```

#### X.509 Certificate
```bash
# Generate client certificate in Atlas
# Download and configure in Kafka Connect
```

### 3. Encryption

#### In-Transit Encryption
- **Always enabled** in Atlas
- **TLS 1.2+** required
- **SNI support** available

#### At-Rest Encryption
- **Available** in M10+ clusters
- **Customer Key Management** supported
- **FIPS 140-2 Level 1** validated

## Performance Optimization

### 1. Atlas Cluster Configuration

#### Cluster Tier Selection
```bash
# Development: M0 (Free), M2, M5
# Production: M10+ recommended
# High Performance: M30+, M40+
```

#### Regional Deployment
```bash
# Choose region closest to Kafka infrastructure
# Consider read preference for global deployments
```

### 2. Connection Pool Optimization

```json
{
  "connection.uri": "mongodb+srv://cluster0.abc123.mongodb.net/database?maxPoolSize=50&minPoolSize=5&maxIdleTimeMS=30000&waitQueueTimeoutMS=5000"
}
```

### 3. Change Stream Optimization

#### Resume Tokens
```json
{
  "startup.mode": "timestamp",
  "startup.mode.timestamp.start.at.operation.time": "1640995200"
}
```

#### Batch Configuration
```json
{
  "poll.max.batch.size": "1000",
  "poll.await.time.ms": "5000",
  "batch.size": "100"
}
```

### 4. Atlas Performance Advisor

Monitor and optimize:
- **Index recommendations**
- **Query performance**
- **Connection patterns**

## Monitoring

### 1. Atlas Monitoring

#### Real-time Metrics
- **Operations per second**
- **Connection count**
- **Replication lag**
- **Change stream events**

#### Alerts Setup
```bash
# Set up alerts for:
# - High connection count
# - Change stream failures
# - Performance degradation
```

### 2. Kafka Connect Monitoring

```bash
# Monitor connector health
curl http://localhost:8083/connectors/mongodb-atlas-source-connector/status

# Monitor connector metrics
curl http://localhost:8083/connectors/mongodb-atlas-source-connector/metrics
```

### 3. Custom Monitoring Script

```bash
#!/bin/bash
# atlas-health-check.sh

# Check Atlas connectivity
mongosh "$ATLAS_CONNECTION_STRING" --eval "db.adminCommand('ping')"

# Check change stream lag
mongosh "$ATLAS_CONNECTION_STRING" --eval "
  db.getSiblingDB('exemplo').watch().hasNext() ? 
  'Change streams active' : 'No change stream activity'
"

# Check connector status
curl -s http://localhost:8083/connectors/mongodb-atlas-source-connector/status | jq .
```

## Troubleshooting

### Common Issues

#### 1. Connection Failures

**Symptoms**: Connector fails to connect to Atlas

**Solutions**:
```bash
# Check IP whitelist
# Verify connection string
# Test connectivity:
mongosh "mongodb+srv://cluster0.abc123.mongodb.net/test" --username kafka-connector

# Check DNS resolution
nslookup cluster0.abc123.mongodb.net
```

#### 2. Authentication Errors

**Symptoms**: Authentication failed errors

**Solutions**:
```bash
# Verify user exists and has correct permissions
# Check password/username
# Verify authentication database
mongosh "$ATLAS_CONNECTION_STRING" --eval "db.runCommand({usersInfo: 'kafka-connector'})"
```

#### 3. Change Stream Issues

**Symptoms**: No events flowing from Atlas

**Solutions**:
```bash
# Check change stream permissions
# Verify database/collection exists
# Test change stream manually:
mongosh "$ATLAS_CONNECTION_STRING" --eval "
  db.getSiblingDB('exemplo').collection.watch().next()
"
```

#### 4. Performance Issues

**Symptoms**: High latency, timeouts

**Solutions**:
```bash
# Optimize connection pool settings
# Check Atlas Performance Advisor
# Monitor connection count
# Consider cluster tier upgrade
```

### Debug Commands

```bash
# Test Atlas connection
mongosh "$ATLAS_CONNECTION_STRING" --eval "db.adminCommand('ping')"

# Check user permissions
mongosh "$ATLAS_CONNECTION_STRING" --eval "db.runCommand({connectionStatus: 1})"

# Monitor change stream
mongosh "$ATLAS_CONNECTION_STRING" --eval "
  const changeStream = db.getSiblingDB('exemplo').users.watch();
  print('Waiting for changes...');
  while(changeStream.hasNext()) {
    print(JSON.stringify(changeStream.next()));
  }
"

# Check connector logs
docker-compose logs -f kafka-connect | grep -i atlas
```

### Support Resources

- **Atlas Documentation**: https://docs.atlas.mongodb.com/
- **Kafka Connect MongoDB**: https://docs.mongodb.com/kafka-connector/
- **Community Forums**: https://community.mongodb.com/
- **Atlas Support**: Available for paid clusters