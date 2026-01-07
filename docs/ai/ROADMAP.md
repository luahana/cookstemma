# ROADMAP.md — Pairing Planet

> Track what to work on. Update this file when tasks are completed.

---

## CURRENT SPRINT

**Active tasks for Claude Code to work on (in priority order):**

### Priority 0 — Critical (Do These First)

- [x] **Profile Page Local Caching** — Cache "My Recipes", "My Logs", "Saved" tabs (2026-01-05)

### Priority 1 — High Impact

- [ ] **Follow System** — Users can follow each other
  - Backend: `UserFollow.java`, `FollowService.java`, `FollowController.java`
  - Frontend: `follow_provider.dart`, `follow_button.dart`, `followers_list_screen.dart`
  - DB: `user_follows` table, add `follower_count`/`following_count` to users

- [ ] **Push Notifications (FCM)** — Bring users back with notifications
  - Types: NEW_FOLLOWER, RECIPE_COOKED, RECIPE_VARIATION
  - Backend: `notifications` table, `user_fcm_tokens` table
  - Frontend: FCM integration, notification handling

### Priority 2 — Engagement

- [ ] **Social Sharing** — Rich link previews for KakaoTalk, Instagram, Twitter
- [ ] **Improved Onboarding** — 5-screen flow explaining recipe variation concept
- [ ] **Full-Text Search** — PostgreSQL trigram search for recipes

### Priority 3 — Gamification

- [ ] **Achievement Badges** — "첫 요리", "용감한 요리사", "꾸준한 요리사"
- [ ] **Comments on Recipes** — Threaded discussions
- [ ] **Variation Tree Visualization** — Interactive tree diagram

### Priority 4 — Scale

- [ ] **Web Version (SEO)** — Next.js for search engine discoverability
- [ ] **Premium Subscription** — $4.99/month for analytics, PDF export

---

## COMPLETED

### Core Features
- [x] Recipe CRUD — Create, read, update recipes with ingredients and steps
- [x] Recipe Variations — Create variations with parent/root tracking
- [x] Cooking Logs — Log attempts with emoji outcomes (😊/😐/😢)
- [x] Recipe List — Paginated feed with infinite scroll
- [x] Recipe Detail — Full view with tabs for logs and variants
- [x] Variants Gallery — Grid/list view with thumbnails

### User System
- [x] Firebase Authentication — Google, Apple, Anonymous sign-in
- [x] User Profiles — Basic profile with created recipes and logs
- [x] Save/Bookmark — Save recipes for later (2026-01-05)

### Infrastructure
- [x] Event Tracking — Isar queue, outbox pattern, EventSyncManager (2026-01-05)
- [x] Basic Offline Cache — Recipe list/detail caching with fallback
- [x] Cache Indicator — Orange banner showing "오프라인 데이터" with timestamp

### UI/UX
- [x] Emoji Outcomes — SUCCESS/PARTIAL/FAILED instead of star ratings
- [x] Activity Counts — Variant count and log count on recipe cards
- [x] Empty States — Friendly messages with action buttons
- [x] Error States — User-friendly error messages with retry

---

## BACKLOG (Not Yet Scheduled)

### Infrastructure
- [ ] Image Compression — Resize to 1200x1200, WebP conversion, >80% size reduction
- [ ] Anonymous Content Limits — Limit to 1 recipe + 1 log before requiring login
- [ ] Sentry Observability — Production crash monitoring (blocked by Kotlin version)
- [ ] Idempotency Keys — Prevent duplicate writes on network retries

### Deferred (Need More Data First)
- [ ] Recipe Insights ("간단해요", "실패 적어요") — Need 10+ logs per recipe
- [ ] Profile Success Rate — Need outcome field & log data
- [ ] ML Recommendations — Need user behavior data

---

## IMPLEMENTATION SPECS

<details>
<summary>Profile Page Local Caching (Priority 0)</summary>

**Goal**: Cache profile tabs locally to avoid hitting server every time.

**Cache Strategy**:
| Tab | Cache Key | TTL |
|-----|-----------|-----|
| My Recipes | `my_recipes_{userId}` | 5 min |
| My Logs | `my_logs_{userId}` | 5 min |
| Saved | `saved_recipes_{userId}` | 5 min |

