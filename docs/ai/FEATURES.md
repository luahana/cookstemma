# FEATURES.md — Pairing Planet

> Features, tasks, decisions, and terminology - all in one place.

---

# 🎯 CURRENT SPRINT

### High Priority
| ID | Feature | Status | Locked By |
|----|---------|--------|-----------|
| FEAT-009 | Follow System | 📋 Planned | - |
| FEAT-010 | Push Notifications | 📋 Planned | - |
| FEAT-011 | Profile Caching | 📋 Planned | - |

### Medium Priority
| ID | Feature | Status | Locked By |
|----|---------|--------|-----------|
| FEAT-012 | Recipe Search | ✅ Done | - |
| FEAT-013 | Recipe Categories | 📋 Planned | - |
| FEAT-014 | User Settings | 📋 Planned | - |

### Backlog
- Dark mode
- Localization (Korean, English)
- Share to social media
- Recipe rating system
- Comments on recipes
- Weekly meal planner

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
**Status:** 📋 Planned
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

## ✅ Completed

### [FEAT-001]: Social Login (Google/Apple)
**Status:** ✅ Done
**Description:** Users sign in with Google/Apple via Firebase Auth, exchanged for app JWT.
**Acceptance Criteria:**
- [x] Google Sign-In button
- [x] Apple Sign-In (iOS)
- [x] Anonymous browsing
- [x] Token refresh

---

### [FEAT-002]: Recipe List (Home Feed)
**Status:** ✅ Done
**Description:** Paginated recipe feed with infinite scroll, offline cache.
**Acceptance Criteria:**
- [x] Recipe cards with thumbnail, title, author
- [x] Infinite scroll (20/page)
- [x] Pull-to-refresh
- [x] Offline cache with indicator

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

## 📋 Planned

### [FEAT-009]: Follow System
**Status:** 📋 Planned
**Branch:** `feature/follow-system`

**Description:** Follow other users to build social graph.

**Research Findings:**
- Instagram: Optimistic UI, instant count update, "Follows you" badge
- Twitter: Mutual follow detection, rate limiting
- Industry standard: Optimistic updates with rollback on error
- Pitfall: Race conditions with rapid tap, count inconsistency

**Acceptance Criteria:**
- [ ] Follow/unfollow button with optimistic UI
- [ ] Follower/following counts (cached locally)
- [ ] Followers list screen with pagination
- [ ] Following list screen with pagination
- [ ] Debounce rapid taps (300ms)
- [ ] Rollback on API failure
- [ ] "Follows you" badge for mutual follows

**Technical Notes:**
- Backend: `POST /api/v1/users/{id}/follow`, `DELETE /api/v1/users/{id}/follow`
- Database: `user_follows` table
- Frontend: Riverpod, optimistic update pattern

**Edge Cases:**
- Network failure → Rollback UI
- Rapid tap → Debounce
- Self-follow → Prevent

---

### [FEAT-010]: Push Notifications
**Status:** 📋 Planned
**Branch:** `feature/push-notifications`

**Description:** FCM notifications for social interactions.

**Research Findings:**
- Slack: Grouped notifications, badge count
- Instagram: Activity grouping ("X and 5 others liked...")
- Industry standard: Foreground handling, deep linking
- Pitfall: Notification spam, stale token handling

**Acceptance Criteria:**
- [ ] NEW_FOLLOWER notification
- [ ] RECIPE_COOKED notification
- [ ] Notification list screen with grouping
- [ ] Mark as read (individual and all)
- [ ] Deep link to relevant screen
- [ ] Handle foreground notifications
- [ ] Badge count on app icon

**Technical Notes:**
- Firebase Cloud Messaging
- Store device tokens in backend
- Background message handler

**Edge Cases:**
- Token expired → Re-register
- Multiple devices → Send to all
- App in foreground → In-app banner

---

### [FEAT-011]: Profile Caching
**Status:** 📋 Planned
**Branch:** `feature/profile-caching`

**Description:** Cache profile tabs locally.

**Acceptance Criteria:**
- [ ] My Recipes cached (5min TTL)
- [ ] My Logs cached (5min TTL)
- [ ] Saved recipes cached (5min TTL)
- [ ] Invalidate cache on create/delete
- [ ] Offline indicator
- [ ] Pull-to-refresh bypasses cache

**Technical Notes:**
- Isar for local storage
- TTL-based invalidation

---

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

### [FEAT-013]: Recipe Categories
**Status:** 📋 Planned
**Branch:** `feature/categories`

