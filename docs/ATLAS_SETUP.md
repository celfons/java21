# Integração com MongoDB Atlas

Este guia explica como configurar o MongoDB Kafka Connector para funcionar com o MongoDB Atlas, o serviço de banco de dados em nuvem da MongoDB.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração do MongoDB Atlas](#configuração-do-mongodb-atlas)
3. [Configuração do Projeto](#configuração-do-projeto)
4. [Conectores para Atlas](#conectores-para-atlas)
5. [Teste e Verificação](#teste-e-verificação)
6. [Considerações de Produção](#considerações-de-produção)
7. [Solução de Problemas](#solução-de-problemas)

## 🔧 Pré-requisitos

### MongoDB Atlas
- Conta no MongoDB Atlas (gratuita disponível)
- Cluster configurado (M0 grátis ou superior)
- Usuário de banco de dados criado
- Lista de IPs permitidos configurada

### Projeto Local
- Ambiente local funcionando (veja [SETUP.md](SETUP.md))
- Acesso à internet
- String de conexão do Atlas

## 🌐 Configuração do MongoDB Atlas

### 1. Criar Conta e Cluster

#### Passo 1: Registro
1. Acesse [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Clique em "Try Free"
3. Complete o registro

#### Passo 2: Criar Cluster
1. Clique em "Build a Database"
2. Escolha "Shared" (gratuito)
3. Selecione a região mais próxima (ex: São Paulo)
4. Nomeie seu cluster (ex: "KafkaConnector")
5. Clique em "Create Cluster"

### 2. Configurar Segurança

#### Criar Usuário de Banco:
1. No painel, vá em "Database Access"
2. Clique em "Add New Database User"
3. Configure:
   ```
   Username: kafkauser
   Password: [gere uma senha segura]
   Database User Privileges: Atlas admin
   ```
4. Clique em "Add User"

#### Configurar Rede:
1. Vá em "Network Access"
2. Clique em "Add IP Address"
3. Para desenvolvimento: "Allow Access from Anywhere" (0.0.0.0/0)
4. Para produção: adicione apenas IPs específicos

### 3. Obter String de Conexão

1. Vá em "Database" > "Connect"
2. Escolha "Connect your application"
3. Selecione driver "Node.js" e versão "4.1 or later"
4. Copie a string de conexão:
```
mongodb+srv://kafkauser:<password>@kafkaconnector.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

## ⚙️ Configuração do Projeto

### 1. Atualizar Arquivo .env

Edite o arquivo `.env` e adicione as configurações do Atlas:

```env
# MongoDB Atlas Configuration
ATLAS_CONNECTION_STRING=mongodb+srv://kafkauser:SuaSenhaSegura@kafkaconnector.xxxxx.mongodb.net/?retryWrites=true&w=majority
ATLAS_DATABASE=inventory
ATLAS_COLLECTION=products

# Para usar Atlas como fonte primária (opcional)
USE_ATLAS_AS_PRIMARY=false

# Configurações específicas do Atlas
ATLAS_READ_PREFERENCE=primaryPreferred
ATLAS_READ_CONCERN=majority
ATLAS_WRITE_CONCERN=majority
```

### 2. Criar Configuração do Conector Atlas

Crie `config/kafka-connect/mongodb-atlas-source-connector.json`:

```json
{
  "name": "mongodb-atlas-source-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "tasks.max": "1",
    "connection.uri": "mongodb+srv://kafkauser:SuaSenhaSegura@kafkaconnector.xxxxx.mongodb.net/?retryWrites=true&w=majority",
    "database": "inventory",
    "collection": "products",
    "topic.prefix": "atlas",
    "change.stream.full.document": "updateLookup",
    "publish.full.document.only": "true",
    "output.format.value": "json",
    "output.format.key": "json",
    "copy.existing": "true",
    "copy.existing.max.threads": "1",
    "copy.existing.queue.size": "1000",
    "poll.max.batch.size": "1000",
    "poll.await.time.ms": "5000",
    "heartbeat.interval.ms": "10000",
    "errors.tolerance": "all",
    "errors.log.enable": "true",
    "errors.log.include.messages": "true",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false"
  }
}
```

### 3. Script para Configuração Atlas

Crie `scripts/setup-atlas-connector.sh`:

```bash
#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONNECT_URL="http://localhost:8083"
CONFIG_FILE="$PROJECT_DIR/config/kafka-connect/mongodb-atlas-source-connector.json"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
            ;;
    esac
}

main() {
    log INFO "=== Configurando MongoDB Atlas Connector ==="
    
    # Verificar se arquivo de configuração existe
    if [ ! -f "$CONFIG_FILE" ]; then
        log ERROR "Arquivo de configuração não encontrado: $CONFIG_FILE"
        exit 1
    fi
    
    # Verificar se Kafka Connect está disponível
    if ! curl -s "$CONNECT_URL/" > /dev/null; then
        log ERROR "Kafka Connect não está disponível em $CONNECT_URL"
        exit 1
    fi
    
    # Verificar se conector já existe
    CONNECTOR_NAME="mongodb-atlas-source-connector"
    if curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME" > /dev/null; then
        log WARN "Conector $CONNECTOR_NAME já existe. Removendo..."
        curl -s -X DELETE "$CONNECT_URL/connectors/$CONNECTOR_NAME"
        sleep 5
    fi
    
    # Criar conector
    log INFO "Criando conector Atlas..."
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data @"$CONFIG_FILE" \
        "$CONNECT_URL/connectors")
    
    if echo "$RESPONSE" | grep -q "error"; then
        log ERROR "Erro ao criar conector:"
        echo "$RESPONSE" | jq .
        exit 1
    else
        log INFO "Conector Atlas criado com sucesso!"
        echo "$RESPONSE" | jq .
    fi
    
    # Verificar status
    sleep 10
    log INFO "Verificando status do conector..."
    curl -s "$CONNECT_URL/connectors/$CONNECTOR_NAME/status" | jq .
    
    log INFO "=== Configuração do Atlas Connector concluída! ==="
}

main "$@"
```

Torne o script executável:
```bash
chmod +x scripts/setup-atlas-connector.sh
```

## 🔗 Conectores para Atlas

### 1. Conector Source (Atlas → Kafka)

Este conector lê mudanças do Atlas e publica no Kafka.

#### Configuração:
```json
{
  "name": "atlas-to-kafka",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb+srv://user:pass@cluster.mongodb.net/",
    "database": "production",
    "topic.prefix": "atlas",
    "change.stream.full.document": "updateLookup"
  }
}
```

#### Deploy:
```bash
./scripts/setup-atlas-connector.sh
```

### 2. Conector Sink (Kafka → Atlas)

Este conector lê mensagens do Kafka e escreve no Atlas.

#### Configuração `mongodb-atlas-sink-connector.json`:
```json
{
  "name": "kafka-to-atlas",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSinkConnector",
    "tasks.max": "1",
    "connection.uri": "mongodb+srv://user:pass@cluster.mongodb.net/",
    "database": "analytics",
    "collection": "events",
    "topics": "user-events,system-events",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "document.id.strategy": "com.mongodb.kafka.connect.sink.processor.id.strategy.BsonOidStrategy",
    "post.processor.chain": "com.mongodb.kafka.connect.sink.processor.DocumentIdAdder",
    "delete.on.null.values": "false",
    "writemodel.strategy": "com.mongodb.kafka.connect.sink.writemodel.strategy.ReplaceOneDefaultStrategy"
  }
}
```

#### Deploy Sink:
```bash
curl -X POST -H "Content-Type: application/json" \
  --data @config/kafka-connect/mongodb-atlas-sink-connector.json \
  http://localhost:8083/connectors
```

### 3. Configuração Híbrida

Para usar tanto MongoDB local quanto Atlas:

#### No Makefile, adicione:
```makefile
setup-atlas:
	@echo "$(YELLOW)Configurando conectores Atlas...$(NC)"
	@./scripts/setup-atlas-connector.sh

hybrid-setup:
	@echo "$(YELLOW)Configuração híbrida (Local + Atlas)...$(NC)"
	@$(MAKE) setup
	@$(MAKE) setup-atlas
```

## 🧪 Teste e Verificação

### 1. Inserir Dados no Atlas

Use o MongoDB Compass ou Atlas UI:

```javascript
// No Atlas shell
use inventory
db.products.insertOne({
  name: "Produto Atlas",
  description: "Produto inserido diretamente no Atlas",
  price: 149.99,
  source: "atlas",
  created_at: new Date()
})
```

### 2. Verificar Mensagens no Kafka

```bash
# Monitorar tópicos do Atlas
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic atlas.inventory.products \
  --from-beginning
```

### 3. Script de Teste Completo

Crie `scripts/test-atlas-integration.js`:

```javascript
// Teste de integração Atlas
const { MongoClient } = require('mongodb');

async function testAtlasIntegration() {
    const uri = "mongodb+srv://kafkauser:password@cluster.mongodb.net/";
    const client = new MongoClient(uri);
    
    try {
        await client.connect();
        console.log("Conectado ao Atlas!");
        
        const db = client.db("inventory");
        const collection = db.collection("products");
        
        // Inserir dados de teste
        const testProduct = {
            name: "Produto Teste Atlas",
            price: 99.99,
            category: "Test",
            inserted_at: new Date(),
            test_id: Math.random().toString(36)
        };
        
        const result = await collection.insertOne(testProduct);
        console.log("Produto inserido:", result.insertedId);
        
        // Aguardar e verificar
        setTimeout(async () => {
            const count = await collection.countDocuments();
            console.log("Total de documentos:", count);
        }, 5000);
        
    } catch (error) {
        console.error("Erro:", error);
    } finally {
        await client.close();
    }
}

testAtlasIntegration();
```

### 4. Verificação de Conectividade

```bash
# Teste de conectividade simples
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test-atlas-connection",
    "config": {
      "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
      "connection.uri": "'"$ATLAS_CONNECTION_STRING"'",
      "database": "test",
      "collection": "connectivity"
    }
  }' \
  http://localhost:8083/connectors

# Verificar status
curl http://localhost:8083/connectors/test-atlas-connection/status

# Remover teste
curl -X DELETE http://localhost:8083/connectors/test-atlas-connection
```

## 🏭 Considerações de Produção

### 1. Segurança

#### Gerenciamento de Credenciais:
```bash
# Usar secrets para credenciais
docker secret create atlas_uri "mongodb+srv://..."
```

#### Configuração com Secrets:
```yaml
kafka-connect:
  secrets:
    - atlas_uri
  environment:
    CONNECT_CONFIG_PROVIDERS: "file"
    CONNECT_CONFIG_PROVIDERS_FILE_CLASS: "org.apache.kafka.common.config.provider.FileConfigProvider"
```

### 2. Performance

#### Configurações Otimizadas:
```json
{
  "config": {
    "tasks.max": "3",
    "poll.max.batch.size": "1000",
    "poll.await.time.ms": "5000",
    "heartbeat.interval.ms": "10000",
    "copy.existing.max.threads": "3",
    "copy.existing.queue.size": "5000"
  }
}
```

### 3. Monitoramento

#### Métricas do Atlas:
- Use MongoDB Atlas monitoring
- Configure alertas para performance
- Monitor bandwidth usage

#### Métricas do Kafka Connect:
```bash
# JMX metrics
curl http://localhost:8083/metrics
```

### 4. Backup e Disaster Recovery

#### Configurar Múltiplas Regiões:
```json
{
  "config": {
    "connection.uri": "mongodb+srv://user:pass@cluster-primary.net/,mongodb+srv://user:pass@cluster-secondary.net/",
    "read.preference": "secondaryPreferred"
  }
}
```

## 🚨 Solução de Problemas

### 1. Problemas de Conectividade

#### Erro: "Connection refused"
```bash
# Verificar network access no Atlas
# Verificar string de conexão
# Testar conectividade
mongosh "mongodb+srv://cluster.mongodb.net/" --username kafkauser
```

#### Erro: "Authentication failed"
```bash
# Verificar credenciais
# Verificar permissões do usuário
# Verificar database name na URI
```

### 2. Problemas de Performance

#### Latência Alta:
- Escolher região Atlas mais próxima
- Usar read preference apropriado
- Ajustar batch sizes

#### Rate Limiting:
```json
{
  "config": {
    "poll.await.time.ms": "10000",
    "heartbeat.interval.ms": "30000"
  }
}
```

### 3. Problemas de Change Streams

#### Change Stream Error:
```bash
# Verificar se cluster suporta change streams (M10+)
# Para M0: usar copy.existing=true e polling
```

#### Resume Token Issues:
```json
{
  "config": {
    "change.stream.full.document": "updateLookup",
    "startup.mode": "latest"
  }
}
```

### 4. Debug e Logs

#### Aumentar Logging:
```properties
# Em connect-log4j.properties
log4j.logger.com.mongodb.kafka=DEBUG
log4j.logger.com.mongodb=DEBUG
```

#### Verificar Status Detalhado:
```bash
# Status completo do conector
curl http://localhost:8083/connectors/mongodb-atlas-source-connector/status | jq .

# Tasks específicas
curl http://localhost:8083/connectors/mongodb-atlas-source-connector/tasks/0/status | jq .
```

## 📊 Exemplo Completo: E-commerce com Atlas

### 1. Estrutura de Dados

#### No Atlas:
```javascript
// Database: ecommerce
// Collections: products, orders, customers

// Produtos
db.products.insertMany([
  {
    sku: "LAPTOP-001",
    name: "Laptop Professional",
    price: 2999.99,
    category: "electronics",
    stock: 50,
    updated_at: new Date()
  }
]);

// Pedidos
db.orders.insertMany([
  {
    order_id: "ORD-2024-001",
    customer_id: "CUST-001",
    products: [
      { sku: "LAPTOP-001", quantity: 1, price: 2999.99 }
    ],
    total: 2999.99,
    status: "confirmed",
    created_at: new Date()
  }
]);
```

### 2. Conectores Específicos

#### Products Connector:
```json
{
  "name": "atlas-products-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb+srv://...",
    "database": "ecommerce",
    "collection": "products",
    "topic.prefix": "ecommerce",
    "change.stream.full.document": "updateLookup"
  }
}
```

#### Orders Connector:
```json
{
  "name": "atlas-orders-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb+srv://...",
    "database": "ecommerce",
    "collection": "orders",
    "topic.prefix": "ecommerce",
    "pipeline": "[{\"$match\": {\"fullDocument.status\": \"confirmed\"}}]"
  }
}
```

### 3. Processamento de Eventos

#### Consumir no Kafka:
```bash
# Monitorar novos produtos
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic ecommerce.ecommerce.products

# Monitorar pedidos confirmados
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic ecommerce.ecommerce.orders
```

## 📚 Recursos Adicionais

### Documentação Oficial
- [MongoDB Atlas](https://docs.atlas.mongodb.com/)
- [MongoDB Kafka Connector](https://docs.mongodb.com/kafka-connector/current/)
- [Confluent Platform](https://docs.confluent.io/)

### Tutoriais e Exemplos
- [Atlas Getting Started](https://docs.atlas.mongodb.com/getting-started/)
- [Kafka Connect Tutorial](https://kafka.apache.org/documentation/#connect)

### Ferramentas Úteis
- [MongoDB Compass](https://www.mongodb.com/products/compass)
- [Kafka Tool](https://www.kafkatool.com/)
- [Atlas CLI](https://docs.atlas.mongodb.com/atlas-cli/)

---

**🌟 Dica**: Começe com um cluster M0 gratuito para desenvolvimento e depois migre para M10+ para produção com change streams completos!