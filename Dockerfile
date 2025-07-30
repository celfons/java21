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

# Create directories for configuration
RUN mkdir -p /etc/kafka-connect /var/log/kafka-connect

# Copy configuration files
COPY config/kafka-connect/connect-log4j.properties /etc/kafka/connect-log4j.properties
COPY config/kafka-connect/ /etc/kafka-connect/

# Set proper permissions
RUN chown -R appuser:appuser /etc/kafka-connect /var/log/kafka-connect

# Copy health check script
COPY scripts/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh
RUN chown appuser:appuser /usr/local/bin/health-check.sh

# Copy startup script
COPY scripts/azure-startup.sh /usr/local/bin/azure-startup.sh
RUN chmod +x /usr/local/bin/azure-startup.sh
RUN chown appuser:appuser /usr/local/bin/azure-startup.sh

# Expose Kafka Connect REST API port
EXPOSE 8083

# Switch back to appuser for security
USER appuser

# Use startup script for Azure deployment
CMD ["/usr/local/bin/azure-startup.sh"]