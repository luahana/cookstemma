# FEATURES.md — Pairing Planet

> All features, technical decisions, and domain terminology in one place.

---

# 🔒 HOW TO LOCK A FEATURE

**When Claude Code instance starts working on a feature:**

### Step 1: Update the table above
```markdown
| FEAT-009 | Follow System | 🟡 In Progress | Claude-1 |
```

### Step 2: Add lock info to the feature section
```markdown
### [FEAT-009]: Follow System
**Status:** 🟡 In Progress
**Locked by:** Claude-1 (branch: feature/follow-system)
**Lock time:** 2025-01-08 14:30 UTC
**Server port:** 4001
```

### Step 3: Commit and push IMMEDIATELY
```bash
git add docs/ai/FEATURES.md
git commit -m "docs: lock FEAT-009"
git push origin dev
```

### Step 4: THEN create branch and start coding

### When done: Remove lock
```markdown
**Status:** ✅ Done
# Delete "Locked by", "Lock time", and "Server port" lines
```
---

# 📋 FEATURES
## Status Legend
| Status | Meaning | Action |
|--------|---------|--------|
| 📋 Planned | Not started | Available to lock |
| 🟡 In Progress | Being worked on | Check "Locked by" - don't touch! |
| ✅ Done | Completed | No lock needed |
## Template

```markdown
### [FEAT-XXX]: Feature Name

**Status:** 📋 Planned | 🟡 In Progress | ✅ Done
**Branch:** `feature/xxx`

# ═══ WHEN STARTING WORK, ADD THESE ═══
**Status:** 🟡 In Progress
**Locked by:** Claude-1 (branch: feature/xxx)
**Lock time:** 2025-01-08 14:30 UTC
**Server port:** 4001 (or 4002, 4003 if running multiple backends)

# ═══ WHEN DONE, CHANGE TO ═══
**Status:** ✅ Done
# (Delete Locked by, Lock time, Server port lines)

**Description:** What it does

**User Story:** As a [user], I want [action], so that [benefit]
**Research Findings:**
- How [App1] does it: ...
- Industry standard: ...
- Pitfall to avoid: ...

**Acceptance Criteria:**
- [ ] Criterion
- [ ] Edge case handling

**Technical Notes:**
- Backend: ...
- Frontend: ...
```

---

## Implemented ✅

### [FEAT-001]: Social Login (Google/Apple)

**Status:** ✅ Done

**Description:** Users sign in with Google/Apple via Firebase Auth, exchanged for app JWT.

**Acceptance Criteria:**
- [x] Google Sign-In button
- [x] Apple Sign-In (iOS)
- [x] Anonymous browsing
- [x] Token refresh

**Technical Notes:** Firebase token → Backend → JWT pair (access + refresh)

---

### [FEAT-002]: Recipe List (Home Feed)

**Status:** ✅ Done

**Description:** Paginated recipe feed with infinite scroll, offline cache.

**Acceptance Criteria:**
- [x] Recipe cards with thumbnail, title, author
- [x] Infinite scroll (20/page)
- [x] Pull-to-refresh
- [x] Offline cache with indicator

**Technical Notes:** Cache-first pattern, Isar local storage, 5min TTL

---

### [FEAT-003]: Recipe Detail

**Status:** ✅ Done

**Description:** Full recipe view with ingredients, steps, logs, variants tabs.

**Acceptance Criteria:**
- [x] Image carousel
- [x] Ingredients by type (MAIN, SECONDARY, SEASONING)
- [x] Numbered steps
- [x] Tabs: Logs, Variants
- [x] Save/bookmark button

---

### [FEAT-004]: Create Recipe

**Status:** ✅ Done

**Description:** Multi-step form to create recipes.

**Acceptance Criteria:**
- [x] Add title, description
- [x] Add ingredients
- [x] Add steps with images
- [x] Add recipe photos
- [x] Draft saved locally

---

### [FEAT-005]: Recipe Variations

**Status:** ✅ Done

**Description:** Create modified versions of recipes with change tracking.

**Acceptance Criteria:**
- [x] Pre-fill from parent recipe
- [x] Track changes
- [x] parentPublicId + rootPublicId linking

**Technical Notes:**
- `parentPublicId` = direct parent
- `rootPublicId` = original recipe (top of tree)

---

### [FEAT-006]: Cooking Logs

**Status:** ✅ Done

**Description:** Log cooking attempts with photos, notes, outcome.

**Acceptance Criteria:**
- [x] Outcome: SUCCESS 😊 / PARTIAL 😐 / FAILED 😢
- [x] Photos
- [x] Notes
- [x] Linked to recipe

---

### [FEAT-007]: Save/Bookmark

**Status:** ✅ Done

**Description:** Save recipes to personal collection.

**Acceptance Criteria:**
- [x] Save button on recipe detail
- [x] Toggle save/unsave
- [x] Saved tab in profile

---

### [FEAT-008]: User Profile

**Status:** ✅ Done

**Description:** Profile page with tabs for user content.

**Acceptance Criteria:**
- [x] Profile photo, username
- [x] My Recipes tab
- [x] My Logs tab
- [x] Saved tab

---

### [FEAT-009]: Follow System

**Status:** ✅ Done
**Branch:** `feature/follow-system`
**PR:** #8

**Description:** Follow other users to build social graph.

**Acceptance Criteria:**
- [x] Follow/unfollow button
- [x] Follower/following counts
- [x] Followers list screen
- [x] Following list screen
- [x] Pull-to-refresh for empty states

**Technical Notes:**
- Backend: `user_follows` table, atomic count updates
- API: `POST/DELETE /api/v1/users/{id}/follow`
- Optimistic UI update with rollback on error

---

