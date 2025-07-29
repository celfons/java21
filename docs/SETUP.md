# Guia de Setup Detalhado

Este guia fornece instruções detalhadas para configurar e personalizar o ambiente MongoDB Kafka Connector.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Inicialização](#inicialização)
5. [Verificação](#verificação)
6. [Personalização](#personalização)
7. [Solução de Problemas](#solução-de-problemas)

## 🔧 Pré-requisitos

### Sistema Operacional
- **Linux**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- **macOS**: 10.14+
- **Windows**: 10+ (com WSL2 recomendado)

### Software Necessário

#### Docker & Docker Compose
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose
sudo usermod -aG docker $USER

# CentOS/RHEL
sudo yum install docker docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# macOS (via Homebrew)
brew install docker docker-compose

# Verificar instalação
docker --version
docker-compose --version
```

#### Ferramentas Auxiliares
```bash
# Ubuntu/Debian
sudo apt install curl jq make git

# CentOS/RHEL
sudo yum install curl jq make git

# macOS
brew install curl jq make git
```

### Recursos de Sistema
- **RAM**: Mínimo 8GB, recomendado 16GB
- **CPU**: Mínimo 4 cores
- **Disco**: Mínimo 10GB livres
- **Rede**: Portas 8080, 8081, 8083, 9092, 27017-27019 disponíveis

## 🚀 Instalação

### 1. Clone do Repositório
```bash
git clone https://github.com/celfons/mongodb-kafka-connector-example.git
cd mongodb-kafka-connector-example
```

### 2. Verificar Estrutura do Projeto
```bash
tree -L 3
```

Estrutura esperada:
```
.
├── README.md
├── docker-compose.yml
├── Dockerfile.kafka-connect
├── Makefile
├── .env.example
├── config/
│   ├── kafka-connect/
│   │   ├── mongodb-source-connector.json
│   │   └── connect-log4j.properties
│   └── mongodb/
│       └── replica-init.js
├── scripts/
│   ├── init-replica.sh
│   ├── setup-connector.sh
│   ├── health-check.sh
│   └── sample-data.js
└── docs/
    ├── SETUP.md
    ├── ATLAS_SETUP.md
    └── TROUBLESHOOTING.md
```

## ⚙️ Configuração

### 1. Arquivo de Ambiente
```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar configurações
nano .env
```

### 2. Configurações Importantes

#### MongoDB
```env
# Credenciais do administrador
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=SuaSenhaSegura123

# Nome do Replica Set
MONGO_REPLICA_SET_NAME=rs0

# Portas (altere se necessário)
MONGO_PORT=27017
MONGO_SECONDARY_PORT_1=27018
MONGO_SECONDARY_PORT_2=27019
```

#### Kafka
```env
# Listeners (importante para acesso externo)
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://SEU_IP:9092

# Para desenvolvimento local, use:
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092

# Para servidor remoto, use o IP público:
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://192.168.1.100:9092
```

#### Interfaces Web
```env
# Mongo Express
ME_CONFIG_BASICAUTH_USERNAME=admin
ME_CONFIG_BASICAUTH_PASSWORD=SuaSenhaExpress123

# Kafka UI (sem autenticação por padrão)
KAFKA_UI_CLUSTERS_0_NAME=producao
```

### 3. Configuração do Conector

Edite `config/kafka-connect/mongodb-source-connector.json`:

```json
{
  "name": "mongodb-source-connector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb://admin:SuaSenhaSegura123@mongo-primary:27017,mongo-secondary-1:27017,mongo-secondary-2:27017/?replicaSet=rs0&authSource=admin",
    "database": "seu_database",
    "collection": "sua_collection",
    "topic.prefix": "mongodb"
  }
}
```

## 🏁 Inicialização

### 1. Setup Automático (Recomendado)
```bash
make setup
```

Este comando executará:
1. Verificação de dependências
2. Build das imagens Docker
3. Inicialização dos serviços
4. Configuração do Replica Set
5. Setup do Kafka Connector
6. Inserção de dados de exemplo

### 2. Setup Manual (Passo a Passo)

#### Passo 1: Build das Imagens
```bash
make build
```

#### Passo 2: Iniciar Serviços
```bash
make up
```

#### Passo 3: Aguardar Inicialização
```bash
# Aguardar ~60 segundos para todos os serviços estarem prontos
sleep 60
make status
```

#### Passo 4: Configurar MongoDB Replica Set
```bash
make init-replica
```

#### Passo 5: Configurar Kafka Connector
```bash
make setup-connector
```

#### Passo 6: Inserir Dados de Exemplo
```bash
make sample-data
```

## ✅ Verificação

### 1. Status dos Serviços
```bash
make status
```

Saída esperada:
```
       Name                     Command               State                    Ports
kafka             /etc/confluent/docker/run        Up      0.0.0.0:9092->9092/tcp
kafka-connect     /etc/confluent/docker/run        Up      0.0.0.0:8083->8083/tcp
kafka-ui          /bin/sh -c java $JAVA_OPTS ...   Up      0.0.0.0:8080->8080/tcp
mongo-express     tini -- /docker-entrypoint.sh    Up      0.0.0.0:8081->8081/tcp
mongo-primary     docker-entrypoint.sh --repl ...  Up      0.0.0.0:27017->27017/tcp
mongo-secondary-1 docker-entrypoint.sh --repl ...  Up      0.0.0.0:27018->27017/tcp
mongo-secondary-2 docker-entrypoint.sh --repl ...  Up      0.0.0.0:27019->27017/tcp
zookeeper         /etc/confluent/docker/run        Up      0.0.0.0:2181->2181/tcp
```

### 2. Verificação de Saúde
```bash
make health
```

### 3. Testar Conectividade
```bash
make test-connection
```

### 4. Verificar Conector
```bash
curl http://localhost:8083/connectors/mongodb-source-connector/status
```

### 5. Verificar Tópicos Kafka
```bash
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### 6. Testar Fluxo de Dados

#### Inserir dados no MongoDB:
```bash
make debug-mongo
```

No shell MongoDB:
```javascript
use inventory
db.products.insertOne({
  name: "Produto Teste",
  price: 99.99,
  created_at: new Date()
})
```

#### Verificar mensagens no Kafka:
```bash
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mongodb.inventory.products \
  --from-beginning
```

## 🎨 Personalização

### 1. Adicionar Novos Bancos/Collections

#### Criar novo conector:
```bash
cat > config/kafka-connect/novo-conector.json << EOF
{
  "name": "novo-conector",
  "config": {
    "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
    "connection.uri": "mongodb://admin:password123@mongo-primary:27017/?replicaSet=rs0&authSource=admin",
    "database": "novo_database",
    "collection": "nova_collection",
    "topic.prefix": "novo_topico"
  }
}
EOF
```

#### Aplicar configuração:
```bash
curl -X POST -H "Content-Type: application/json" \
  --data @config/kafka-connect/novo-conector.json \
  http://localhost:8083/connectors
```

### 2. Configurar Múltiplos Conectores

Crie um script para aplicar múltiplos conectores:
```bash
#!/bin/bash
for config in config/kafka-connect/*.json; do
  echo "Aplicando $config..."
  curl -X POST -H "Content-Type: application/json" \
    --data @"$config" \
    http://localhost:8083/connectors
  sleep 5
done
```

### 3. Personalizar Logging

Edite `config/kafka-connect/connect-log4j.properties`:
```properties
# Aumentar nível de debug para MongoDB
log4j.logger.com.mongodb.kafka=DEBUG

# Adicionar appender para arquivo específico
log4j.appender.mongodbAppender=org.apache.log4j.FileAppender
log4j.appender.mongodbAppender.File=/tmp/mongodb-connector.log
```

### 4. Configurar Retenção de Tópicos

```bash
# Configurar retenção de 7 dias
docker-compose exec kafka kafka-configs \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name mongodb.inventory.products \
  --alter \
  --add-config retention.ms=604800000
```

### 5. Adicionar Autenticação SASL (Produção)

Edite `docker-compose.yml`:
```yaml
kafka:
  environment:
    KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
    KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
    KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SASL_PLAINTEXT
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,SASL_PLAINTEXT:SASL_PLAINTEXT
    KAFKA_OPTS: "-Djava.security.auth.login.config=/etc/kafka/kafka_server_jaas.conf"
```

## 🔧 Configurações Avançadas

### 1. Ajuste de Performance

#### MongoDB:
```yaml
mongo-primary:
  command: --replSet rs0 --bind_ip_all --wiredTigerCacheSizeGB 2
```

#### Kafka:
```yaml
kafka:
  environment:
    KAFKA_NUM_IO_THREADS: 8
    KAFKA_NUM_NETWORK_THREADS: 3
    KAFKA_LOG_FLUSH_INTERVAL_MESSAGES: 10000
```

### 2. Configurar SSL/TLS

#### MongoDB com SSL:
```yaml
mongo-primary:
  volumes:
    - ./ssl/mongodb.pem:/etc/ssl/mongodb.pem
  command: --replSet rs0 --sslMode requireSSL --sslPEMKeyFile /etc/ssl/mongodb.pem
```

#### Kafka com SSL:
```yaml
kafka:
  environment:
    KAFKA_SSL_KEYSTORE_FILENAME: kafka.keystore.jks
    KAFKA_SSL_KEYSTORE_CREDENTIALS: keystore_creds
    KAFKA_SSL_KEY_CREDENTIALS: key_creds
    KAFKA_SECURITY_INTER_BROKER_PROTOCOL: SSL
```

### 3. Monitoramento com Prometheus

Adicione ao `docker-compose.yml`:
```yaml
prometheus:
  image: prom/prometheus
  ports:
    - "9090:9090"
  volumes:
    - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml

jmx-exporter:
  image: sscaling/jmx-prometheus-exporter
  ports:
    - "5556:5556"
```

## 🚨 Solução de Problemas Comuns

### 1. Erro de Permissão Docker
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Portas em Uso
```bash
# Verificar portas em uso
netstat -tlnp | grep -E ':(8080|8081|8083|9092|27017)'

# Alterar portas no .env se necessário
```

### 3. Memória Insuficiente
```bash
# Verificar uso de memória
docker stats

# Ajustar limites no docker-compose.yml
services:
  kafka:
    mem_limit: 2g
    memswap_limit: 2g
```

### 4. Replica Set não Inicializa
```bash
# Verificar logs
make logs-mongo

# Forçar reinicialização
docker-compose exec mongo-primary mongosh --eval "rs.reconfig({...}, {force: true})"
```

### 5. Kafka Connect não Conecta
```bash
# Verificar conectividade
docker-compose exec kafka-connect curl -f http://localhost:8083/

# Verificar plugins
curl http://localhost:8083/connector-plugins | jq '.[] | select(.class | contains("MongoSourceConnector"))'
```

## 📚 Próximos Passos

1. [Configurar MongoDB Atlas](ATLAS_SETUP.md)
2. [Guia completo de troubleshooting](TROUBLESHOOTING.md)
3. [Configurar ambiente de produção](PRODUCTION.md)

## 🆘 Suporte

Se você encontrar problemas não cobertos neste guia:

1. Verifique os logs: `make logs`
2. Execute verificação de saúde: `make health --detailed`
3. Consulte [Troubleshooting](TROUBLESHOOTING.md)
4. Abra uma issue no GitHub

---

**💡 Dica**: Mantenha este documento atualizado conforme suas personalizações!