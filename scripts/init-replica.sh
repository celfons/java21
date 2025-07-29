#!/bin/bash

# Script para inicialização do Replica Set MongoDB
# Autor: MongoDB Kafka Connector Example
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/init-replica.log"

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
        sleep 5
        ((attempt++))
    done
    
    log ERROR "$service_name não ficou pronto após $max_attempts tentativas"
    return 1
}

# Função principal
main() {
    log INFO "=== Iniciando configuração do MongoDB Replica Set ==="
    
    # Verificar dependências
    check_command "docker"
    
    # Verificar docker compose (v2) ou docker-compose (v1)
    if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
        log ERROR "Docker Compose não encontrado. Instale Docker Compose v2 ou v1."
        exit 1
    fi
    
    # Navegar para o diretório do projeto
    cd "$PROJECT_DIR"
    
    # Verificar se o arquivo .env existe
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            log WARN "Arquivo .env não encontrado. Copiando .env.example para .env"
            cp ".env.example" ".env"
        else
            log ERROR "Arquivo .env.example não encontrado. Por favor, crie o arquivo .env com as configurações necessárias."
            exit 1
        fi
    fi
    
    # Verificar se os containers MongoDB estão rodando
    log INFO "Verificando status dos containers MongoDB..."
    
    if ! docker compose ps mongo-primary | grep -q "Up"; then
        log INFO "Iniciando containers MongoDB..."
        docker compose up -d mongo-primary mongo-secondary-1 mongo-secondary-2
    else
        log INFO "Containers MongoDB já estão rodando"
    fi
    
    # Aguardar MongoDB primary estar pronto
    wait_for_service "MongoDB Primary" \
        "docker compose exec -T mongo-primary mongosh --eval 'db.adminCommand({ping: 1})'"
    
    # Aguardar MongoDB secondary nodes estarem prontos
    wait_for_service "MongoDB Secondary 1" \
        "docker compose exec -T mongo-secondary-1 mongosh --eval 'db.adminCommand({ping: 1})'"
    
    wait_for_service "MongoDB Secondary 2" \
        "docker compose exec -T mongo-secondary-2 mongosh --eval 'db.adminCommand({ping: 1})'"
    
    # Verificar se o replica set já foi inicializado
    log INFO "Verificando status do Replica Set..."
    
    if docker compose exec -T mongo-primary mongosh --eval 'rs.status()' &> /dev/null; then
        log WARN "Replica Set já foi inicializado. Verificando configuração..."
        docker compose exec -T mongo-primary mongosh --eval 'rs.status()'
    else
        log INFO "Inicializando Replica Set..."
        
        # Executar script de inicialização
        docker compose exec -T mongo-primary mongosh --file /docker-entrypoint-initdb.d/replica-init.js
        
        if [ $? -eq 0 ]; then
            log INFO "Replica Set inicializado com sucesso!"
        else
            log ERROR "Erro ao inicializar Replica Set"
            exit 1
        fi
    fi
    
    # Verificar saúde do replica set
    log INFO "Verificando saúde do Replica Set..."
    
    sleep 10  # Aguardar estabilização
    
    if docker compose exec -T mongo-primary mongosh --eval '
        const status = rs.status();
        const primary = status.members.find(m => m.stateStr === "PRIMARY");
        const secondaries = status.members.filter(m => m.stateStr === "SECONDARY");
        
        print("Primary: " + (primary ? primary.name : "NENHUM"));
        print("Secondaries: " + secondaries.length);
        
        if (!primary || secondaries.length < 2) {
            quit(1);
        }
    '; then
        log INFO "Replica Set está funcionando corretamente!"
        log INFO "Primary e secondaries configurados com sucesso"
    else
        log ERROR "Replica Set não está funcionando corretamente"
        exit 1
    fi
    
    # Exibir informações do replica set
    log INFO "=== Informações do Replica Set ==="
    docker compose exec -T mongo-primary mongosh --eval '
        const status = rs.status();
        status.members.forEach(member => {
            print(`Membro: ${member.name} - Estado: ${member.stateStr} - Saúde: ${member.health}`);
        });
    '
    
    log INFO "=== Configuração do MongoDB Replica Set concluída com sucesso! ==="
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