**Description:** Organize recipes by categories/tags.

**Acceptance Criteria:**
- [ ] Add tags to recipes (max 5)
- [ ] Browse by category
- [ ] Popular tags section

---

### [FEAT-014]: User Settings
**Status:** 📋 Planned
**Branch:** `feature/settings`

**Description:** App settings screen.

**Acceptance Criteria:**
- [ ] Notification preferences
- [ ] Account management
- [ ] Logout with confirmation
- [ ] Delete account flow

---

# 🏛️ DECISIONS

### [DEC-001]: Isar for Local Database
**Date:** 2024-12-15 | **Status:** ✅ Accepted
**Decision:** Use Isar for offline caching
**Reason:** Type-safe, fast, supports queries

---

### [DEC-002]: Either<Failure, T> for Error Handling
**Date:** 2024-12-20 | **Status:** ✅ Accepted
**Decision:** Use Either from dartz package
**Reason:** Forces explicit handling, type-safe

---

### [DEC-003]: publicId (UUID) for API
**Date:** 2024-12-18 | **Status:** ✅ Accepted
**Decision:** Every entity has `id` (internal) + `publicId` (UUID)
**Reason:** Security, don't expose auto-increment IDs

---

### [DEC-004]: Soft Delete
**Date:** 2024-12-22 | **Status:** ✅ Accepted
**Decision:** Use `deleted_at` timestamp
**Reason:** Maintains references, allows recovery

---

### [DEC-005]: Firebase Auth + Backend JWT
**Date:** 2024-12-10 | **Status:** ✅ Accepted
**Decision:** Firebase for social login, exchange for our JWT
**Reason:** Firebase handles OAuth, we control JWT

---

### [DEC-006]: Optimistic UI Updates
**Date:** 2025-01-08 | **Status:** ✅ Accepted
**Decision:** Use optimistic updates for follow/like/save
**Reason:** Better UX, instant feedback

---

### [DEC-007]: Firebase Flavors (Dev/Staging/Prod)
**Date:** 2025-01-08 | **Status:** ✅ Accepted
**Decision:** Three separate Firebase projects
**Reason:** Isolate environments, safe testing

---

### [DEC-008]: Feature Locking for Multi-Instance
**Date:** 2025-01-08 | **Status:** ✅ Accepted
**Decision:** Lock features in FEATURES.md when working
**Reason:** Prevent conflicts between Claude Code instances

---

### [DEC-009]: Multiple Backend Ports for Parallel Development
**Date:** 2025-01-08 | **Status:** ✅ Accepted
**Decision:** Use different ports (4001, 4002, 4003) when running multiple backends
**Reason:** Allow multiple Claude Code instances to run simultaneously
**Command:** `./gradlew bootRun --args='--server.port=4002'`

---

# 📖 GLOSSARY

| Term | Definition |
|------|------------|
| **Recipe** | Dish with ingredients and steps |
| **Original Recipe** | Recipe with no parent (`parentPublicId = null`) |
| **Variation** | Recipe modified from another |
| **Log Post** | Cooking attempt record |
| **publicId** | UUID exposed in API |
| **Slice** | Spring paginated response with `content` |
| **TTL** | Time To Live - cache validity |
| **Optimistic UI** | Update UI immediately, rollback if fails |
| **Flavor** | Build variant for different Firebase project |
| **Lock** | Marker in FEATURES.md showing who's working on feature |
| **Server port** | Backend port (4001 default, 4002/4003 for parallel instances) |

---

# 📊 QUICK REFERENCE

| ID | Feature | Status | Locked By | Port |
|----|---------|--------|-----------|------|
| FEAT-001 | Social Login | ✅ | - | - |
| FEAT-002 | Recipe List | ✅ | - | - |
| FEAT-003 | Recipe Detail | ✅ | - | - |
| FEAT-004 | Create Recipe | ✅ | - | - |
| FEAT-005 | Recipe Variations | ✅ | - | - |
| FEAT-006 | Cooking Logs | ✅ | - | - |
| FEAT-007 | Save/Bookmark | ✅ | - | - |
| FEAT-008 | User Profile | ✅ | - | - |
| FEAT-009 | Follow System | 📋 | - | - |
| FEAT-010 | Push Notifications | 📋 | - | - |
| FEAT-011 | Profile Caching | 📋 | - | - |
| FEAT-012 | Recipe Search | ✅ | - | - |
| FEAT-013 | Recipe Categories | 📋 | - | - |
| FEAT-014 | User Settings | 📋 | - | - |
