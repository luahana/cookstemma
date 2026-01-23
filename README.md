# Cookstemma Fullstack

Monorepo containing all Cookstemma applications - Your personal cooking journal. Log meals, track your progress, and grow as a home cook. Discover recipes and share your culinary journey platform.

## Project Structure

```
cookstemma/
├── backend/              # Spring Boot API (Java 21)
├── frontend_web/         # Next.js web app (planned)
├── .github/workflows/    # CI/CD pipelines
└── docker-compose.yml    # Local development stack
```

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Java 21 (for backend development)
- Node.js 18+ (for web development)

### Local Development with Docker

Start all services:
```bash
docker-compose up -d
```

This starts:
- **Backend API**: http://localhost:4000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **MinIO (S3)**: http://localhost:9000 (Console: http://localhost:9001)

### Individual Project Setup

#### Backend (Spring Boot)
```bash
cd backend
./gradlew bootRun --args='--spring.profiles.active=dev'
```

#### Web (Next.js) - Coming Soon
```bash
cd web
npm install
npm run dev
```

## Architecture

### Backend
- **Framework**: Spring Boot 3.x with Java 21
- **Database**: PostgreSQL 16
- **Cache**: Redis
- **Storage**: AWS S3 / MinIO (local dev)
- **Auth**: Firebase Authentication + JWT

### Web
- **Framework**: Next.js 14+
- **Auth**: NextAuth.js
- **Styling**: Tailwind CSS

## Deployment

### Backend
- **Dev**: AWS ECS (us-east-2) - Rolling update
- **Staging/Prod**: AWS ECS (us-east-2) - Rolling update

See [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md) for details.


## License

Private - All rights reserved
