# Modern CRUD API with Java 21 and Virtual Threads

🚀 **Production-ready** CRUD application demonstrating modern Java development with Spring Boot 3.4.5, virtual threads, H2 database, and GraalVM native compilation support.

![Java](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.5-green)
![Virtual Threads](https://img.shields.io/badge/Virtual%20Threads-Enabled-blue)
![H2 Database](https://img.shields.io/badge/Database-H2-yellow)
![GraalVM](https://img.shields.io/badge/GraalVM-Native-purple)

## 📋 Overview

This project showcases a modern Java 21 CRUD application with advanced features:

- **Java 21 Virtual Threads** - Lightweight, high-throughput concurrency
- **Spring Boot 3.4.5** - Latest Spring Boot with native compilation support
- **H2 Database** - In-memory database for development and testing
- **GraalVM Native** - Fast startup and low memory consumption
- **Spring AOT** - Automatic GraalVM hints generation
- **RESTful API** - Complete CRUD operations with validation
- **Async Processing** - Virtual threads for scalable operations

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   REST API      │    │   Service       │    │   Repository    │
│   Controllers   │───▶│   Layer         │───▶│   (JPA/H2)      │
│   (Virtual      │    │   (Virtual      │    │                 │
│   Threads)      │    │   Threads)      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
    ┌────▼────┐              ┌───▼───┐              ┌────▼────┐
    │   DTO   │              │ Entity│              │   H2    │
    │Validation│              │Mapping│              │Database │
    └─────────┘              └───────┘              └─────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Java 21** - OpenJDK 21 or newer
- **Maven 3.8+** - For building the project
- **GraalVM 22.3+** - For native compilation (optional)

### Running the Application

1. **Clone and build**
```bash
git clone <repository-url>
cd mongodb-kafka-connector-example
```

2. **Run with Maven**
```bash
mvn spring-boot:run
```

3. **Or build and run JAR**
```bash
mvn clean package
java -jar target/crud-app-0.0.1-SNAPSHOT.jar
```

The application will start on **http://localhost:8080**

### 🧪 Testing the API

#### Health Check
```bash
curl http://localhost:8080/api/users/health
```

#### Create a User
```bash
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao.silva@email.com",
    "phone": "+55 11 99999-1111"
  }'
```

#### Get All Users (with pagination)
```bash
curl "http://localhost:8080/api/users?page=0&size=10&sort=name,asc"
```

#### Get User by ID
```bash
curl http://localhost:8080/api/users/1
```

#### Update User
```bash
curl -X PUT http://localhost:8080/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva Updated",
    "phone": "+55 11 88888-8888"
  }'
```

#### Virtual Threads Demo - Statistics
```bash
curl http://localhost:8080/api/users/stats
```

#### Delete User
```bash
curl -X DELETE http://localhost:8080/api/users/1
```

## 📊 Features

### Core Components

- ✅ **RESTful CRUD API** - Complete user management operations
- ✅ **Java 21 Virtual Threads** - High-performance concurrent processing
- ✅ **Spring Boot 3.4.5** - Latest framework with native support
- ✅ **H2 Database** - In-memory database for development
- ✅ **JPA/Hibernate** - Object-relational mapping
- ✅ **Bean Validation** - Input validation with custom messages
- ✅ **Exception Handling** - Global error handling and responses
- ✅ **Pagination & Sorting** - Efficient data retrieval
- ✅ **Async Operations** - Virtual threads for background processing

### Production Features

- 🔒 **Validation**: Comprehensive input validation
- 📊 **Monitoring**: Actuator endpoints for health and metrics
- ⚡ **Performance**: Virtual threads for high concurrency
- 🚨 **Error Handling**: Global exception handling with proper HTTP status
- 📖 **Documentation**: Comprehensive API documentation
- 🏗️ **Architecture**: Clean layered architecture (Controller → Service → Repository)

## 🎯 Virtual Threads Demonstration

This application showcases Java 21 virtual threads in several ways:

### 1. Virtual Thread Configuration
```java
@Bean(name = "virtualThreadExecutor")
public Executor virtualThreadExecutor() {
    return Executors.newVirtualThreadPerTaskExecutor();
}
```

### 2. Async Processing
```java
@Async("virtualThreadExecutor")
public CompletableFuture<List<UserResponseDTO>> searchUsersAsync(String searchTerm) {
    return CompletableFuture.supplyAsync(() -> {
        // Processing on virtual thread
        return userRepository.findByNameOrEmailContaining(searchTerm)
                .stream()
                .map(this::mapToResponseDTO)
                .collect(Collectors.toList());
    }, virtualThreadExecutor);
}
```

### 3. Virtual Thread Monitoring
The `/api/users/stats` endpoint shows thread information:
```json
{
  "activeUsers": 5,
  "threadInfo": {
    "currentThread": "VirtualThread[#21]/runnable@ForkJoinPool-1-worker-1",
    "isVirtual": true
  }
}
```

## 🗄️ Database Access

### H2 Console
Access the H2 database console at: **http://localhost:8080/h2-console**

**Connection Details:**
- **JDBC URL**: `jdbc:h2:mem:testdb`
- **Username**: `sa`
- **Password**: `password`

### Database Schema
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
```

## 🔨 Building for Production

### Standard JAR Build
```bash
mvn clean package
java -jar target/crud-app-0.0.1-SNAPSHOT.jar
```

### GraalVM Native Build

1. **Install GraalVM** (if not already installed)
```bash
# Using SDKMAN
sdk install java 22.3.r21-grl
sdk use java 22.3.r21-grl
```

2. **Build Native Image**
```bash
mvn -Pnative native:compile
```

3. **Run Native Executable**
```bash
./target/crud-app
```

### Native Build Benefits
- **Fast Startup**: ~50ms vs ~2-3 seconds for JVM
- **Low Memory**: ~20MB vs ~100MB+ for JVM
- **No Warmup**: Peak performance immediately

## 📋 API Reference

### User Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/users/health` | Application health check |
| `POST` | `/api/users` | Create new user |
| `GET` | `/api/users` | Get all users (paginated) |
| `GET` | `/api/users/{id}` | Get user by ID |
| `PUT` | `/api/users/{id}` | Update user |
| `DELETE` | `/api/users/{id}` | Delete user |
| `GET` | `/api/users/stats` | Get statistics (virtual threads demo) |

### Query Parameters

#### Pagination (`GET /api/users`)
- `page` - Page number (default: 0)
- `size` - Page size (default: 10)
- `sort` - Sort field and direction (e.g., `name,asc`)

### Request/Response Examples

#### Create User Request
```json
{
  "name": "Maria Santos",
  "email": "maria.santos@email.com",
  "phone": "+55 21 99999-2222"
}
```

#### User Response
```json
{
  "id": 1,
  "name": "Maria Santos",
  "email": "maria.santos@email.com",
  "phone": "+55 21 99999-2222",
  "active": true,
  "createdAt": "2025-08-03T22:30:33.768202",
  "updatedAt": "2025-08-03T22:30:33.768213"
}
```

#### Error Response
```json
{
  "status": 400,
  "error": "Validation Failed",
  "message": "Input validation failed",
  "timestamp": "2025-08-03T22:30:33.768202",
  "validationErrors": {
    "email": "Email must be valid",
    "name": "Name is required"
  }
}
```

## 🧪 Testing

### Run Tests
```bash
mvn test
```

### Test Coverage
- **Unit Tests**: Controller layer with MockMvc
- **Integration Tests**: Full application context loading
- **Validation Tests**: Input validation scenarios

## 🏭 Production Deployment

### Environment Variables
```bash
export SPRING_PROFILES_ACTIVE=production
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/crud_db
export SPRING_DATASOURCE_USERNAME=app_user
export SPRING_DATASOURCE_PASSWORD=secure_password
```

### Docker Deployment
```dockerfile
FROM ghcr.io/graalvm/native-image:22.3.0 AS build
COPY . /app
WORKDIR /app
RUN mvn -Pnative native:compile

FROM scratch
COPY --from=build /app/target/crud-app /crud-app
EXPOSE 8080
ENTRYPOINT ["/crud-app"]
```

### Health Monitoring
- **Health**: `GET /actuator/health`
- **Metrics**: `GET /actuator/metrics`
- **Info**: `GET /actuator/info`

## 🛠️ Development

### Project Structure
```
src/
├── main/
│   ├── java/com/celfons/crud/
│   │   ├── CrudApplication.java
│   │   ├── config/
│   │   │   ├── VirtualThreadsConfig.java
│   │   │   └── GraalVMConfig.java
│   │   ├── controller/
│   │   │   └── UserController.java
│   │   ├── service/
│   │   │   └── UserService.java
│   │   ├── repository/
│   │   │   └── UserRepository.java
│   │   ├── entity/
│   │   │   └── User.java
│   │   ├── dto/
│   │   │   ├── UserCreateDTO.java
│   │   │   ├── UserUpdateDTO.java
│   │   │   └── UserResponseDTO.java
│   │   └── exception/
│   │       ├── GlobalExceptionHandler.java
│   │       ├── ResourceNotFoundException.java
│   │       └── BusinessException.java
│   └── resources/
│       └── application.yml
└── test/
    └── java/com/celfons/crud/
        ├── CrudApplicationTests.java
        └── controller/
            └── UserControllerTest.java
```

### Configuration Profiles
- **Development**: In-memory H2 database
- **Test**: Isolated H2 database instance
- **Production**: External database (PostgreSQL, MySQL, etc.)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

#### Virtual Threads Not Working
- Ensure Java 21+ is being used
- Check `Thread.currentThread().isVirtual()` in logs
- Verify virtual thread executor configuration

#### Native Build Fails
- Install GraalVM with native-image tool
- Check reflection configuration hints
- Verify Spring AOT processing

#### Database Connection Issues
- Check H2 console at `/h2-console`
- Verify JDBC URL in configuration
- Ensure database initialization settings

### Getting Help
- Check application logs for detailed error messages
- Use H2 console to inspect database state
- Monitor virtual thread usage via `/api/users/stats`

---

**Made with ❤️ using Java 21, Spring Boot 3.4.5, and Virtual Threads**