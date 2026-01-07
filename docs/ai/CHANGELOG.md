# Production Enhancements Changelog

**Legend**:
- `[FE]` - Frontend-only changes
- `[BE]` - Backend-only changes
- `[FE+BE]` - Changes spanning both frontend and backend

---

## Phase 1: Event Tracking Infrastructure ✅ (Completed: 2026-01-05)

### Overview
`[FE+BE]` Implemented event-based architecture with Outbox pattern for analytics and ML data collection.

### What Was Implemented

#### 1. Core Infrastructure `[FE]`
- **Isar Database Integration**
  - Added `isar: ^3.1.0+1` and `isar_flutter_libs: ^3.1.0+1`
  - Created `QueuedEvent` collection for persistent event queue
  - Initialized in `main.dart` before app start

- **Event Domain Model**
  - Created `AppEvent` entity with 11 event types
  - Defined `EventPriority` (immediate vs batched)
  - UUID-based event IDs for idempotency

- **Data Layer**
  - `AnalyticsLocalDataSource`: Isar CRUD operations
  - `AnalyticsRemoteDataSource`: API calls to backend
  - `AnalyticsRepositoryImpl`: Outbox pattern implementation

#### 2. Event Sync Strategy `[FE]`
- **EventSyncManager** (replacement for WorkManager due to compatibility)
  - Periodic sync every 5 minutes using Timer
  - App lifecycle sync (on resume/pause) via WidgetsBindingObserver
  - Manual sync capability

#### 3. API Integration `[FE]`
- Added analytics endpoints to `constants.dart`:
  - `ApiEndpoints.events` → `/events`
  - `ApiEndpoints.eventsBatch` → `/events/batch`

#### 4. Feature Integration `[FE]`
- Integrated event tracking into:
  - Recipe creation (`recipeCreated`, `variationCreated`)
  - Log post creation (`logCreated`, `logFailed`)
  - Recipe detail view (`recipeViewed`)
  - Log detail view (`logViewed`)
  - Image upload (`logPhotoUploaded`)

### Files Created `[FE]`
```
lib/domain/entities/analytics/app_event.dart
lib/data/models/local/queued_event.dart
lib/data/datasources/analytics/analytics_local_data_source.dart
lib/data/datasources/analytics/analytics_remote_data_source.dart
lib/domain/repositories/analytics_repository.dart
lib/data/repositories/analytics_repository_impl.dart
lib/core/providers/isar_provider.dart
lib/core/providers/analytics_providers.dart
lib/core/workers/event_sync_manager.dart
```

### Files Modified `[FE]`
```
pubspec.yaml - Added dependencies
lib/main.dart - Initialize Isar and EventSyncManager
lib/core/constants/constants.dart - Added analytics endpoints
lib/features/recipe/providers/recipe_providers.dart - Event tracking
lib/features/recipe/presentation/screens/recipe_create_screen.dart - Use recipeCreationProvider
lib/features/recipe/presentation/screens/recipe_detail_screen.dart - Use recipeDetailWithTrackingProvider
lib/features/log_post/providers/log_post_providers.dart - Event tracking
lib/core/providers/image_providers.dart - Created UploadImageWithTrackingUseCase
lib/core/widgets/image_upload_section.dart - Use uploadImageWithTrackingUseCaseProvider
```

### Dependencies Added `[FE]`
```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  uuid: ^4.3.3

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.13  # Downgraded for compatibility
```

### Issues Resolved `[FE]`

1. **isar_flutter_libs Android Namespace Missing**
   - Error: `Namespace not specified`
   - Fix: Added `namespace 'dev.isar.isar_flutter_libs'` to build.gradle
   - Location: `C:\Users\truep\AppData\Local\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle`

2. **WorkManager Compatibility**
   - Error: `Unresolved reference 'shim'`
   - Root Cause: workmanager 0.5.2 uses deprecated Flutter embedding APIs
   - Solution: Created EventSyncManager as alternative using Timer and WidgetsBindingObserver

3. **Sentry Kotlin Version Incompatibility**
   - Error: Language version 1.4 no longer supported
   - Solution: Temporarily disabled sentry_flutter dependency

4. **build_runner Version Conflict**
   - Error: isar_generator requires build ^2.3.0, build_runner 2.10.4 requires build ^4.0.0
   - Solution: Downgraded build_runner to ^2.4.13

5. **json_serializable Version Conflict**
   - Error: isar_generator requires source_gen ^1.2.2, json_serializable 6.11.3 requires source_gen ^4.1.1
   - Solution: Downgraded json_serializable to ^6.8.0

### Backend Requirements (TODO) `[BE]`

Backend must implement these endpoints:

