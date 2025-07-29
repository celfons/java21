# Troubleshooting Guide

This guide helps you diagnose and fix common issues with the MongoDB Kafka Connector example.

## Table of Contents

- [Quick Diagnosis](#quick-diagnosis)
- [Service-Specific Issues](#service-specific-issues)
- [Network Issues](#network-issues)
- [Performance Issues](#performance-issues)
- [Data Issues](#data-issues)
- [Debug Tools](#debug-tools)
- [Common Error Messages](#common-error-messages)
- [Recovery Procedures](#recovery-procedures)

## Quick Diagnosis

### Health Check Commands

```bash
# Overall system health
make status

# Check Docker containers
docker ps

# Check service logs
make logs

# Check disk space
df -h
docker system df
```

### System Requirements Check

```bash
# Memory usage
free -h

# CPU usage
top

# Port availability
netstat -tulpn | grep -E '(27017|9092|8083|2181|8080|8081)'

# Docker version
docker --version
docker-compose --version
```

## Service-Specific Issues

### MongoDB Issues

#### Problem: MongoDB Container Won't Start

**Symptoms**:
```
mongo1 exited with code 1
```

**Diagnosis**:
```bash
# Check container logs
docker-compose logs mongo1

# Check disk space
docker system df

# Check port conflicts
netstat -tulpn | grep 27017
```

**Solutions**:

1. **Port Conflict**:
   ```bash
   # Stop conflicting service
   sudo systemctl stop mongod
   
   # Or change port in docker-compose.yml
   ports:
     - "27018:27017"  # Use different external port
   ```

2. **Insufficient Permissions**:
   ```bash
   # Fix volume permissions
   sudo chown -R 999:999 mongo1_data/
   ```

3. **Corrupted Data**:
   ```bash
   # Remove corrupted volumes
   make clean
   docker volume prune -f
   ```

#### Problem: Replica Set Initialization Failed

**Symptoms**:
```
rs.initiate() failed
No primary available
```

**Diagnosis**:
```bash
# Connect to mongo1
docker-compose exec mongo1 mongosh

# Check replica set status
rs.status()

# Check configuration
rs.conf()
```

**Solutions**:

1. **Force Reconfiguration**:
   ```javascript
   // In mongosh
   config = rs.conf()
   rs.reconfig(config, {force: true})
   ```

2. **Manual Initialization**:
   ```bash
   # Re-run initialization script
   docker-compose exec mongo1 mongosh --file /docker-entrypoint-initdb.d/replica-init.js
   ```

3. **Network Issues**:
   ```bash
   # Check network connectivity
   docker-compose exec mongo2 ping mongo1
   docker-compose exec mongo3 ping mongo1
   ```

### Kafka Issues

#### Problem: Kafka Won't Start

**Symptoms**:
```
kafka exited with code 1
java.net.BindException: Address already in use
```

**Diagnosis**:
```bash
# Check Kafka logs
docker-compose logs kafka

# Check Zookeeper connection
docker-compose exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092
```

**Solutions**:

1. **Zookeeper Not Ready**:
   ```bash
   # Wait for Zookeeper
   docker-compose up zookeeper
   sleep 30
   docker-compose up kafka
   ```

2. **Port Conflict**:
   ```bash
   # Check what's using port 9092
   sudo lsof -i :9092
   
   # Change port in .env
   KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9093
   ```

3. **JVM Memory Issues**:
   ```bash
   # Reduce memory allocation
   # In docker-compose.yml
   environment:
     KAFKA_HEAP_OPTS: "-Xmx1G -Xms1G"
   ```

#### Problem: Kafka Topics Not Created

**Symptoms**:
```
kafka-topics --list returns empty
```

**Solutions**:

1. **Manual Topic Creation**:
   ```bash
   docker-compose exec kafka kafka-topics \
     --bootstrap-server localhost:9092 \
     --create --topic mongodb.exemplo.users \
     --partitions 3 --replication-factor 1
   ```

2. **Enable Auto-Creation**:
   ```bash
   # In docker-compose.yml
   environment:
     KAFKA_AUTO_CREATE_TOPICS_ENABLE: "true"
   ```

### Kafka Connect Issues

#### Problem: Kafka Connect Won't Start

**Symptoms**:
```
kafka-connect container keeps restarting
```

**Diagnosis**:
```bash
# Check Kafka Connect logs
docker-compose logs kafka-connect

# Check if Kafka is ready
curl -f http://localhost:8083/connectors
```

**Solutions**:

1. **Kafka Not Ready**:
   ```bash
   # Wait for Kafka to be fully ready
   docker-compose exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092
   ```

2. **Plugin Issues**:
   ```bash
   # Check if MongoDB plugin is installed
   curl http://localhost:8083/connector-plugins | jq '.[] | select(.class | contains("mongodb"))'
   ```

3. **Memory Issues**:
   ```bash
   # Increase memory allocation
   environment:
     KAFKA_HEAP_OPTS: "-Xmx2G -Xms2G"
   ```

#### Problem: MongoDB Connector Creation Failed

**Symptoms**:
```
POST /connectors returns 400 or 500 error
```

**Diagnosis**:
```bash
# Check connector configuration
cat config/kafka-connect/mongodb-source-connector.json | jq .

# Test MongoDB connectivity
docker-compose exec kafka-connect mongosh "mongodb://admin:password123@mongo1:27017/?authSource=admin"
```

**Solutions**:

1. **Invalid Configuration**:
   ```bash
   # Validate JSON
   jq . config/kafka-connect/mongodb-source-connector.json
   
   # Check required fields
   jq '.config."connection.uri"' config/kafka-connect/mongodb-source-connector.json
   ```

2. **MongoDB Connection Issues**:
   ```json
   {
     "connection.uri": "mongodb://admin:password123@mongo1:27017,mongo2:27017,mongo3:27017/?authSource=admin&replicaSet=rs0"
   }
   ```

3. **Permission Issues**:
   ```javascript
   // In mongosh
   use admin
   db.createUser({
     user: "kafka-connector",
     pwd: "password",
     roles: ["read"]
   })
   ```

### UI Services Issues

#### Problem: Kafka UI Not Accessible

**Symptoms**:
```
http://localhost:8080 returns connection refused
```

**Solutions**:

1. **Service Not Started**:
   ```bash
   docker-compose up kafka-ui
   ```

2. **Port Conflict**:
   ```bash
   # Change port in .env
   KAFKA_UI_PORT=8090
   ```

3. **Kafka Not Connected**:
   ```bash
   # Check Kafka UI logs
   docker-compose logs kafka-ui
   ```

## Network Issues

### Docker Network Problems

**Symptoms**:
```
Services can't communicate with each other
```

**Diagnosis**:
```bash
# Check network
docker network ls
docker network inspect kafka-mongodb-network

# Test connectivity
docker-compose exec mongo1 ping kafka
docker-compose exec kafka ping mongo1
```

**Solutions**:

1. **Recreate Network**:
   ```bash
   docker-compose down
   docker network rm kafka-mongodb-network
   docker-compose up
   ```

2. **DNS Resolution**:
   ```bash
   # Use IP addresses if hostnames fail
   docker-compose exec mongo1 ip addr
   ```

### Firewall Issues

**Solutions**:

1. **Ubuntu/Debian**:
   ```bash
   sudo ufw allow 27017:27019/tcp
   sudo ufw allow 9092/tcp
   sudo ufw allow 8080:8083/tcp
   ```

2. **CentOS/RHEL**:
   ```bash
   sudo firewall-cmd --permanent --add-port=27017-27019/tcp
   sudo firewall-cmd --permanent --add-port=9092/tcp
   sudo firewall-cmd --permanent --add-port=8080-8083/tcp
   sudo firewall-cmd --reload
   ```

## Performance Issues

### High Memory Usage

**Diagnosis**:
```bash
# Check container memory usage
docker stats

# Check system memory
free -h
```

**Solutions**:

1. **Reduce JVM Heap**:
   ```yaml
   environment:
     KAFKA_HEAP_OPTS: "-Xmx1G -Xms1G"
     CONNECT_HEAP_OPTS: "-Xmx512M -Xms512M"
   ```

2. **Limit Container Memory**:
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
       reservations:
         memory: 1G
   ```

### High CPU Usage

**Solutions**:

1. **Optimize Kafka Settings**:
   ```bash
   KAFKA_NUM_NETWORK_THREADS=3
   KAFKA_NUM_IO_THREADS=8
   ```

2. **Reduce Log Level**:
   ```bash
   KAFKA_LOG4J_ROOT_LOGLEVEL=WARN
   ```

### Slow Change Stream Processing

**Diagnosis**:
```bash
# Check change stream lag
mongosh --host mongo1:27017 --eval "
  db.getSiblingDB('exemplo').runCommand({
    aggregate: 1,
    pipeline: [{$changeStream: {}}],
    cursor: {}
  })
"
```

**Solutions**:

1. **Optimize Connector Settings**:
   ```json
   {
     "poll.max.batch.size": "500",
     "poll.await.time.ms": "1000",
     "batch.size": "100"
   }
   ```

2. **Add Indexes**:
   ```javascript
   // Add indexes for better performance
   db.users.createIndex({"_id": 1})
   db.products.createIndex({"sku": 1})
   ```

## Data Issues

### Missing Change Events

**Symptoms**:
```
Changes in MongoDB not appearing in Kafka topics
```

**Diagnosis**:
```bash
# Check connector status
curl http://localhost:8083/connectors/mongodb-source-connector/status

# Check topics
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Monitor topic
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mongodb.exemplo.users \
  --from-beginning
```

**Solutions**:

1. **Restart Connector**:
   ```bash
   curl -X POST http://localhost:8083/connectors/mongodb-source-connector/restart
   ```

2. **Check Database/Collection**:
   ```bash
   # Verify database and collection exist
   mongosh --host mongo1:27017 --eval "
     use exemplo
     show collections
   "
   ```

3. **Test Change Stream**:
   ```javascript
   // In mongosh
   use exemplo
   const changeStream = db.users.watch()
   while(changeStream.hasNext()) {
     print(JSON.stringify(changeStream.next()))
   }
   ```

### Duplicate Events

**Solutions**:

1. **Check Connector Configuration**:
   ```json
   {
     "startup.mode": "latest"
   }
   ```

2. **Reset Connector Offsets**:
   ```bash
   # Delete and recreate connector
   curl -X DELETE http://localhost:8083/connectors/mongodb-source-connector
   ./scripts/setup-connector.sh
   ```

## Debug Tools

### MongoDB Debug Commands

```javascript
// Check replica set status
rs.status()

// Check oplog
db.oplog.rs.find().sort({$natural: -1}).limit(5)

// Check change stream
use exemplo
db.users.watch([{$match: {operationType: "insert"}}])

// Check user permissions
db.runCommand({usersInfo: "admin"})
```

### Kafka Debug Commands

```bash
# List topics
kafka-topics --bootstrap-server localhost:9092 --list

# Describe topic
kafka-topics --bootstrap-server localhost:9092 --describe --topic mongodb.exemplo.users

# Check consumer groups
kafka-consumer-groups --bootstrap-server localhost:9092 --list

# Reset consumer group offset
kafka-consumer-groups --bootstrap-server localhost:9092 --group connect-cluster --reset-offsets --to-earliest --topic mongodb.exemplo.users --execute
```

### Kafka Connect Debug Commands

```bash
# List connectors
curl http://localhost:8083/connectors

# Get connector info
curl http://localhost:8083/connectors/mongodb-source-connector

# Get connector config
curl http://localhost:8083/connectors/mongodb-source-connector/config

# Get connector status
curl http://localhost:8083/connectors/mongodb-source-connector/status

# Get connector tasks
curl http://localhost:8083/connectors/mongodb-source-connector/tasks

# Restart connector
curl -X POST http://localhost:8083/connectors/mongodb-source-connector/restart

# Restart specific task
curl -X POST http://localhost:8083/connectors/mongodb-source-connector/tasks/0/restart
```

## Common Error Messages

### Error: "Replica set not initialized"

**Solution**:
```bash
docker-compose exec mongo1 mongosh --file /docker-entrypoint-initdb.d/replica-init.js
```

### Error: "Connection refused to kafka:9092"

**Solution**:
```bash
# Wait for Kafka to start
sleep 30
# Or check if Kafka is running
docker-compose ps kafka
```

### Error: "Authentication failed"

**Solution**:
```bash
# Check MongoDB credentials in .env
# Verify user exists:
mongosh --host mongo1:27017 --eval "
  use admin
  db.auth('admin', 'password123')
  db.listUsers()
"
```

### Error: "Topic does not exist"

**Solution**:
```bash
# Enable auto-creation or create manually
docker-compose exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic mongodb.exemplo.users \
  --partitions 3 --replication-factor 1
```

### Error: "Connector task failed"

**Solution**:
```bash
# Check connector logs
docker-compose logs kafka-connect | grep ERROR

# Check connector status
curl http://localhost:8083/connectors/mongodb-source-connector/status | jq .

# Restart connector
curl -X POST http://localhost:8083/connectors/mongodb-source-connector/restart
```

## Recovery Procedures

### Complete System Recovery

```bash
# 1. Stop all services
make down

# 2. Clean volumes and networks
make clean

# 3. Remove Docker images (if needed)
docker-compose down --rmi all

# 4. Restart from scratch
make dev-setup
```

### Partial Recovery

#### MongoDB Only
```bash
docker-compose restart mongo1 mongo2 mongo3
sleep 30
docker-compose exec mongo1 mongosh --file /docker-entrypoint-initdb.d/replica-init.js
```

#### Kafka Only
```bash
docker-compose restart zookeeper kafka
sleep 30
docker-compose restart kafka-connect
```

#### Connector Only
```bash
curl -X DELETE http://localhost:8083/connectors/mongodb-source-connector
./scripts/setup-connector.sh
```

### Data Recovery

#### Backup MongoDB
```bash
make backup
```

#### Restore MongoDB
```bash
make restore BACKUP_DIR=backups/20231201_120000
```

#### Reset Kafka Topics
```bash
# Delete topics
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --delete --topic mongodb.exemplo.users

# Recreate topics
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --create --topic mongodb.exemplo.users --partitions 3 --replication-factor 1
```

## Getting Help

### Log Collection

```bash
# Collect all logs
mkdir debug-logs
docker-compose logs > debug-logs/all-services.log
docker-compose logs mongo1 > debug-logs/mongo1.log
docker-compose logs kafka > debug-logs/kafka.log
docker-compose logs kafka-connect > debug-logs/kafka-connect.log

# System information
docker system info > debug-logs/docker-info.txt
docker-compose config > debug-logs/compose-config.yml
```

### Community Resources

- **MongoDB Community**: https://community.mongodb.com/
- **Confluent Community**: https://forum.confluent.io/
- **Stack Overflow**: Use tags `mongodb`, `apache-kafka`, `kafka-connect`
- **GitHub Issues**: Report bugs and feature requests

### Professional Support

- **MongoDB Support**: For Atlas and Enterprise customers
- **Confluent Support**: For Confluent Platform customers
- **Docker Support**: For Docker Enterprise customers