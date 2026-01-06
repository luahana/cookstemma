# Production Enhancements Changelog

## Phase 1: Event Tracking Infrastructure ✅ (Completed: 2026-01-05)

### Overview
Implemented event-based architecture with Outbox pattern for analytics and ML data collection.

### What Was Implemented

#### 1. Core Infrastructure
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

#### 2. Event Sync Strategy
- **EventSyncManager** (replacement for WorkManager due to compatibility)
  - Periodic sync every 5 minutes using Timer
  - App lifecycle sync (on resume/pause) via WidgetsBindingObserver
  - Manual sync capability

#### 3. API Integration
- Added analytics endpoints to `constants.dart`:
  - `ApiEndpoints.events` → `/events`
  - `ApiEndpoints.eventsBatch` → `/events/batch`

#### 4. Feature Integration
- Integrated event tracking into log post creation
- Tracks `logCreated` and `logFailed` events with metadata

### Files Created
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
doc/ai/CHANGELOG.md
```

### Files Modified
```
pubspec.yaml - Added dependencies
lib/main.dart - Initialize Isar and EventSyncManager
lib/core/constants/constants.dart - Added analytics endpoints
lib/features/log_post/providers/log_post_providers.dart - Event tracking
```

### Dependencies Added
```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  uuid: ^4.3.3

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.13  # Downgraded for compatibility
```

### Issues Resolved

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

### Backend Requirements (TODO)

Backend must implement these endpoints:

#### POST /events
Single event tracking for immediate priority events.

**Request:**
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

#### POST /events/batch
Batch event tracking for analytics events.

**Request:**
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

| Event Type | Priority | Trigger | Properties |
|------------|----------|---------|------------|
| recipeCreated | immediate | User creates recipe | recipe complexity, ingredient count |
| logCreated | immediate | User creates log | rating, has_title, image_count, content_length |
| variationCreated | immediate | User creates variation | parent_recipe_id |
| logFailed | immediate | Log creation fails | error message, rating |
| recipeViewed | batched | User views recipe | source (feed/search/profile) |
| logViewed | batched | User views log | - |
| recipeSaved | batched | User saves recipe | - |
| recipeShared | batched | User shares recipe | share_method |
| variationTreeViewed | batched | User explores variation tree | depth_level |
| searchPerformed | batched | User searches | query, results_count |
| logPhotoUploaded | batched | User uploads photo | image_size, format |

### Testing Status
- ✅ App builds and runs successfully
- ✅ Isar initialized successfully
- ✅ EventSyncManager starts periodic sync (5 min interval)
- ✅ App lifecycle sync working (resume/pause)
- ⏳ End-to-end event tracking (pending backend implementation)
- ⏳ Isar Inspector verification (pending user test)

### Verification Steps
1. Create a log post in the app
2. Check console logs for "Event queued: logCreated"
3. Open Isar Inspector URL (printed in console)
4. View queued events in `QueuedEvent` collection
5. Verify events sync when backend is ready

### Next Steps
1. Implement backend analytics endpoints (/events and /events/batch)
2. Test event sync with real backend
3. Add idempotency checks in backend (use eventId)
4. Set up analytics dashboard (Metabase/Superset)
5. Proceed to Phase 2: Image Compression & WebP Conversion

### Additional Events Implemented (2026-01-05)

Added 5 more event types to complete core user action tracking:

**New Events:**
1. **recipeCreated** - Recipe creation tracking
2. **variationCreated** - Recipe variation tracking
3. **recipeViewed** - Recipe detail view tracking
4. **logViewed** - Log post detail view tracking
5. **logPhotoUploaded** - Photo upload tracking (all images)

**Files Modified:**
```
lib/features/recipe/providers/recipe_providers.dart - Added RecipeCreationNotifier and recipeDetailWithTrackingProvider
lib/features/recipe/presentation/screens/recipe_create_screen.dart - Updated to use recipeCreationProvider
lib/features/recipe/presentation/screens/recipe_detail_screen.dart - Updated to use recipeDetailWithTrackingProvider
lib/features/log_post/providers/log_post_providers.dart - Updated logPostDetailProvider with view tracking
lib/core/providers/image_providers.dart - Created UploadImageWithTrackingUseCase
lib/core/widgets/image_upload_section.dart - Updated to use uploadImageWithTrackingUseCaseProvider
```

**Event Details:**

| Event Type | Priority | Tracked Data |
|------------|----------|--------------|
| recipeCreated | immediate | ingredient_count, step_count, has_images, image_count |
| variationCreated | immediate | ingredient_count, step_count, has_images, image_count, parent_recipe_id, root_recipe_id, change_category |
| recipeViewed | batched | has_parent, has_root, ingredient_count, step_count |
| logViewed | batched | rating, image_count, content_length |
| logPhotoUploaded | batched | image_size, image_type, format, public_id |

**Total Events Implemented:** 7/11
- ✅ recipeCreated
- ✅ logCreated
- ✅ variationCreated
- ✅ logFailed
- ✅ recipeViewed
- ✅ logViewed
- ✅ logPhotoUploaded
- ⏳ recipeSaved (pending)
- ⏳ recipeShared (pending)
- ⏳ variationTreeViewed (pending)
- ⏳ searchPerformed (pending)

---

## Phase 2: Image Compression & WebP Conversion (Planned)

Status: Not started

See TECHSPEC.md section "2. Image Compression & WebP Conversion" for details.
