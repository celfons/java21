# Product CRUD API - Java 21 Virtual Threads + MongoDB Atlas

🚀 **Modern CRUD API** built with Java 21 Virtual Threads, Spring Boot 3.4.5, and MongoDB Atlas with GraalVM native compilation support.

![Java 21](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.5-green)
![MongoDB Atlas](https://img.shields.io/badge/MongoDB-Atlas-green)
![GraalVM](https://img.shields.io/badge/GraalVM-Native-blue)
![Virtual Threads](https://img.shields.io/badge/Virtual%20Threads-Enabled-purple)

## 📋 Overview

This project demonstrates a **cloud-native** CRUD application with:

- **Java 21 Virtual Threads** for superior scalability
- **Spring Boot 3.4.5** with native support for virtual threads
- **MongoDB Atlas** cloud database integration
- **SOLID principles** and **Clean Code** architecture
- **GraalVM native compilation** for ultra-fast startup and low memory usage
- **Docker multi-stage build** with Alpine Linux and musl for minimal images

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │    │   Spring Boot   │    │   MongoDB       │
│   Applications  │───▶│   API           │───▶│   Atlas         │
│                 │    │   (Virtual      │    │   (Cloud)       │
└─────────────────┘    │   Threads)      │    └─────────────────┘
                       └─────────────────┘
```

**Key Features:**
- **Virtual Threads**: Native Java 21 virtual threads for handling thousands of concurrent requests
- **Clean Architecture**: Separated layers (Controller → Service → Repository → Model)
- **SOLID Principles**: Interface segregation, dependency inversion, single responsibility
- **Native Compilation**: GraalVM for lightning-fast startup and minimal memory footprint

## 🚀 Quick Start

### Prerequisites

- **Java 21** (OpenJDK or Oracle JDK)
- **Maven 3.8+**
- **Docker 20.0+** (for containerized deployment)
- **MongoDB Atlas Cluster** (free tier available at [mongodb.com/atlas](https://mongodb.com/atlas))

### 1. MongoDB Atlas Setup

1. Create a free MongoDB Atlas account
2. Create a new cluster
3. Create a database user with read/write permissions
4. Whitelist your IP address (or use 0.0.0.0/0 for development)
5. Get your connection string from the Atlas dashboard

### 2. Configure Database Connection

Edit `src/main/resources/application.properties`:

```properties
spring.data.mongodb.uri=mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@YOUR_CLUSTER.mongodb.net/productdb?retryWrites=true&w=majority
```

Replace:
- `YOUR_USERNAME` with your Atlas database username
- `YOUR_PASSWORD` with your Atlas database password
- `YOUR_CLUSTER` with your Atlas cluster name

### 3. Local Development

#### Option A: Traditional JVM Build

```bash
# Clone the repository
git clone <repository-url>
cd mongodb-kafka-connector-example

# Build and run
./mvnw spring-boot:run
```

#### Option B: Native Build (Requires GraalVM)

```bash
# Install GraalVM 21 with native-image
# Download from: https://www.graalvm.org/downloads/

# Build native executable
./mvnw clean -Pnative native:compile

# Run native executable
./target/product-crud
```

### 4. Docker Deployment

#### Build and Run with Docker

```bash
# Build native Docker image (requires more time and resources)
docker build -t product-crud-native .

# OR build JVM Docker image (faster, for development)
# First build the JAR locally:
./mvnw clean package -DskipTests

# Then build the simple Docker image:
docker build -f Dockerfile.simple -t product-crud-jvm .

# Run container with environment variables
docker run -p 8080:8080 \
  -e SPRING_DATA_MONGODB_URI="mongodb+srv://USERNAME:PASSWORD@CLUSTER.mongodb.net/productdb?retryWrites=true&w=majority" \
  product-crud-jvm
```

#### Using Docker Compose (Optional)

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  product-crud:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATA_MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@CLUSTER.mongodb.net/productdb?retryWrites=true&w=majority
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

```bash
docker-compose up --build
```

## 📡 API Endpoints

### Product CRUD Operations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/products` | Create a new product |
| `GET` | `/api/products` | Get all products |
| `GET` | `/api/products/{id}` | Get product by ID |
| `PUT` | `/api/products/{id}` | Update product |
| `DELETE` | `/api/products/{id}` | Delete product |
| `GET` | `/api/products/search?name={name}` | Search products by name |
| `GET` | `/api/products/price-range?min={min}&max={max}` | Filter by price range |

### Product JSON Schema

```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "price": "number",
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Example Requests

#### Create Product
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop Pro",
    "description": "High-performance laptop for developers",
    "price": 1299.99
  }'
```

#### Get All Products
```bash
curl http://localhost:8080/api/products
```

#### Search Products
```bash
curl "http://localhost:8080/api/products/search?name=laptop"
```

## 🔧 Development

### Project Structure

```
src/
├── main/
│   ├── java/com/celfons/productcrud/
│   │   ├── ProductCrudApplication.java       # Main application class
│   │   ├── controller/
│   │   │   └── ProductController.java        # REST API endpoints
│   │   ├── service/
│   │   │   ├── ProductService.java           # Service interface
│   │   │   └── ProductServiceImpl.java       # Business logic
│   │   ├── repository/
│   │   │   └── ProductRepository.java        # Data access layer
│   │   ├── model/
│   │   │   └── Product.java                  # Entity model
│   │   └── config/
│   │       └── VirtualThreadConfig.java      # Virtual threads config
│   └── resources/
│       └── application.properties            # Configuration
└── test/
    └── java/com/celfons/productcrud/        # Unit tests
```

### Virtual Threads Configuration

The application is configured to use Java 21 virtual threads through:

1. **Spring Boot Property**: `spring.threads.virtual.enabled=true`
2. **Custom Configuration**: `VirtualThreadConfig.java` provides custom executor
3. **Automatic**: Spring Boot 3.x automatically detects and uses virtual threads when available

### Testing

```bash
# Run all tests
./mvnw test

# Run tests with coverage
./mvnw test jacoco:report

# Integration tests (requires MongoDB Atlas connection)
./mvnw test -Dspring.profiles.active=integration
```

## 🚢 Production Deployment

### Performance Characteristics

#### JVM Deployment
- **Startup Time**: ~3-5s 
- **Memory Usage**: ~200-300MB  
- **Throughput**: 10,000+ concurrent requests with virtual threads
- **Image Size**: ~270MB (Alpine + JRE + JAR)

#### Native Deployment (GraalVM)
- **Startup Time**: ~50ms (native binary)
- **Memory Usage**: ~20-50MB (native binary)  
- **Throughput**: 10,000+ concurrent requests with virtual threads
- **Image Size**: ~50MB (Alpine + native binary)

**Note**: Native compilation provides faster startup and lower memory usage but requires longer build times.

### Monitoring

The application includes Spring Boot Actuator endpoints:

- `/actuator/health` - Health check
- `/actuator/info` - Application info
- `/actuator/metrics` - Application metrics

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_DATA_MONGODB_URI` | MongoDB Atlas connection string | Required |
| `SERVER_PORT` | Server port | `8080` |
| `SPRING_PROFILES_ACTIVE` | Active profiles | `default` |

## 🔍 Architecture Principles

### SOLID Principles Implementation

1. **Single Responsibility**: Each class has one reason to change
   - `ProductController`: Handles HTTP requests
   - `ProductService`: Contains business logic
   - `ProductRepository`: Manages data access

2. **Open/Closed**: Open for extension, closed for modification
   - Interface-based design allows easy extension
   - New features can be added without modifying existing code

3. **Liskov Substitution**: Derived classes are substitutable
   - `ProductServiceImpl` can be replaced with any `ProductService` implementation

4. **Interface Segregation**: Clients depend only on interfaces they use
   - `ProductService` interface contains only necessary methods

5. **Dependency Inversion**: Depend on abstractions, not concretions
   - Controller depends on `ProductService` interface
   - Service depends on `ProductRepository` interface

### Clean Code Practices

- **Meaningful Names**: Clear, descriptive variable and method names
- **Small Functions**: Each method does one thing well
- **Comments**: Only where necessary, code is self-documenting
- **Error Handling**: Proper exception handling with meaningful messages
- **Consistent Formatting**: Following Java conventions

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email [your-email@example.com] or create an issue in the repository.

---

Built with ❤️ using Java 21 Virtual Threads and MongoDB Atlas