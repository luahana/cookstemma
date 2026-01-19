# Pairing Planet - Frontend (Flutter)

Mobile-only Flutter application for the Pairing Planet recipe evolution platform.

## About

Pairing Planet treats recipes as an **evolving knowledge graph** rather than static content. The app documents how recipes survive, evolve, and branch through user experimentation.

**Tech Stack**: Flutter + Riverpod + Dio + Firebase Auth + Isar (offline-first)

## Quick Start

```bash
# Install dependencies
flutter pub get

# Generate code (required after modifying DTOs)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Documentation

All project documentation has been consolidated to the root-level `docs/ai/` directory:

### For AI Development
- **[CLAUDE.md](../docs/ai/CLAUDE.md)** - Development guide for Claude Code (frontend + backend workflows)
- **[TECHSPEC.md](../docs/ai/TECHSPEC.md)** - Full-stack technical specification
- **[ROADMAP.md](../docs/ai/ROADMAP.md)** - Implementation phases and feature roadmap
- **[CHANGELOG.md](../docs/ai/CHANGELOG.md)** - Project changelog with FE/BE tags
- **[BACKEND_SETUP.md](../docs/ai/BACKEND_SETUP.md)** - Backend setup instructions

### Quick Links
- **Frontend Architecture**: See [CLAUDE.md - Frontend Section](../docs/ai/CLAUDE.md#frontend-flutter-mobile-app)
- **Backend API Contracts**: See [TECHSPEC.md - API Contracts](../docs/ai/TECHSPEC.md#api-contracts)
- **Full-Stack Development**: See [CLAUDE.md - Working Across Frontend and Backend](../docs/ai/CLAUDE.md#working-across-frontend-and-backend)

## Environment Setup

Create `.env` file in project root:

```
BASE_URL=http://10.0.2.2:4000/api/v1  # Android emulator localhost
ENV=dev
```

## Project Structure

```
lib/
├── core/          # Router, network, constants, providers
├── domain/        # Entities, repositories, use cases
├── data/          # DTOs, data sources, repository implementations
├── features/      # Feature modules (recipe, log_post, auth, home)
└── shared/        # Shared utilities
```

## Resources

- Flutter Documentation: https://docs.flutter.dev/
- Riverpod: https://riverpod.dev/
- Firebase: https://firebase.google.com/docs/flutter/setup
