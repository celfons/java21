#!/bin/bash
# Enhanced health check script

# Check if Kafka Connect REST API is responding
if ! curl -s -f http://localhost:8083/ > /dev/null; then
    echo "Health check failed: Kafka Connect REST API not responding"
    exit 1
fi

# Check if connectors endpoint is accessible
if ! curl -s -f http://localhost:8083/connectors > /dev/null; then
    echo "Health check failed: Connectors endpoint not accessible"
    exit 1
fi

# Check if MongoDB connector plugin is available
if ! curl -s http://localhost:8083/connector-plugins | grep -q "mongodb"; then
    echo "Warning: MongoDB connector plugin not found in plugins list"
    # Don't fail the health check if MongoDB plugin is missing
    # as the service can still start and plugins might be added later
fi

echo "Health check passed: Kafka Connect is healthy"
exit 0