### [FEAT-010]: Push Notifications

**Status:** ✅ Done
**Branch:** `feature/push-notifications`
**PR:** #7

**Description:** FCM notifications for social interactions.

**Acceptance Criteria:**
- [x] NEW_FOLLOWER notification
- [x] RECIPE_COOKED notification
- [x] RECIPE_VARIATION notification
- [x] Notification list screen
- [x] Mark as read
- [x] Unread count badge

**Technical Notes:**
- Backend: `notifications` + `user_fcm_tokens` tables
- Frontend: Firebase Messaging integration
- Deep linking to relevant screens

---

### [FEAT-011]: Profile Caching

**Status:** ✅ Done
**Branch:** `feature/profile-caching`
**PR:** #4

**Description:** Cache profile tabs locally for offline access.

**Acceptance Criteria:**
- [x] My Recipes cached (5min TTL)
- [x] My Logs cached
- [x] Saved cached
- [x] Cache indicator with timestamp
- [x] Background refresh

**Technical Notes:** Isar-based caching with cache-first pattern

---

### [FEAT-012]: Social Sharing

**Status:** ✅ Done
**Branch:** `feature/social-sharing`

**Description:** Share recipes with Open Graph meta tags for rich link previews.

**Acceptance Criteria:**
- [x] Share button on recipe detail
- [x] Open Graph HTML endpoint for crawlers
- [x] Locale-aware share options (KakaoTalk for Korea, WhatsApp for others)
- [x] Native share sheet via share_plus
- [x] Copy link functionality

**Technical Notes:**
- Backend: `/share/recipe/{publicId}` returns HTML with og:title, og:image, og:description
- Frontend: ShareBottomSheet with locale detection via localeProvider
- Deep link support for app opening

---

### [FEAT-013]: Profile Edit

**Status:** ✅ Done
**Branch:** `feature/social-sharing`

**Description:** Edit profile with birthday, gender, and language preference.

**Acceptance Criteria:**
- [x] Birthday date picker
- [x] Gender dropdown (Male/Female/Other)
- [x] Language dropdown (Korean/English)
- [x] Language change updates app locale dynamically
- [x] Unsaved changes warning

**Technical Notes:**
- Backend: `PATCH /api/v1/users/me` with locale field
- Frontend: EasyLocalization for dynamic locale switching
- Profile refresh after save
### [FEAT-012]: Recipe Search
**Status:** ✅ Done

**Description:** Search recipes with filters and relevance ranking.

**Acceptance Criteria:**
- [x] Search by title (debounced 300ms)
- [x] Search by description
- [x] Search by ingredient name
- [x] Search ranking (pg_trgm SIMILARITY-based ordering)
- [x] Filter by ingredient (via search query)
- [x] Recent searches (local, max 10) - search_history_provider.dart
- [x] Empty state with suggestions - search_empty_state.dart, search_suggestions_overlay.dart

**Technical Notes:**
- Backend: PostgreSQL pg_trgm extension for trigram matching (V9__add_search_indexes.sql)
- Uses `%` operator for fuzzy matching + ILIKE for substring fallback
- SIMILARITY() function for relevance-based ordering
- GIN indexes on title, description, and ingredient names
- Frontend: enhanced_search_app_bar.dart, search_local_data_source.dart

---

### [FEAT-014]: Image Variants

**Status:** ✅ Done

**Description:** Server-side image resizing for optimized delivery.

**Acceptance Criteria:**
- [x] Thumbnail variant (300px)
- [x] Display variant (800px)
- [x] Original preserved
- [x] AppCachedImage supports variant parameter

**Technical Notes:**
- Backend generates variants on upload
- URL pattern: `/images/{id}?variant=thumbnail`

---

### [FEAT-015]: Enhanced Search

**Status:** ✅ Done

**Description:** Search with autocomplete suggestions and history.

**Acceptance Criteria:**
- [x] Search suggestions from API
- [x] Recent search history (local)
- [x] Clear history option
- [x] Search by recipe title, food name

**Technical Notes:**
- Autocomplete endpoint: `/api/v1/autocomplete`
- Local history stored in SharedPreferences

---

### [FEAT-025]: Idempotency Keys

**Status:** ✅ Done
**Branch:** `feature/idempotency-keys`
**PR:** #15

**Description:** Prevent duplicate writes on network retries using idempotency keys pattern (Stripe-style).

**Acceptance Criteria:**
- [x] Client generates UUID v4 for POST/PATCH requests
- [x] Server stores key + response, returns cached on retry
- [x] 24-hour TTL for keys
- [x] Request hash verification to detect misuse
- [x] Hourly cleanup of expired keys
- [x] Keys scoped per user

**Technical Notes:**
- Backend: `idempotency_keys` table, `IdempotencyFilter` after JWT auth
- Frontend: `IdempotencyInterceptor` in Dio chain before retry interceptor
- Reuses same key on retry, clears on success/non-retryable error
- Returns 422 if same key used with different request body

**How it works:**
```
Client                                  Server
  │  POST /recipes                        │
  │  Idempotency-Key: uuid-123            │
  │ ──────────────────────────────────────>
  │       (timeout)                       │
  │ <──────────────────────────────────── X
  │  RETRY with same key                  │
  │ ──────────────────────────────────────>
  │       200 OK (cached response)        │
  │ <──────────────────────────────────────
```

---

### [FEAT-026]: Image Soft Delete with Account Deletion

**Status:** ✅ Done
**Branch:** `feature/image-soft-delete`
**PR:** #35

**Description:** Soft-delete user's images when account is closed, with 30-day grace period for recovery.

