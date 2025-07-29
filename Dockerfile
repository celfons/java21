FROM confluentinc/cp-kafka-connect:7.4.0

# Install MongoDB Kafka Connector
RUN confluent-hub install --no-prompt mongodb/kafka-connect-mongodb:1.11.1

# Copy custom configuration
COPY config/kafka-connect/connect-log4j.properties /etc/kafka/connect-log4j.properties

# Create directories for configuration
RUN mkdir -p /etc/kafka-connect

# Set proper permissions
USER root
RUN chown -R appuser:appuser /etc/kafka-connect
USER appuser

# Health check script
COPY --chown=appuser:appuser scripts/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh

# Expose Kafka Connect REST API port
EXPOSE 8083

# Start Kafka Connect
CMD ["/etc/confluent/docker/run"]