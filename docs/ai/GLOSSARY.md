# GLOSSARY.md — Pairing Planet

> Domain terminology and definitions. Ensures consistent language across code and docs.

---

## How to Use This File

**Claude Code:** Before adding a term, ASK the user:
> "Should I add '[term]' to GLOSSARY.md?"

**When to add:** New domain concept, confusing term, or term used differently than common meaning.

---

# Core Concepts

| Term | Definition | Example |
|------|------------|---------|
| **Recipe** | A dish with ingredients and cooking steps. Can be original or a variation. | "김치찌개 레시피" |
| **Original Recipe** | A recipe with no parent. The root of a variation tree. `parentPublicId = null` | First version of a dish |
| **Variation** | A recipe created by modifying another recipe. Has `parentPublicId` and `rootPublicId`. | "매운 김치찌개" (spicier version) |
| **Parent Recipe** | The direct recipe a variation was created from. | If A → B → C, B is parent of C |
| **Root Recipe** | The original recipe at the top of a variation tree. | If A → B → C, A is root of C |
| **Variation Tree** | The hierarchy of all recipes derived from one original. | A family tree of recipe modifications |
| **Log Post** | A cooking attempt record with photos, notes, and outcome. | "오늘 김치찌개 만들었어요 😊" |
| **Cooking Log** | Same as Log Post. Used interchangeably. | — |

---

# Outcome Types

| Term | Emoji | Meaning |
|------|-------|---------|
| **SUCCESS** | 😊 | Cooking attempt went well |
| **PARTIAL** | 😐 | Okay but not perfect |
| **FAILED** | 😢 | Did not turn out well |

---

# Ingredient Types

| Term | Korean | Used For |
|------|--------|----------|
| **MAIN** | 주재료 | Primary ingredients (meat, vegetables) |
| **SECONDARY** | 부재료 | Supporting ingredients |
| **SEASONING** | 양념 | Spices, sauces, seasonings |

---

# Technical Terms

| Term | Definition | Code Example |
|------|------------|--------------|
| **publicId** | UUID exposed in API. Never expose internal `id`. | `recipe.publicId` (UUID) |
| **id** | Internal database auto-increment. Never expose. | `recipe.id` (Long) |
| **DTO** | Data Transfer Object. Used for API requests/responses. | `RecipeDetailDto` |
| **Entity** | Domain object. Pure Dart, no annotations. | `RecipeEntity` |
| **Slice** | Spring paginated response with `content` array. | `{ content: [], last: false }` |
| **Page** | Alternative pagination with `totalElements`. | `{ content: [], totalElements: 100 }` |

---

# Architecture Terms

| Term | Definition | Location |
|------|------------|----------|
| **Repository** | Interface for data access. Returns `Either<Failure, T>`. | `lib/domain/repositories/` |
| **DataSource** | Implementation that fetches data (remote or local). | `lib/data/datasources/` |
| **Provider** | Riverpod state holder. Watches or reads repositories. | `lib/features/*/providers/` |
| **UseCase** | Business logic unit (optional layer). | `lib/domain/usecases/` |
| **Failure** | Typed error returned in `Either.Left`. | `ServerFailure`, `ConnectionFailure` |

---

# User Types

| Term | Definition | Permissions |
|------|------------|-------------|
| **Anonymous User** | Browsing without login | View only, no create |
| **Authenticated User** | Logged in with social account | Full access |
| **Creator** | User who creates recipes/logs | Owner permissions on their content |

---

# API Terms

| Term | Definition | Example |
|------|------------|---------|
| **Endpoint** | API URL path | `/api/v1/recipes` |
| **Access Token** | Short-lived JWT for API auth | Expires in 1 hour |
| **Refresh Token** | Long-lived token to get new access token | Expires in 30 days |
| **Bearer Token** | Token format in Authorization header | `Bearer eyJhbG...` |

---

# Database Terms

| Term | Definition | Example |
|------|------------|---------|
| **posts** | Database table for recipes (legacy name) | `SELECT * FROM posts` |
| **log_posts** | Database table for cooking logs | `SELECT * FROM log_posts` |
| **Flyway** | Database migration tool | `V1__create_tables.sql` |
| **Migration** | SQL script to change database schema | Versioned files in `db/migration/` |

---

# Cache Terms

| Term | Definition |
|------|------------|
| **Cache-first** | Load cached data immediately, then refresh from network |
| **Network-first** | Try network first, fall back to cache on failure |
| **TTL** | Time To Live - how long cached data is valid (5 min for profile) |
| **Invalidation** | Marking cached data as stale/outdated |
| **CachedData<T>** | Generic wrapper holding data + cachedAt timestamp for staleness tracking |
| **Stale Data** | Cached data past its TTL, shown with orange indicator banner |
| **Hive Box** | Named container for Hive key-value storage (e.g., `profile_cache`) |

---

# Event Tracking Terms

| Term | Definition |
|------|------------|
| **Outbox Pattern** | Queue events locally in Isar, sync to server reliably with retry |
| **EventPriority** | Enum: IMMEDIATE (writes), HIGH, NORMAL, LOW (analytics) |
| **SyncStatus** | Enum: PENDING, SYNCING, SYNCED, FAILED |
| **Idempotency Key** | UUID to prevent duplicate event processing on retry |
| **EventSyncManager** | Background service that syncs queued events to server |

---

# Image Terms

| Term | Definition |
|------|------------|
| **ImageVariants** | Frontend entity containing URLs for all image sizes (original, large, medium, thumb, small) |
| **ImageVariant** | Backend enum: ORIGINAL, LARGE_1200, MEDIUM_800, THUMB_400, THUMB_200 |
| **Device Pixel Ratio** | Screen density multiplier (1x, 2x, 3x) used to select optimal image size |
| **getBestUrl()** | Method to select optimal image variant based on displayWidth × devicePixelRatio |

---

# Search Terms

| Term | Definition |
|------|------------|
| **SearchType** | Enum distinguishing recipe search vs log post search |
| **Search History** | Recent searches stored locally in Hive, per SearchType |
| **Search Suggestions** | Real-time suggestions shown while typing in search bar |
| **EnhancedSearchAppBar** | Custom search bar widget with suggestions overlay |

---

# Korean Terms in Code

| Korean | English | Used Where |
|--------|---------|------------|
| 레시피 | Recipe | UI labels |
| 요리 기록 | Cooking Log | UI labels |
| 저장 | Save/Bookmark | UI labels |
| 팔로우 | Follow | UI labels |
| 오프라인 데이터 | Offline Data | Cache indicator |

---

See [FEATURES.md](FEATURES.md) for feature descriptions.
See [TECHSPEC.md](TECHSPEC.md) for technical architecture.
