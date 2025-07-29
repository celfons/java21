#!/bin/bash

# Script para verificação de saúde dos serviços
# Autor: MongoDB Kafka Connector Example
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/tmp/health-check.log"

# URLs dos serviços
CONNECT_URL="http://localhost:8083"
KAFKA_UI_URL="http://localhost:8080"
MONGO_EXPRESS_URL="http://localhost:8081"

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

# Função para verificar status do container Docker
check_container_status() {
    local container_name="$1"
    local status
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "$container_name"; then
        status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "$container_name" | awk '{print $2}')
        log INFO "✓ Container $container_name: $status"
        return 0
    else
        log ERROR "✗ Container $container_name: não está rodando"
        return 1
    fi
}

# Função para verificar saúde do MongoDB
check_mongodb_health() {
    log INFO "Verificando saúde do MongoDB..."
    
    local mongo_containers=("mongo-primary" "mongo-secondary-1" "mongo-secondary-2")
    local healthy_count=0
    
    for container in "${mongo_containers[@]}"; do
        if check_container_status "$container"; then
            if docker-compose exec -T "$container" mongosh --eval 'db.adminCommand({ping: 1})' &> /dev/null; then
                log INFO "  ✓ $container: responde a ping"
                ((healthy_count++))
            else
                log ERROR "  ✗ $container: não responde a ping"
            fi
        fi
    done
    
    # Verificar replica set
    if [ $healthy_count -gt 0 ]; then
        if docker-compose exec -T mongo-primary mongosh --eval '
            try {
                const status = rs.status();
                const primary = status.members.find(m => m.stateStr === "PRIMARY");
                const secondaries = status.members.filter(m => m.stateStr === "SECONDARY");
                
                print("Primary: " + (primary ? primary.name : "NENHUM"));
                print("Secondaries: " + secondaries.length);
                
                if (primary && secondaries.length >= 1) {
                    print("REPLICA_SET_OK");
                } else {
                    print("REPLICA_SET_ISSUES");
                }
            } catch (e) {
                print("REPLICA_SET_ERROR: " + e.message);
            }
        ' 2>/dev/null | grep -q "REPLICA_SET_OK"; then
            log INFO "  ✓ Replica Set está funcionando corretamente"
        else
            log WARN "  ⚠ Replica Set tem problemas ou não está inicializado"
        fi
    fi
    
    return 0
}

# Função para verificar saúde do Kafka
check_kafka_health() {
    log INFO "Verificando saúde do Kafka..."
    
    # Verificar Zookeeper
    if check_container_status "zookeeper"; then
        if docker-compose exec -T zookeeper bash -c 'echo "ruok" | nc localhost 2181' 2>/dev/null | grep -q "imok"; then
            log INFO "  ✓ Zookeeper: responde corretamente"
        else
            log ERROR "  ✗ Zookeeper: não responde corretamente"
        fi
    fi
    
    # Verificar Kafka broker
    if check_container_status "kafka"; then
        if docker-compose exec -T kafka kafka-broker-api-versions --bootstrap-server localhost:9092 &> /dev/null; then
            log INFO "  ✓ Kafka Broker: responde a API calls"
            
            # Verificar tópicos
            local topic_count
            topic_count=$(docker-compose exec -T kafka kafka-topics --bootstrap-server localhost:9092 --list | wc -l)
            log INFO "  ✓ Tópicos disponíveis: $topic_count"
        else
            log ERROR "  ✗ Kafka Broker: não responde a API calls"
        fi
    fi
    
    return 0
}

# Função para verificar saúde do Kafka Connect
check_kafka_connect_health() {
    log INFO "Verificando saúde do Kafka Connect..."
    
    if check_container_status "kafka-connect"; then
        # Verificar REST API
        if curl -s "$CONNECT_URL/" &> /dev/null; then
            log INFO "  ✓ REST API: acessível"
            
            # Verificar plugins
            local plugin_count
            plugin_count=$(curl -s "$CONNECT_URL/connector-plugins" | jq '. | length' 2>/dev/null || echo "0")
            log INFO "  ✓ Plugins carregados: $plugin_count"
            
            # Verificar conectores
            local connectors
            connectors=$(curl -s "$CONNECT_URL/connectors" 2>/dev/null || echo "[]")
            local connector_count
            connector_count=$(echo "$connectors" | jq '. | length' 2>/dev/null || echo "0")
            log INFO "  ✓ Conectores ativos: $connector_count"
            
            if [ "$connector_count" -gt 0 ]; then
                echo "$connectors" | jq -r '.[]' | while read -r connector; do
                    local status
                    status=$(curl -s "$CONNECT_URL/connectors/$connector/status" | jq -r '.connector.state' 2>/dev/null || echo "UNKNOWN")
                    log INFO "    - $connector: $status"
                done
            fi
        else
            log ERROR "  ✗ REST API: não acessível"
        fi
    fi
    
    return 0
}

