# FEATURES.md — Pairing Planet

> Functional specification of all features. Used for documentation and test planning.

---

## How to Use This File

1. **Before implementing any feature** → Document it here first
2. **Writing tests** → Use acceptance criteria as test cases
3. **Code review** → Verify implementation matches spec
4. **Onboarding** → Understand all features in one place

---

## Feature Template

```markdown
### [Feature ID]: Feature Name

**Status:** 🟡 In Progress | ✅ Implemented | 📋 Planned

**Branch:** `feature/feature-name`

**Description:**
Brief description of what this feature does.

**User Story:**
As a [user type], I want to [action], so that [benefit].

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

**UI/UX:**
- Screen: `ScreenName`
- Entry point: How user accesses this feature
- Flow: Step-by-step user journey

**Technical Details:**
- Frontend files: `lib/features/xxx/`
- Backend endpoint: `POST /api/v1/xxx`
- Database: Tables affected

**Edge Cases:**
- What happens when X?
- What happens when Y?

**Error Handling:**
- Error scenario 1 → Show message "..."
- Error scenario 2 → Retry with exponential backoff

**Test Cases:**
- [ ] Test case 1
- [ ] Test case 2
- [ ] Test case 3
```

---

# 🔐 Authentication

### [AUTH-001]: Social Login (Google/Apple)

**Status:** ✅ Implemented

**Description:**
Users can sign in using Google or Apple accounts via Firebase Authentication.

**User Story:**
As a new user, I want to sign in with my Google/Apple account, so that I don't need to create a new password.

**Acceptance Criteria:**
- [x] Google Sign-In button on login screen
- [x] Apple Sign-In button on login screen (iOS only)
- [x] Anonymous sign-in for browsing without account
- [x] Firebase token exchanged for app JWT tokens
- [x] Tokens stored securely in flutter_secure_storage
- [x] Auto-refresh of expired access tokens

**UI/UX:**
- Screen: `LoginScreen`
- Entry point: App launch (if not logged in) or profile menu
- Flow: Tap button → OAuth popup → Redirect back → Home screen

**Technical Details:**
- Frontend: `lib/features/auth/`
- Backend: `POST /api/v1/auth/social-login`
- Database: `users`, `social_accounts` tables

**Edge Cases:**
- User cancels OAuth flow → Return to login screen
- Network error during login → Show retry option
- Firebase token expired → Request new token
- User has existing account with same email → Link accounts

**Error Handling:**
- Invalid Firebase token → "인증에 실패했습니다. 다시 시도해주세요."
- Network error → "네트워크 연결을 확인해주세요."

**Test Cases:**
- [ ] Successful Google login creates user and returns tokens
- [ ] Successful Apple login creates user and returns tokens
- [ ] Invalid Firebase token returns 401
- [ ] Existing user login returns existing user data
- [ ] Token refresh works when access token expires

---

### [AUTH-002]: Anonymous Browsing

**Status:** ✅ Implemented

**Description:**
Users can browse recipes without creating an account.

**User Story:**
As a visitor, I want to browse recipes without signing up, so that I can evaluate the app before committing.

**Acceptance Criteria:**
- [x] Can view recipe list without login
- [x] Can view recipe details without login
- [x] Prompted to login when trying to create content
- [x] Anonymous session converted to full account on login

**Test Cases:**
- [ ] Anonymous user can view recipe list
- [ ] Anonymous user can view recipe detail
- [ ] Anonymous user prompted to login on create recipe
- [ ] Anonymous user prompted to login on create log

---

# 🍳 Recipes

### [RCP-001]: Recipe List (Home Feed)

**Status:** ✅ Implemented

**Description:**
Paginated list of recipes with infinite scroll.

**User Story:**
As a user, I want to browse recipes in a feed, so that I can discover new dishes.

**Acceptance Criteria:**
- [x] Display recipe cards with thumbnail, title, author
- [x] Show variant count and log count on cards
- [x] Infinite scroll pagination (20 items per page)
- [x] Pull-to-refresh functionality
- [x] Offline cache with cache indicator
- [x] Empty state when no recipes

**UI/UX:**
- Screen: `HomeScreen`
- Entry point: Bottom navigation "Home" tab
- Flow: Scroll → Load more → Tap card → Recipe detail

