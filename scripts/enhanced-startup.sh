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

# List available plugins
echo "$(date): Available Kafka Connect plugins:"
find /usr/share/java /usr/share/confluent-hub-components -name "*.jar" | grep -i mongo || echo "No MongoDB connector JARs found"

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