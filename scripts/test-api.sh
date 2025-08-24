#!/bin/bash
# Simple test script for the Rinha API

BASE_URL="${1:-http://localhost:8080}"

echo "🧪 Testing Rinha de Backend 2025 API"
echo "Base URL: $BASE_URL"
echo ""

# Test health endpoint
echo "📋 Testing health endpoint..."
curl -s "$BASE_URL/actuator/health" | jq . 2>/dev/null || curl -s "$BASE_URL/actuator/health"
echo ""

# Test POST /payments
echo "💰 Testing POST /payments..."
CORRELATION_ID=$(uuidgen 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "$(date +%s)-test")
RESPONSE=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/payments" \
    -H "Content-Type: application/json" \
    -d "{\"correlationId\":\"$CORRELATION_ID\",\"amount\":123.45}")

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

echo "Status: $HTTP_CODE"
if [ "$BODY" != "" ]; then
    echo "Body: $BODY"
fi
echo ""

# Test GET /payments-summary
echo "📊 Testing GET /payments-summary..."
curl -s "$BASE_URL/payments-summary" | jq . 2>/dev/null || curl -s "$BASE_URL/payments-summary"
echo ""

# Test idempotency
echo "🔄 Testing idempotency with same correlationId..."
RESPONSE2=$(curl -s -w "%{http_code}" -X POST "$BASE_URL/payments" \
    -H "Content-Type: application/json" \
    -d "{\"correlationId\":\"$CORRELATION_ID\",\"amount\":123.45}")

HTTP_CODE2="${RESPONSE2: -3}"
BODY2="${RESPONSE2%???}"

echo "Status: $HTTP_CODE2"
if [ "$BODY2" != "" ]; then
    echo "Body: $BODY2"
fi
echo ""

echo "✅ Test completed!"