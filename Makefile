# Makefile para MongoDB Kafka Connector Example
# Autor: MongoDB Kafka Connector Example
# Data: 2024

# Variáveis
COMPOSE_FILE = docker-compose.yml
ENV_FILE = .env
PROJECT_NAME = mongodb-kafka-example

# Cores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Comandos padrão
.PHONY: help setup up down restart logs status health clean init-replica setup-connector sample-data build rebuild

# Comando padrão
all: help

# Exibir ajuda
help:
	@echo "$(GREEN)MongoDB Kafka Connector Example - Makefile$(NC)"
	@echo ""
	@echo "$(YELLOW)Comandos disponíveis:$(NC)"
	@echo "  $(GREEN)setup$(NC)           - Configuração inicial completa"
	@echo "  $(GREEN)up$(NC)              - Iniciar todos os serviços"
	@echo "  $(GREEN)down$(NC)            - Parar todos os serviços"
	@echo "  $(GREEN)restart$(NC)         - Reiniciar todos os serviços"
	@echo "  $(GREEN)build$(NC)           - Build das imagens Docker"
	@echo "  $(GREEN)rebuild$(NC)         - Rebuild completo das imagens"
	@echo ""
	@echo "$(YELLOW)Comandos de configuração:$(NC)"
	@echo "  $(GREEN)init-replica$(NC)    - Inicializar MongoDB Replica Set"
	@echo "  $(GREEN)setup-connector$(NC) - Configurar MongoDB Kafka Connector"
	@echo "  $(GREEN)sample-data$(NC)     - Inserir dados de exemplo"
	@echo ""
	@echo "$(YELLOW)Comandos de monitoramento:$(NC)"
	@echo "  $(GREEN)logs$(NC)            - Visualizar logs de todos os serviços"
	@echo "  $(GREEN)logs-follow$(NC)     - Seguir logs em tempo real"
	@echo "  $(GREEN)status$(NC)          - Status dos containers"
	@echo "  $(GREEN)health$(NC)          - Verificação de saúde dos serviços"
	@echo "  $(GREEN)health-detailed$(NC) - Verificação detalhada de saúde"
	@echo ""
	@echo "$(YELLOW)Comandos de limpeza:$(NC)"
	@echo "  $(GREEN)clean$(NC)           - Limpar containers e volumes"
	@echo "  $(GREEN)clean-all$(NC)       - Limpeza completa (cuidado!)"
	@echo ""
	@echo "$(YELLOW)URLs de acesso:$(NC)"
	@echo "  Kafka UI:        http://localhost:8080"
	@echo "  Mongo Express:   http://localhost:8081"
	@echo "  Kafka Connect:   http://localhost:8083"

# Verificar se .env existe
check-env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "$(YELLOW)Arquivo .env não encontrado. Copiando .env.example...$(NC)"; \
		cp .env.example $(ENV_FILE); \
		echo "$(GREEN)Arquivo .env criado. Revise as configurações se necessário.$(NC)"; \
	fi

# Configuração inicial completa
setup: check-env
	@echo "$(GREEN)=== Configuração inicial do MongoDB Kafka Connector ===$(NC)"
	@echo "$(YELLOW)1. Construindo imagens Docker...$(NC)"
	@$(MAKE) build
	@echo "$(YELLOW)2. Iniciando serviços...$(NC)"
	@$(MAKE) up
	@echo "$(YELLOW)3. Aguardando serviços estarem prontos...$(NC)"
	@sleep 30
	@echo "$(YELLOW)4. Inicializando MongoDB Replica Set...$(NC)"
	@$(MAKE) init-replica
	@echo "$(YELLOW)5. Configurando Kafka Connector...$(NC)"
	@$(MAKE) setup-connector
	@echo "$(YELLOW)6. Inserindo dados de exemplo...$(NC)"
	@$(MAKE) sample-data
	@echo "$(GREEN)=== Configuração concluída! ===$(NC)"
	@$(MAKE) health

# Build das imagens Docker
build: check-env
	@echo "$(YELLOW)Construindo imagens Docker...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build

# Rebuild completo
rebuild: check-env
	@echo "$(YELLOW)Reconstruindo imagens Docker (sem cache)...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build --no-cache

# Iniciar serviços
up: check-env
	@echo "$(YELLOW)Iniciando serviços...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)Serviços iniciados!$(NC)"
	@$(MAKE) status

# Parar serviços
down:
	@echo "$(YELLOW)Parando serviços...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Serviços parados!$(NC)"

# Reiniciar serviços
restart:
	@echo "$(YELLOW)Reiniciando serviços...$(NC)"
	@$(MAKE) down
	@sleep 5
	@$(MAKE) up

# Inicializar MongoDB Replica Set
init-replica:
	@echo "$(YELLOW)Inicializando MongoDB Replica Set...$(NC)"
	@./scripts/init-replica.sh

# Configurar Kafka Connector
setup-connector:
	@echo "$(YELLOW)Configurando MongoDB Kafka Connector...$(NC)"
	@./scripts/setup-connector.sh

# Inserir dados de exemplo
sample-data:
	@echo "$(YELLOW)Inserindo dados de exemplo...$(NC)"
	@docker-compose exec -T mongo-primary mongosh mongodb://admin:password123@localhost:27017/inventory?authSource=admin --file /dev/stdin < scripts/sample-data.js

