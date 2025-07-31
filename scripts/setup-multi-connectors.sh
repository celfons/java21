#!/bin/bash
# Script para configurar múltiplos conectores MongoDB Atlas Kafka Connect com filtros por tipo de operação
# Updated for MongoDB Atlas and external Kafka

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

echo -e "${GREEN}=== Configuração de Múltiplos Conectores MongoDB Atlas Kafka ===${NC}"
echo -e "${BLUE}Este script configurará conectores separados para INSERT, UPDATE e DELETE${NC}"
echo

# Function to substitute environment variables in JSON
substitute_env_vars() {
    local config_file=$1
    local temp_file="/tmp/$(basename "$config_file")"
    
    # Read the config file and substitute environment variables
    envsubst < "$config_file" > "$temp_file"
    echo "$temp_file"
}

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
    
    # Substitute environment variables in the config
    local processed_config=$(substitute_env_vars "$config_file")
    
    connector_name=$(jq -r '.name' "$processed_config")
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
            rm -f "$processed_config"
            return 0
        fi
    fi
    
    # Criar conector
    echo -e "${YELLOW}Criando conector $connector_name...${NC}"
    
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d @"$processed_config" \
        "$CONNECT_URL/connectors")
    
    if echo "$RESPONSE" | jq -e '.name' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Conector criado com sucesso${NC}"
        echo -e "${BLUE}Nome do conector: $(echo "$RESPONSE" | jq -r '.name')${NC}"
    else
        echo -e "${RED}✗ Falha ao criar conector${NC}"
        echo "Resposta: $RESPONSE"
        rm -f "$processed_config"
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
                rm -f "$processed_config"
                return 1
                ;;
            *)
                if [ $attempt -eq $MAX_ATTEMPTS ]; then
                    echo -e "${RED}✗ Conector não conseguiu chegar ao estado de execução${NC}"
                    curl -s "$CONNECT_URL/connectors/$connector_name/status" | jq .
                    rm -f "$processed_config"
                    return 1
                fi
                echo "Tentativa $attempt/$MAX_ATTEMPTS - Status: $STATUS"
                sleep $SLEEP_INTERVAL
                ((attempt++))
                ;;
        esac
    done
    
    echo -e "${GREEN}✓ Conector $connector_name configurado com sucesso${NC}"
    echo
    
    # Clean up temporary file
    rm -f "$processed_config"
    return 0
}

# Validate required environment variables
echo -e "${YELLOW}Validando variáveis de ambiente...${NC}"

if [ -z "$MONGODB_ATLAS_CONNECTION_STRING" ]; then
    echo -e "${RED}✗ MONGODB_ATLAS_CONNECTION_STRING é obrigatória${NC}"
    echo "Por favor, defina esta variável de ambiente com sua connection string do MongoDB Atlas"
    exit 1
fi

if [ -z "$KAFKA_BOOTSTRAP_SERVERS" ]; then
    echo -e "${RED}✗ KAFKA_BOOTSTRAP_SERVERS é obrigatória${NC}"
    echo "Por favor, defina esta variável de ambiente com os bootstrap servers do seu cluster Kafka externo"
    exit 1
fi

echo -e "${GREEN}✓ Variáveis de ambiente obrigatórias estão definidas${NC}"

# Aguardar Kafka Connect estar pronto
echo -e "${YELLOW}Aguardando Kafka Connect estar pronto...${NC}"

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
echo -e "${BLUE}Plugins Kafka Connect disponíveis:${NC}"
curl -s "$CONNECT_URL/connector-plugins" | jq -r '.[] | select(.class | contains("mongodb")) | .class'

# Verificar se diretório de conectores existe
if [ ! -d "$CONNECTORS_DIR" ]; then
    echo -e "${RED}✗ Diretório de conectores não encontrado: $CONNECTORS_DIR${NC}"
    exit 1
fi

# Lista de arquivos de configuração dos conectores
CONNECTOR_CONFIGS=(
    "$CONNECTORS_DIR/mongo-insert-connector.json"
    "$CONNECTORS_DIR/mongo-update-connector.json"
    "$CONNECTORS_DIR/mongo-delete-connector.json"
)

echo -e "${BLUE}=== Configurando Conectores Individuais ===${NC}"

# Variável para rastrear falhas
failed_connectors=0

# Configurar cada conector
for config_file in "${CONNECTOR_CONFIGS[@]}"; do
    echo -e "${BLUE}--------------------------------------------------${NC}"
    if create_connector "$config_file"; then
        echo -e "${GREEN}✓ Sucesso${NC}"
    else
        echo -e "${RED}✗ Falha${NC}"
        ((failed_connectors++))
    fi
done

echo -e "${BLUE}=== Resumo da Configuração ===${NC}"

if [ $failed_connectors -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os conectores foram configurados com sucesso!${NC}"
    echo
    echo -e "${BLUE}Conectores criados:${NC}"
    echo "  🟢 mongo-insert-connector  → Tópico: mongo-insert.*"
    echo "  🟡 mongo-update-connector  → Tópico: mongo-update.*"
    echo "  🔴 mongo-delete-connector  → Tópico: mongo-delete.*"
    echo
    echo -e "${BLUE}Próximos passos:${NC}"
    echo "  1. Teste inserções, atualizações e deleções no MongoDB Atlas"
    echo "  2. Monitore os tópicos Kafka separados para cada tipo de operação"
    echo "  3. Use ferramentas de monitoramento Kafka para visualizar as mensagens"
    echo
    echo -e "${BLUE}Comandos úteis:${NC}"
    echo "  - Status dos conectores: curl http://localhost:8083/connectors"
    echo "  - Status específico: curl http://localhost:8083/connectors/[nome]/status"
else
    echo -e "${RED}✗ $failed_connectors conector(es) falharam ao ser configurados${NC}"
    echo -e "${YELLOW}Verifique os logs acima para detalhes dos erros${NC}"
fi

echo -e "${BLUE}=== Status Final dos Conectores ===${NC}"
curl -s "$CONNECT_URL/connectors" | jq .