**Policy:**
- Recipes are NOT deleted when user closes account (remain visible)
- Images ARE soft-deleted with user account
- Images restored if user logs back in within 30 days
- Images hard-deleted from S3 after 30-day grace period

**Acceptance Criteria:**
- [x] Add `deletedAt` and `deleteScheduledAt` fields to Image entity
- [x] Soft-delete all user images when account is closed
- [x] Restore all user images when account is restored
- [x] Hard-delete images from S3 when account is permanently purged
- [x] Database migration with proper indexes
- [x] Comprehensive test coverage (9 tests)

**Technical Notes:**
- Backend: `Image.java` with soft delete fields, `ImageService` with soft/restore/hard delete methods
- Migration: `V18__add_image_soft_delete.sql` with indexes for efficient queries
- `UserService.deleteAccount()` → calls `imageService.softDeleteAllByUploader()`
- `UserService.restoreDeletedAccount()` → calls `imageService.restoreAllByUploader()`
- `UserService.purgeExpiredDeletedAccounts()` → calls `imageService.hardDeleteAllByUploader()`

**Flow:**
```
User closes account
    ↓
User soft-deleted (status=DELETED, 30-day schedule)
Images soft-deleted (same schedule)
    ↓
User logs in within 30 days?
    ├── YES → User & images restored
    └── NO (30 days pass) → Scheduler purges:
            Images hard-deleted from S3
            User hard-deleted from DB
```

---

### [FEAT-027]: Edit/Delete Log Posts

**Status:** ✅ Done
**Branch:** `dev`
**PR:** #39

**Description:** Allow users to edit and delete their own cooking log posts.

**Acceptance Criteria:**
- [x] Edit log content, outcome, and hashtags (images read-only)
- [x] Delete log with confirmation dialog (soft delete)
- [x] Only show edit/delete options to log creator
- [x] Return 403 Forbidden for unauthorized update/delete attempts
- [x] Comprehensive test coverage (28 tests)

**Technical Notes:**
- Backend: `PUT /api/v1/log_posts/{publicId}` and `DELETE /api/v1/log_posts/{publicId}`
- Backend: `creatorId` added to `LogPostDetailResponseDto` for ownership check
- Backend: `AccessDeniedException` handler returning 403 Forbidden
- Frontend: `LogEditSheet` bottom sheet for editing
- Frontend: `PopupMenuButton` in log detail screen (three-dot menu)
- Frontend: Ownership check via `myProfileProvider` comparing user ID

---

### [FEAT-028]: Cooking Style (Cuisine Type Rename)

**Status:** ✅ Done
**Branch:** `feature/cooking-style`

**Description:** Changed recipe categorization concept from "Cuisine Type" (origin-based) to "Cooking Style" (adaptation-based). A Korean-style pizza uses Korean flavors and techniques, regardless of pizza's Italian origin.

**Acceptance Criteria:**
- [x] Update terminology from "Cuisine Type" to "Cooking Style"
- [x] Add "-style" suffix to English labels (Korean-style, Italian-style, etc.)
- [x] Add helper text explaining the concept on recipe creation form
- [x] Update profile pie chart label to "Cooking Style Distribution"
- [x] Update both English and Korean translations

**Technical Notes:**
- Frontend-only change (no backend/database changes needed)
- Field name `culinaryLocale` kept as internal implementation detail
- Files modified:
  - `assets/translations/en-US.json`
  - `assets/translations/ko-KR.json`
  - `lib/features/recipe/presentation/widgets/locale_dropdown.dart`

---

### [INFRA-001]: AWS Dev Environment with ALB

**Status:** ✅ Done
**Branch:** `dev`

**Description:** AWS infrastructure for dev environment with Application Load Balancer for stable DNS endpoint, RDS PostgreSQL database, and ECS Fargate deployment.

**Acceptance Criteria:**
- [x] VPC with public subnets (no NAT for cost savings)
- [x] ALB with HTTP listener for stable DNS endpoint
- [x] ECS Fargate service with auto-deployment
- [x] RDS PostgreSQL with snapshot restore capability
- [x] S3 bucket for images with public read access
- [x] Firebase credentials integrated for social login
- [x] All secrets managed via AWS Secrets Manager

**Technical Notes:**
- ALB DNS: `pairing-planet-dev-alb-857509432.us-east-2.elb.amazonaws.com`
- HTTP only (no HTTPS) for dev environment to save costs
- RDS snapshot restore support for disaster recovery
- Terraform modules: `vpc`, `alb`, `ecs`, `rds`, `secrets`
- Mobile app configured to use ALB endpoint

**Files Modified:**
- `backend/terraform/environments/dev/main.tf` - Added ALB module, Firebase secret
- `backend/terraform/modules/alb/main.tf` - HTTP-only support
- `backend/terraform/modules/ecs/main.tf` - Added Firebase credentials secret
- `backend/terraform/modules/rds/main.tf` - Snapshot restore support
- `frontend_mobile/lib/config/app_config.dart` - AWS endpoint for dev

---

### [FEAT-036]: Hive to Isar Migration & Performance Optimizations

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Migrated local storage from Hive to Isar and implemented Flutter performance best practices for smoother UI and reduced memory usage.

**Acceptance Criteria:**
- [x] Migrate all local data sources from Hive to Isar
- [x] Create Isar collection models for cached data
- [x] Add cacheWidth/cacheHeight to Image.file widgets
- [x] Wrap expensive widgets with RepaintBoundary
- [x] Add itemExtent to ListViews for scroll performance
- [x] Add ValueKey to dynamic list items
- [x] Create background JSON parsing utility
- [x] Implement provider singleton pattern for DataSources

