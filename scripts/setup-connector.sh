#!/bin/bash

# Script para configuração do MongoDB Kafka Connector
# Autor: MongoDB Kafka Connector Example
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/setup-connector.log"
CONNECT_URL="http://localhost:8083"
CONNECTOR_CONFIG="$PROJECT_DIR/config/kafka-connect/mongodb-source-connector.json"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
    esac
}

# Função para verificar se o comando existe
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log ERROR "Comando '$1' não encontrado. Por favor, instale antes de continuar."
        exit 1
    fi
}

# Função para aguardar serviço estar pronto
wait_for_service() {
    local service_name="$1"
    local check_command="$2"
    local max_attempts="${3:-30}"
    local attempt=1
    
    log INFO "Aguardando $service_name estar pronto..."
    
    while [ $attempt -le $max_attempts ]; do
        if eval "$check_command" &> /dev/null; then
            log INFO "$service_name está pronto!"
            return 0
        fi
        
        log DEBUG "Tentativa $attempt/$max_attempts - $service_name não está pronto ainda..."
        sleep 10
        ((attempt++))
    done
    
    log ERROR "$service_name não ficou pronto após $max_attempts tentativas"
    return 1
}

# Função para verificar conectores existentes
list_connectors() {
    log INFO "Listando conectores existentes..."
    if curl -s "$CONNECT_URL/connectors" | jq . 2>/dev/null; then
        return 0
    else
        log WARN "Não foi possível listar conectores ou nenhum conector encontrado"
        return 1
    fi
}

# Função para verificar status do conector
check_connector_status() {
    local connector_name="$1"
    log INFO "Verificando status do conector '$connector_name'..."
    
    local status_response
    status_response=$(curl -s "$CONNECT_URL/connectors/$connector_name/status" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "$status_response" | jq .
        local state=$(echo "$status_response" | jq -r '.connector.state')
        
        if [ "$state" = "RUNNING" ]; then
            log INFO "Conector '$connector_name' está rodando com sucesso!"
            return 0
        else
            log WARN "Conector '$connector_name' está no estado: $state"
            return 1
        fi
    else
        log ERROR "Não foi possível verificar o status do conector '$connector_name'"
        return 1
    fi
}

# Função para deletar conector existente
delete_connector() {
    local connector_name="$1"
    log INFO "Removendo conector existente '$connector_name'..."
    
    if curl -s -X DELETE "$CONNECT_URL/connectors/$connector_name" &> /dev/null; then
        log INFO "Conector '$connector_name' removido com sucesso"
        sleep 5  # Aguardar cleanup
        return 0
    else
        log ERROR "Erro ao remover conector '$connector_name'"
        return 1
    fi
}

# Função para criar/atualizar conector
deploy_connector() {
    local config_file="$1"
    local connector_name
    
    # Extrair nome do conector do arquivo JSON
    connector_name=$(jq -r '.name' "$config_file")
    
    if [ -z "$connector_name" ] || [ "$connector_name" = "null" ]; then
        log ERROR "Nome do conector não encontrado no arquivo de configuração"
        exit 1
    fi
    
    log INFO "Configurando conector '$connector_name'..."
    
    # Verificar se conector já existe
    if curl -s "$CONNECT_URL/connectors/$connector_name" &> /dev/null; then
        log WARN "Conector '$connector_name' já existe. Removendo..."
        delete_connector "$connector_name"
    fi
    
    # Criar novo conector
    log INFO "Criando conector '$connector_name'..."
    
    local response
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data "@$config_file" \
        "$CONNECT_URL/connectors")
    
    if [ $? -eq 0 ]; then
        log INFO "Conector criado com sucesso!"
        echo "$response" | jq .
        
        # Aguardar e verificar status
        sleep 10
        check_connector_status "$connector_name"
    else
        log ERROR "Erro ao criar conector. Resposta:"
        echo "$response"
        exit 1
    fi
}

# Função para verificar tópicos no Kafka
check_kafka_topics() {
    log INFO "Verificando tópicos criados no Kafka..."
    
    if docker-compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -q "mongodb"; then
        log INFO "Tópicos MongoDB encontrados:"
        docker-compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list | grep "mongodb"
    else
        log WARN "Nenhum tópico MongoDB encontrado ainda"
    fi
}

# Função para testar conectividade
test_connectivity() {
    log INFO "Testando conectividade dos serviços..."
    
    # Testar MongoDB
    if docker-compose exec -T mongo-primary mongosh --eval 'db.adminCommand({ping: 1})' &> /dev/null; then
        log INFO "✓ MongoDB está acessível"
    else
        log ERROR "✗ MongoDB não está acessível"
        return 1
    fi
    
    # Testar Kafka
    if docker-compose exec -T kafka kafka-broker-api-versions --bootstrap-server localhost:9092 &> /dev/null; then
        log INFO "✓ Kafka está acessível"
    else
        log ERROR "✗ Kafka não está acessível"
        return 1
    fi
    
    # Testar Kafka Connect
    if curl -s "$CONNECT_URL/" &> /dev/null; then
        log INFO "✓ Kafka Connect está acessível"
    else
        log ERROR "✗ Kafka Connect não está acessível"
        return 1
    fi
}

# Função principal
main() {
    log INFO "=== Iniciando configuração do MongoDB Kafka Connector ==="
    
    # Verificar dependências
    check_command "curl"
    check_command "jq"
    check_command "docker"
    check_command "docker-compose"
    
    # Navegar para o diretório do projeto
    cd "$PROJECT_DIR"
    
    # Verificar se arquivo de configuração existe
    if [ ! -f "$CONNECTOR_CONFIG" ]; then
        log ERROR "Arquivo de configuração não encontrado: $CONNECTOR_CONFIG"
        exit 1
    fi
    
    # Testar conectividade
    test_connectivity
    
    # Aguardar Kafka Connect estar pronto
    wait_for_service "Kafka Connect" \
        "curl -s $CONNECT_URL/" \
        60
    
    # Verificar plugins disponíveis
    log INFO "Verificando plugins disponíveis no Kafka Connect..."
    curl -s "$CONNECT_URL/connector-plugins" | jq '.[] | select(.class | contains("MongoSourceConnector"))'
    
    # Listar conectores existentes
    list_connectors
    
    # Fazer deploy do conector
    deploy_connector "$CONNECTOR_CONFIG"
    
    # Aguardar estabilização
    sleep 15
    
    # Verificar tópicos criados
    check_kafka_topics
    
    # Informações finais
    log INFO "=== Configuração concluída com sucesso! ==="
    log INFO ""
    log INFO "URLs de acesso:"
    log INFO "  - Kafka Connect REST API: $CONNECT_URL"
    log INFO "  - Kafka UI: http://localhost:8080"
    log INFO "  - Mongo Express: http://localhost:8081"
    log INFO ""
    log INFO "Para verificar o status do conector:"
    log INFO "  curl $CONNECT_URL/connectors/mongodb-source-connector/status"
    log INFO ""
    log INFO "Para ver mensagens no Kafka:"
    log INFO "  docker-compose exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic mongodb.inventory.products --from-beginning"
    log INFO ""
    log INFO "Logs salvos em: $LOG_FILE"
}

# Função para cleanup em caso de erro
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log ERROR "Script falhou com código de saída $exit_code"
        log INFO "Verifique os logs em: $LOG_FILE"
    fi
    exit $exit_code
}

# Configurar trap para cleanup
trap cleanup EXIT

# Executar função principal
main "$@"