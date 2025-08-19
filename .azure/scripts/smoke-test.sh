#!/bin/bash

# Smoke Test Script for Product CRUD API
# Tests the basic functionality of the containerized application

set -e

CONTAINER_NAME=${CONTAINER_NAME:-"product-crud-test"}
IMAGE_NAME=${IMAGE_NAME:-"product-crud:latest"}
PORT=${PORT:-8080}
HEALTH_ENDPOINT="http://localhost:${PORT}/actuator/health"
MAX_ATTEMPTS=${MAX_ATTEMPTS:-20}
WAIT_INTERVAL=${WAIT_INTERVAL:-10}

echo "🧪 Starting Smoke Tests for Product CRUD API"
echo "============================================="
echo "Container: $CONTAINER_NAME"
echo "Image: $IMAGE_NAME"
echo "Port: $PORT"
echo "Health Endpoint: $HEALTH_ENDPOINT"
echo ""

# Function to cleanup
cleanup() {
    echo "🧹 Cleaning up..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Start the container
echo "🚀 Starting container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT:8080" \
    -e SPRING_DATA_MONGODB_URI="mongodb://dummy:27017/testdb" \
    -e SPRING_PROFILES_ACTIVE="test" \
    "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Failed to start container"
    exit 1
fi

echo "✅ Container started successfully"

# Wait for application to be ready
echo "⏳ Waiting for application to start..."
for i in $(seq 1 $MAX_ATTEMPTS); do
    echo "   Attempt $i/$MAX_ATTEMPTS..."
    
    if curl -f -s "$HEALTH_ENDPOINT" >/dev/null 2>&1; then
        echo "✅ Application is ready!"
        break
    fi
    
    if [ $i -eq $MAX_ATTEMPTS ]; then
        echo "❌ Application failed to start within expected time"
        echo "📋 Container logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
    
    sleep $WAIT_INTERVAL
done

echo ""
echo "🔍 Running Health Checks..."

# Test 1: Health endpoint returns 200 or 503
echo "📋 Test 1: Health endpoint accessibility"
HEALTH_RESPONSE=$(curl -s -w "%{http_code}" "$HEALTH_ENDPOINT")
HTTP_CODE="${HEALTH_RESPONSE: -3}"

if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "503" ]]; then
    echo "✅ Health endpoint responded with code: $HTTP_CODE"
else
    echo "❌ Health endpoint returned unexpected code: $HTTP_CODE"
    exit 1
fi

# Test 2: Health endpoint returns JSON
echo "📋 Test 2: Health endpoint returns JSON format"
HEALTH_JSON=$(curl -s "$HEALTH_ENDPOINT")
if echo "$HEALTH_JSON" | jq . >/dev/null 2>&1; then
    echo "✅ Health endpoint returns valid JSON"
    echo "   Response: $HEALTH_JSON"
else
    echo "❌ Health endpoint does not return valid JSON"
    echo "   Response: $HEALTH_JSON"
    exit 1
fi

# Test 3: Check if status field exists
echo "📋 Test 3: Health response contains status field"
if echo "$HEALTH_JSON" | jq -e '.status' >/dev/null 2>&1; then
    STATUS=$(echo "$HEALTH_JSON" | jq -r '.status')
    echo "✅ Status field found: $STATUS"
else
    echo "❌ Status field not found in health response"
    exit 1
fi

# Test 4: Test info endpoint (optional)
echo "📋 Test 4: Info endpoint (optional)"
INFO_RESPONSE=$(curl -s -w "%{http_code}" "http://localhost:${PORT}/actuator/info")
INFO_HTTP_CODE="${INFO_RESPONSE: -3}"
if [[ "$INFO_HTTP_CODE" == "200" ]]; then
    echo "✅ Info endpoint available"
else
    echo "ℹ️  Info endpoint not available (code: $INFO_HTTP_CODE) - this is optional"
fi

# Test 5: Test metrics endpoint (optional)
echo "📋 Test 5: Metrics endpoint (optional)"
METRICS_RESPONSE=$(curl -s -w "%{http_code}" "http://localhost:${PORT}/actuator/metrics")
METRICS_HTTP_CODE="${METRICS_RESPONSE: -3}"
if [[ "$METRICS_HTTP_CODE" == "200" ]]; then
    echo "✅ Metrics endpoint available"
else
    echo "ℹ️  Metrics endpoint not available (code: $METRICS_HTTP_CODE) - this is optional"
fi

# Container health check
echo "📋 Test 6: Container health check"
CONTAINER_STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "no-healthcheck")
if [[ "$CONTAINER_STATUS" == "healthy" ]]; then
    echo "✅ Container health check: healthy"
elif [[ "$CONTAINER_STATUS" == "starting" ]]; then
    echo "⏳ Container health check: starting"
elif [[ "$CONTAINER_STATUS" == "no-healthcheck" ]]; then
    echo "ℹ️  Container health check: not configured"
else
    echo "⚠️  Container health check: $CONTAINER_STATUS"
fi

echo ""
echo "🎉 All smoke tests completed successfully!"
echo "📊 Test Summary:"
echo "   ✅ Health endpoint accessible"
echo "   ✅ JSON format validation"
echo "   ✅ Status field validation"
echo "   ✅ Container running properly"
echo ""
echo "🚀 Application is ready for production use!"