#### POST /api/v1/events
Single event tracking for immediate priority events.

**Request**:
```json
{
  "eventId": "550e8400-e29b-41d4-a716-446655440000",
  "eventType": "logCreated",
  "userId": "user-123",
  "timestamp": "2026-01-05T10:30:00Z",
  "recipeId": "recipe-456",
  "logId": "log-789",
  "properties": {
    "rating": 4.5,
    "has_title": true,
    "image_count": 3,
    "content_length": 250
  }
}
```

**Response:** 200 OK

#### POST /api/v1/events/batch
Batch event tracking for analytics events.

**Request**:
```json
{
  "events": [
    {
      "eventId": "uuid-1",
      "eventType": "recipeViewed",
      "userId": "user-123",
      "timestamp": "2026-01-05T10:30:00Z",
      "recipeId": "recipe-456",
      "properties": {}
    },
    {
      "eventId": "uuid-2",
      "eventType": "searchPerformed",
      "userId": "user-123",
      "timestamp": "2026-01-05T10:31:00Z",
      "properties": {
        "query": "kimchi",
        "results_count": 15
      }
    }
  ]
}
```

**Response:** 200 OK

### Event Types Reference

| Event Type | Priority | Layer | Trigger | Properties |
|------------|----------|-------|---------|------------|
| recipeCreated | immediate | FE | User creates recipe | ingredient_count, step_count, has_images, image_count |
| logCreated | immediate | FE | User creates log | rating, has_title, image_count, content_length |
| variationCreated | immediate | FE | User creates variation | parent_recipe_id, root_recipe_id, change_category |
| logFailed | immediate | FE | Log creation fails | error message, rating |
| recipeViewed | batched | FE | User views recipe | has_parent, has_root, ingredient_count, step_count |
| logViewed | batched | FE | User views log | rating, image_count, content_length |
| recipeSaved | batched | FE | User saves recipe | - |
| recipeShared | batched | FE | User shares recipe | share_method |
| variationTreeViewed | batched | FE | User explores variation tree | depth_level |
| searchPerformed | batched | FE | User searches | query, results_count |
| logPhotoUploaded | batched | FE | User uploads photo | image_size, image_type, format, public_id |

### Testing Status
- ✅ `[FE]` App builds and runs successfully
- ✅ `[FE]` Isar initialized successfully
- ✅ `[FE]` EventSyncManager starts periodic sync (5 min interval)
- ✅ `[FE]` App lifecycle sync working (resume/pause)
- ⏳ `[FE+BE]` End-to-end event tracking (pending backend implementation)
- ⏳ `[FE]` Isar Inspector verification (pending user test)

### Verification Steps `[FE]`
1. Create a log post in the app
2. Check console logs for "Event queued: logCreated"
3. Open Isar Inspector URL (printed in console)
4. View queued events in `QueuedEvent` collection
5. Verify events sync when backend is ready

### Events Implemented: 7/11
- ✅ `[FE]` recipeCreated
- ✅ `[FE]` logCreated
- ✅ `[FE]` variationCreated
- ✅ `[FE]` logFailed
- ✅ `[FE]` recipeViewed
- ✅ `[FE]` logViewed
- ✅ `[FE]` logPhotoUploaded
- ⏳ `[FE]` recipeSaved (pending save feature)
- ⏳ `[FE]` recipeShared (pending share feature)
- ⏳ `[FE]` variationTreeViewed (pending)
- ⏳ `[FE]` searchPerformed (pending search feature)

### Next Steps
1. `[BE]` Implement backend analytics endpoints (`/events` and `/events/batch`)
2. `[BE]` Add idempotency checks in backend (use eventId)
3. `[BE]` Set up analytics database (PostgreSQL table or separate analytics DB)
4. `[BE]` Set up analytics dashboard (Metabase/Superset)
5. `[FE+BE]` Test event sync with real backend
6. Proceed to Phase 2: Image Compression & WebP Conversion

---

## Phase 2: Image Compression & WebP Conversion (Planned)

### Status
Not started

### Goals `[FE+BE]`
- Reduce image file sizes by >80% (5MB → <1MB)
- Implement global image deduplication
- WebP format conversion client-side
- Perceptual hashing for duplicate detection

### Implementation Plan

#### Frontend Changes `[FE]`
1. Image compression pipeline
   - Resize to max 1200x1200 (maintain aspect ratio)
   - Convert to WebP (quality: 80%)
   - Generate perceptual hash (8x8 average hash)
2. Deduplication check before upload
   - Query backend: `GET /api/v1/images/find-by-hash?hash={hash}`
   - If found → reuse existing `imagePublicId`
   - If not found → proceed with upload
