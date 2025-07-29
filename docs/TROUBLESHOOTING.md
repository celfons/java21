# Guia de Solução de Problemas

Este guia abrangente ajuda a diagnosticar e resolver problemas comuns no ambiente MongoDB Kafka Connector.

## 📋 Índice

1. [Diagnóstico Inicial](#diagnóstico-inicial)
2. [Problemas de Docker](#problemas-de-docker)
3. [Problemas do MongoDB](#problemas-do-mongodb)
4. [Problemas do Kafka](#problemas-do-kafka)
5. [Problemas do Kafka Connect](#problemas-do-kafka-connect)
6. [Problemas de Rede](#problemas-de-rede)
7. [Problemas de Performance](#problemas-de-performance)
8. [Problemas de Dados](#problemas-de-dados)
9. [Logs e Debugging](#logs-e-debugging)
10. [FAQ](#faq)

## 🔍 Diagnóstico Inicial

### Comandos de Diagnóstico Rápido

```bash
# Status geral do ambiente
make status
make health

# Verificar recursos do sistema
df -h
free -h
docker system df

# Verificar conectividade
make test-connection

# Logs recentes de todos os serviços
make logs | tail -100
```

### Checklist de Verificação

#### ✅ Pré-requisitos
- [ ] Docker está instalado e rodando
- [ ] Docker Compose está instalado
- [ ] Portas necessárias estão livres (8080, 8081, 8083, 9092, 27017-27019)
- [ ] Pelo menos 8GB de RAM disponível
- [ ] Pelo menos 10GB de espaço em disco livre

#### ✅ Configuração
- [ ] Arquivo `.env` existe e está configurado
- [ ] Permissões dos scripts estão corretas (`chmod +x scripts/*.sh`)
- [ ] Estrutura de diretórios está completa

#### ✅ Serviços
- [ ] Todos os containers estão rodando
- [ ] Health checks estão passando
- [ ] Logs não mostram erros críticos

## 🐳 Problemas de Docker

### Container não inicia

#### Sintomas:
```bash
ERROR: Container exits immediately
ERROR: Port already in use
ERROR: Out of memory
```

#### Diagnóstico:
```bash
# Verificar status dos containers
docker-compose ps

# Verificar logs específicos
docker-compose logs [service-name]

# Verificar uso de recursos
docker stats

# Verificar portas em uso
netstat -tlnp | grep -E ':(8080|8081|8083|9092|27017|27018|27019)'
```

#### Soluções:

**Porta em uso:**
```bash
# Identificar processo usando a porta
sudo lsof -i :8080

# Matar processo se necessário
sudo kill -9 [PID]

# Ou alterar porta no .env
KAFKA_UI_PORT=8090
```

**Memória insuficiente:**
```bash
# Limpar containers não utilizados
docker system prune -f

# Ajustar limites de memória no docker-compose.yml
services:
  kafka:
    mem_limit: 2g
    memswap_limit: 2g
```

**Permissões de arquivo:**
```bash
# Corrigir permissões
sudo chown -R $USER:$USER .
chmod +x scripts/*.sh
```

### Build falha

#### Sintomas:
```bash
ERROR: failed to build kafka-connect
ERROR: Package not found
```

#### Soluções:
```bash
# Rebuild sem cache
docker-compose build --no-cache

# Verificar conectividade com internet
curl -I https://packages.confluent.io

# Build individual
docker build -f Dockerfile.kafka-connect -t custom-kafka-connect .
```

### Volume não monta

#### Sintomas:
```bash
ERROR: Cannot create container
ERROR: Invalid mount config
```

#### Soluções:
```bash
# Verificar se diretórios existem
ls -la config/

# Criar diretórios se necessário
mkdir -p config/kafka-connect config/mongodb

# Verificar permissões
ls -la config/
```

## 🗄️ Problemas do MongoDB

### Replica Set não inicializa

#### Sintomas:
```bash
ERROR: not master and slaveOk=false
ERROR: no primary found
ERROR: Connection refused
```

#### Diagnóstico:
```bash
# Verificar status dos containers MongoDB
docker-compose ps | grep mongo

# Verificar logs do primary
docker-compose logs mongo-primary

# Tentar conectar manualmente
docker-compose exec mongo-primary mongosh --eval "rs.status()"
```

#### Soluções:

**Forçar reinicialização:**
```bash
# Parar MongoDB containers
docker-compose stop mongo-primary mongo-secondary-1 mongo-secondary-2

# Remover volumes (CUIDADO: apaga dados!)
docker volume rm $(docker volume ls -q | grep mongo)

# Reiniciar
docker-compose up -d mongo-primary mongo-secondary-1 mongo-secondary-2

# Aguardar e executar init
sleep 30
make init-replica
```

**Configuração manual:**
```bash
# Acessar primary
docker-compose exec mongo-primary mongosh

# Reconfigurar replica set
rs.reconfig({
  "_id": "rs0",
  "version": 1,
  "members": [
    {"_id": 0, "host": "mongo-primary:27017", "priority": 2},
    {"_id": 1, "host": "mongo-secondary-1:27017", "priority": 1},
    {"_id": 2, "host": "mongo-secondary-2:27017", "priority": 1}
  ]
}, {force: true})
```

### Problemas de autenticação

#### Sintomas:
```bash
ERROR: Authentication failed
ERROR: not authorized
```

#### Soluções:
```bash
# Verificar credenciais no .env
cat .env | grep MONGO

# Recriar usuário administrativo
docker-compose exec mongo-primary mongosh --eval "
use admin
db.createUser({
  user: 'admin',
  pwd: 'password123',
  roles: [{role: 'root', db: 'admin'}]
})
"
```

### Performance lenta

#### Sintomas:
- Consultas demoram muito
- High CPU/Memory usage
- Timeouts frequentes

#### Soluções:
```bash
# Verificar índices
docker-compose exec mongo-primary mongosh --eval "
use inventory
db.products.getIndexes()
"

# Criar índices necessários
docker-compose exec mongo-primary mongosh --eval "
use inventory
db.products.createIndex({created_at: -1})
db.products.createIndex({category: 1})
"

# Ajustar configurações no docker-compose.yml
mongo-primary:
  command: --replSet rs0 --bind_ip_all --wiredTigerCacheSizeGB 2
```

## 🚀 Problemas do Kafka

### Zookeeper não conecta

#### Sintomas:
```bash
ERROR: Connection to zookeeper failed
ERROR: zookeeper is not available
```

#### Diagnóstico:
```bash
# Verificar status do Zookeeper
docker-compose logs zookeeper

# Testar conectividade
docker-compose exec zookeeper bash -c "echo 'ruok' | nc localhost 2181"
```

#### Soluções:
```bash
# Reiniciar Zookeeper
docker-compose restart zookeeper

# Verificar se porta está livre
netstat -tlnp | grep 2181

# Limpar dados do Zookeeper se necessário
docker-compose down
docker volume rm $(docker volume ls -q | grep zookeeper)
docker-compose up -d zookeeper
```

### Kafka Broker não inicia

#### Sintomas:
```bash
ERROR: Kafka server failed to start
ERROR: Broker not available
```

#### Diagnóstico:
```bash
# Verificar logs do Kafka
docker-compose logs kafka

# Verificar configuração de listeners
docker-compose exec kafka env | grep KAFKA_
```

#### Soluções:

**Problemas de listener:**
```bash
# Verificar configuração no .env
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092

# Para acesso externo, usar IP real:
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://192.168.1.100:9092
```

**Problemas de ID do broker:**
```bash
# Verificar se KAFKA_BROKER_ID é único
# No docker-compose.yml, cada broker deve ter ID diferente
```

### Tópicos não aparecem

#### Sintomas:
```bash
ERROR: Topic not found
No topics found
```

#### Diagnóstico:
```bash
# Listar tópicos
docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# Verificar configuração de auto-create
docker-compose exec kafka env | grep AUTO_CREATE
```

#### Soluções:
```bash
# Criar tópico manualmente
docker-compose exec kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create \
  --topic test-topic \
  --partitions 3 \
  --replication-factor 1

# Habilitar auto-create
KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
```

## 🔌 Problemas do Kafka Connect

### Kafka Connect não inicia

#### Sintomas:
```bash
ERROR: Connect worker failed to start
ERROR: Unable to connect to Kafka
```

#### Diagnóstico:
```bash
# Verificar logs do Connect
docker-compose logs kafka-connect

# Verificar configuração
curl http://localhost:8083/
```

#### Soluções:

**Problemas de conectividade com Kafka:**
```bash
# Verificar se Kafka está acessível
docker-compose exec kafka-connect kafka-broker-api-versions --bootstrap-server kafka:29092

# Ajustar configuração de bootstrap servers
CONNECT_BOOTSTRAP_SERVERS=kafka:29092
```

**Problemas de plugins:**
```bash
# Verificar plugins instalados
curl http://localhost:8083/connector-plugins

# Reinstalar MongoDB connector
docker-compose build --no-cache kafka-connect
```

### Conector falha ao inicializar

#### Sintomas:
```bash
ERROR: Connector failed
ERROR: Task failed
```

#### Diagnóstico:
```bash
# Verificar status do conector
curl http://localhost:8083/connectors/mongodb-source-connector/status

# Verificar configuração
curl http://localhost:8083/connectors/mongodb-source-connector/config
```

#### Soluções:

**Problemas de configuração:**
```bash
# Verificar string de conexão
# No arquivo mongodb-source-connector.json
"connection.uri": "mongodb://admin:password123@mongo-primary:27017,mongo-secondary-1:27017,mongo-secondary-2:27017/?replicaSet=rs0&authSource=admin"

# Testar conectividade
docker-compose exec kafka-connect mongosh "mongodb://admin:password123@mongo-primary:27017/?authSource=admin"
```

**Problemas de permissões:**
```bash
# Verificar permissões do usuário MongoDB
docker-compose exec mongo-primary mongosh --eval "
use admin
db.auth('admin', 'password123')
db.runCommand({usersInfo: 'admin'})
"
```

### Change Streams não funcionam

#### Sintomas:
```bash
ERROR: Change stream failed
ERROR: Resume token not found
```

#### Soluções:
```bash
# Verificar se replica set está configurado
docker-compose exec mongo-primary mongosh --eval "rs.status()"

# Habilitar oplog
# Replica set já habilita oplog automaticamente

# Configurar conector para copy.existing
"copy.existing": "true",
"startup.mode": "copy_existing"
```

## 🌐 Problemas de Rede

### Containers não se comunicam

#### Sintomas:
```bash
ERROR: Connection refused
ERROR: Host not found
```

#### Diagnóstico:
```bash
# Verificar rede Docker
docker network ls
docker network inspect mongodb-kafka-network

# Testar conectividade entre containers
docker-compose exec kafka ping mongo-primary
docker-compose exec kafka-connect ping kafka
```

#### Soluções:
```bash
# Recriar rede
docker-compose down
docker network prune
docker-compose up -d

# Verificar configuração de rede no docker-compose.yml
networks:
  mongodb-kafka-network:
    driver: bridge
```

### Acesso externo não funciona

#### Sintomas:
- Interfaces web não abrem
- Conexão de fora do Docker falha

#### Soluções:
```bash
# Verificar binding de portas
docker-compose ps

# Verificar firewall
sudo ufw status
sudo ufw allow 8080
sudo ufw allow 8081
sudo ufw allow 8083

# Para ambientes cloud, verificar security groups
```

## ⚡ Problemas de Performance

### Alto uso de CPU

#### Diagnóstico:
```bash
# Verificar uso por container
docker stats

# Verificar processos internos
docker-compose exec kafka top
docker-compose exec mongo-primary top
```

#### Soluções:
```bash
# Ajustar configurações do Kafka
KAFKA_NUM_IO_THREADS=4
KAFKA_NUM_NETWORK_THREADS=3

# Ajustar configurações do MongoDB
mongo-primary:
  command: --replSet rs0 --bind_ip_all --wiredTigerCacheSizeGB 1
```

### Alto uso de memória

#### Soluções:
```bash
# Limitar memória dos containers
services:
  kafka:
    mem_limit: 2g
  mongo-primary:
    mem_limit: 1g
  kafka-connect:
    mem_limit: 1g

# Ajustar heap do Kafka
KAFKA_HEAP_OPTS="-Xmx1G -Xms1G"
```

### Latência alta

#### Soluções:
```bash
# Ajustar configurações de rede
KAFKA_SOCKET_SEND_BUFFER_BYTES=102400
KAFKA_SOCKET_RECEIVE_BUFFER_BYTES=102400

# Ajustar batch sizes
"poll.max.batch.size": "500",
"poll.await.time.ms": "1000"
```

## 📊 Problemas de Dados

### Dados não sincronizam

#### Diagnóstico:
```bash
# Verificar se dados existem no MongoDB
docker-compose exec mongo-primary mongosh --eval "
use inventory
db.products.countDocuments()
"

# Verificar se mensagens chegam no Kafka
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mongodb.inventory.products \
  --from-beginning \
  --timeout-ms 10000
```

#### Soluções:
```bash
# Reiniciar conector
curl -X POST http://localhost:8083/connectors/mongodb-source-connector/restart

# Verificar filtros no conector
# Remover pipelines complexos temporariamente

# Verificar se collection existe e tem dados
docker-compose exec mongo-primary mongosh --eval "
use inventory
db.products.findOne()
"
```

### Dados duplicados

#### Soluções:
```bash
# Configurar idempotência
"enable.idempotence": "true",
"document.id.strategy": "com.mongodb.kafka.connect.sink.processor.id.strategy.BsonOidStrategy"

# Usar estratégia de upsert
"writemodel.strategy": "com.mongodb.kafka.connect.sink.writemodel.strategy.ReplaceOneDefaultStrategy"
```

### Perda de dados

#### Prevenção:
```bash
# Configurar durabilidade no Kafka
KAFKA_DEFAULT_REPLICATION_FACTOR=3
KAFKA_MIN_INSYNC_REPLICAS=2

# Configurar write concern no MongoDB
"write.concern.w": "majority",
"write.concern.j": "true"

# Backup regular
make backup
```

## 📝 Logs e Debugging

### Habilitar Debug Logging

#### Kafka Connect:
```bash
# Editar config/kafka-connect/connect-log4j.properties
log4j.logger.com.mongodb.kafka=DEBUG
log4j.logger.com.mongodb=DEBUG
log4j.logger.org.apache.kafka.connect=DEBUG
```

#### MongoDB:
```bash
# Habilitar profiling
docker-compose exec mongo-primary mongosh --eval "
use inventory
db.setProfilingLevel(2)
"

# Ver operações lentas
docker-compose exec mongo-primary mongosh --eval "
use inventory
db.system.profile.find().limit(5).sort({ts: -1})
"
```

### Coleta de Logs

#### Script para coleta completa:
```bash
#!/bin/bash
mkdir -p troubleshooting-logs
cd troubleshooting-logs

# Informações do sistema
date > system-info.txt
docker --version >> system-info.txt
docker-compose --version >> system-info.txt
free -h >> system-info.txt
df -h >> system-info.txt

# Status dos containers
docker-compose ps > containers-status.txt

# Logs de todos os serviços
docker-compose logs --no-color > all-services.log

# Logs individuais
docker-compose logs mongo-primary > mongo-primary.log
docker-compose logs kafka > kafka.log
docker-compose logs kafka-connect > kafka-connect.log

# Configurações
cp ../.env env-config.txt
cp ../config/kafka-connect/mongodb-source-connector.json .

# Status dos conectores
curl -s http://localhost:8083/connectors > connectors-list.txt
curl -s http://localhost:8083/connectors/mongodb-source-connector/status > connector-status.txt

echo "Logs coletados em troubleshooting-logs/"
```

## ❓ FAQ

### Q: Como resetar completamente o ambiente?
```bash
make clean-all
make setup
```

### Q: Como alterar as senhas padrão?
```bash
# Editar .env
nano .env

# Recriar containers
docker-compose down
docker-compose up -d
make init-replica
```

### Q: Como adicionar mais nós ao MongoDB?
```bash
# Adicionar no docker-compose.yml
mongo-secondary-3:
  image: mongo:7.0
  # ... configuração similar

# Reconfigurar replica set
docker-compose exec mongo-primary mongosh --eval "
rs.add('mongo-secondary-3:27017')
"
```

### Q: Como migrar para produção?
1. Alterar todas as senhas
2. Configurar TLS/SSL
3. Usar volumes persistentes
4. Configurar monitoramento
5. Implementar backup automático

### Q: Como escalar horizontalmente?
```bash
# Adicionar mais brokers Kafka
# Adicionar mais tasks ao conector
"tasks.max": "3"

# Usar múltiplos conectores para collections diferentes
```

### Q: Posso usar com MongoDB Atlas?
Sim! Veja o [guia do Atlas](ATLAS_SETUP.md).

### Q: Como monitorar em produção?
```bash
# JMX metrics
# Prometheus + Grafana
# ELK Stack para logs
# MongoDB Atlas monitoring
```

## 🆘 Quando procurar ajuda

Se após seguir este guia o problema persistir:

1. **Colete informações**:
   ```bash
   # Execute o script de coleta de logs acima
   ./collect-troubleshooting-logs.sh
   ```

2. **Documente o problema**:
   - Passos para reproduzir
   - Mensagens de erro exatas
   - Configurações modificadas
   - Versões dos componentes

3. **Procure ajuda**:
   - GitHub Issues do projeto
   - MongoDB Community Forums
   - Confluent Community Slack
   - Stack Overflow (tags: mongodb, kafka, kafka-connect)

## 📚 Recursos Adicionais

### Documentação Oficial
- [MongoDB Troubleshooting](https://docs.mongodb.com/manual/faq/diagnostics/)
- [Kafka Connect Debugging](https://kafka.apache.org/documentation/#connect_development)
- [Docker Troubleshooting](https://docs.docker.com/config/troubleshooting/)

### Ferramentas de Debug
- MongoDB Compass (GUI para MongoDB)
- Kafka Tool (GUI para Kafka)
- Portainer (GUI para Docker)
- htop/top para monitoramento de sistema

### Scripts Úteis
```bash
# Health check detalhado
./scripts/health-check.sh --detailed

# Monitor contínuo
watch -n 5 'make status'

# Logs em tempo real
make logs-follow
```

---

**💡 Lembre-se**: A maioria dos problemas pode ser resolvida com um `make clean && make setup`. Quando em dúvida, comece do zero!