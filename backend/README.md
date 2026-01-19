# Cookstemma - Backend (Spring Boot)

REST API backend for the Cookstemma recipe evolution platform.

## About

Spring Boot backend providing authentication, recipe management, log posts, image storage, and analytics for the Cookstemma mobile application.

**Tech Stack**: Spring Boot 3.5.8 + PostgreSQL + Redis + JWT + S3/MinIO

## Quick Start

```bash
# Start local services (PostgreSQL, Redis, MinIO)
docker-compose up -d

# Run the backend
./gradlew bootRun

# Run tests
./gradlew test
```

**API Base URL**: http://localhost:4000/api/v1

## Documentation

All project documentation has been consolidated to the root-level `docs/ai/` directory:

### For AI Development
- **[CLAUDE.md](../docs/ai/CLAUDE.md)** - Development guide for Claude Code (frontend + backend workflows)
- **[TECHSPEC.md](../docs/ai/TECHSPEC.md)** - Full-stack technical specification
- **[ROADMAP.md](../docs/ai/ROADMAP.md)** - Implementation phases and feature roadmap
- **[CHANGELOG.md](../docs/ai/CHANGELOG.md)** - Project changelog with FE/BE tags
- **[BACKEND_SETUP.md](../docs/ai/BACKEND_SETUP.md)** - **⭐ Complete backend setup guide**

### Quick Links
- **Backend Setup**: See [BACKEND_SETUP.md](../docs/ai/BACKEND_SETUP.md)
- **Backend Architecture**: See [TECHSPEC.md - Backend Architecture](../docs/ai/TECHSPEC.md#backend-architecture)
- **API Contracts**: See [TECHSPEC.md - API Contracts](../docs/ai/TECHSPEC.md#api-contracts)
- **Full-Stack Development**: See [CLAUDE.md - Working Across Frontend and Backend](../docs/ai/CLAUDE.md#working-across-frontend-and-backend)

## Prerequisites

- **Java 21**
- **Docker** (for PostgreSQL, Redis, MinIO)

## Environment Configuration

Create `src/main/resources/application-dev.yml`:

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydatabase
    username: myuser
    password: mypassword

  data:
    redis:
      host: localhost
      port: 6379
      password: mypassword

minio:
  endpoint: http://localhost:9000
  access-key: minioadmin
  secret-key: minioadmin
  bucket: cookstemma-images

jwt:
  secret: your-super-secret-jwt-key-change-this-in-production
  access-token-expiration: 3600000   # 1 hour
  refresh-token-expiration: 2592000000  # 30 days

firebase:
  admin:
    service-account-key: /path/to/firebase-service-account.json
```

**For complete setup instructions**, see [BACKEND_SETUP.md](../docs/ai/BACKEND_SETUP.md).

## Project Structure

```
src/main/java/com/cookstemma/cookstemma/
├── controller/       # REST API endpoints
├── service/          # Business logic layer
├── repository/       # Data access layer (Spring Data JPA)
├── domain/           # JPA entities
├── dto/              # Request/Response DTOs
├── config/           # Configuration (Security, Firebase, S3, Redis, QueryDSL)
├── security/         # Authentication & authorization
├── exception/        # Custom exceptions & error handlers
├── scheduler/        # Scheduled tasks
└── util/             # Utility classes
```

## Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/social-login` | POST | Login with Firebase token |
| `/api/v1/auth/reissue` | POST | Refresh JWT tokens |
| `/api/v1/recipes` | GET | List recipes (paginated) |
| `/api/v1/recipes/{id}` | GET | Get recipe detail |
| `/api/v1/recipes` | POST | Create recipe |
| `/api/v1/log-posts` | GET/POST | List/create log posts |
| `/api/v1/images/upload` | POST | Upload image to S3/MinIO |
| `/api/v1/events` | POST | Track analytics event |
| `/api/v1/events/batch` | POST | Batch track events |

**Full API documentation**: See [TECHSPEC.md - API Contracts](../docs/ai/TECHSPEC.md#api-contracts)

## Database Migrations

Migrations are managed by **Flyway** and run automatically on startup.

**Location**: `src/main/resources/db/migration/`

**Create new migration**: `V{version}__{description}.sql`

Example: `V7__add_hashtags_table.sql`

## Testing

```bash
# Run all tests
./gradlew test

# Run with coverage
./gradlew test jacocoTestReport
```

Integration tests use **TestContainers** to spin up real PostgreSQL instances.

## Docker Deployment

```bash
# Build JAR
./gradlew bootJar

# Build Docker image
docker build -t cookstemma-backend:latest .

# Run with Docker Compose
docker-compose -f docker-compose.prod.yaml up -d
```

## Resources

- Spring Boot Documentation: https://spring.io/projects/spring-boot
- Spring Data JPA: https://spring.io/projects/spring-data-jpa
- QueryDSL: http://querydsl.com/
- Flyway: https://flywaydb.org/
- TestContainers: https://www.testcontainers.org/
