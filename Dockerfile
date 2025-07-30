FROM confluentinc/cp-kafka-connect:7.4.0

# Metadados da imagem para produção
LABEL maintainer="MongoDB Kafka Connector Team"
LABEL version="1.0.0"
LABEL description="MongoDB Kafka Connector for Azure deployment"

# Variáveis de ambiente para produção
ENV CONNECT_PLUGIN_PATH="/usr/share/java,/usr/share/confluent-hub-components"
ENV CONNECT_REST_PORT=8083
ENV CONNECT_LOG4J_ROOT_LOGLEVEL=INFO

# Switch to root for installations
USER root

# Install MongoDB Kafka Connector with better error handling
RUN echo "Installing MongoDB Kafka Connector..." && \
    confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.1 || \
    echo "Warning: Could not install MongoDB connector automatically"

# Create directories for configuration and logs
RUN mkdir -p /etc/kafka-connect /var/log/kafka-connect /usr/share/confluent-hub-components

# Copy production configuration files if they exist
COPY config/kafka-connect/ /etc/kafka-connect/

# Copy startup and health check scripts
COPY scripts/enhanced-startup.sh /usr/local/bin/enhanced-startup.sh
COPY scripts/enhanced-health-check.sh /usr/local/bin/enhanced-health-check.sh

# Set proper permissions
RUN chmod +x /usr/local/bin/enhanced-startup.sh /usr/local/bin/enhanced-health-check.sh
RUN chown -R appuser:appuser /etc/kafka-connect /var/log/kafka-connect /usr/local/bin/enhanced-startup.sh /usr/local/bin/enhanced-health-check.sh

# Health check configurado para Azure
HEALTHCHECK --interval=30s --timeout=15s --start-period=180s --retries=10 \
    CMD /usr/local/bin/enhanced-health-check.sh

# Expose Kafka Connect REST API port
EXPOSE 8083

# Switch back to appuser for security
USER appuser

# Use enhanced startup script
CMD ["/usr/local/bin/enhanced-startup.sh"]