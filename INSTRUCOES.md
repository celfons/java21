# Rinha de Backend 2025 - Implementation Instructions

## Challenge Overview

This implementation follows the Rinha de Backend 2025 challenge specifications for a high-performance payment processing API.

## Key Requirements Met

### 1. Project Setup ✅
- **Group**: `dev.rinha`
- **Artifact**: `rinha`
- **Java 21** with virtual threads enabled
- **Spring Boot 3.4.5**
- **Dependencies**: web, actuator (minimal), validation, lettuce/redis, native support
- **Build support**: Both JVM and GraalVM native
- **Makefile**: All required targets implemented

### 2. API Endpoints ✅

#### POST /payments
- Accepts JSON with `correlationId` (UUID) and `amount` (decimal)
- Full validation with proper error responses
- Idempotency using Redis SETNX (`payments:cid:{correlationId}`)
- Routes to default processor, fallback when circuit breaker open
- Updates aggregation only after upstream success
- Returns 200 with empty body on success

#### GET /payments-summary
- Query parameters: `from`, `to` (ISO8601 or epoch, optional)
- Returns aggregated totals by processor type
- Long cents internally, string decimal externally
- Interval information included in response

#### Health Endpoints ✅
- `/actuator/health/liveness` - lightweight endpoint
- Does not exceed processor health check limits (1 request per 5s)
- Internal scheduler for baseline metrics (not implemented in this basic version)

### 3. External Processors Integration ✅

#### HTTP Client
- Uses `java.net.http.HttpClient` singleton
- Virtual thread executor for requests
- Configurable base URLs via environment variables
- Timeouts: 50ms connect, 80ms overall

#### Circuit Breaker
- States: CLOSED, OPEN, HALF_OPEN
- Opens after 3 consecutive failures
- Open duration: 750ms
- Half-open: 2 test requests
- No speculative parallel requests

### 4. Idempotency ✅
- Redis SETNX with key pattern: `payments:cid:{correlationId}`
- 30-minute TTL on idempotency keys
- Atomic operations for consistency
- Proper cleanup on failures

### 5. Infrastructure ✅
- **HAProxy**: Load balancer configuration
- **Docker Compose**: Complete setup with Redis
- **Resource limits**: Optimized for profit maximization
- **Health checks**: Proper monitoring and failover

## Performance Characteristics

### Optimizations
- **Virtual Threads**: Handle thousands of concurrent requests
- **Native Compilation**: ~50MB memory footprint
- **Redis Pooling**: Optimized connection management
- **Circuit Breaker**: Prevents cascade failures
- **Timeouts**: Aggressive but safe (50ms/80ms)

### Resource Usage
- **Application**: 200MB RAM, 0.5 CPU per instance
- **Redis**: 300MB RAM, 0.5 CPU
- **HAProxy**: 50MB RAM, 0.2 CPU
- **Total**: ~750MB RAM, ~1.4 CPU for full setup

## Running the Implementation

### Quick Start
```bash
# Build and start infrastructure
make docker-native
make up

# Test the API
./scripts/test-api.sh

# Run load tests
make load-test

# Monitor via HAProxy stats
open http://localhost:8404/stats
```

### Environment Configuration
```bash
REDIS_HOST=redis
PROCESSOR_DEFAULT_URL=http://haproxy:8081
PROCESSOR_FALLBACK_URL=http://haproxy:8082
```

## Architecture Decisions

### Why Virtual Threads?
- Eliminates thread pool bottlenecks
- Handles massive concurrency with minimal overhead
- Natural backpressure handling
- Perfect for I/O-heavy workloads like payment processing

### Why Redis?
- Atomic operations for idempotency (SETNX)
- High-performance aggregation storage
- Proven scalability for financial systems
- Simple data model for this use case

### Why Circuit Breaker?
- Prevents cascade failures to external processors
- Automatic recovery mechanism
- Configurable thresholds for different failure scenarios
- Essential for high-availability payment systems

## Compliance Notes

This implementation strictly follows the challenge requirements:
- No speculative requests to processors
- Proper timeout handling
- Idempotency guaranteed via Redis
- Aggregation updates only after successful processing
- Health check rate limiting respected
- Resource usage optimized for profit

The solution balances performance, reliability, and cost-effectiveness to achieve maximum score in the Rinha de Backend 2025 challenge.