**Technical Notes:**
- Frontend: 60 files changed, 12 new Isar collection files
- Image optimization: 7 widget files with cacheWidth/cacheHeight
- Repaint boundaries: 4 widget files (log_post_card, featured_star_card, recent_logs_gallery)
- List performance: itemExtent added to 4 ListViews, ValueKey added to 3 dynamic lists
- Background parsing: `json_parser.dart` with compute() for isolate-based JSON parsing
- Provider singleton: `userRemoteDataSourceProvider` used by 5 profile providers
- All 802 tests pass

---

### [FEAT-037]: Duplicate Submission Prevention

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Comprehensive fix for duplicate submissions across the app. Prevents double form submissions, fixes race conditions in sync engine, and improves idempotency key handling.

**Root Causes Fixed:**
1. **Double-tap on submit buttons** - No guard against rapid taps before loading state updates
2. **Sync engine race condition** - Multiple concurrent sync calls processing same queue items
3. **Idempotency key removal** - Keys removed immediately after success, not protecting rapid retries

**Acceptance Criteria:**
- [x] Create reusable `SubmissionGuard` mixin for form submissions
- [x] Apply guard to `LogPostCreateScreen` and `RecipeCreateScreen`
- [x] Fix race condition in `LogSyncEngine._processSyncQueue()`
- [x] Keep idempotency keys for 30 seconds (TTL) instead of removing immediately
- [x] Comprehensive unit tests for all fixes (51 tests)

**Technical Notes:**
- `SubmissionGuard` mixin (`lib/core/utils/submission_guard.dart`):
  - Provides `guardedSubmit<T>()` method that blocks concurrent calls
  - Returns `null` for blocked calls, action result for executed calls
  - Automatically resets state on completion or error
- `LogSyncEngine` fix (`lib/data/datasources/sync/log_sync_engine.dart`):
  - Set `_isSyncing = true` IMMEDIATELY after check, before any async operations
  - Previous code had async gap allowing multiple concurrent executions
- `IdempotencyInterceptor` fix (`lib/core/network/idempotency_interceptor.dart`):
  - Added `_IdempotencyEntry` class with TTL tracking
  - Keys persist for 30 seconds to prevent duplicates from rapid double-taps
  - Keys still cleared on non-retryable errors (4xx, 500)

**Tests Added:**
- `test/core/utils/submission_guard_test.dart` (11 tests)
- `test/core/network/idempotency_interceptor_test.dart` (25 tests)
- `test/data/datasources/sync/log_sync_engine_test.dart` (5 new concurrency tests)

---

### [FEAT-038]: Profile Bio & Social Links

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Users can add a bio/description and social media links (YouTube, Instagram) to their profile. Designed for App Store/Play Store compliance with security measures.

**User Story:** As a user, I want to add a bio and social media links to my profile, so that other users can learn about me and find my content on other platforms.

**Research Findings:**
- How Instagram does it: Bio (150 chars), website link, opens in external browser
- App Store compliance: External links must open in system browser (not WebView) for security
- Security: HTML sanitization, URL validation, HTTPS enforcement

**Acceptance Criteria:**
- [x] Bio field (max 150 characters) in profile edit
- [x] YouTube URL field with validation
- [x] Instagram handle/URL field with validation
- [x] Display bio on own profile (cooking_dna_header)
- [x] Display bio on other users' profiles (user_profile_screen)
- [x] Social link buttons (YouTube red, Instagram pink) open external browser
- [x] Backend sanitization (HTML stripping, URL normalization)
- [x] Translations in both English and Korean

**Technical Notes:**
- Backend:
  - `V27__add_user_bio_and_social_links.sql` - Migration for bio, youtube_url, instagram_handle columns
  - `User.java` - Entity fields with length constraints
  - `UserDto.java` - Fields for API response
  - `UpdateProfileRequestDto.java` - @Size(max=150) for bio, @Pattern regex for YouTube/Instagram validation
  - `UserService.java` - `sanitizeBio()` (HTML stripping), `normalizeYoutubeUrl()` (HTTPS), `normalizeInstagramHandle()` (extract handle from URL)
- Frontend:
  - `pubspec.yaml` - Added `url_launcher: ^6.2.5`
  - `url_launcher_utils.dart` - Utility for launching external URLs with `LaunchMode.externalApplication`
  - `user_dto.dart` / `update_profile_request_dto.dart` - New fields
  - `profile_edit_screen.dart` - Bio TextField (150 char counter), YouTube/Instagram TextFields with validation
  - `cooking_dna_header.dart` - Bio display + social link buttons (own profile)
  - `user_profile_screen.dart` - Bio display + social link buttons (other users)
  - `en-US.json` / `ko-KR.json` - Translation keys for bio, socialLinks, validation messages

**Security Features:**
- HTML tag stripping prevents XSS in bio
- Strict regex validation for YouTube/Instagram URLs
- HTTPS enforcement for all URLs
- `LaunchMode.externalApplication` opens links in system browser (App Store compliant)

---

### [FEAT-039]: Multi-Language Support

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Mobile app supports 11 languages for global users.

**Supported Languages (11 total):**
| Code | Language | Native Name |
|------|----------|-------------|
| ko-KR | Korean | 한국어 |
| en-US | English | English |
| zh-CN | Chinese (Simplified) | 简体中文 |
| ja-JP | Japanese | 日本語 |
| fr-FR | French | Français |
| es-ES | Spanish | Español |
| it-IT | Italian | Italiano |
| de-DE | German | Deutsch |
| ru-RU | Russian | Русский |
| pt-BR | Portuguese (Brazil) | Português |
| el-GR | Greek | Ελληνικά |

**Acceptance Criteria:**
- [x] Language switcher in Profile Edit screen
- [x] All UI strings translatable via easy_localization
- [x] 11 locales with complete translations (~980 keys each)
- [x] Persist language preference (SharedPreferences)
- [x] App restart on language change (Phoenix.rebirth)
- [x] Fallback to English for missing translations

