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

### [FEAT-030]: Autocomplete Category Filtering

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Category-based autocomplete with multilingual support for recipe ingredient and dish search.

**Acceptance Criteria:**
- [x] Filter autocomplete by type (DISH, MAIN, SECONDARY, SEASONING)
- [x] MAIN type includes both MAIN_INGREDIENT and SECONDARY_INGREDIENT results
- [x] Multilingual support (7 languages: en-US, ko-KR, ja-JP, zh-CN, es-ES, fr-FR, de-DE)
- [x] CJK single-character search (Korean, Japanese, Chinese work with 1 character)
- [x] pg_trgm fuzzy search for 3+ character queries
- [x] Prefix search fallback for CJK locales with short keywords
- [x] Score-based result ordering
- [x] Redis caching with graceful database fallback
- [x] Comprehensive test coverage (35+ tests)

**Technical Notes:**
- Backend:
  - `AutocompleteService.java`: Search logic with CJK locale detection
  - `AutocompleteItemRepository.java`: Native queries with pg_trgm and ILIKE
  - `AutocompleteItem.java`: Entity with JSONB multilingual `name` field
  - `V20__create_autocomplete_items.sql`: Table + 105 items with translations
  - `V21__autocomplete_type_to_varchar.sql`: Enum to VARCHAR migration
- API: `GET /api/v1/autocomplete?keyword={}&locale={}&type={}`
- Type mapping:
  - `DISH` → dishes only
  - `MAIN` → main + secondary ingredients (merged results)
  - `SECONDARY` → secondary ingredients only
  - `SEASONING` → seasonings only
- CJK optimization: Uses prefix search (ILIKE) for ko-KR, ja-JP, zh-CN with < 3 chars

---

### [FEAT-031]: Gamification Level Display on User Profile

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Display user's gamification level and title on their public profile page. Users can see the level (Lv.1-26+) and tier title (Beginner → Master Chef) when viewing another user's profile.

**Acceptance Criteria:**
- [x] Show level badge (Lv.X) on user profile header
- [x] Show tier title (Beginner Cook, Home Cook, etc.)
- [x] Color-coded by tier (Grey → Green → Blue → Purple → Orange → Gold)
- [x] Level calculated from user's recipes and cooking logs
- [x] Comprehensive test coverage (backend + frontend)

**Technical Notes:**
- Backend:
  - `UserDto.java`: Added `level` (int) and `levelName` (String) fields
  - `UserService.getUserProfile()`: Calculates level from user's XP
  - `CookingDnaService`: Public methods for XP/level calculation
  - XP formula: 50/recipe + 30/success + 15/partial + 5/failed
- Frontend:
  - `LevelBadge` widget with color-coded level display
  - `UserProfileScreen`: Shows LevelBadge below username
  - `UserDto`: Added level and levelName fields
- Level Tiers:
  | Level | Tier | Color |
  |-------|------|-------|
  | 1-5 | Beginner | Grey |
  | 6-10 | Home Cook | Green |
  | 11-15 | Skilled Cook | Blue |
  | 16-20 | Home Chef | Purple |
  | 21-25 | Expert Chef | Orange |
  | 26+ | Master Chef | Gold |
- Tests:
  - `CookingDnaServiceTest.java`: Unit tests for XP/level calculation
  - `UserServiceTest.java`: Integration tests for profile with level
  - `UserControllerTest.java`: API response includes level fields
  - `level_badge_test.dart`: Widget tests for color/rendering
  - `level_badge_golden_test.dart`: Visual regression tests
  - `user_dto_test.dart`: JSON serialization tests

---

### [FEAT-032]: Servings and Cooking Time

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Add servings count and cooking time range to recipes for better meal planning. Users can specify how many servings a recipe makes and approximate cooking time.

**Acceptance Criteria:**
- [x] Servings selector (1-12, default: 2)
- [x] Cooking time dropdown with 5 ranges (Under 15min, 15-30min, 30min-1hr, 1-2hr, Over 2hr)
- [x] Display on recipe detail screen with icons
- [x] Editable in recipe create/edit screens
- [x] Inherited from parent recipe in variation mode
- [x] Translations (en-US, ko-KR)

