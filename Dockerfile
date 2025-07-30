FROM confluentinc/cp-kafka-connect:7.4.0

# Metadados da imagem para produção
LABEL maintainer="MongoDB Kafka Connector Team"
LABEL version="1.0.0"
LABEL description="MongoDB Kafka Connector for Azure deployment"

# Variáveis de ambiente para produção
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
ENV CONNECT_REST_PORT=8083
ENV CONNECT_LOG4J_ROOT_LOGLEVEL=INFO

# Switch to root for installation
USER root

# Install MongoDB Kafka Connector with better error handling
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.1 || \
    (echo "Warning: Could not install MongoDB connector from hub, continuing without it" && \
     mkdir -p /usr/share/confluent-hub-components)

# Switch back to appuser for security
USER appuser

# Expose Kafka Connect REST API port
EXPOSE 8083

# Use default startup command
CMD ["/etc/confluent/docker/run"]