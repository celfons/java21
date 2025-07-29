# MongoDB + Kafka + Kafka Connect - Complete Example

🚀 **Production-ready** MongoDB Kafka Connector example with real-time data synchronization using Docker.

![Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![MongoDB](https://img.shields.io/badge/MongoDB-7.0-green)
![Kafka](https://img.shields.io/badge/Apache_Kafka-7.4.0-orange)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 Overview

This project demonstrates a complete, production-ready setup for real-time data synchronization between MongoDB and Apache Kafka using the MongoDB Source Connector. Perfect for:

- **Real-time analytics** and data streaming
- **Event-driven architectures** and microservices
- **Data pipeline** construction
- **Change Data Capture (CDC)** implementations

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MongoDB       │    │   Kafka         │    │   Consumers     │
│   Replica Set   │───▶│   + Connect     │───▶│   Applications  │
│   (3 nodes)     │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
     ┌───▼───┐              ┌────▼────┐              ┌───▼───┐
     │ Mongo │              │ Kafka   │              │ Your  │
     │Express│              │   UI    │              │ Apps  │
     └───────┘              └─────────┘              └───────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker 20.0+ and Docker Compose
- 8GB+ RAM available
- Ports 27017-27019, 2181, 8080-8083, 9092 available

### One-Command Setup

```bash
# Clone the repository
git clone https://github.com/celfons/mongodb-kafka-connector-example.git
cd mongodb-kafka-connector-example

# Complete setup with sample data
make dev-setup

# Optional: Setup multiple filtered connectors for different operations
make setup-multi-connectors
```

**That's it!** 🎉 Your environment is ready with filtered connectors for INSERT, UPDATE, DELETE operations.

### Manual Setup

```bash
# 1. Create environment file
make .env

# 2. Build and start services
make setup

# 3. Insert sample data (optional)
make sample-data
```

## 🌐 Access Points

After setup, access these services:

| Service | URL | Description |
|---------|-----|-------------|
| **Kafka UI** | http://localhost:8080 | Monitor Kafka topics and messages |
| **MongoDB Express** | http://localhost:8081 | MongoDB administration interface |
| **Kafka Connect API** | http://localhost:8083 | Connector management REST API |

**Default credentials:**
- MongoDB Express: `admin` / `admin`
- MongoDB: `admin` / `password123`

## 📊 Features

### Core Components

- ✅ **MongoDB Replica Set** (3 nodes) - High availability
- ✅ **Apache Kafka** with Zookeeper - Message streaming
- ✅ **Kafka Connect** with MongoDB Source Connector
- ✅ **Multiple Filtered Connectors** - Separate connectors for INSERT, UPDATE, DELETE operations
- ✅ **Kafka UI** - Visual monitoring and management
- ✅ **MongoDB Express** - Database administration
- ✅ **Health Checks** - Automated service monitoring
- ✅ **Sample Data** - Ready-to-use test datasets

### Production Features

- 🔒 **Security**: Authentication and authorization
- 📊 **Monitoring**: Health checks and logging
- 🔄 **High Availability**: Replica set configuration
- ⚡ **Performance**: Optimized configurations
- 🚨 **Error Handling**: Dead letter queues
- 📖 **Documentation**: Comprehensive guides

## ⚙️ Multiple Connectors with Operation Filters

### 🎯 Overview

This project now includes **separate connectors** for different MongoDB operation types, allowing each event type to be sent to distinct Kafka topics:

- **🟢 INSERT Connector**: Captures only insertion operations → Topic `mongo-insert.*`
- **🟡 UPDATE Connector**: Captures only update operations → Topic `mongo-update.*`
- **🔴 DELETE Connector**: Captures only deletion operations → Topic `mongo-delete.*`

### 📁 Connector Structure

```
connectors/
├── mongo-insert-connector.json   # Filters only INSERT operations
├── mongo-update-connector.json   # Filters only UPDATE operations
└── mongo-delete-connector.json   # Filters only DELETE operations
```

### 🔧 Filter Configuration

Each connector uses **MongoDB Change Stream** with aggregation pipeline to filter by `operationType`:

```json
{
  "name": "mongo-insert-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "pipeline": "[{\"$match\": {\"operationType\": \"insert\"}}]",
    "topic.prefix": "mongo-insert",
    "database": "exemplo",
    ...
  }
}
```

**Available operation types:**
- `insert` - Insertion of new documents
- `update` - Update of existing documents
- `delete` - Deletion of documents
- `replace` - Complete replacement of documents

### 🚀 How to Use Multiple Connectors

#### Option 1: Complete Setup (Recommended for new projects)
```bash
# 1. Complete initial setup
make dev-setup

# 2. Setup multiple connectors with filters
make setup-multi-connectors
```

#### Option 2: Multiple Connectors Only (For existing projects)
```bash
# Setup only the filtered connectors (requires environment already started)
make setup-multi-connectors
```

#### Option 3: Manual
```bash
# Run script directly
./scripts/setup-multi-connectors.sh
```

### 📋 Created Kafka Topics

After setup, the following topics will be created automatically:

| Connector | Example Topic | Description |
|----------|---------------|-------------|
| **INSERT** | `mongo-insert.exemplo.users` | Only user insertions |
| **UPDATE** | `mongo-update.exemplo.users` | Only user updates |
| **DELETE** | `mongo-delete.exemplo.users` | Only user deletions |
| **INSERT** | `mongo-insert.exemplo.products` | Only product insertions |
| **UPDATE** | `mongo-update.exemplo.products` | Only product updates |
| **DELETE** | `mongo-delete.exemplo.products` | Only product deletions |

### 📄 Kafka Message Example

**INSERT Message** (topic: `mongo-insert.exemplo.users`):
```json
{
  "_id": {
    "_data": "82644F2A8D000000012B0429296E1404"
  },
  "operationType": "insert",
  "clusterTime": {
    "$timestamp": {
      "t": 1682951293,
      "i": 1
    }
  },
  "ns": {
    "db": "exemplo",
    "coll": "users"
  },
  "documentKey": {
    "_id": {
      "$oid": "644f2a8d1234567890abcdef"
    }
  },
  "fullDocument": {
    "_id": {
      "$oid": "644f2a8d1234567890abcdef"
    },
    "name": "João Silva",
    "email": "joao@exemplo.com",
    "createdAt": {
      "$date": "2023-05-01T12:34:56.789Z"
    }
  }
}
```

**UPDATE Message** (topic: `mongo-update.exemplo.users`):
```json
{
  "_id": {
    "_data": "82644F2A8E000000012B0429296E1404"
  },
  "operationType": "update",
  "clusterTime": {
    "$timestamp": {
      "t": 1682951294,
      "i": 1
    }
  },
  "ns": {
    "db": "exemplo",
    "coll": "users"
  },
  "documentKey": {
    "_id": {
      "$oid": "644f2a8d1234567890abcdef"
    }
  },
  "updateDescription": {
    "updatedFields": {
      "status": "active",
      "lastLogin": {
        "$date": "2023-05-01T12:35:56.789Z"
      }
    },
    "removedFields": []
  },
  "fullDocument": {
    "_id": {
      "$oid": "644f2a8d1234567890abcdef"
    },
    "name": "João Silva",
    "email": "joao@exemplo.com",
    "status": "active",
    "lastLogin": {
      "$date": "2023-05-01T12:35:56.789Z"
    },
    "createdAt": {
      "$date": "2023-05-01T12:34:56.789Z"
    }
  }
}
```

**DELETE Message** (topic: `mongo-delete.exemplo.users`):
```json
{
  "_id": {
    "_data": "82644F2A8F000000012B0429296E1404"
  },
  "operationType": "delete",
  "clusterTime": {
    "$timestamp": {
      "t": 1682951295,
      "i": 1
    }
  },
  "ns": {
    "db": "exemplo",
    "coll": "users"
  },
  "documentKey": {
    "_id": {
      "$oid": "644f2a8d1234567890abcdef"
    }
  }
}
```

### 🧪 Testing the Filters

1. **Start the environment**:
   ```bash
   make dev-setup
   make setup-multi-connectors
   ```

2. **Insert test data**:
   ```bash
   make sample-data
   ```

3. **Monitor topics** in real-time:
   ```bash
   # Option 1: Via web interface (Recommended)
   # Access http://localhost:8080 and view the topics
   
   # Option 2: Via command line
   make monitor-topics
   ```

4. **Test specific operations**:
   ```bash
   # Connect to MongoDB and perform manual operations
   docker-compose exec mongo1 mongosh "mongodb://admin:password123@localhost:27017/exemplo?authSource=admin"
   
   # Insert document (will appear in mongo-insert.exemplo.*)
   db.users.insertOne({name: "Test Insert", email: "insert@test.com"})
   
   # Update document (will appear in mongo-update.exemplo.*)
   db.users.updateOne({name: "Test Insert"}, {$set: {status: "updated"}})
   
   # Delete document (will appear in mongo-delete.exemplo.*)
   db.users.deleteOne({name: "Test Insert"})
   ```

### 🔍 Monitoring and Verification

#### Via Kafka UI (Web Interface)
- **URL**: http://localhost:8080
- View messages in real-time
- Analyze connector configuration
- Monitor performance and metrics

#### Via Kafka Connect API
```bash
# Status of all connectors
curl -s http://localhost:8083/connectors | jq

# Specific status of INSERT connector
curl -s http://localhost:8083/connectors/mongo-insert-connector/status | jq

# Specific status of UPDATE connector
curl -s http://localhost:8083/connectors/mongo-update-connector/status | jq

# Specific status of DELETE connector
curl -s http://localhost:8083/connectors/mongo-delete-connector/status | jq
```

### ⚠️ Important Notes

1. **Change Streams**: Requires MongoDB in Replica Set mode (already configured in this project)
2. **Performance**: Multiple connectors consume more resources - monitor usage
3. **Dead Letter Queues**: Each connector has its own DLQ for error handling
4. **Topics**: Topics are created automatically when the first messages arrive

### 🎛️ Connector Customization

To customize the connectors, edit the JSON files in `connectors/`:

```bash
# Edit INSERT connector configuration
nano connectors/mongo-insert-connector.json

# Apply changes (requires connector restart)
make setup-multi-connectors
```

**Configurations that can be customized:**
- Specific databases and collections
- More complex pipeline filters
- Performance settings (batch size, poll intervals)
- Destination topics
- Message formatting

## 🕒 TTL (Time To Live) Index Example

### Overview

This project includes a complete example of MongoDB **TTL (Time To Live) indexes** with **Change Streams** to capture document expiration events. TTL indexes automatically delete documents when they reach their expiration time, and these deletions are captured in real-time by Change Streams and forwarded to Kafka.

### 🎯 What You'll Learn

- How to create TTL indexes for automatic document expiration
- How Change Streams capture TTL expiration events as delete operations
- How the MongoDB Kafka Connector forwards TTL deletions to Kafka topics
- Real-time monitoring of document lifecycle events

### 📋 TTL Example Components

| Component | Description |
|-----------|-------------|
| **TTL Indexes** | Automatic document expiration based on date fields |
| **Sample Data** | Sessions and tokens that expire at different intervals |
| **Change Stream Monitor** | Real-time monitoring of TTL expiration events |
| **Kafka Integration** | TTL deletions forwarded to Kafka topics |

### 🚀 Quick Start - TTL Example

```bash
# 1. Start the environment (if not already running)
make dev-setup

# 2. Setup TTL indexes and insert sample data
make ttl-demo

# 3. Monitor TTL expiration events in real-time
make ttl-monitor

# 4. In another terminal, watch Kafka topics for TTL events
make monitor-topics
```

### 📊 TTL Collections Created

The example creates two collections with different TTL configurations:

#### 1. Sessions Collection
- **TTL Field**: `expiresAt`
- **Expiration**: Documents expire when `expiresAt` time is reached
- **Use Case**: User sessions, temporary data
- **Sample Expiration**: 30-150 seconds (for demo purposes)

```javascript
// TTL Index
db.sessions.createIndex(
    { "expiresAt": 1 }, 
    { expireAfterSeconds: 0 }
)

// Sample Document
{
    sessionId: "sess_demo_001",
    userId: "user_123",
    expiresAt: ISODate("2024-01-01T12:30:00Z"), // Expires at this exact time
    isActive: true
}
```

#### 2. User Tokens Collection
- **TTL Field**: `createdAt`
- **Expiration**: Documents expire 60 seconds after `createdAt`
- **Use Case**: API tokens, temporary access keys
- **Sample Expiration**: 60 seconds after creation

```javascript
// TTL Index
db.user_tokens.createIndex(
    { "createdAt": 1 }, 
    { expireAfterSeconds: 60 }
)

// Sample Document
{
    tokenId: "token_api_001",
    userId: "user_123", 
    createdAt: ISODate("2024-01-01T12:00:00Z"), // Expires 60 seconds after this time
    tokenType: "api_key"
}
```

### 🔍 Monitoring TTL Expiration Events

#### Via Change Stream Monitor
```bash
# Real-time monitoring of TTL deletions
make ttl-monitor
```

**Sample Output:**
```
🗑️  TTL EXPIRATION EVENT #1
   Time: 2024-01-01T12:30:01.000Z
   Database: exemplo
   Collection: sessions
   Operation: delete
   Document ID: {"_id": ObjectId("...") }
   🕒 TTL Type: Session expiration (expiresAt field)
```

#### Via Kafka Topics
TTL expiration events appear in Kafka topics as **delete operations**:

```bash
# Monitor Kafka topics for TTL events
make monitor-topics

# Or monitor specific delete operations
docker-compose exec kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic mongo-delete.exemplo.sessions \
    --from-beginning
```

**Sample Kafka Message for TTL Expiration:**
```json
{
    "_id": {
        "_data": "82644F2A8F000000012B0429296E1404"
    },
    "operationType": "delete",
    "clusterTime": {
        "$timestamp": {
            "t": 1682951295,
            "i": 1
        }
    },
    "ns": {
        "db": "exemplo",
        "coll": "sessions"
    },
    "documentKey": {
        "_id": {
            "$oid": "644f2a8d1234567890abcdef"
        }
    }
}
```

### ⚙️ TTL Commands

```bash
# Setup TTL indexes only
make ttl-setup

# Insert TTL sample data only  
make ttl-sample-data

# Complete TTL demo (indexes + data)
make ttl-demo

# Monitor TTL expiration events
make ttl-monitor

# Monitor via Kafka UI (Web interface)
# Visit: http://localhost:8080
```

### 📚 Understanding TTL Behavior

#### TTL Background Process
- MongoDB runs a background task **every 60 seconds** to remove expired documents
- Documents may not be deleted exactly at expiration time (up to 60-second delay)
- TTL deletions are captured by Change Streams as `delete` operations

#### TTL vs Manual Deletion
- **TTL Deletions**: Automatic, triggered by MongoDB's background process
- **Manual Deletions**: Triggered by application code or user actions
- **Both appear identically** in Change Streams as `delete` operations

#### Change Stream Integration
1. **TTL Index**: Marks documents for expiration
2. **Background Task**: MongoDB deletes expired documents
3. **Change Stream**: Captures deletion as `delete` operation
4. **Kafka Connector**: Forwards event to Kafka topic
5. **Consumers**: Process TTL expiration events

### 🧪 Testing Scenarios

#### Scenario 1: Immediate Expiration
```bash
# Insert document that expires in 30 seconds
make ttl-sample-data

# Monitor for expiration (wait 1-2 minutes)
make ttl-monitor
```

#### Scenario 2: Continuous Expiration
The sample data creates multiple documents that expire at different intervals, demonstrating:
- Batch expiration events
- Staggered expiration timing
- Real-time Change Stream notifications

#### Scenario 3: Kafka Integration
```bash
# Terminal 1: Monitor Change Streams
make ttl-monitor

# Terminal 2: Monitor Kafka topics
make monitor-topics  

# Terminal 3: Watch Kafka UI
# Visit: http://localhost:8080
```

### 🔧 Customizing TTL Configuration

#### Create Custom TTL Index
```javascript
// Expire documents 30 minutes after creation
db.mycollection.createIndex(
    { "createdAt": 1 },
    { expireAfterSeconds: 1800 }
)

// Expire documents at specific time
db.mycollection.createIndex(
    { "expiresAt": 1 },
    { expireAfterSeconds: 0 }
)
```

#### Production TTL Examples
```javascript
// User sessions (30 minutes)
db.sessions.createIndex(
    { "lastActivity": 1 },
    { expireAfterSeconds: 1800 }
)

// Email verification tokens (24 hours)
db.verification_tokens.createIndex(
    { "createdAt": 1 },
    { expireAfterSeconds: 86400 }
)

// Audit logs (90 days)
db.audit_logs.createIndex(
    { "timestamp": 1 },
    { expireAfterSeconds: 7776000 }
)
```

### ⚠️ Important Notes

1. **Replica Set Required**: TTL indexes work with Change Streams only in replica set mode
2. **Background Task**: TTL cleanup runs every 60 seconds, not immediately
3. **Index Limitations**: TTL field must be Date or array of Dates
4. **Compound Indexes**: TTL setting only applies to first field in compound index
5. **Performance**: TTL operations are lightweight but consider impact on large collections

### 🎛️ Kafka Connect TTL Integration

The MongoDB Kafka Connector automatically captures TTL expiration events:

- **Topic Naming**: `mongodb.exemplo.sessions` (or with operation prefix if using filtered connectors)
- **Message Format**: Standard MongoDB Change Stream delete event
- **Filtering**: Use Change Stream pipelines to filter TTL events specifically
- **Dead Letter Queue**: Failed TTL events are handled like other connector errors

## 🛠️ Available Commands

```bash
# Essential commands
make help                    # Show all available commands
make status                  # Check service health
make logs                    # View all service logs

# Development
make dev-setup              # Complete development setup
make sample-data            # Insert test data
make monitor-topics         # Watch Kafka messages

# Connector Management
make setup-multi-connectors # Setup multiple filtered connectors (INSERT, UPDATE, DELETE)

# Management
make clean                  # Clean up everything
make backup                 # Backup MongoDB data
make restart-*              # Restart specific services
```

## 📝 Configuration

### Environment Variables

Key configurations in `.env`:

```bash
# MongoDB
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123
MONGO_REPLICA_SET_NAME=rs0

# Kafka
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092

# Ports
KAFKA_UI_PORT=8080
MONGO_EXPRESS_PORT=8081
```

### Connector Configuration

The MongoDB Source Connector is configured in `config/kafka-connect/mongodb-source-connector.json`:

- **Change Streams**: Real-time change capture
- **Multiple Collections**: All collections in database
- **Error Handling**: Dead letter queue for failed messages
- **JSON Format**: Simplified JSON output

## 🧪 Testing Real-time Sync

1. **Insert data** into MongoDB:
   ```bash
   make sample-data
   ```

2. **Monitor Kafka topics**:
   ```bash
   make monitor-topics
   ```

3. **View in Kafka UI**:
   - Open http://localhost:8080
   - Check topics: `mongodb.exemplo.users`, `mongodb.exemplo.products`

4. **Make changes** in MongoDB Express:
   - Open http://localhost:8081
   - Update documents and see changes in Kafka

## 📚 Documentation

- 📖 [Detailed Setup Guide](docs/SETUP.md)
- ☁️ [MongoDB Atlas Integration](docs/ATLAS_SETUP.md)
- 🔧 [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## 🏭 Production Deployment

### Azure Cloud Deployment (Automated) 🚀

This project includes a complete CI/CD pipeline for automated deployment to Azure:

- ✅ **Automated Build and Push** to Azure Container Registry (ACR)
- ✅ **Deploy to Azure Web App for Containers** or Azure Container Instances
- ✅ **Automatic environment variable configuration**
- ✅ **MongoDB Atlas integration** for production
- ✅ **Automatic health verification** of the application

#### 🔧 Quick Setup

1. **Configure GitHub Secrets** (mandatory):
   ```bash
   # Azure Container Registry
   ACR_REGISTRY=<your-registry>.azurecr.io
   ACR_USERNAME=<acr-username>
   ACR_PASSWORD=<acr-password>
   
   # Azure Web App
   AZURE_WEBAPP_NAME=<web-app-name>
   AZURE_RESOURCE_GROUP=<resource-group-name>
   
   # Azure Credentials (service principal JSON)
   AZURE_CREDENTIALS=<credentials-json>
   
   # Production MongoDB Atlas
   MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://<user>:<pass>@<cluster>.mongodb.net/<db>
   ```

2. **Automatic Deploy**:
   - Push to `main` branch → Automatic deployment to production
   - Manual dispatch → Deploy to staging/development

3. **Application Access**:
   - **URL**: `https://<webapp-name>.azurewebsites.net:8083`
   - **API Connectors**: `/connectors`
   - **Health Check**: `/connector-plugins`

#### 📚 Complete Documentation

See the [complete CI/CD documentation](.github/workflows/README.md) for:
- Detailed secrets configuration
- How to obtain Azure credentials
- Troubleshooting and problem solving
- Pipeline customization

#### 🔐 Secrets Configuration Examples

**How to configure secrets in GitHub:**

1. Access `Settings` → `Secrets and variables` → `Actions` in your repository
2. Click `New repository secret` for each one:

```bash
# Example of AZURE_CREDENTIALS (service principal JSON):
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "your-secret-key-here",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-2222-3333-4444-555555555555"
}

# Example of ACR_REGISTRY:
myregistry.azurecr.io

# Example of MONGODB_ATLAS_CONNECTION_STRING:
mongodb+srv://admin:password123@cluster0.abcde.mongodb.net/production?retryWrites=true&w=majority
```

**How to obtain Azure credentials:**
```bash
# 1. Login to Azure CLI
az login

# 2. Create service principal
az ad sp create-for-rbac \
  --name "mongodb-kafka-cd" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth

# 3. Enable admin in ACR
az acr update --name YOUR_REGISTRY --admin-enabled true

# 4. Get ACR credentials
az acr credential show --name YOUR_REGISTRY
```

### Traditional Deployment

For on-premise environments or other clouds:

1. **Security**: Configure authentication and TLS
2. **Scaling**: Increase replica set and Kafka partitions
3. **Monitoring**: Configure logs and alerts
4. **Networking**: Configure appropriate network security
5. **Backup**: Implement automated backup strategies

See the [Production Setup Guide](docs/SETUP.md#production-deployment) for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- 🐛 Report issues on GitHub
- 💬 Join our community discussions

---

**Made with ❤️ for the MongoDB and Kafka community**