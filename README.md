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
```

**That's it!** 🎉 Your environment is ready.

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

## 🛠️ Available Commands

```bash
# Essential commands
make help          # Show all available commands
make status        # Check service health
make logs          # View all service logs

# Development
make dev-setup     # Complete development setup
make sample-data   # Insert test data
make monitor-topics # Watch Kafka messages

# Management
make clean         # Clean up everything
make backup        # Backup MongoDB data
make restart-*     # Restart specific services
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

For production environments:

1. **Security**: Configure authentication and TLS
2. **Scaling**: Increase replica set and Kafka partitions
3. **Monitoring**: Set up logging and alerting
4. **Networking**: Configure proper network security
5. **Backup**: Implement automated backup strategies

See [Production Setup Guide](docs/SETUP.md#production-deployment) for details.

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