**Technical Details:**
- Frontend: `lib/features/home/`
- Backend: `GET /api/v1/recipes?page=0&size=20`
- Cache: Isar `RecipeCacheDto`

**Edge Cases:**
- Empty feed → Show "첫 번째 레시피를 만들어보세요!" with CTA
- Network error + no cache → Show error with retry
- Network error + has cache → Show cached data with indicator

**Test Cases:**
- [ ] Recipe list loads first page
- [ ] Scroll to bottom loads next page
- [ ] Pull-to-refresh reloads first page
- [ ] Cached data shown when offline
- [ ] Cache indicator shows last update time

---

### [RCP-002]: Recipe Detail

**Status:** ✅ Implemented

**Description:**
Full recipe view with ingredients, steps, and tabs for logs/variants.

**User Story:**
As a user, I want to view recipe details, so that I can cook the dish.

**Acceptance Criteria:**
- [x] Display recipe images in carousel
- [x] Show title, description, author info
- [x] List ingredients with amounts and types
- [x] List cooking steps in order
- [x] Tab for cooking logs
- [x] Tab for recipe variants
- [x] Save/bookmark button
- [x] Create variation button
- [x] Create log button

**Test Cases:**
- [ ] Recipe detail loads correctly
- [ ] Image carousel swipes between images
- [ ] Ingredients grouped by type (MAIN, SECONDARY, SEASONING)
- [ ] Steps numbered correctly
- [ ] Logs tab shows related logs
- [ ] Variants tab shows child recipes

---

### [RCP-003]: Create Recipe

**Status:** ✅ Implemented

**Description:**
Multi-step form to create a new recipe.

**User Story:**
As a cook, I want to create a recipe, so that I can share my dishes with others.

**Acceptance Criteria:**
- [x] Step 1: Add title and description
- [x] Step 2: Add ingredients (name, amount, type)
- [x] Step 3: Add cooking steps with optional images
- [x] Step 4: Add recipe photos
- [x] Step 5: Review and publish
- [x] Draft saved locally if interrupted
- [x] Requires login to publish

**UI/UX:**
- Screen: `CreateRecipeScreen` (multi-page form)
- Entry point: FAB on home screen, "+" button
- Flow: Step 1 → Step 2 → Step 3 → Step 4 → Review → Publish

**Technical Details:**
- Frontend: `lib/features/recipe/screens/create/`
- Backend: `POST /api/v1/recipes`
- Images: Upload first, then attach publicIds

**Edge Cases:**
- User exits mid-creation → Save draft locally
- Image upload fails → Show retry option
- Network error on publish → Queue for retry

**Test Cases:**
- [ ] Can add title and description
- [ ] Can add multiple ingredients
- [ ] Can add multiple steps
- [ ] Can upload recipe images
- [ ] Draft saved on exit
- [ ] Successful publish creates recipe

---

### [RCP-004]: Create Recipe Variation

**Status:** ✅ Implemented

**Description:**
Create a modified version of an existing recipe with change tracking.

**User Story:**
As a cook, I want to create a variation of a recipe, so that I can document my modifications.

**Acceptance Criteria:**
- [x] Pre-fill form with parent recipe data
- [x] Track changes (added/removed/modified ingredients)
- [x] Select change category (INGREDIENT, TECHNIQUE, SEASONING, etc.)
- [x] Link to parent recipe (parentPublicId)
- [x] Link to root recipe (rootPublicId)
- [x] Show "inspired by" attribution

**Technical Details:**
- Frontend: `lib/features/recipe/screens/create_variation/`
- Backend: `POST /api/v1/recipes` with parentPublicId, rootPublicId
- Lineage: parentPublicId = direct parent, rootPublicId = original

**Test Cases:**
- [ ] Variation created with correct parentPublicId
- [ ] Variation created with correct rootPublicId
- [ ] Changes highlighted in diff view
- [ ] Change category saved correctly

---

# 📝 Cooking Logs

### [LOG-001]: Create Cooking Log

**Status:** ✅ Implemented

**Description:**
Log a cooking attempt with photos, notes, and emoji outcome.

**User Story:**
As a cook, I want to log my cooking attempts, so that I can track my progress.

