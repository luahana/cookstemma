# Backend Setup Guide - Pairing Planet

This guide will help you set up and run the Spring Boot backend for Pairing Planet.

---

## Table of Contents
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Environment Configuration](#environment-configuration)
- [Running Locally](#running-locally)
- [Database Migrations](#database-migrations)
- [Testing](#testing)
- [Docker Deployment](#docker-deployment)
- [Common Issues & Troubleshooting](#common-issues--troubleshooting)

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software
- **Java 21** (OpenJDK or Oracle JDK)
  ```bash
  java -version  # Should show version 21.x.x
  ```

- **Docker** (for PostgreSQL, Redis, MinIO)
  ```bash
  docker --version
  docker-compose --version
  ```

- **Git** (for version control)

### Optional but Recommended
- **IntelliJ IDEA** or **VS Code** with Java extensions
- **Postman** or **Insomnia** for API testing
- **DBeaver** or **pgAdmin** for database management

---

## Initial Setup

### 1. Clone the Repository

```bash
cd pairing_planet
```

### 2. Verify Project Structure

```
pairing_planet/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/pairingplanet/pairing_planet/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   └── test/
├── build.gradle
├── docker-compose.yaml
└── Dockerfile
```

---

## Environment Configuration

### 1. Start Local Services (PostgreSQL, Redis, MinIO)

```bash
docker-compose up -d
```

This starts:
- **PostgreSQL** on port `5432`
  - Database: `mydatabase`
  - User: `myuser`
  - Password: `mypassword`

- **Redis** on port `6379`
  - Password: `mypassword`

- **MinIO** (S3-compatible storage) on ports `9000` (API) and `9001` (Console)
  - User: `minioadmin`
  - Password: `minioadmin`

**Verify services are running**:
```bash
docker-compose ps

# Should show:
# NAME          SERVICE    STATUS    PORTS
# my-postgres   postgres   Up        0.0.0.0:5432->5432/tcp
# my-redis      redis      Up        0.0.0.0:6379->6379/tcp
# my-minio      minio      Up        0.0.0.0:9000-9001->9000-9001/tcp
```

### 2. Create Application Configuration

Create `src/main/resources/application-dev.yml` (this file is gitignored):

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydatabase
    username: myuser
    password: mypassword
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: validate  # Let Flyway handle schema
    show-sql: true        # Log SQL queries (dev only)
    properties:
      hibernate:
        format_sql: true  # Pretty-print SQL
        dialect: org.hibernate.dialect.PostgreSQLDialect

  data:
    redis:
      host: localhost
      port: 6379
      password: mypassword

  flyway:
    enabled: true
    baseline-on-migrate: true
    locations: classpath:db/migration

# MinIO Configuration (S3-compatible)
minio:
  endpoint: http://localhost:9000
  access-key: minioadmin
  secret-key: minioadmin
  bucket: pairing-planet-images

# JWT Configuration
jwt:
  secret: your-super-secret-jwt-key-change-this-in-production-min-256-bits
  access-token-expiration: 3600000   # 1 hour in milliseconds
  refresh-token-expiration: 2592000000  # 30 days in milliseconds

# Firebase Configuration
firebase:
  admin:
    service-account-key: path/to/firebase-service-account.json
    # Or use environment variable: ${FIREBASE_SERVICE_ACCOUNT_KEY_PATH}

# Internal API Key (for bot/scheduled tasks)
internal:
  api:
    key: pairing-planet-dev-internal-key
```

### 3. Firebase Service Account Setup

**Option A: Using Firebase Admin SDK (Recommended)**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one)
3. Go to Project Settings → Service Accounts
4. Click "Generate New Private Key"
5. Download the JSON file
6. Save it as `firebase-service-account.json` in a secure location (NOT in the project repo)
7. Update `application-dev.yml` with the file path

**Option B: Using Environment Variable**

```bash
export FIREBASE_SERVICE_ACCOUNT_KEY_PATH=/path/to/firebase-service-account.json
```

### 4. MinIO Bucket Creation

1. Open MinIO Console: http://localhost:9001
2. Login with `minioadmin` / `minioadmin`
3. Create bucket: `pairing-planet-images`
4. Set bucket policy to public-read (for image URLs)

---

## Running Locally

### Using Gradle

```bash
# Build the project
./gradlew build

# Run the application
./gradlew bootRun

# Run with specific profile
./gradlew bootRun --args='--spring.profiles.active=dev'
```

### Using IDE (IntelliJ IDEA)

1. Open `pairing_planet` folder in IntelliJ
2. Wait for Gradle sync to complete
3. Right-click `PairingPlanetApplication.java`
4. Select "Run 'PairingPlanetApplication'"
5. Or use the Run configuration and set:
   - **Active profiles**: `dev`
   - **VM options**: `-Dspring.profiles.active=dev`

### Verify Backend is Running

```bash
# Health check
curl http://localhost:4001/actuator/health

# Expected response:
# {"status":"UP"}
```

**API Base URL**: `http://localhost:4001/api/v1`

---

## Database Migrations

### Flyway Migration Workflow

**Migrations run automatically** on application startup.

**Migration Files Location**: `src/main/resources/db/migration/`

**Naming Convention**:
- **Versioned**: `V{version}__{description}.sql` (e.g., `V1__init.sql`, `V2__tables.sql`)
- **Repeatable**: `R__{description}.sql` (e.g., `R__insert_foods_master.sql`)

### Creating a New Migration

1. Create a new file in `src/main/resources/db/migration/`:
   ```
   V7__add_hashtags_table.sql
   ```

2. Write your SQL:
   ```sql
   CREATE TABLE hashtags (
       id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
       public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
       tag VARCHAR(50) NOT NULL UNIQUE,
       usage_count INT DEFAULT 0,
       created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
   );

   CREATE INDEX idx_hashtags_usage ON hashtags(usage_count DESC);
   ```

3. Restart the application → Flyway applies the migration automatically

### Flyway Commands

```bash
# Check migration status
./gradlew flywayInfo

# Manually run migrations
./gradlew flywayMigrate

# Repair migration checksums (use with caution)
./gradlew flywayRepair

# Clean database (DANGEROUS - drops all tables)
./gradlew flywayClean
```

### Important Migration Rules

1. **NEVER modify applied migrations** - create new versioned migrations instead
2. **Test migrations locally** before committing
3. **Use transactions** where possible (Flyway auto-wraps most SQL)
4. **Soft delete** - always add `deleted_at` columns, never hard delete

---

## Testing

### Unit Tests

```bash
# Run all tests
./gradlew test

# Run specific test class
./gradlew test --tests RecipeServiceTest

# Run tests with coverage
./gradlew test jacocoTestReport
```

### Integration Tests with TestContainers

Integration tests use **TestContainers** to spin up real PostgreSQL instances.

**Example Test**:
```java
@SpringBootTest
@Testcontainers
class RecipeServiceIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("test")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Test
    void testCreateRecipe() {
        // Test with real database
    }
}
```

**Run integration tests**:
```bash
./gradlew integrationTest  # If configured separately
# OR
./gradlew test  # Runs all tests including integration
```

---

## Docker Deployment

### Build Docker Image

```bash
# Build JAR
./gradlew bootJar

# Build Docker image
docker build -t pairing-planet-backend:latest .

# Or using Docker Compose
docker-compose -f docker-compose.prod.yaml build
```

### Run with Docker Compose (Production)

Create `docker-compose.prod.yaml`:

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "4001:4001"
    environment:
      SPRING_PROFILES_ACTIVE: prod
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/pairingplanet
      SPRING_DATASOURCE_USERNAME: ${DB_USERNAME}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      SPRING_DATA_REDIS_HOST: redis
      JWT_SECRET: ${JWT_SECRET}
      FIREBASE_SERVICE_ACCOUNT_KEY_PATH: /app/secrets/firebase-key.json
    volumes:
      - ./secrets:/app/secrets:ro
    depends_on:
      - postgres
      - redis
    networks:
      - app-network

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: pairingplanet
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

**Run**:
```bash
docker-compose -f docker-compose.prod.yaml up -d
```

---

## Common Issues & Troubleshooting

### Issue 1: Port Already in Use

**Error**: `Port 4001 is already in use`

**Solution**:
```bash
# Find process using port 4001
lsof -i :4001  # macOS/Linux
netstat -ano | findstr :4001  # Windows

# Kill the process or change port in application.yml
server:
  port: 8080
```

### Issue 2: Database Connection Refused

**Error**: `Connection refused: localhost:5432`

**Solution**:
```bash
# Check if PostgreSQL container is running
docker-compose ps

# Restart PostgreSQL
docker-compose restart postgres

# Check logs
docker-compose logs postgres
```

### Issue 3: Flyway Migration Checksum Mismatch

**Error**: `Migration checksum mismatch for migration version X`

**Cause**: Someone modified an already-applied migration

**Solution**:
```bash
# Option 1: Repair checksums (if safe)
./gradlew flywayRepair

# Option 2: Drop database and start fresh (dev only!)
docker-compose down -v
docker-compose up -d
./gradlew bootRun
```

### Issue 4: Firebase Authentication Fails

**Error**: `Failed to initialize Firebase SDK`

**Solution**:
1. Verify `firebase-service-account.json` path is correct
2. Check file permissions (should be readable)
3. Verify JSON file is valid (not corrupted)
4. Check Firebase project settings match the JSON file

### Issue 5: Redis Connection Timeout

**Error**: `Unable to connect to Redis`

**Solution**:
```bash
# Test Redis connection
redis-cli -h localhost -p 6379 -a mypassword ping
# Should return: PONG

# If fails, restart Redis
docker-compose restart redis
```

### Issue 6: MinIO Bucket Not Found

**Error**: `The specified bucket does not exist`

**Solution**:
1. Open MinIO Console: http://localhost:9001
2. Login with `minioadmin` / `minioadmin`
3. Create bucket: `pairing-planet-images`
4. Set bucket policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {"AWS": ["*"]},
         "Action": ["s3:GetObject"],
         "Resource": ["arn:aws:s3:::pairing-planet-images/*"]
       }
     ]
   }
   ```

### Issue 7: Gradle Build Fails

**Error**: `Could not resolve dependencies`

**Solution**:
```bash
# Clear Gradle cache
./gradlew clean

# Refresh dependencies
./gradlew build --refresh-dependencies

# Use Gradle wrapper (recommended)
./gradlew build  # NOT gradle build
```

---

## Environment Variables Reference

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `dev`, `prod` | Yes |
| `SPRING_DATASOURCE_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/db` | Yes |
| `SPRING_DATASOURCE_USERNAME` | Database username | `myuser` | Yes |
| `SPRING_DATASOURCE_PASSWORD` | Database password | `mypassword` | Yes |
| `SPRING_DATA_REDIS_HOST` | Redis host | `localhost` | Yes |
| `SPRING_DATA_REDIS_PASSWORD` | Redis password | `mypassword` | Yes |
| `JWT_SECRET` | JWT signing secret (256-bit min) | `your-secret-key` | Yes |
| `FIREBASE_SERVICE_ACCOUNT_KEY_PATH` | Path to Firebase JSON | `/path/to/firebase.json` | Yes |
| `AWS_ACCESS_KEY` | AWS S3 access key | `AKIAIOSFODNN7EXAMPLE` | If using S3 |
| `AWS_SECRET_KEY` | AWS S3 secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCY` | If using S3 |
| `MINIO_ENDPOINT` | MinIO endpoint | `http://localhost:9000` | If using MinIO |
| `INTERNAL_API_KEY` | Internal API authentication | `bot-secret-key` | Yes |

---

## API Documentation

### Swagger/OpenAPI (Optional)

To enable Swagger UI, add to `build.gradle`:

```gradle
implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.2.0'
```

Access: http://localhost:4001/swagger-ui.html

### Manual API Testing

**Example: Create Recipe**

```bash
# 1. Login to get access token
curl -X POST http://localhost:4001/api/v1/auth/social-login \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "GOOGLE",
    "idToken": "firebase-id-token-here",
    "locale": "ko-KR"
  }'

# Response: { "accessToken": "...", "refreshToken": "..." }

# 2. Create recipe
curl -X POST http://localhost:4001/api/v1/recipes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access-token>" \
  -d '{
    "title": "My Recipe",
    "description": "Delicious",
    "ingredients": [{"name": "Salt", "amount": "1g", "type": "SEASONING"}],
    "steps": [{"stepNumber": 1, "instruction": "Mix"}],
    "imagePublicIds": [],
    "locale": "ko-KR"
  }'
```

---

## Next Steps

Once your backend is running:

1. ✅ Verify health endpoint: http://localhost:4001/actuator/health
2. ✅ Test authentication with Postman/Insomnia
3. ✅ Run frontend and connect to backend (see [CLAUDE.md](CLAUDE.md#working-across-frontend-and-backend))
4. ✅ Implement analytics endpoints (`/events`, `/events/batch`) - see [CHANGELOG.md](CHANGELOG.md)
5. ✅ Set up production environment (AWS RDS, ElastiCache, S3)

For full architecture details, see [TECHSPEC.md](TECHSPEC.md).
For development workflows, see [CLAUDE.md](CLAUDE.md).