**Implementation**:
```dart
// profile_local_data_source.dart
class ProfileLocalDataSource {
  final Isar isar;
  
  Future<List<RecipeSummaryDto>?> getMyRecipes(String userId) async {
    final cached = await isar.profileCaches
      .where().keyEqualTo('my_recipes_$userId').findFirst();
    if (cached == null || cached.isExpired) return null;
    return cached.recipes;
  }
  
  Future<void> cacheMyRecipes(String userId, List<RecipeSummaryDto> recipes) async {
    await isar.writeTxn(() => isar.profileCaches.put(
      ProfileCache(key: 'my_recipes_$userId', recipes: recipes, cachedAt: DateTime.now())
    ));
  }
}

// profile_provider.dart
final myRecipesProvider = FutureProvider.family<List<RecipeEntity>, String>((ref, userId) async {
  final local = ref.read(profileLocalDataSourceProvider);
  final remote = ref.read(profileRemoteDataSourceProvider);
  
  // Cache-first
  final cached = await local.getMyRecipes(userId);
  if (cached != null) {
    // Refresh in background
    remote.getMyRecipes(userId).then((fresh) => local.cacheMyRecipes(userId, fresh));
    return cached.map((dto) => dto.toEntity()).toList();
  }
  
  // Fetch from server
  final fresh = await remote.getMyRecipes(userId);
  await local.cacheMyRecipes(userId, fresh);
  return fresh.map((dto) => dto.toEntity()).toList();
});
```
</details>

<details>
<summary>Follow System (Priority 1)</summary>

**Database Migration** (`V__add_user_follows.sql`):
```sql
CREATE TABLE user_follows (
    follower_id BIGINT NOT NULL REFERENCES users(id),
    following_id BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

CREATE INDEX idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_user_follows_following ON user_follows(following_id);

ALTER TABLE users ADD COLUMN follower_count INT DEFAULT 0;
ALTER TABLE users ADD COLUMN following_count INT DEFAULT 0;
```

**API Endpoints**:
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/users/{id}/follow` | Follow user |
| DELETE | `/api/v1/users/{id}/follow` | Unfollow |
| GET | `/api/v1/users/{id}/followers` | List followers (paginated) |
| GET | `/api/v1/users/{id}/following` | List following (paginated) |
| GET | `/api/v1/users/{id}/follow-status` | Check if current user follows |

**Backend Files**:
- `domain/UserFollow.java` — Entity
- `repository/UserFollowRepository.java` — JPA repository
- `service/FollowService.java` — Business logic
- `controller/FollowController.java` — REST endpoints
- `dto/follow/FollowResponseDto.java` — Response DTO

**Frontend Files**:
- `data/datasources/follow_remote_data_source.dart`
- `data/repositories/follow_repository_impl.dart`
- `domain/repositories/follow_repository.dart`
- `features/profile/providers/follow_provider.dart`
- `features/profile/widgets/follow_button.dart`
- `features/profile/screens/followers_list_screen.dart`
</details>

<details>
<summary>Push Notifications (Priority 1)</summary>

**Database Migration** (`V__add_notifications.sql`):
```sql
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    public_id UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(200),
    body TEXT,
    data JSONB,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE read_at IS NULL;

CREATE TABLE user_fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    fcm_token VARCHAR(500) NOT NULL,
    device_type VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);
```

**Notification Types**:
| Type | Trigger | Message Example |
|------|---------|-----------------|
| NEW_FOLLOWER | User follows you | "@김씨님이 팔로우했어요" |
| RECIPE_COOKED | Someone logs your recipe | "@이씨님이 내 레시피로 요리했어요 😊" |
| RECIPE_VARIATION | Someone creates variation | "@박씨님이 내 레시피를 변형했어요" |
</details>

---

## HOW TO USE THIS FILE

**For Claude Code**:
1. Read CURRENT SPRINT to find next task
2. Pick highest priority uncompleted item `[ ]`
3. Expand implementation spec if available
4. After completing, change `[ ]` to `[x]`
5. Add completion date if significant

**For Humans**:
- Add new tasks to appropriate priority level
- Move completed tasks to COMPLETED section periodically
- Add implementation specs in collapsible sections

---

See [CLAUDE.md](CLAUDE.md) for coding rules.
See [TECHSPEC.md](TECHSPEC.md) for architecture details.
See [CHANGELOG.md](CHANGELOG.md) for version history.
