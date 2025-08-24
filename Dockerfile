# Multi-stage Dockerfile for GraalVM Native Build with Alpine Linux and musl

# Stage 1: Build stage with GraalVM and Maven
FROM ghcr.io/graalvm/graalvm-community:21-muslib AS builder

# Install required packages for native build
RUN microdnf install -y findutils

# Set working directory
WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .

# Make Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (for better caching)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build native executable with musl static linking
RUN ./mvnw clean -Pnative native:compile -DskipTests

# Stage 2: Runtime stage with Alpine Linux
FROM alpine:3.19

# Install required runtime dependencies
RUN apk add --no-cache \
    libc6-compat \
    && addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy the native executable from builder stage
COPY --from=builder /app/target/rinha /app/rinha

# Change ownership to non-root user
RUN chown appuser:appgroup /app/rinha && \
    chmod +x /app/rinha

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Set memory limits for native image
ENV JAVA_OPTS="-XX:MaxRAMPercentage=80.0"

# Run the native executable
ENTRYPOINT ["./rinha"]