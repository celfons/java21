# MongoDB Atlas + Kafka Connect - Cloud-Ready Example

🚀 **Production-ready** MongoDB Atlas Kafka Connector setup with real-time data synchronization using external cloud services.

![Architecture](https://img.shields.io/badge/Architecture-Cloud--Native-blue)
![MongoDB Atlas](https://img.shields.io/badge/MongoDB-Atlas-green)
![Kafka](https://img.shields.io/badge/Apache_Kafka-External-orange)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 Overview

This project demonstrates a **cloud-ready** setup for real-time data synchronization between **MongoDB Atlas** and external **Apache Kafka** clusters using the MongoDB Source Connector. Perfect for:

- **Real-time analytics** and data streaming
- **Event-driven architectures** and microservices
- **Data pipeline** construction with cloud services
- **Change Data Capture (CDC)** implementations using Atlas change streams

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MongoDB       │    │   Kafka         │    │   Consumer      │
│   Atlas         │───▶│   Connect       │───▶│   Applications  │
│   (Cloud)       │    │   (Docker)      │    │   (Your Apps)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
     ┌───▼───┐              ┌────▼────┐              ┌───▼───┐
     │Change │              │External │              │ Data  │
     │Streams│              │ Kafka   │              │Consumers│
     └───────┘              │Cluster  │              └───────┘
                            └─────────┘
```

**Key Components:**
- **MongoDB Atlas**: Managed MongoDB cluster with change streams
- **Kafka Connect**: Dockerized connector service
- **External Kafka**: Your existing Kafka cluster or managed service
- **No Local Dependencies**: Pure cloud/external service integration
## 🚀 Quick Start

### Prerequisites

- **MongoDB Atlas Cluster**: Set up at [mongodb.com/atlas](https://mongodb.com/atlas)
- **External Kafka Cluster**: Managed service or your own Kafka cluster
- **Docker 20.0+** and Docker Compose
- **Port 8083** available for Kafka Connect API

### Environment Setup

1. **Clone the repository**
```bash
git clone https://github.com/celfons/mongodb-kafka-connector-example.git
cd mongodb-kafka-connector-example
```

2. **Create and configure environment**
```bash
# Create environment file
make .env

# Edit .env file with your connection strings
nano .env
```

3. **Required environment variables**
```bash
# MongoDB Atlas connection
MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority

# External Kafka cluster
KAFKA_BOOTSTRAP_SERVERS=<kafka-broker-1>:9092,<kafka-broker-2>:9092

# Database to monitor
MONGODB_DATABASE=exemplo
```

### Quick Setup

```bash
# Build and start Kafka Connect
make setup

# Setup single connector for all operations
make setup-connector

# OR setup multiple filtered connectors (INSERT, UPDATE, DELETE)
make setup-multi-connectors
```

**That's it!** 🎉 Your Kafka Connect is now streaming changes from MongoDB Atlas to your Kafka cluster.

## 🌐 Access Points

After setup, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| **Kafka Connect API** | http://localhost:8083 | Connector management REST API |

**Useful API endpoints:**
- `GET /connectors` - List all connectors
- `GET /connectors/{name}/status` - Check connector status
- `GET /connector-plugins` - List available plugins

## 🧪 Testing

### Mock Configuration Tests

This project includes **mock tests** that validate the Atlas configuration without requiring actual MongoDB Atlas or Kafka clusters. These tests ensure all configurations are correct and ready for deployment.

#### 🔄 What Gets Tested

The mock test suite validates:

- ✅ **Docker Configuration**: Kafka Connect service configuration
- ✅ **Connector Templates**: JSON syntax and environment variable placeholders
- ✅ **Environment Setup**: Required variables and cleanup of legacy settings
- ✅ **Script Validation**: Setup scripts syntax and functionality
- ✅ **File Structure**: Removal of obsolete local setup files

#### 🚀 Automated Test Execution

Tests run automatically on:
- **Push to main/develop branches**
- **Pull requests**
- **Manual workflow dispatch**

View test results in the [GitHub Actions tab](../../actions/workflows/atlas-tests.yml).

#### 🖥️ Running Tests Locally

```bash
# Run mock configuration tests
make test

# Run health checks (when Kafka Connect is running)
make health-check

# Check service status
make status
```

#### 🔧 What Tests Don't Require

- ❌ No MongoDB Atlas cluster needed
- ❌ No external Kafka cluster needed
- ❌ No actual data synchronization
- ✅ Pure configuration and template validation

## 📊 Features

### Core Components

- ✅ **MongoDB Atlas Integration** - Connect to managed MongoDB clusters
- ✅ **External Kafka Support** - Connect to any Kafka cluster or managed service
- ✅ **Kafka Connect** - Containerized connector service
- ✅ **Multiple Filtered Connectors** - Separate connectors for INSERT, UPDATE, DELETE operations
- ✅ **Change Stream Support** - Real-time change capture from Atlas
- ✅ **Health Monitoring** - Automated service health checks
- ✅ **Mock Testing** - No external dependencies required for testing

### Production Features

- 🔒 **Security**: Environment-based configuration
- 📊 **Monitoring**: Health checks and status endpoints
- 🔄 **High Availability**: Works with Atlas replica sets
- ⚡ **Performance**: Optimized connector configurations
- 🚨 **Error Handling**: Dead letter queues
- 📖 **Documentation**: Comprehensive Atlas setup guides
"

# 7. Check Kafka topics for messages
docker compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list
```

#### 🔧 Test Configuration

The automated tests use environment variables that can be customized:

```bash
# Test environment settings (in .env file)
COMPOSE_PROJECT_NAME=mongodb-kafka-test
MONGO_REPLICA_SET_NAME=rs0
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123
```

#### ⚠️ Prerequisites for Local Testing

Ensure you have installed:
- Docker 20.0+ and Docker Compose
- `curl`, `jq`, `netcat` utilities
- MongoDB shell (`mongosh`) for database operations

#### 🐛 Troubleshooting Tests

**Common issues and solutions:**

```bash
# If tests fail due to timing issues
# Increase wait times and retry

# Check service logs
docker compose logs [service-name]

# Manual health check individual services
curl http://localhost:8083/connectors        # Kafka Connect
curl http://localhost:8080                   # Kafka UI
mongosh --host localhost:27017 --eval "db.adminCommand('ping')"  # MongoDB

# Clean restart
docker compose down -v && docker compose up -d
```

**Test timeout issues:**
- MongoDB replica set initialization can take up to 2 minutes
- Kafka Connect startup requires additional time for plugin loading
- Network connectivity between containers needs stabilization time

#### 📊 Test Reports

The GitHub Actions workflow generates comprehensive test reports including:
- Service startup logs and status
- Health check results for all components
- Connector configuration and status
- Resource usage statistics
- Error details and troubleshooting information

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
# 1. Complete initial Atlas setup
make setup

# 2. Setup multiple connectors with filters
make setup-multi-connectors
```

#### Option 2: Multiple Connectors Only (For existing projects)
```bash
# Setup only the filtered connectors (requires Kafka Connect already started)
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
   # Connect to MongoDB Atlas using your connection string
   mongosh "${MONGODB_ATLAS_CONNECTION_STRING}"
   
   # Switch to your database
   use exemplo
   
   # Insert document (will appear in mongo-insert.exemplo.*)
   db.users.insertOne({name: "Test Insert", email: "insert@test.com"})
   
   # Update document (will appear in mongo-update.exemplo.*)
   db.users.updateOne({name: "Test Insert"}, {$set: {status: "updated"}})
   
   # Delete document (will appear in mongo-delete.exemplo.*)
   db.users.deleteOne({name: "Test Insert"})
   ```
   
   **Note**: You need `mongosh` installed locally or use MongoDB Atlas web interface.

### 🔍 Monitoring and Verification

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

#### Via External Kafka Tools
Use your existing Kafka monitoring tools or managed service interfaces to:
- View messages in real-time
- Monitor topic performance
- Track consumer lag

### ⚠️ Important Notes

1. **Change Streams**: Requires MongoDB Atlas cluster (automatically supports change streams)
2. **Performance**: Multiple connectors consume more resources - monitor usage
3. **Dead Letter Queues**: Each connector has its own DLQ for error handling
4. **Topics**: Topics are created automatically when the first messages arrive
5. **Atlas Connectivity**: Ensure Kafka Connect can reach your Atlas cluster

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

## 🌊 Real-time Change Streaming

### MongoDB Atlas Change Streams

MongoDB Atlas automatically supports change streams, which enable real-time monitoring of data changes. The Kafka Connect MongoDB Source Connector leverages these change streams to capture:

- **Document insertions** - New data added to collections
- **Document updates** - Changes to existing documents  
- **Document deletions** - Removed documents
- **Collection operations** - Schema changes and collection events

### Change Stream Benefits with Atlas

1. **🔄 Real-time Processing**: Sub-second latency for change detection
2. **📊 Scalable**: Handles high-throughput change operations
3. **🛡️ Reliable**: Built-in resumability and error handling
4. **🎯 Filtered**: Use aggregation pipelines to filter specific changes
5. **☁️ Managed**: No infrastructure maintenance required

### Example Change Stream Message

When a document is inserted into MongoDB Atlas, the connector produces:

```json
{
  "_id": {
    "_data": "82644F2A8D000000012B0429296E1404"
  },
  "operationType": "insert",
  "clusterTime": {
    "$timestamp": {"t": 1682951293, "i": 1}
  },
  "ns": {
    "db": "exemplo",
    "coll": "users"
  },
  "documentKey": {
    "_id": {"$oid": "644f2a8d1234567890abcdef"}
  },
  "fullDocument": {
    "_id": {"$oid": "644f2a8d1234567890abcdef"},
    "name": "João Silva",
    "email": "joao@exemplo.com",
    "createdAt": {"$date": "2023-05-01T12:34:56.789Z"}
  }
}
```

## 🛠️ Available Commands

```bash
# Essential commands
make help                     # Show all available commands
make status                   # Check Kafka Connect health
make logs                     # View Kafka Connect logs

# Development
make setup                    # Complete Atlas setup
make setup-connector          # Setup single connector
make setup-multi-connectors   # Setup multiple filtered connectors

# Testing and Health
make test                     # Run mock configuration tests
make health-check             # Run Atlas health checks

# Management
make clean                    # Clean up everything
make restart-connect          # Restart Kafka Connect service
```

## 📝 Configuration

### Environment Variables

Key configurations in `.env`:

```bash
# MongoDB Atlas Configuration (REQUIRED)
MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority
MONGODB_DATABASE=exemplo

# External Kafka Configuration (REQUIRED)
KAFKA_BOOTSTRAP_SERVERS=<kafka-broker-1>:9092,<kafka-broker-2>:9092

# Kafka Connect Configuration
CONNECT_GROUP_ID=connect-cluster
CONNECT_CONFIG_STORAGE_TOPIC=connect-configs
CONNECT_OFFSET_STORAGE_TOPIC=connect-offsets
CONNECT_STATUS_STORAGE_TOPIC=connect-status

# Optional: Kafka Security Configuration
KAFKA_SECURITY_PROTOCOL=PLAINTEXT
KAFKA_SASL_MECHANISM=
KAFKA_SASL_JAAS_CONFIG=
```

### Connector Configuration

The MongoDB Source Connector is configured in `config/kafka-connect/mongodb-source-connector.json`:

- **Change Streams**: Real-time change capture from Atlas
- **Environment Variables**: Uses placeholders for Atlas connection string
- **Multiple Collections**: All collections in specified database
- **Error Handling**: Dead letter queue for failed messages
- **JSON Format**: Simplified JSON output

## 🧪 Testing Real-time Sync

1. **Connect to MongoDB Atlas**:
   ```bash
   # Use MongoDB Atlas web interface or connect locally
   mongosh "${MONGODB_ATLAS_CONNECTION_STRING}"
   ```

2. **Insert test data**:
   ```javascript
   use exemplo
   db.users.insertOne({name: "Test User", email: "test@example.com"})
   ```

3. **Monitor connector status**:
   ```bash
   curl http://localhost:8083/connectors/mongodb-atlas-connector/status
   ```

4. **Check Kafka topics**:
   Use your Kafka cluster's monitoring tools to verify messages are being produced to topics like `mongodb.exemplo.users`.

## 📚 Documentation

- 📖 [Detailed Setup Guide](docs/SETUP.md)
- ☁️ [MongoDB Atlas Integration](docs/ATLAS_SETUP.md)
- 🔧 [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

## 🏭 Production Deployment

### Cloud-Native Setup 🚀

This Atlas-based configuration is designed for cloud deployment:

**Advantages:**
- ✅ **No Local Dependencies** - Only Kafka Connect needs to be deployed
- ✅ **MongoDB Atlas Integration** - Fully managed database service
- ✅ **External Kafka Support** - Works with any Kafka service (Confluent Cloud, AWS MSK, etc.)
- ✅ **Minimal Infrastructure** - Single container deployment
- ✅ **Environment-based Config** - All connections via environment variables

### Deployment Options

#### Option 1: Container Platforms
Deploy to any container platform:
```bash
# Build production image
docker build -t your-registry/kafka-connect-atlas .

# Push to registry
docker push your-registry/kafka-connect-atlas

# Deploy with your platform (Kubernetes, Docker Swarm, etc.)
# Set environment variables for Atlas and Kafka connections
```

#### Option 2: Azure Container Instances (Automated)
This project includes Azure deployment automation:

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