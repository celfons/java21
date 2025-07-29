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
# Note: This step requires internet access to api.hub.confluent.io
# In production, this will download and install the MongoDB connector
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.1 || echo "Warning: Could not install MongoDB connector (network access required)"

# Install additional connectors and dependencies for production
# RUN confluent-hub install --no-prompt confluentinc/kafka-connect-transforms:latest || echo "Warning: Could not install transforms (network access required)"

# Copy custom configuration
COPY config/kafka-connect/connect-log4j.properties /etc/kafka/connect-log4j.properties

# Create directories for configuration
USER root
RUN mkdir -p /etc/kafka-connect /var/log/kafka-connect

# Copy production configuration files
COPY config/kafka-connect/ /etc/kafka-connect/

# Set proper permissions
RUN chown -R appuser:appuser /etc/kafka-connect /var/log/kafka-connect

# Health check script for Azure
COPY --chown=appuser:appuser scripts/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh

# Create startup script for Azure deployment
COPY scripts/azure-startup.sh /usr/local/bin/azure-startup.sh
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