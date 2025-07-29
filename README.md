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

## ⚙️ Conectores Múltiplos com Filtros por Operação

### 🎯 Visão Geral

Este projeto agora inclui **conectores separados** para diferentes tipos de operação do MongoDB, permitindo que cada tipo de evento seja enviado para tópicos Kafka distintos:

- **🟢 INSERT Connector**: Captura apenas operações de inserção → Tópico `mongo-insert.*`
- **🟡 UPDATE Connector**: Captura apenas operações de atualização → Tópico `mongo-update.*`
- **🔴 DELETE Connector**: Captura apenas operações de exclusão → Tópico `mongo-delete.*`

### 📁 Estrutura dos Conectores

```
connectors/
├── mongo-insert-connector.json   # Filtra apenas operações INSERT
├── mongo-update-connector.json   # Filtra apenas operações UPDATE
└── mongo-delete-connector.json   # Filtra apenas operações DELETE
```

### 🔧 Configuração dos Filtros

Cada conector utiliza o **MongoDB Change Stream** com pipeline de agregação para filtrar por `operationType`:

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

**Tipos de operação disponíveis:**
- `insert` - Inserção de novos documentos
- `update` - Atualização de documentos existentes
- `delete` - Exclusão de documentos
- `replace` - Substituição completa de documentos

### 🚀 Como Usar os Conectores Múltiplos

#### Opção 1: Setup Completo (Recomendado para novos projetos)
```bash
# 1. Configuração inicial completa
make dev-setup

# 2. Configurar conectores múltiplos com filtros
make setup-multi-connectors
```

#### Opção 2: Apenas Conectores Múltiplos (Para projetos existentes)
```bash
# Configurar apenas os conectores com filtros (requer ambiente já iniciado)
make setup-multi-connectors
```

#### Opção 3: Manual
```bash
# Executar script diretamente
./scripts/setup-multi-connectors.sh
```

### 📋 Tópicos Kafka Criados

Após a configuração, os seguintes tópicos serão criados automaticamente:

| Conector | Tópico de Exemplo | Descrição |
|----------|------------------|-----------|
| **INSERT** | `mongo-insert.exemplo.users` | Apenas inserções de usuários |
| **UPDATE** | `mongo-update.exemplo.users` | Apenas atualizações de usuários |
| **DELETE** | `mongo-delete.exemplo.users` | Apenas exclusões de usuários |
| **INSERT** | `mongo-insert.exemplo.products` | Apenas inserções de produtos |
| **UPDATE** | `mongo-update.exemplo.products` | Apenas atualizações de produtos |
| **DELETE** | `mongo-delete.exemplo.products` | Apenas exclusões de produtos |

### 📄 Exemplo de Mensagem Kafka

**Mensagem de INSERT** (tópico: `mongo-insert.exemplo.users`):
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

**Mensagem de UPDATE** (tópico: `mongo-update.exemplo.users`):
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

**Mensagem de DELETE** (tópico: `mongo-delete.exemplo.users`):
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

### 🧪 Testando os Filtros

1. **Inicie o ambiente**:
   ```bash
   make dev-setup
   make setup-multi-connectors
   ```

2. **Insira dados de teste**:
   ```bash
   make sample-data
   ```

3. **Monitore os tópicos** em tempo real:
   ```bash
   # Opção 1: Via interface web (Recomendado)
   # Acesse http://localhost:8080 e visualize os tópicos
   
   # Opção 2: Via linha de comando
   make monitor-topics
   ```

4. **Teste operações específicas**:
   ```bash
   # Conectar ao MongoDB e fazer operações manuais
   docker-compose exec mongo1 mongosh "mongodb://admin:password123@localhost:27017/exemplo?authSource=admin"
   
   # Inserir documento (aparecerá em mongo-insert.exemplo.*)
   db.users.insertOne({name: "Teste Insert", email: "insert@test.com"})
   
   # Atualizar documento (aparecerá em mongo-update.exemplo.*)
   db.users.updateOne({name: "Teste Insert"}, {$set: {status: "updated"}})
   
   # Excluir documento (aparecerá em mongo-delete.exemplo.*)
   db.users.deleteOne({name: "Teste Insert"})
   ```

### 🔍 Monitoramento e Verificação

#### Via Kafka UI (Interface Web)
- **URL**: http://localhost:8080
- Visualize mensagens em tempo real
- Analise configuração dos conectores
- Monitore performance e métricas

#### Via API do Kafka Connect
```bash
# Status de todos os conectores
curl -s http://localhost:8083/connectors | jq

# Status específico do conector INSERT
curl -s http://localhost:8083/connectors/mongo-insert-connector/status | jq

# Status específico do conector UPDATE
curl -s http://localhost:8083/connectors/mongo-update-connector/status | jq

# Status específico do conector DELETE
curl -s http://localhost:8083/connectors/mongo-delete-connector/status | jq
```

### ⚠️ Observações Importantes

1. **Change Streams**: Requer MongoDB em modo Replica Set (já configurado neste projeto)
2. **Performance**: Conectores múltiplos consomem mais recursos - monitore o uso
3. **Dead Letter Queues**: Cada conector tem sua própria DLQ para tratamento de erros
4. **Tópicos**: Os tópicos são criados automaticamente quando as primeiras mensagens chegam

### 🎛️ Personalização dos Conectores

Para personalizar os conectores, edite os arquivos JSON em `connectors/`:

```bash
# Editar configuração do conector INSERT
nano connectors/mongo-insert-connector.json

# Aplicar mudanças (requer reinicialização do conector)
make setup-multi-connectors
```

**Configurações que podem ser personalizadas:**
- Database e collections específicas
- Filtros mais complexos no pipeline
- Configurações de performance (batch size, poll intervals)
- Tópicos de destino
- Formatação das mensagens

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