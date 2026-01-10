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