**Technical Notes:**
- Package: easy_localization ^3.0.8
- Translation files: `assets/translations/{locale}.json`
- Locale configuration in `main_common.dart` (supportedLocales)
- Language options in `profile_edit_screen.dart` (_localeOptions)

---

### [INFRA-002]: Bot Fleet System (Backend Infrastructure)

**Status:** 🟡 In Progress
**Branch:** `feature/bot-fleet-system`

**Description:** Backend infrastructure for an AI-driven bot fleet that will generate realistic recipes, variants, and cooking logs to seed Pairing Planet with synthetic data. This phase implements the backend authentication and persona management.

**Target:** 500 recipes, 2000 logs from 10 bot personas (5 Korean, 5 English)

**Acceptance Criteria (Phase 1 - Backend):**
- [x] Database migrations for bot_personas and bot_api_keys tables
- [x] Bot persona entity with localized display names, tone, skill level, dietary focus
- [x] Bot API key entity with Stripe-style prefix + SHA-256 hash pattern
- [x] BOT role added to Role enum
- [x] Persona reference added to User entity
- [x] BotAuthService for API key authentication
- [x] BotUserService for bot user and API key management
- [x] BotPersonaService for persona queries
- [x] POST /api/v1/auth/bot-login endpoint (public)
- [x] Admin endpoints for bot user creation and API key management
- [x] Rate limiting for bot-login (20 req/min)
- [x] Comprehensive test coverage (31 tests)

**Acceptance Criteria (Phase 2 - Bot Engine - Planned):**
- [ ] Python bot engine with ChatGPT integration
- [ ] Nano Banana Pro image generation
- [ ] Content generation pipeline (recipes, variants, logs)
- [ ] Celery + Redis task queue
- [ ] Scheduler for content drip

**Technical Notes:**
- Backend:
  - `V29__bot_personas_and_api_keys.sql` - Tables for personas and API keys
  - `V30__seed_bot_personas.sql` - 10 pre-seeded personas (5 Korean, 5 English archetypes)
  - `BotPersona.java` - Entity with JSONB display_name for localization
  - `BotApiKey.java` - Stripe-style API key (pp_bot_xxx prefix + hash)
  - `BotAuthService.java` - API key authentication and token generation
  - `BotAdminController.java` - Admin-only bot management endpoints
- API Keys:
  - Format: `pp_bot_<base64-url-random-32-bytes>`
  - Stored as SHA-256 hash (key only shown once at creation)
  - Max 5 active keys per bot user
  - Optional expiration date

**Bot Personas:**
| Username | Locale | Archetype | Specialty |
|----------|--------|-----------|-----------|
| chef_park_soojin | ko-KR | Professional Chef | Fine dining, fusion |
| yoriking_minsu | ko-KR | College Student | Budget, quick meals |
| healthymom_hana | ko-KR | Health Parent | Kid-friendly healthy |
| bakingmom_jieun | ko-KR | Home Baker | Korean bakery, desserts |
| worldfoodie_junhyuk | ko-KR | Cultural Enthusiast | Global cuisines |
| chef_marcus_stone | en-US | Professional Chef | Farm-to-table |
| broke_college_cook | en-US | College Student | Dorm hacks, budget |
| fitfamilyfoods | en-US | Health Parent | Meal prep, nutrition |
| sweettoothemma | en-US | Home Baker | American/European pastry |
| globaleatsalex | en-US | Cultural Enthusiast | International recipes |

---

## Planned 📋

### [FEAT-016]: Improved Onboarding

**Status:** 📋 Planned

**Description:** 5-screen flow explaining recipe variation concept.

**Acceptance Criteria:**
- [ ] Welcome screen
- [ ] Recipe concept explanation
- [ ] Variation concept explanation
- [ ] Cooking log explanation
- [ ] Get started button

---

### [FEAT-017]: Full-Text Search

**Status:** 📋 Planned

**Description:** PostgreSQL trigram search for recipes.

**Acceptance Criteria:**
- [ ] Search by ingredients
- [ ] Search by description
- [ ] Fuzzy matching
- [ ] Search ranking

---

### [FEAT-018]: Achievement Badges

**Status:** 📋 Planned

**Description:** Gamification badges for cooking milestones.

**Acceptance Criteria:**
- [ ] "첫 요리" - First log
- [ ] "용감한 요리사" - First variation
- [ ] "꾸준한 요리사" - 10 logs
- [ ] Badge display on profile

---

### [FEAT-029]: International Measurement Units

**Status:** 📋 Planned

**Description:** Structured ingredient measurements with unit conversion and recipe scaling for global users. Replaces free-text amount field with numeric quantity + unit enum.

**User Story:** As an international user, I want to view recipe ingredients in my preferred measurement system (metric/US), so that I can follow recipes without manual conversion.

**Research Findings:**
- How Paprika does it: Structured input (qty + unit dropdown), user preference setting, one-click conversion
- Industry standard: 67% of international recipe users rely on automated unit converters (CookSmart 2025)
- Pitfall to avoid: Volume↔weight conversion requires ingredient density database (too complex, unreliable)

**Acceptance Criteria:**
- [ ] New `MeasurementUnit` enum (ML, L, TSP, TBSP, CUP, G, KG, OZ, LB, PIECE, PINCH, etc.)
- [ ] RecipeIngredient entity: add `quantity` (Double) + `unit` (Enum), keep `amount` for legacy
- [ ] User preference: METRIC / US / ORIGINAL (stored in user profile)
- [ ] Locale-based default detection on signup (US locale → US units, others → Metric)
- [ ] Conversion service: volume↔volume, weight↔weight only (no density guessing)
- [ ] Frontend: quantity input + unit dropdown (replaces free-text amount)
- [ ] Recipe scaling: adjust servings, ingredients auto-scale
- [ ] Legacy support: existing recipes with string amounts continue to work
- [ ] Settings page: "Measurement units" preference option

