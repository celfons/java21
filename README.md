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

### Azure Cloud Deployment (Automatizado) 🚀

Este projeto inclui uma esteira de CI/CD completa para deploy automatizado no Azure:

- ✅ **Build e Push automatizado** para Azure Container Registry (ACR)
- ✅ **Deploy para Azure Web App for Containers** ou Azure Container Instances
- ✅ **Configuração automática** de variáveis de ambiente
- ✅ **Integração com MongoDB Atlas** para produção
- ✅ **Verificação de saúde** automática da aplicação

#### 🔧 Configuração Rápida

1. **Configure os Secrets no GitHub** (obrigatório):
   ```bash
   # Azure Container Registry
   ACR_REGISTRY=<seu-registry>.azurecr.io
   ACR_USERNAME=<username-do-acr>
   ACR_PASSWORD=<password-do-acr>
   
   # Azure Web App
   AZURE_WEBAPP_NAME=<nome-do-web-app>
   AZURE_RESOURCE_GROUP=<nome-do-resource-group>
   
   # Credenciais Azure (JSON do service principal)
   AZURE_CREDENTIALS=<json-das-credenciais>
   
   # MongoDB Atlas produtivo
   MONGODB_ATLAS_CONNECTION_STRING=mongodb+srv://<user>:<pass>@<cluster>.mongodb.net/<db>
   ```

2. **Deploy Automático**:
   - Push na branch `main` → Deploy automático para produção
   - Dispatch manual → Deploy para staging/development

3. **Acesso à Aplicação**:
   - **URL**: `https://<webapp-name>.azurewebsites.net:8083`
   - **API Connectors**: `/connectors`
   - **Health Check**: `/connector-plugins`

#### 📚 Documentação Completa

Veja a [documentação completa do CI/CD](.github/workflows/README.md) para:
- Configuração detalhada dos secrets
- Como obter credenciais Azure
- Troubleshooting e solução de problemas
- Customização da pipeline

#### 🔐 Exemplos de Configuração dos Secrets

**Como configurar os secrets no GitHub:**

1. Acesse `Settings` → `Secrets and variables` → `Actions` no seu repositório
2. Clique em `New repository secret` para cada um:

```bash
# Exemplo de AZURE_CREDENTIALS (JSON do service principal):
{
  "clientId": "12345678-1234-1234-1234-123456789012",
  "clientSecret": "sua-secret-key-aqui",
  "subscriptionId": "87654321-4321-4321-4321-210987654321",
  "tenantId": "11111111-2222-3333-4444-555555555555"
}

# Exemplo de ACR_REGISTRY:
meuregistry.azurecr.io

# Exemplo de MONGODB_ATLAS_CONNECTION_STRING:
mongodb+srv://admin:password123@cluster0.abcde.mongodb.net/producao?retryWrites=true&w=majority
```

**Como obter as credenciais Azure:**
```bash
# 1. Login no Azure CLI
az login

# 2. Criar service principal
az ad sp create-for-rbac \
  --name "mongodb-kafka-cd" \
  --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth

# 3. Habilitar admin no ACR
az acr update --name SEU_REGISTRY --admin-enabled true

# 4. Obter credenciais do ACR
az acr credential show --name SEU_REGISTRY
```

### Deployment Tradicional

Para ambientes on-premise ou outras clouds:

1. **Security**: Configure authentication e TLS
2. **Scaling**: Aumente replica set e partições do Kafka
3. **Monitoring**: Configure logs e alertas
4. **Networking**: Configure segurança de rede adequada
5. **Backup**: Implemente estratégias de backup automatizado

Veja o [Guia de Setup para Produção](docs/SETUP.md#production-deployment) para detalhes.

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