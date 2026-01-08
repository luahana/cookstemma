# ROADMAP.md — Pairing Planet

> Track what to work on. Update this file when tasks are completed.

---

## CURRENT SPRINT

**Active tasks for Claude Code to work on (in priority order):**

### Priority 0 — Critical (Do These First)

- [x] **Profile Page Local Caching** — Cache "My Recipes", "My Logs", "Saved" tabs in Isar (2026-01-07)
  - Files: `profile_provider.dart`, `user_local_data_source.dart`
  - Pattern: Cache-first, show cached data immediately, then refresh from network
  - Add cache indicator like home feed

### Priority 1 — High Impact

- [x] **Follow System** — Users can follow each other (2026-01-07)
  - Backend: `UserFollow.java`, `FollowService.java`, `FollowController.java`
  - Frontend: `follow_provider.dart`, `follow_button.dart`, `followers_list_screen.dart`
  - DB: `user_follows` table, add `follower_count`/`following_count` to users

- [x] **Push Notifications (FCM)** — Bring users back with notifications (2026-01-07)
  - Types: RECIPE_COOKED, RECIPE_VARIATION, NEW_FOLLOWER
  - Backend: `notifications` table, `user_fcm_tokens` table
  - Frontend: FCM integration, notification handling

### Priority 2 — Engagement

- [x] **Social Sharing** — Rich link previews for KakaoTalk, Instagram, Twitter (2026-01-07)
  - Backend: Open Graph HTML endpoint
  - Frontend: Locale-aware share options
- [x] **Profile Edit** — Birthday, gender, language preference (2026-01-07)
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
- [x] Follow System — Follow/unfollow with counts (2026-01-07)
- [x] Push Notifications — FCM for NEW_FOLLOWER, RECIPE_COOKED, RECIPE_VARIATION (2026-01-07)
- [x] Profile Edit — Birthday, gender, language preference (2026-01-07)

### Content Sharing
- [x] Social Sharing — Open Graph meta tags for rich link previews (2026-01-07)
- [x] Locale-aware Share — KakaoTalk for Korea, WhatsApp for others (2026-01-07)

### Infrastructure
- [x] Event Tracking — Isar queue, outbox pattern, EventSyncManager (2026-01-05)
- [x] Basic Offline Cache — Recipe list/detail caching with fallback
- [x] Profile Page Caching — My Recipes, My Logs, Saved tabs cached (2026-01-07)
- [x] Cache Indicator — Orange banner showing "오프라인 데이터" with timestamp
- [x] Image Variants — Server-side thumbnail and display variants (2026-01-07)

### UI/UX
- [x] Emoji Outcomes — SUCCESS/PARTIAL/FAILED instead of star ratings
- [x] Activity Counts — Variant count and log count on recipe cards
- [x] Empty States — Friendly messages with action buttons
- [x] Error States — User-friendly error messages with retry
- [x] Enhanced Search — Autocomplete suggestions and search history (2026-01-07)

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