**Technical Notes:**
- Backend:
  - `MeasurementUnit.java` enum
  - `RecipeIngredient.java`: add `quantity`, `unit` fields (nullable for legacy)
  - `User.java`: add `measurementPreference` field
  - `MeasurementConversionService.java`: conversion logic
  - DB migration: add columns to `recipe_ingredients` and `users` tables
- Frontend:
  - `measurement_unit.dart` enum
  - `measurement_service.dart` for conversion
  - `ingredient_section.dart`: structured input UI
  - `kitchen_proof_ingredients.dart`: display with conversion
  - Settings page for preference
- Conversion rates (to base units):
  - Volume → ML: CUP=240, TBSP=15, TSP=5, FL_OZ=30
  - Weight → G: OZ=28.35, LB=453.59, KG=1000

---

## Website Features 🌐

> Next.js website with SEO focus. Mirrors mobile app functionality.
> **Tech Stack:** Next.js (App Router), Tailwind CSS, Firebase Auth, TypeScript

---

### [WEB-001]: SEO Infrastructure

**Status:** 📋 Planned

**Description:** Core SEO setup enabling recipe pages to rank in search engines.

**User Story:** As a potential user, I want to find Pairing Planet recipes through Google search, so that I can discover the platform organically.

**Research Findings:**
- How AllRecipes does it: SSR pages, JSON-LD Recipe schema, comprehensive meta tags
- Industry standard: Google Recipe rich results require structured data (name, image, author, ingredients)
- Pitfall to avoid: Client-side rendering kills SEO; must use SSR/SSG

**Acceptance Criteria:**
- [ ] Server-side rendering for recipe/log detail pages
- [ ] JSON-LD structured data (Recipe schema) on recipe pages
- [ ] Dynamic meta tags (title, description, og:*, twitter:*)
- [ ] Sitemap.xml generation (automated)
- [ ] robots.txt configuration
- [ ] Canonical URLs on all pages
- [ ] Google Search Console integration

**Technical Notes:**
- Next.js App Router with `generateMetadata()` for dynamic meta
- JSON-LD via `<script type="application/ld+json">`
- next-sitemap for automated sitemap generation
- ISR revalidation every 5 minutes for list pages

---

### [WEB-002]: Recipe Pages (Public)

**Status:** 📋 Planned

**Description:** Public recipe pages optimized for SEO and user experience.

**Acceptance Criteria:**
- [ ] Recipe detail page with SSR (`/recipes/[publicId]`)
- [ ] Image gallery/carousel
- [ ] Ingredients list grouped by type (MAIN, SECONDARY, SEASONING)
- [ ] Numbered cooking steps
- [ ] Variants tree display (link to parent/root recipe)
- [ ] Cooking logs preview section
- [ ] Recipe search/list page with pagination
- [ ] Filter by cooking style
- [ ] Responsive layout matching mobile design

**Technical Notes:**
- Route: `/recipes/[publicId]` with `generateStaticParams` for popular recipes
- API: `GET /api/v1/recipes/{publicId}` for detail
- API: `GET /api/v1/recipes` with pagination for list

---

### [WEB-003]: Log Post Pages (Public)

**Status:** 📋 Planned

**Description:** Public cooking log pages showcasing user cooking attempts.

**Acceptance Criteria:**
- [ ] Log detail page with SSR (`/logs/[publicId]`)
- [ ] Outcome display with emoji (SUCCESS 😊 / PARTIAL 😐 / FAILED 😢)
- [ ] Photo gallery
- [ ] Link to associated recipe
- [ ] Log list page with filters (by outcome)
- [ ] Search logs by content

**Technical Notes:**
- Route: `/logs/[publicId]`
- API: `GET /api/v1/log_posts/{publicId}` for detail

---

### [WEB-004]: User Authentication

**Status:** 📋 Planned

**Description:** Google OAuth sign-in via Firebase, mirroring mobile app flow.

**Acceptance Criteria:**
- [ ] Google Sign-In button (Firebase Auth)
- [ ] Firebase token → Backend JWT exchange
- [ ] JWT storage in HTTP-only cookies (secure)
- [ ] Token refresh mechanism
- [ ] Protected route middleware
- [ ] Guest browsing mode (view-only)
- [ ] Sign out functionality

**Technical Notes:**
- Firebase Auth SDK for Web
- Flow: Google popup → Firebase ID token → `POST /api/v1/auth/social-login` → JWT pair
- Middleware checks for valid JWT on protected routes
- Refresh token rotation via `POST /api/v1/auth/reissue`

---

### [WEB-005]: Recipe Management (Auth Required)

**Status:** 📋 Planned

**Description:** Create, edit, and delete recipes (with ownership and relationship restrictions).

**Acceptance Criteria:**
- [ ] Multi-step recipe creation form
- [ ] Add title, description, cooking style
- [ ] Add ingredients (name, amount, type)
- [ ] Add steps with optional images
- [ ] Image upload with preview
- [ ] Create variation from existing recipe (pre-filled form)
- [ ] Change tracking for variations (diff, categories, reason)
- [ ] Edit recipe (owner only, if no variants/logs exist)
- [ ] Delete recipe (owner only, if no variants/logs exist)
- [ ] Clear error message when edit/delete blocked