**Technical Notes:**
- Backend:
  - `CookingTimeRange.java` enum with 5 values
  - `V23__add_servings_and_cooking_time_range.sql` migration
  - Fields added to Recipe entity, all DTOs, RecipeService
- Frontend:
  - `cooking_time_range.dart` constants
  - `ServingsCookingTimeSection` widget with stepper and dropdown
  - Updated create/edit/detail screens
- Defaults: 2 servings, MIN_30_TO_60 (30min-1hour) cooking time

---

### [FEAT-033]: Variation Page UX Improvements

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Enhanced UX for recipe variation creation with clear visual distinction between inherited and new content, and editable hashtags.

**Acceptance Criteria:**
- [x] Orange background theme for editable/interactive elements
- [x] Editable hashtags with inherited/new visual distinction
- [x] Delete inherited hashtags with restore capability
- [x] Title field left empty (not auto-populated from parent)
- [x] Less saturated orange for interactive buttons (orange[300])
- [x] Consistent orange theme across all editable sections

**Technical Notes:**
- Frontend:
  - `app_colors.dart`: Added `editableBackground` (orange[50]), `editableBorder` (orange[100]), `inheritedInteractive` (orange[300])
  - `hashtag_input_section.dart`: Changed from `List<String>` to `List<Map<String, dynamic>>` with `isOriginal`/`isDeleted` flags
  - Updated: `ingredient_section.dart`, `step_section.dart`, `hook_section.dart`, `servings_cooking_time_section.dart`, `locale_dropdown.dart`
  - Also updated: `log_post_create_screen.dart`, `log_edit_sheet.dart`, `hashtag_step.dart` for hashtag consistency

---

### [FEAT-034]: Image Upload Status Blocking

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Prevent recipe submission when images are still uploading or have failed, with clear visual feedback about upload status.

**Acceptance Criteria:**
- [x] Status banner showing upload progress (orange) or errors (red)
- [x] Submit button disabled during active uploads
- [x] Submit button disabled when upload errors exist
- [x] Users can retry failed uploads or remove them to proceed
- [x] Applied to both recipe create and edit screens
- [x] Translations (en-US, ko-KR)

**Technical Notes:**
- Frontend:
  - `recipe_create_screen.dart`: Added `_hasUploadingImages`, `_hasUploadErrors`, `_uploadStatusCounts` getters and `_buildUploadStatusBanner()` widget
  - `recipe_edit_screen.dart`: Same changes
  - Translation keys: `recipe.uploadingPhotos`, `recipe.uploadFailed`
- UX Flow:
  - Images uploading → Orange banner with spinner + count
  - Images failed → Red banner with error icon + retry guidance
  - All success → Banner hidden, submit enabled

---

### [FEAT-035]: Profile Navigation Bar Visibility

**Status:** ✅ Done
**Branch:** `dev`

**Description:** Keep the bottom navigation bar visible when viewing other users' profiles, matching the UX pattern used by Instagram, Twitter, and other social apps.

**User Story:** As a user browsing other users' profiles, I want the bottom navigation bar to stay visible so I can quickly return to any main tab without tapping "back" multiple times.

**Research Findings:**
- How Instagram does it: Profile pages keep bottom nav visible, tapping nav icons returns to tab root
- How Twitter/X does it: Same pattern - bottom nav always visible on profiles
- Industry standard: All major social apps keep bottom nav visible on user profile pages

**Acceptance Criteria:**
- [x] Bottom nav visible on UserProfileScreen
- [x] Bottom nav visible on FollowersListScreen
- [x] Tapping nav icon navigates directly to tab root (Home, Recipes, Logs, Profile)
- [x] No tab highlighted when viewing user profiles (currentIndex = -1)
- [x] Level progress ring shown for authenticated users
- [x] Unit tests for navigation logic

**Technical Notes:**
- Frontend:
  - `user_profile_screen.dart`: Added `CustomBottomNavBar` to Scaffold, `_navigateToTab()` method
  - `followers_list_screen.dart`: Same changes
  - Uses `context.go()` (not push) to navigate to tab roots - clears profile from stack
  - `currentIndex: -1` means no tab is highlighted when on profile screens
- Why not nested shell routes: Attempted but caused GoRouter duplicate key errors with `StatefulShellRoute`
- Tests:
  - `profile_bottom_nav_test.dart`: Route mapping and configuration tests (10 tests)

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
