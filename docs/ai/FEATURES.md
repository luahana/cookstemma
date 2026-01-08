# FEATURES.md — Pairing Planet

> All features, technical decisions, and domain terminology in one place.

---

# 📋 FEATURES

## Template

```markdown
### [FEAT-XXX]: Feature Name

**Status:** 📋 Planned | 🟡 In Progress | ✅ Done
**Branch:** `feature/xxx`

**Description:** What it does

**User Story:** As a [user], I want [action], so that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

**Technical Notes:** Implementation details, edge cases
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