3. Update `UploadImageUseCase` with compression logic

#### Backend Changes `[BE]`
1. New endpoint: `GET /api/v1/images/find-by-hash`
   - Input: perceptual hash string
   - Output: Existing `ImageUploadResponseDto` if found, 404 if not
2. Update `images` table schema:
   ```sql
   ALTER TABLE images ADD COLUMN perceptual_hash VARCHAR(64);
   CREATE INDEX idx_images_perceptual_hash ON images(perceptual_hash);
   ```
3. Store hash on image upload
4. Deduplication logic in `ImageService`

#### Success Criteria
- ✅ `[FE]` Image size reduced by >80%
- ✅ `[FE+BE]` Global deduplication working (same image stored once)
- ✅ `[FE]` Upload time reduced
- ✅ `[BE]` CDN cost savings

See [TECHSPEC.md](TECHSPEC.md) section "3. Image Compression & WebP Conversion" for detailed specifications.

---

## Phase 3: Offline-First Caching (Planned)

### Status
Not started

### Goals `[FE]`
- Enable offline access to saved/logged recipes
- Selective caching strategy (not entire catalog)
- LRU eviction for recently viewed recipes

### Implementation Plan `[FE]`
1. Isar schema for cached recipes
2. Cache reasons: `saved`, `ownedLog`, `recentlyViewed`
3. Offline-first repository pattern
4. Cache cleanup (daily periodic task)

See [TECHSPEC.md](TECHSPEC.md) section "7. Offline-First Strategy" for details.

---

## Phase 4: Anonymous Content Limits (Planned)

### Status
Not started

### Goals `[FE+BE]`
- Limit anonymous users to 1 recipe OR 1 log post
- Migrate anonymous content on login

### Implementation Plan

#### Frontend `[FE]`
1. Anonymous user ID tracking (device-bound UUID)
2. Content count tracking (local storage)
3. Login triggers:
   - After 1st content → soft nudge
   - Before 2nd content → hard block
4. Migration API call on login

#### Backend `[BE]`
1. Anonymous user tracking (creator_id = "anon_{UUID}")
2. Migration endpoint: `POST /api/v1/users/migrate-anonymous-content`
3. Reassign content from anonymous ID to authenticated user ID

See [TECHSPEC.md](TECHSPEC.md) section "4. Anonymous Content Limits & Migration" for details.

---

## Phase 5: Observability with Sentry (Planned)

### Status
Partially configured (Kotlin compatibility issue)

### Goals `[FE]`
- Track 100% of crashes
- Sample 10% of transactions
- API error tracking with context
- Filter PII

### Blockers `[FE]`
- Sentry Flutter plugin has Kotlin version incompatibility
- Need to resolve before enabling

See [TECHSPEC.md](TECHSPEC.md) section "5. Observability & Monitoring" for details.

---

## Phase 6: Idempotency Keys (Planned)

### Status
Not started

### Goals `[FE+BE]`
- Prevent duplicate writes on network retries
- Add `Idempotency-Key` header to POST/PUT/PATCH requests

### Implementation Plan

#### Frontend `[FE]`
1. Create `IdempotencyInterceptor` for Dio
2. Generate UUID for each write operation
3. Add to Dio interceptor stack

#### Backend `[BE]`
1. Store `Idempotency-Key` → response mapping (Redis, 24h TTL)
2. Check for duplicate keys before processing
3. Return cached response for duplicates

See [TECHSPEC.md](TECHSPEC.md) section "6. Idempotency for Write Operations" for details.

---

## Future Feature Planning

### Save/Bookmark System (Planned) `[FE+BE]`
- **Backend**: New table `saved_recipes`, endpoint `POST /recipes/{id}/save`
- **Frontend**: Bookmark UI, saved recipes list in profile
- **Impact**: Contributes to ranking algorithm

### Hashtag System (Planned) `[FE+BE]`
- **Backend**: `hashtags` table, autocomplete endpoint
- **Frontend**: Hashtag input, trending tags section
- **Impact**: Discovery and contextual connections

### Search Feature (Planned) `[FE+BE]`
- **Backend**: Full-text search (PostgreSQL trgm), Elasticsearch integration
- **Frontend**: Search bar, filter UI
- **Events**: Track `searchPerformed` events

---

## Notes

- This changelog documents changes across the full stack
- Each entry is tagged with `[FE]`, `[BE]`, or `[FE+BE]` to indicate which layer is affected
- Backend requirements are documented even if not yet implemented
- Frontend implementations often precede backend (event tracking is queued locally)
- See [TECHSPEC.md](TECHSPEC.md) for detailed specifications
- See [CLAUDE.md](CLAUDE.md) for development workflows