**Technical Notes:**
- API: `POST /api/v1/recipes` for create
- API: `GET /api/v1/recipes/{publicId}/modifiable` to check permissions
- API: `PUT /api/v1/recipes/{publicId}` for edit
- API: `DELETE /api/v1/recipes/{publicId}` for delete
- Show lock icon and reason when modification blocked

---

### [WEB-006]: Log Post Management (Auth Required)

**Status:** 📋 Planned

**Description:** Create, edit, and delete cooking log posts.

**Acceptance Criteria:**
- [ ] Create log form (select recipe, outcome, notes, photos)
- [ ] Image upload with preview
- [ ] Hashtag input
- [ ] Edit log (owner only) - content, outcome, hashtags
- [ ] Delete log with confirmation (owner only, soft delete)

**Technical Notes:**
- API: `POST /api/v1/log_posts` for create
- API: `PUT /api/v1/log_posts/{publicId}` for edit
- API: `DELETE /api/v1/log_posts/{publicId}` for delete
- Images are read-only after creation (same as mobile)

---

### [WEB-007]: User Profile

**Status:** 📋 Planned

**Description:** User profile page with content tabs and social features.

**Acceptance Criteria:**
- [ ] Profile page (`/users/[publicId]`)
- [ ] Profile photo, username display
- [ ] Follower/following counts
- [ ] Tabs: My Recipes, My Logs, Saved
- [ ] Follow/unfollow button
- [ ] Followers list modal
- [ ] Following list modal
- [ ] Own profile: Settings link
- [ ] Profile edit (birthday, gender, language)

**Technical Notes:**
- API: `GET /api/v1/users/{userId}` for profile
- API: `GET /api/v1/users/me` for own profile
- API: `POST/DELETE /api/v1/users/{userId}/follow`
- My Profile at `/profile` (shortcut to own profile)

---

### [WEB-008]: Search & Discovery

**Status:** 📋 Planned

**Description:** Search functionality for recipes and logs.

**Acceptance Criteria:**
- [ ] Search bar in header
- [ ] Recipe search by title, description, ingredients
- [ ] Log search by content
- [ ] Autocomplete suggestions
- [ ] Recent search history (local storage)
- [ ] Clear history option
- [ ] Home feed with trending recipes

**Technical Notes:**
- API: `GET /api/v1/recipes?q={query}` with pg_trgm fuzzy search
- API: `GET /api/v1/log_posts?q={query}`
- API: `GET /api/v1/autocomplete` for suggestions
- Debounce search input (300ms)

---

### [WEB-009]: Save/Bookmark

**Status:** 📋 Planned

**Description:** Save recipes and logs to personal collection.

**Acceptance Criteria:**
- [ ] Save button on recipe detail
- [ ] Save button on log detail
- [ ] Toggle save/unsave
- [ ] Optimistic UI update
- [ ] Saved tab in profile
- [ ] Login prompt for guests

**Technical Notes:**
- API: `POST/DELETE /api/v1/recipes/{publicId}/save`
- API: `POST/DELETE /api/v1/log_posts/{publicId}/save`
- API: `GET /api/v1/recipes/saved` and `GET /api/v1/log_posts/saved`

---

### [WEB-010]: Internationalization (i18n)

**Status:** 📋 Planned

**Description:** Multi-language support for global users.

**Supported Languages (7 total):**
| Code | Language | Priority |
|------|----------|----------|
| en | English | Primary |
| ko | Korean | Primary |
| ja | Japanese | Secondary |
| zh | Chinese (Simplified) | Secondary |
| es | Spanish | Secondary |
| fr | French | Secondary |
| it | Italian | Secondary |

**Acceptance Criteria:**
- [ ] Language switcher in settings/header
- [ ] All UI strings translatable
- [ ] 7 locales: en, ko, ja, zh, es, fr, it
- [ ] URL-based locale (e.g., `/ko/recipes/...`, `/ja/recipes/...`)
- [ ] SEO: hreflang tags for all language variants
- [ ] Persist language preference
- [ ] Browser locale detection for default language
- [ ] Fallback to English for missing translations

**Technical Notes:**
- next-intl or next-i18next for i18n
- Translation files in `src/i18n/`:
  - `en.json` (English - base)
  - `ko.json` (Korean)
  - `ja.json` (Japanese)
  - `zh.json` (Chinese Simplified)
  - `es.json` (Spanish)
  - `fr.json` (French)
  - `it.json` (Italian)
- Match mobile app translation keys where applicable
- Consider translation management tool (Crowdin, Lokalise) for community contributions

---

# 🏛️ DECISIONS

## Template

```markdown
### [DEC-XXX]: Decision Title

**Date:** YYYY-MM-DD
**Status:** ✅ Accepted | ❌ Rejected

**Context:** Problem we faced
**Decision:** What we chose
**Reason:** Why
**Alternatives:** What else we considered
```

---

### [DEC-001]: Isar for Local Database

**Date:** 2024-12-15
**Status:** ✅ Accepted

**Context:** Need offline caching with query support.
**Decision:** Use Isar
**Reason:** Type-safe, fast, supports queries (unlike Hive)
**Alternatives:** Hive (no queries), SQLite (too heavy), Drift (SQL-based)

---

### [DEC-002]: Either<Failure, T> for Error Handling

**Date:** 2024-12-20
**Status:** ✅ Accepted

**Context:** Need consistent error handling.
**Decision:** Use Either from dartz package
**Reason:** Forces explicit handling, type-safe, clear contracts
**Alternatives:** Try-catch (easy to forget), nullable returns (loses info)

---

### [DEC-003]: publicId (UUID) for API

**Date:** 2024-12-18
**Status:** ✅ Accepted

