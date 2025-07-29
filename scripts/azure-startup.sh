#!/bin/bash
set -e

echo "🚀 Iniciando Kafka Connect para Azure..."

# Configurar variáveis de ambiente específicas do Azure
if [ ! -z "$MONGO_CONNECTION_STRING" ]; then
    echo "📦 Configurando MongoDB Atlas connection string..."
    export CONNECT_MONGO_CONNECTION_URI="$MONGO_CONNECTION_STRING"
fi

# Configurar environment específico
if [ "$ENVIRONMENT" = "production" ]; then
    echo "🏭 Configurando ambiente de produção..."
    export CONNECT_LOG4J_ROOT_LOGLEVEL=WARN
    export CONNECT_CONSUMER_MAX_POLL_RECORDS=1000
    export CONNECT_PRODUCER_BATCH_SIZE=32768
elif [ "$ENVIRONMENT" = "staging" ]; then
    echo "🔧 Configurando ambiente de staging..."
    export CONNECT_LOG4J_ROOT_LOGLEVEL=INFO
elif [ "$ENVIRONMENT" = "development" ]; then
    echo "🧪 Configurando ambiente de desenvolvimento..."
    export CONNECT_LOG4J_ROOT_LOGLEVEL=DEBUG
fi

# Log das configurações (sem mostrar credenciais)
echo "📋 Configurações do Kafka Connect:"
echo "   - Bootstrap Servers: $CONNECT_BOOTSTRAP_SERVERS"
echo "   - Group ID: $CONNECT_GROUP_ID"
echo "   - Environment: $ENVIRONMENT"
echo "   - Log Level: $CONNECT_LOG4J_ROOT_LOGLEVEL"

# Iniciar Kafka Connect
echo "▶️  Iniciando Kafka Connect..."
exec /etc/confluent/docker/run