**Acceptance Criteria:**
- [x] Select outcome: SUCCESS 😊 / PARTIAL 😐 / FAILED 😢
- [x] Add photos of the result
- [x] Add notes/review text
- [x] Link to recipe
- [x] Timestamp recorded

**UI/UX:**
- Screen: `CreateLogScreen`
- Entry point: "Log" button on recipe detail
- Flow: Select outcome → Add photos → Add notes → Publish

**Technical Details:**
- Frontend: `lib/features/log_post/`
- Backend: `POST /api/v1/log-posts`

**Test Cases:**
- [ ] Can create log with SUCCESS outcome
- [ ] Can create log with PARTIAL outcome
- [ ] Can create log with FAILED outcome
- [ ] Log linked to correct recipe
- [ ] Photos uploaded and attached

---

# ⭐ Save/Bookmark

### [SAVE-001]: Save Recipe

**Status:** ✅ Implemented

**Description:**
Users can save recipes to their personal collection.

**User Story:**
As a user, I want to save recipes, so that I can find them later.

**Acceptance Criteria:**
- [x] Save button on recipe detail
- [x] Toggle save/unsave
- [x] Saved recipes in profile "Saved" tab
- [x] Visual indicator for saved state

**Test Cases:**
- [ ] Tapping save button saves recipe
- [ ] Tapping again unsaves recipe
- [ ] Saved recipes appear in profile
- [ ] Save state persists after app restart

---

# 👤 Profile

### [PROF-001]: User Profile

**Status:** ✅ Implemented

**Description:**
User profile page with tabs for created content.

**User Story:**
As a user, I want to view my profile, so that I can see my recipes and logs.

**Acceptance Criteria:**
- [x] Display profile photo and username
- [x] "My Recipes" tab
- [x] "My Logs" tab
- [x] "Saved" tab
- [x] Edit profile button
- [x] Settings/logout access

**Test Cases:**
- [ ] Profile loads user info
- [ ] My Recipes tab shows user's recipes
- [ ] My Logs tab shows user's logs
- [ ] Saved tab shows bookmarked recipes

---

# 📋 PLANNED FEATURES

### [FOLLOW-001]: Follow System

**Status:** 📋 Planned

**Branch:** `feature/follow-system`

**Description:**
Users can follow other users to build a social graph.

**User Story:**
As a user, I want to follow other cooks, so that I can see their new recipes.

**Acceptance Criteria:**
- [ ] Follow button on user profiles
- [ ] Followers count displayed
- [ ] Following count displayed
- [ ] Followers list screen
- [ ] Following list screen
- [ ] Unfollow functionality

**UI/UX:**
- Screen: `ProfileScreen` (follow button), `FollowersListScreen`
- Entry point: User profile
- Flow: Tap follow → Button changes to "Following" → Count updates

**Technical Details:**
- Frontend: `lib/features/profile/providers/follow_provider.dart`
- Backend: `POST /api/v1/users/{id}/follow`, `DELETE /api/v1/users/{id}/follow`
- Database: `user_follows` table

**Edge Cases:**
- Follow yourself → Disabled/hidden
- Follow then quickly unfollow → Debounce requests
- Network error → Show retry, revert UI optimistic update

**Error Handling:**
- Network error → "팔로우에 실패했습니다. 다시 시도해주세요."
- User not found → "사용자를 찾을 수 없습니다."

**Test Cases:**
- [ ] Can follow a user
- [ ] Can unfollow a user
- [ ] Follower count increments on follow
- [ ] Follower count decrements on unfollow
- [ ] Cannot follow yourself
- [ ] Followers list loads correctly
- [ ] Following list loads correctly

---

### [NOTIF-001]: Push Notifications

**Status:** 📋 Planned

**Branch:** `feature/push-notifications`

**Description:**
FCM push notifications for social interactions.

**User Story:**
As a user, I want to receive notifications, so that I know when someone interacts with my content.

**Acceptance Criteria:**
- [ ] NEW_FOLLOWER: "@김씨님이 팔로우했어요"
- [ ] RECIPE_COOKED: "@이씨님이 내 레시피로 요리했어요 😊"
- [ ] RECIPE_VARIATION: "@박씨님이 내 레시피를 변형했어요"
- [ ] Notification list screen
- [ ] Mark as read functionality
- [ ] Tap notification → Navigate to relevant screen