# Função para verificar UIs web
check_web_interfaces() {
    log INFO "Verificando interfaces web..."
    
    # Kafka UI
    if check_container_status "kafka-ui"; then
        if curl -s "$KAFKA_UI_URL" &> /dev/null; then
            log INFO "  ✓ Kafka UI: acessível em $KAFKA_UI_URL"
        else
            log ERROR "  ✗ Kafka UI: não acessível em $KAFKA_UI_URL"
        fi
    fi
    
    # Mongo Express
    if check_container_status "mongo-express"; then
        if curl -s "$MONGO_EXPRESS_URL" &> /dev/null; then
            log INFO "  ✓ Mongo Express: acessível em $MONGO_EXPRESS_URL"
        else
            log ERROR "  ✗ Mongo Express: não acessível em $MONGO_EXPRESS_URL"
        fi
    fi
    
    return 0
}

# Função para verificar recursos do sistema
check_system_resources() {
    log INFO "Verificando recursos do sistema..."
    
    # Verificar uso de CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "N/A")
    log INFO "  CPU: ${cpu_usage}% em uso"
    
    # Verificar uso de memória
    local mem_info
    mem_info=$(free -h | grep "Mem:" | awk '{print $3 "/" $2}' || echo "N/A")
    log INFO "  Memória: $mem_info em uso"
    
    # Verificar uso de disco
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}' || echo "N/A")
    log INFO "  Disco: $disk_usage"
    
    # Verificar volumes Docker
    log INFO "  Volumes Docker:"
    docker volume ls --format "table {{.Name}}\t{{.Driver}}" | grep -E "(mongo|kafka|zookeeper)" || log WARN "    Nenhum volume encontrado"
    
    return 0
}

# Função para gerar relatório resumido
generate_summary() {
    log INFO "=== RESUMO DA VERIFICAÇÃO DE SAÚDE ==="
    
    local services=("mongo-primary" "mongo-secondary-1" "mongo-secondary-2" "zookeeper" "kafka" "kafka-connect" "kafka-ui" "mongo-express")
    local running_count=0
    
    for service in "${services[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "$service"; then
            ((running_count++))
        fi
    done
    
    log INFO "Serviços rodando: $running_count/${#services[@]}"
    
    if [ $running_count -eq ${#services[@]} ]; then
        log INFO "✓ Todos os serviços estão rodando"
    elif [ $running_count -gt $((${#services[@]} / 2)) ]; then
        log WARN "⚠ Alguns serviços não estão rodando"
    else
        log ERROR "✗ Maioria dos serviços não está rodando"
    fi
    
    log INFO ""
    log INFO "URLs de acesso:"
    log INFO "  - Kafka Connect API: $CONNECT_URL"
    log INFO "  - Kafka UI: $KAFKA_UI_URL" 
    log INFO "  - Mongo Express: $MONGO_EXPRESS_URL"
    log INFO ""
    log INFO "Para logs detalhados, verifique: $LOG_FILE"
}

# Função principal
main() {
    local detailed="${1:-false}"
    
    log INFO "=== Verificação de Saúde dos Serviços ==="
    log INFO "Hora: $(date)"
    
    # Verificar dependências
    check_command "docker"
    check_command "docker-compose"
    check_command "curl"
    
    # Navegar para o diretório do projeto
    cd "$PROJECT_DIR"
    
    # Verificações básicas
    check_mongodb_health
    check_kafka_health
    check_kafka_connect_health
    check_web_interfaces
    
    # Verificações detalhadas se solicitado
    if [ "$detailed" = "true" ] || [ "$detailed" = "--detailed" ]; then
        check_system_resources
    fi
    
    # Gerar resumo
    generate_summary
    
    log INFO "=== Verificação de saúde concluída ==="
}

# Verificar argumentos
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    echo "Uso: $0 [--detailed]"
    echo "  --detailed    Inclui verificações detalhadas de recursos do sistema"
    exit 0
fi

# Executar função principal
main "$@"