**Context:** Don't want to expose internal DB IDs.
**Decision:** Every entity has `id` (internal Long) + `publicId` (UUID)
**Reason:** Security, flexibility, works across distributed systems
**Alternatives:** Expose internal ID (security risk), UUID as PK (performance)

---

### [DEC-004]: Soft Delete

**Date:** 2024-12-22
**Status:** ✅ Accepted

**Context:** Preserve data for variations, allow recovery.
**Decision:** Use `deleted_at` timestamp instead of hard delete
**Reason:** Maintains references, audit trail, recovery
**Alternatives:** Hard delete (loses data), archive table (complex)

---

### [DEC-005]: Firebase Auth + Backend JWT

**Date:** 2024-12-10
**Status:** ✅ Accepted

**Context:** Need social login without managing OAuth.
**Decision:** Firebase for social login, exchange for our JWT
**Reason:** Firebase handles complexity, we control our JWT
**Alternatives:** Firebase only (vendor lock), self-hosted OAuth (complex)

---

### [DEC-006]: PostgreSQL for Idempotency Keys

**Date:** 2026-01-08
**Status:** ✅ Accepted

**Context:** Need storage for idempotency keys with 24h TTL.
**Decision:** Use PostgreSQL table with scheduled cleanup
**Reason:** No new infrastructure, transactional with main data, simpler deployment
**Alternatives:** Redis (faster, built-in TTL, but extra dependency and sync complexity)

---

### [DEC-007]: Physical Device Development with ADB Reverse

**Date:** 2026-01-12
**Status:** ✅ Accepted

**Context:** Need to test on physical Android devices connected via USB while backend runs on localhost.
**Decision:** Use `adb reverse` for port forwarding, with explicit localhost config in .env
**Reason:** Simple setup, no network configuration needed, works reliably with USB
**Setup:**
```bash
adb reverse tcp:4001 tcp:4001  # Backend API
adb reverse tcp:9000 tcp:9000  # MinIO images
```
**Config:** Set `BASE_URL=http://localhost:4001/api/v1` in `.env` to use localhost mode
**Alternatives:**
- Use computer's IP address (requires same network, IP changes)
- Android emulator with 10.0.2.2 (can't test real device features)

---

# 📖 GLOSSARY

| Term | Definition |
|------|------------|
| **Recipe** | Dish with ingredients and steps |
| **Original Recipe** | Recipe with no parent (`parentPublicId = null`) |
| **Variation** | Recipe modified from another, has `parentPublicId` + `rootPublicId` |
| **Parent Recipe** | Direct recipe a variation was created from |
| **Root Recipe** | Original at top of variation tree |
| **Log Post** | Cooking attempt record with photos and outcome |
| **publicId** | UUID exposed in API (never expose internal `id`) |
| **Slice** | Spring paginated response with `content` array |
| **TTL** | Time To Live - cache validity duration |
| **Idempotency Key** | Client-generated UUID to prevent duplicate writes on retry |

---

# 📊 FEATURE INDEX

## Mobile App Features

| ID | Feature | Status |
|----|---------|--------|
| FEAT-001 | Social Login | ✅ |
| FEAT-002 | Recipe List | ✅ |
| FEAT-003 | Recipe Detail | ✅ |
| FEAT-004 | Create Recipe | ✅ |
| FEAT-005 | Recipe Variations | ✅ |
| FEAT-006 | Cooking Logs | ✅ |
| FEAT-007 | Save/Bookmark | ✅ |
| FEAT-008 | User Profile | ✅ |
| FEAT-009 | Follow System | ✅ |
| FEAT-010 | Push Notifications | ✅ |
| FEAT-011 | Profile Caching | ✅ |
| FEAT-012 | Social Sharing | ✅ |
| FEAT-013 | Profile Edit | ✅ |
| FEAT-014 | Image Variants | ✅ |
| FEAT-015 | Enhanced Search | ✅ |
| FEAT-016 | Improved Onboarding | 📋 |
| FEAT-017 | Full-Text Search | 📋 |
| FEAT-018 | Achievement Badges | 📋 |
| FEAT-025 | Idempotency Keys | ✅ |
| FEAT-026 | Image Soft Delete | ✅ |
| FEAT-027 | Edit/Delete Log Posts | ✅ |
| FEAT-028 | Cooking Style | ✅ |
| FEAT-029 | International Measurement Units | 📋 |
| FEAT-030 | Autocomplete Category Filtering | ✅ |
| FEAT-031 | Gamification Level Display | ✅ |
| FEAT-032 | Servings & Cooking Time | ✅ |
| FEAT-033 | Variation Page UX | ✅ |
| FEAT-034 | Image Upload Status | ✅ |
| FEAT-035 | Profile Navigation Bar | ✅ |
| FEAT-036 | Isar Migration & Performance | ✅ |
| FEAT-037 | Duplicate Submission Prevention | ✅ |
| FEAT-038 | Profile Bio & Social Links | ✅ |
| FEAT-039 | Multi-Language Support | ✅ |
| INFRA-001 | AWS Dev Environment with ALB | ✅ |
| INFRA-002 | Bot Fleet System (Backend) | 🟡 In Progress |

## Website Features

| ID | Feature | Status |
|----|---------|--------|
| WEB-001 | SEO Infrastructure | 📋 |
| WEB-002 | Recipe Pages (Public) | 📋 |
| WEB-003 | Log Post Pages (Public) | 📋 |
| WEB-004 | User Authentication | 📋 |
| WEB-005 | Recipe Management | 📋 |
| WEB-006 | Log Post Management | 📋 |
| WEB-007 | User Profile | 📋 |
| WEB-008 | Search & Discovery | 📋 |
| WEB-009 | Save/Bookmark | 📋 |
| WEB-010 | Internationalization | 📋 |
