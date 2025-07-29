# MongoDB Kafka Connector - Ambiente de Produção

Este projeto fornece um ambiente completo e pronto para produção do **MongoDB Kafka Connector**, incluindo MongoDB Replica Set, Apache Kafka, Kafka Connect, e interfaces de gerenciamento.

## 🚀 Início Rápido

### Pré-requisitos
- Docker 20.0+
- Docker Compose 2.0+
- Make (opcional, mas recomendado)
- 8GB RAM disponível
- 10GB espaço em disco

### Configuração em 3 passos

1. **Clone e configure**:
```bash
git clone https://github.com/celfons/mongodb-kafka-connector-example.git
cd mongodb-kafka-connector-example
```

2. **Execute a configuração automática**:
```bash
make setup
```

3. **Acesse as interfaces**:
- **Kafka UI**: http://localhost:8080
- **Mongo Express**: http://localhost:8081
- **Kafka Connect API**: http://localhost:8083

## 📋 O que está incluído

### Serviços
- **MongoDB Replica Set** (3 nós) - Banco de dados principal
- **Apache Kafka** - Sistema de mensageria
- **Zookeeper** - Coordenação do Kafka
- **Kafka Connect** - Integração MongoDB ↔ Kafka
- **Kafka UI** - Interface web para Kafka
- **Mongo Express** - Interface web para MongoDB

### Recursos
- **Scripts automatizados** para inicialização e configuração
- **Health checks** integrados
- **Logging estruturado**
- **Dados de exemplo** para testes
- **Makefile** para automação
- **Documentação completa** em português

## 🛠️ Comandos Principais

### Setup e Inicialização
```bash
make setup           # Configuração completa automática
make up              # Iniciar serviços
make down            # Parar serviços
make restart         # Reiniciar serviços
```

### Configuração Manual (se necessário)
```bash
make init-replica    # Inicializar MongoDB Replica Set
make setup-connector # Configurar Kafka Connector
make sample-data     # Inserir dados de exemplo
```

### Monitoramento
```bash
make status          # Status dos containers
make health          # Verificação de saúde
make logs            # Visualizar logs
make logs-follow     # Seguir logs em tempo real
```

### Desenvolvimento
```bash
make test-connection # Testar conectividade
make debug-mongo     # Acessar MongoDB shell
make debug-kafka     # Listar tópicos Kafka
make debug-connect   # Status dos conectores
```

## 🔧 Configuração

### Variáveis de Ambiente
O arquivo `.env` é criado automaticamente a partir do `.env.example`. As principais configurações:

```env
# MongoDB
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password123
MONGO_REPLICA_SET_NAME=rs0

# Kafka
KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092

# Interfaces Web
ME_CONFIG_BASICAUTH_USERNAME=admin
ME_CONFIG_BASICAUTH_PASSWORD=express123
```

### Personalização
- Edite `.env` para alterar senhas e configurações
- Modifique `config/kafka-connect/mongodb-source-connector.json` para configurar o conector
- Ajuste `docker-compose.yml` para necessidades específicas

## 📊 Monitoramento e Logs

### Verificação de Saúde
```bash
./scripts/health-check.sh          # Verificação básica
./scripts/health-check.sh --detailed # Verificação detalhada
```

### Logs Estruturados
- Todos os serviços têm logs estruturados
- Health checks automáticos
- Logs salvos em `/tmp/*.log`

### Métricas
- Kafka UI fornece métricas detalhadas
- Mongo Express mostra estatísticas do banco
- Kafka Connect expõe métricas via REST API

## 🧪 Testando o Ambiente

### 1. Verificar Conectores
```bash
curl http://localhost:8083/connectors
```

### 2. Inserir Dados de Teste
```bash
make sample-data
```

### 3. Monitorar Mensagens no Kafka
```bash
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic mongodb.inventory.products \
  --from-beginning
```

### 4. Verificar no MongoDB
```bash
make debug-mongo
# No shell MongoDB:
use inventory
db.products.find().limit(5)
```

## 🔒 Segurança

### Credenciais Padrão
- **MongoDB**: admin/password123
- **Mongo Express**: admin/express123

### Para Produção
1. Altere todas as senhas no arquivo `.env`
2. Configure TLS/SSL para comunicação segura
3. Implemente autenticação adequada
4. Configure firewall e rede privada

## 📚 Documentação Adicional

- [**Guia de Setup Detalhado**](docs/SETUP.md)
- [**Integração com MongoDB Atlas**](docs/ATLAS_SETUP.md)
- [**Solução de Problemas**](docs/TROUBLESHOOTING.md)

## 🆘 Solução de Problemas Rápida

### Serviços não iniciam
```bash
make clean
make setup
```

### Replica Set não inicializa
```bash
make init-replica
```

### Conector com erro
```bash
make setup-connector
curl http://localhost:8083/connectors/mongodb-source-connector/status
```

### Ver logs de erro
```bash
make logs-connect
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🏷️ Versões

- MongoDB: 7.0
- Kafka: 7.4.0 (Confluent Platform)
- MongoDB Kafka Connector: 1.11.0

## 📞 Suporte

- **Issues**: Use o GitHub Issues para relatar problemas
- **Discussões**: Use GitHub Discussions para perguntas
- **Email**: [seu-email@exemplo.com]

---

**Desenvolvido com ❤️ para a comunidade brasileira de desenvolvedores**