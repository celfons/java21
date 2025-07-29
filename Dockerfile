FROM confluentinc/cp-kafka-connect:7.4.0

# Metadados da imagem para produção
LABEL maintainer="MongoDB Kafka Connector Team"
LABEL version="1.0.0"
LABEL description="MongoDB Kafka Connector for Azure deployment"

# Variáveis de ambiente para produção
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
ENV CONNECT_REST_PORT=8083
ENV CONNECT_LOG4J_ROOT_LOGLEVEL=INFO

# Install MongoDB Kafka Connector
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.1

# Install additional connectors and dependencies for production
RUN confluent-hub install --no-prompt confluentinc/kafka-connect-transforms:latest

# Copy custom configuration
COPY config/kafka-connect/connect-log4j.properties /etc/kafka/connect-log4j.properties

# Create directories for configuration
RUN mkdir -p /etc/kafka-connect /var/log/kafka-connect

# Copy production configuration files
COPY config/kafka-connect/ /etc/kafka-connect/

# Set proper permissions
USER root
RUN chown -R appuser:appuser /etc/kafka-connect /var/log/kafka-connect
USER appuser

# Health check script for Azure
COPY --chown=appuser:appuser scripts/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh

# Create startup script for Azure deployment
USER root
RUN cat > /usr/local/bin/azure-startup.sh << 'EOF'
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
EOF

RUN chmod +x /usr/local/bin/azure-startup.sh
RUN chown appuser:appuser /usr/local/bin/azure-startup.sh

# Health check configurado para Azure
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8083/connectors || exit 1

# Expose Kafka Connect REST API port
EXPOSE 8083

# Switch back to appuser for security
USER appuser

# Use startup script for Azure deployment
CMD ["/usr/local/bin/azure-startup.sh"]