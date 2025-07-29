#!/bin/bash
# Script para configurar múltiplos conectores MongoDB Kafka Connect com filtros por tipo de operação

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuração
CONNECT_URL=${CONNECT_URL:-http://localhost:8083}
CONNECTORS_DIR="connectors"
MAX_ATTEMPTS=30
SLEEP_INTERVAL=10

echo -e "${GREEN}=== Configuração de Múltiplos Conectores MongoDB Kafka ===${NC}"
echo -e "${BLUE}Este script configurará conectores separados para INSERT, UPDATE e DELETE${NC}"
echo

# Função para verificar se Kafka Connect está pronto
check_kafka_connect_ready() {
    curl -s -f "$CONNECT_URL/connectors" > /dev/null 2>&1
}

# Função para verificar se conector existe
check_connector_exists() {
    local connector_name=$1
    curl -s -f "$CONNECT_URL/connectors/$connector_name" > /dev/null 2>&1
}

# Função para obter status do conector
get_connector_status() {
    local connector_name=$1
    curl -s "$CONNECT_URL/connectors/$connector_name/status" 2>/dev/null | jq -r '.connector.state' 2>/dev/null || echo "UNKNOWN"
}

# Função para criar um conector
create_connector() {
    local config_file=$1
    local connector_name
    
    # Verificar se arquivo existe
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}✗ Arquivo de configuração não encontrado: $config_file${NC}"
        return 1
    fi
    
    connector_name=$(jq -r '.name' "$config_file")
    echo -e "${YELLOW}Configurando conector: $connector_name${NC}"
    
    # Verificar se conector já existe
    if check_connector_exists "$connector_name"; then
        echo -e "${YELLOW}Conector '$connector_name' já existe${NC}"
        
        # Obter status atual
        STATUS=$(get_connector_status "$connector_name")
        echo -e "${BLUE}Status atual: $STATUS${NC}"
        
        # Perguntar se quer deletar e recriar
        read -p "Deseja deletar e recriar o conector? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Deletando conector existente...${NC}"
            curl -X DELETE "$CONNECT_URL/connectors/$connector_name"
            echo -e "${GREEN}✓ Conector deletado${NC}"
            sleep 5
        else
            echo -e "${BLUE}Mantendo conector existente${NC}"
            return 0
        fi
    fi
    
    # Criar conector
    echo -e "${YELLOW}Criando conector $connector_name...${NC}"
    
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d @"$config_file" \
        "$CONNECT_URL/connectors")
    
    if echo "$RESPONSE" | jq -e '.name' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Conector criado com sucesso${NC}"
        echo -e "${BLUE}Nome do conector: $(echo "$RESPONSE" | jq -r '.name')${NC}"
    else
        echo -e "${RED}✗ Falha ao criar conector${NC}"
        echo "Resposta: $RESPONSE"
        return 1
    fi
    
    # Aguardar conector estar executando
    echo -e "${YELLOW}Aguardando conector entrar em execução...${NC}"
    
    attempt=1
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        STATUS=$(get_connector_status "$connector_name")
        
        case $STATUS in
            "RUNNING")
                echo -e "${GREEN}✓ Conector está executando${NC}"
                break
                ;;
            "FAILED")
                echo -e "${RED}✗ Conector falhou ao iniciar${NC}"
                curl -s "$CONNECT_URL/connectors/$connector_name/status" | jq .
                return 1
                ;;
            *)
                if [ $attempt -eq $MAX_ATTEMPTS ]; then
                    echo -e "${RED}✗ Conector não conseguiu chegar ao estado de execução${NC}"
                    curl -s "$CONNECT_URL/connectors/$connector_name/status" | jq .
                    return 1
                fi
                echo "Tentativa $attempt/$MAX_ATTEMPTS - Status: $STATUS"
                sleep $SLEEP_INTERVAL
                ((attempt++))
                ;;
        esac
    done
    
    return 0
}

# Aguardar Kafka Connect estar pronto
echo -e "${YELLOW}Aguardando Kafka Connect ficar pronto...${NC}"

attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    if check_kafka_connect_ready; then
        echo -e "${GREEN}✓ Kafka Connect está pronto${NC}"
        break
    fi
    
    if [ $attempt -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}✗ Kafka Connect falhou ao ficar pronto${NC}"
        exit 1
    fi
    
    echo "Tentativa $attempt/$MAX_ATTEMPTS - Aguardando Kafka Connect..."
    sleep $SLEEP_INTERVAL
    ((attempt++))
done

# Verificar plugins disponíveis
echo -e "${BLUE}Plugins MongoDB Kafka Connect disponíveis:${NC}"
curl -s "$CONNECT_URL/connector-plugins" | jq -r '.[] | select(.class | contains("mongodb")) | .class'
echo

# Verificar se diretório de conectores existe
if [ ! -d "$CONNECTORS_DIR" ]; then
    echo -e "${RED}✗ Diretório de conectores não encontrado: $CONNECTORS_DIR${NC}"
    exit 1
fi

# Lista de arquivos de configuração dos conectores
connectors=(
    "$CONNECTORS_DIR/mongo-insert-connector.json"
    "$CONNECTORS_DIR/mongo-update-connector.json"
    "$CONNECTORS_DIR/mongo-delete-connector.json"
)

# Configurar cada conector
failed_connectors=0
successful_connectors=0

for config_file in "${connectors[@]}"; do
    echo -e "${BLUE}======================================================================================================${NC}"
    if create_connector "$config_file"; then
        ((successful_connectors++))
    else
        ((failed_connectors++))
    fi
    echo
done

# Resumo final
echo -e "${BLUE}=== Resumo da Configuração ===${NC}"
echo -e "${GREEN}Conectores configurados com sucesso: $successful_connectors${NC}"
echo -e "${RED}Conectores que falharam: $failed_connectors${NC}"
echo

if [ $failed_connectors -eq 0 ]; then
    echo -e "${GREEN}✅ Todos os conectores foram configurados com sucesso!${NC}"
    echo
    echo -e "${BLUE}=== Tópicos Kafka que serão criados ===${NC}"
    echo -e "• ${YELLOW}mongo-insert.exemplo.*${NC} - Para operações de INSERT"
    echo -e "• ${YELLOW}mongo-update.exemplo.*${NC} - Para operações de UPDATE"
    echo -e "• ${YELLOW}mongo-delete.exemplo.*${NC} - Para operações de DELETE"
    echo
    echo -e "${BLUE}=== Monitoramento ===${NC}"
    echo -e "• Kafka UI: ${YELLOW}http://localhost:8080${NC}"
    echo -e "• Kafka Connect API: ${YELLOW}$CONNECT_URL/connectors${NC}"
    echo -e "• Status dos conectores: ${YELLOW}$CONNECT_URL/connectors/{connector-name}/status${NC}"
else
    echo -e "${RED}❌ Alguns conectores falharam na configuração${NC}"
    echo -e "${YELLOW}Verifique os logs acima para mais detalhes${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuração de múltiplos conectores MongoDB Kafka concluída!${NC}"