**Test Cases:**
- [ ] FCM token registered on login
- [ ] NEW_FOLLOWER notification received
- [ ] RECIPE_COOKED notification received
- [ ] RECIPE_VARIATION notification received
- [ ] Tapping notification opens correct screen

---

### [CACHE-001]: Profile Page Local Caching

**Status:** ✅ Implemented

**Branch:** `feature/profile-caching`

**Description:**
Cache profile tabs locally to avoid hitting server every time. Uses Hive for simpler key-value storage instead of Isar.

**User Story:**
As a user, I want my profile to load instantly, so that I don't wait for network requests.

**Acceptance Criteria:**
- [x] "My Recipes" cached in Hive (5 min TTL)
- [x] "My Logs" cached in Hive (5 min TTL)
- [x] "Saved" cached in Hive (5 min TTL)
- [x] Cache indicator showing last update time (orange banner)
- [x] Pull-to-refresh forces cache invalidation
- [x] Cache invalidated on create/delete

**Technical Details:**
- Frontend: `lib/features/profile/providers/`, Hive boxes
- Pattern: Cache-first with CachedData<T> wrapper
- See: DEC-006, DEC-010 in DECISIONS.md

**Test Cases:**
- [x] First load fetches from network and caches
- [x] Second load shows cached data immediately
- [x] Pull-to-refresh updates cache
- [ ] Creating recipe invalidates My Recipes cache
- [ ] Deleting recipe invalidates My Recipes cache

---

### [SEARCH-001]: Enhanced Search

**Status:** ✅ Implemented

**Branch:** `feature/enhanced-search`

**Description:**
Improved search experience with suggestions, search history, and better visual design.

**User Story:**
As a user, I want to see my search history and get suggestions, so that I can find recipes faster.

**Acceptance Criteria:**
- [x] Search history stored per SearchType (recipe vs log)
- [x] Recent searches shown below search bar
- [x] Clear individual search or all history
- [x] Rounded search bar with improved styling
- [x] Search suggestions overlay while typing

**Technical Details:**
- Frontend: `lib/features/search/widgets/enhanced_search_app_bar.dart`
- Frontend: `lib/features/search/widgets/search_suggestions_overlay.dart`
- Frontend: `lib/core/services/search_history_service.dart`
- Storage: Hive for search history persistence

**Test Cases:**
- [x] Search query saved to history on submit
- [x] History grouped by SearchType
- [x] Can clear individual search item
- [x] Can clear all search history
- [ ] Suggestions appear while typing

---

### [IMG-001]: Server-Side Image Variants

**Status:** ✅ Implemented

**Branch:** `feature/image-variants`

**Description:**
Server generates multiple image sizes for bandwidth optimization. Client selects optimal size based on display requirements.

**User Story:**
As a user on mobile data, I want images to load fast, so that I don't waste bandwidth on oversized images.

**Acceptance Criteria:**
- [x] Server generates 5 variants: ORIGINAL, LARGE_1200, MEDIUM_800, THUMB_400, THUMB_200
- [x] Async processing after upload (non-blocking)
- [x] WebP format for better compression
- [x] Client selects optimal variant via getBestUrl()
- [x] AppCachedImage updated to use variants

**Technical Details:**
- Backend: `ImageProcessingService.java` with @Async processing
- Backend: `ImageVariant.java` enum
- Backend: `V10__add_image_variants.sql` migration
- Frontend: `ImageVariants` entity
- Frontend: `AppCachedImage` updated for variant selection
- See: DEC-009 in DECISIONS.md

**Test Cases:**
- [x] Upload generates all variant sizes
- [x] Variants stored with correct metadata
- [x] Client receives variant URLs in response
- [x] getBestUrl returns appropriate size for display width
- [ ] Graceful fallback if variant missing

---

### [EVENT-001]: Event Tracking System

**Status:** ✅ Implemented

**Branch:** `feature/event-tracking`

**Description:**
Reliable event tracking with offline support using outbox pattern. Events queued locally in Isar, synced to server with priority-based batching.

**User Story:**
As the product team, I want reliable analytics, so that I don't lose events due to network issues.

