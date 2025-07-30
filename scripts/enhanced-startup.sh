#!/bin/bash
echo "=== Kafka Connect Enhanced Startup ==="
echo "$(date): Starting Kafka Connect with enhanced logging..."

# Wait for Kafka to be available
echo "$(date): Waiting for Kafka to be available..."
while ! nc -z kafka 9092; do
    echo "$(date): Waiting for Kafka bootstrap server..."
    sleep 5
done

echo "$(date): Kafka is available, starting Kafka Connect..."

# Check for MongoDB connector (simplified)
echo "$(date): Checking for MongoDB connector..."
if [ -d "/usr/share/confluent-hub-components" ]; then
    echo "MongoDB connector directory exists"
else
    echo "Warning: MongoDB connector directory not found"
fi

# Export environment variables for better logging
export CONNECT_LOG4J_ROOT_LOGLEVEL=${CONNECT_LOG4J_ROOT_LOGLEVEL:-INFO}
export CONNECT_LOG4J_LOGGERS="${CONNECT_LOG4J_LOGGERS:-org.apache.kafka.connect.runtime.rest=WARN,org.reflections=ERROR}"

echo "$(date): Configuration summary:"
echo "  Bootstrap Servers: $CONNECT_BOOTSTRAP_SERVERS"
echo "  Group ID: $CONNECT_GROUP_ID"
echo "  Plugin Path: $CONNECT_PLUGIN_PATH"
echo "  Log Level: $CONNECT_LOG4J_ROOT_LOGLEVEL"

echo "$(date): Starting Kafka Connect server..."
exec /etc/confluent/docker/run