# Visualizar logs
logs:
	@docker-compose -f $(COMPOSE_FILE) logs --tail=100

# Seguir logs em tempo real
logs-follow:
	@docker-compose -f $(COMPOSE_FILE) logs -f

# Logs de um serviço específico
logs-mongo:
	@docker-compose -f $(COMPOSE_FILE) logs mongo-primary mongo-secondary-1 mongo-secondary-2

logs-kafka:
	@docker-compose -f $(COMPOSE_FILE) logs kafka zookeeper

logs-connect:
	@docker-compose -f $(COMPOSE_FILE) logs kafka-connect

logs-ui:
	@docker-compose -f $(COMPOSE_FILE) logs kafka-ui mongo-express

# Status dos containers
status:
	@echo "$(YELLOW)Status dos containers:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps

# Verificação de saúde
health:
	@echo "$(YELLOW)Executando verificação de saúde...$(NC)"
	@./scripts/health-check.sh

# Verificação detalhada de saúde
health-detailed:
	@echo "$(YELLOW)Executando verificação detalhada de saúde...$(NC)"
	@./scripts/health-check.sh --detailed

# Limpeza básica
clean:
	@echo "$(YELLOW)Limpando containers parados e imagens não utilizadas...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)Limpeza concluída!$(NC)"

# Limpeza completa (CUIDADO!)
clean-all:
	@echo "$(RED)ATENÇÃO: Esta operação removerá TODOS os dados!$(NC)"
	@read -p "Tem certeza? Digite 'yes' para continuar: " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "$(YELLOW)Removendo todos os containers, volumes e imagens...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down --volumes --remove-orphans
	@docker volume prune -f
	@docker image prune -a -f
	@echo "$(GREEN)Limpeza completa concluída!$(NC)"

# Comandos de desenvolvimento
dev-up:
	@echo "$(YELLOW)Iniciando ambiente de desenvolvimento...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up

dev-logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f kafka-connect mongo-primary

# Comandos de teste
test-connection:
	@echo "$(YELLOW)Testando conexões...$(NC)"
	@curl -s http://localhost:8083/ && echo "$(GREEN)✓ Kafka Connect OK$(NC)" || echo "$(RED)✗ Kafka Connect FAIL$(NC)"
	@curl -s http://localhost:8080/ && echo "$(GREEN)✓ Kafka UI OK$(NC)" || echo "$(RED)✗ Kafka UI FAIL$(NC)"
	@curl -s http://localhost:8081/ && echo "$(GREEN)✓ Mongo Express OK$(NC)" || echo "$(RED)✗ Mongo Express FAIL$(NC)"

# Comandos úteis para debugging
debug-mongo:
	@echo "$(YELLOW)Acessando MongoDB Primary...$(NC)"
	@docker-compose exec mongo-primary mongosh mongodb://admin:password123@localhost:27017/?authSource=admin

debug-kafka:
	@echo "$(YELLOW)Listando tópicos Kafka...$(NC)"
	@docker-compose exec kafka kafka-topics --bootstrap-server localhost:9092 --list

debug-connect:
	@echo "$(YELLOW)Status dos conectores...$(NC)"
	@curl -s http://localhost:8083/connectors | jq .

# Backup dos dados
backup:
	@echo "$(YELLOW)Criando backup dos dados MongoDB...$(NC)"
	@mkdir -p backups
	@docker-compose exec -T mongo-primary mongodump --uri="mongodb://admin:password123@localhost:27017/?authSource=admin" --archive --gzip > backups/mongodb-backup-$(shell date +%Y%m%d-%H%M%S).gz
	@echo "$(GREEN)Backup criado em backups/$(NC)"

# Restaurar backup
restore:
	@echo "$(YELLOW)Lista de backups disponíveis:$(NC)"
	@ls -la backups/ 2>/dev/null || echo "Nenhum backup encontrado"
	@read -p "Digite o nome do arquivo de backup: " backup_file; \
	if [ -f "backups/$$backup_file" ]; then \
		echo "$(YELLOW)Restaurando backup $$backup_file...$(NC)"; \
		docker-compose exec -T mongo-primary mongorestore --uri="mongodb://admin:password123@localhost:27017/?authSource=admin" --archive --gzip < "backups/$$backup_file"; \
		echo "$(GREEN)Backup restaurado!$(NC)"; \
	else \
		echo "$(RED)Arquivo de backup não encontrado!$(NC)"; \
	fi

# Informações do ambiente
info:
	@echo "$(GREEN)=== Informações do Ambiente ===$(NC)"
	@echo "$(YELLOW)Projeto:$(NC) $(PROJECT_NAME)"
	@echo "$(YELLOW)Compose File:$(NC) $(COMPOSE_FILE)"
	@echo "$(YELLOW)Env File:$(NC) $(ENV_FILE)"
	@echo ""
	@echo "$(YELLOW)Containers ativos:$(NC)"
	@docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}"
	@echo ""
	@echo "$(YELLOW)Volumes:$(NC)"
	@docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep $(PROJECT_NAME) || echo "Nenhum volume encontrado"
	@echo ""
	@echo "$(YELLOW)URLs de acesso:$(NC)"
	@echo "  Kafka UI:        http://localhost:8080"
	@echo "  Mongo Express:   http://localhost:8081"
	@echo "  Kafka Connect:   http://localhost:8083"