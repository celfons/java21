#!/bin/bash
# Build script for Product CRUD API

set -e

echo "🚀 Building Product CRUD API with Java 21 Virtual Threads"
echo "=================================================="

# Check Java version
echo "📋 Checking Java version..."
java -version

# Build the application
echo "🔨 Building application with Maven..."
./mvnw clean package -DskipTests

echo "✅ Build completed successfully!"

# Optional: Build Docker images
if [ "$1" = "--docker" ]; then
    echo "🐳 Building Docker images..."
    
    # Build JVM image
    echo "Building JVM Docker image..."
    docker build -f Dockerfile.simple -t product-crud:jvm-latest .
    
    # Optionally build native image (commented out due to long build time)
    # echo "Building native Docker image (this may take 10-30 minutes)..."
    # docker build -t product-crud:native-latest .
    
    echo "✅ Docker images built successfully!"
    docker images | grep product-crud
fi

echo ""
echo "🎉 Build process completed!"
echo ""
echo "📚 Next steps:"
echo "  1. Configure MongoDB Atlas connection in application.properties"
echo "  2. Run locally: java -jar target/product-crud-1.0.0.jar"
echo "  3. Or run with Docker: docker run -p 8080:8080 product-crud:jvm-latest"
echo "  4. API will be available at http://localhost:8080/api/products"
echo "  5. Health check: http://localhost:8080/actuator/health"