**Acceptance Criteria:**
- [x] Events stored locally in Isar before sync
- [x] Priority-based sync (IMMEDIATE for writes, LOW for analytics)
- [x] Idempotency keys prevent duplicate events
- [x] Background sync when connectivity available
- [x] Failed events retried with backoff

**Technical Details:**
- Frontend: `lib/core/services/event_sync_manager.dart`
- Frontend: Isar collections for event queue
- Pattern: Outbox pattern with priority enum
- See: DEC-007, DEC-008 in DECISIONS.md

**Test Cases:**
- [x] Event queued locally on creation
- [x] IMMEDIATE priority events sync instantly
- [x] LOW priority events batched
- [x] Duplicate events rejected by idempotency key
- [ ] Retry logic on sync failure

---

# 📤 Sharing

### [SHARE-001]: Social Sharing

**Status:** 🟡 In Progress

**Branch:** `feature/social-sharing`

**Description:**
Share recipes to social platforms (KakaoTalk, Twitter, Instagram, etc.) with rich link previews showing recipe image, title, and description.

**User Story:**
As a user, I want to share a recipe to KakaoTalk or Twitter, so that my friends can see a preview and open the recipe directly.

**Acceptance Criteria:**
- [ ] Share button on recipe detail screen
- [ ] Rich link preview with Open Graph meta tags
- [ ] Preview shows: recipe image, title, description, creator name
- [ ] Deep link opens recipe detail screen in app
- [ ] Fallback to web URL if app not installed
- [ ] KakaoTalk share with custom template
- [ ] Twitter/X share with card preview
- [ ] Copy link to clipboard option

**UI/UX:**
- Screen: `RecipeDetailScreen`
- Entry point: Share icon button in app bar
- Flow: Tap share → Bottom sheet with options → Select platform → Open platform share dialog

**Technical Details:**
- Frontend: `lib/features/recipe/widgets/share_bottom_sheet.dart`
- Frontend: `share_plus` package for native share
- Backend: `GET /api/v1/recipes/{publicId}/og` returns Open Graph HTML
- Backend: Dynamic Open Graph meta tags for crawlers
- Deep linking: `pairingplanet://recipe/{publicId}`

**Edge Cases:**
- Recipe has no image → Use default app image
- Recipe title too long → Truncate to 60 chars
- Recipe is private → Show "비공개 레시피입니다" message
- User not logged in → Still allow sharing public recipes

**Error Handling:**
- Share failed → "공유에 실패했습니다. 다시 시도해주세요."
- Link copy failed → "클립보드 복사에 실패했습니다."

**Test Cases:**
- [ ] Share button visible on recipe detail
- [ ] Bottom sheet shows all share options
- [ ] Open Graph endpoint returns valid HTML
- [ ] Deep link opens correct recipe
- [ ] Copy link works and shows confirmation

---

## Feature Index

| ID | Feature | Status | Category |
|----|---------|--------|----------|
| AUTH-001 | Social Login | ✅ | Authentication |
| AUTH-002 | Anonymous Browsing | ✅ | Authentication |
| RCP-001 | Recipe List | ✅ | Recipes |
| RCP-002 | Recipe Detail | ✅ | Recipes |
| RCP-003 | Create Recipe | ✅ | Recipes |
| RCP-004 | Create Variation | ✅ | Recipes |
| LOG-001 | Create Log | ✅ | Cooking Logs |
| SAVE-001 | Save Recipe | ✅ | Save/Bookmark |
| PROF-001 | User Profile | ✅ | Profile |
| FOLLOW-001 | Follow System | 📋 | Social |
| NOTIF-001 | Push Notifications | 📋 | Notifications |
| CACHE-001 | Profile Caching | ✅ | Performance |
| SEARCH-001 | Enhanced Search | ✅ | Search |
| IMG-001 | Image Variants | ✅ | Performance |
| EVENT-001 | Event Tracking | ✅ | Analytics |
| SHARE-001 | Social Sharing | 🟡 | Sharing |

---

See [ROADMAP.md](ROADMAP.md) for implementation priorities.
See [CLAUDE.md](CLAUDE.md) for coding rules.
See [TECHSPEC.md](TECHSPEC.md) for technical architecture.
