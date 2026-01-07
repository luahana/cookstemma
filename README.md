# Pairing Planet Fullstack

Monorepo containing all Pairing Planet applications - a recipe sharing and cooking community platform.

## Project Structure

```
pairing_planet_fullstack/
├── backend/              # Spring Boot API (Java 21)
├── frontend_mobile/      # Flutter mobile app (iOS/Android)
├── frontend_web/         # Next.js web app (planned)
├── .github/workflows/    # CI/CD pipelines
└── docker-compose.yml    # Local development stack
```

## Quick Start

### Prerequisites
- Docker & Docker Compose
- Java 21 (for backend development)
- Flutter 3.24+ (for mobile development)
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

#### Frontend Mobile (Flutter)
```bash
cd frontend_mobile
flutter pub get
flutter run
```

#### Frontend Web (Next.js) - Coming Soon
```bash
cd frontend_web
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

### Frontend Mobile
- **Framework**: Flutter 3.24+
- **State**: Riverpod
- **HTTP**: Dio
- **Storage**: Hive, Isar
- **Auth**: Firebase Auth, Google Sign-In, Sign in with Apple

### Frontend Web (Planned)
- **Framework**: Next.js 14+
- **Auth**: NextAuth.js
- **Styling**: Tailwind CSS

## Deployment

### Backend
- **Dev**: AWS ECS (us-east-2) - Rolling update
- **Staging/Prod**: AWS ECS (ap-northeast-2) - Blue/Green via CodeDeploy

See [backend/DEPLOYMENT.md](backend/DEPLOYMENT.md) for details.

## Contributing

1. Create a feature branch from `dev`
2. Make your changes
3. Submit a PR to `dev`
4. After review, merge to `staging` for testing
5. Finally merge to `main`/`master` for production

## License

Private - All rights reserved
