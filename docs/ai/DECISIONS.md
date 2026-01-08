# DECISIONS.md — Pairing Planet

> Architecture Decision Records (ADRs). Document WHY technical decisions were made.

---

## How to Use This File

**Claude Code:** Before adding a decision, ASK the user:
> "Should I document this decision in DECISIONS.md?"

**Format:** Each decision includes context, alternatives, and consequences.

---

## Decision Template

```markdown
### [DEC-XXX]: Decision Title

**Date:** YYYY-MM-DD
**Status:** 🟡 Proposed | ✅ Accepted | ❌ Rejected | 🔄 Superseded by DEC-XXX

**Context:**
What is the issue or problem we're facing?

**Decision:**
What did we decide to do?

**Reason:**
Why did we choose this option?

**Alternatives Considered:**
- Option A: [pros/cons]
- Option B: [pros/cons]

**Consequences:**
- Positive: ...
- Negative: ...
- Neutral: ...
```

---

# Accepted Decisions

### [DEC-001]: Use Isar for Local Database

**Date:** 2024-12-15
**Status:** ✅ Accepted

**Context:**
Need offline caching for recipes, logs, and user data. App should work without network.

**Decision:**
Use Isar as the local database.

**Reason:**
- Type-safe queries with code generation
- Fast performance for large datasets
- Good Flutter integration
- Supports complex queries (unlike Hive)

**Alternatives Considered:**
- Hive: Simpler but no query support, only key-value
- SQLite (sqflite): Too low-level, more boilerplate
- Drift: Good but heavier, SQL-based
- ObjectBox: Similar to Isar but less Flutter community support

**Consequences:**
- Positive: Can query cached data efficiently
- Negative: Must run build_runner after schema changes
- Neutral: Learning curve for Isar-specific syntax

---

### [DEC-002]: Use Either<Failure, T> for Error Handling

**Date:** 2024-12-20
**Status:** ✅ Accepted

**Context:**
Need consistent error handling across repositories and providers.

**Decision:**
Use `Either<Failure, T>` from dartz package in all repository methods.

**Reason:**
- Forces explicit error handling
- No try-catch scattered everywhere
- Type-safe failure types
- Clear contract between layers

**Alternatives Considered:**
- Try-catch with exceptions: Easy to forget handling
- Result class (custom): Reinventing the wheel
- Nullable returns: Loses error information

**Consequences:**
- Positive: Consistent error handling, clear API contracts
- Negative: More verbose, need to fold/map results
- Neutral: Team needs to learn Either pattern

---

### [DEC-003]: Use publicId (UUID) Instead of Internal ID

**Date:** 2024-12-18
**Status:** ✅ Accepted

**Context:**
Need to expose entity identifiers in API without revealing database internals.

**Decision:**
Every entity has both `id` (internal Long) and `publicId` (UUID). Only `publicId` is exposed in API.

**Reason:**
- Security: Don't expose auto-increment IDs (reveals record count, easy to enumerate)
- Flexibility: Can change internal ID scheme without breaking API
- Consistency: UUIDs work across distributed systems

**Alternatives Considered:**
- Expose internal ID: Security risk
- Use UUID as primary key: Performance overhead in database
- HashIds: Reversible, not truly secure

**Consequences:**
- Positive: Secure, flexible API design
- Negative: Extra column in every table, slightly more complex queries
- Neutral: Need to remember to always use publicId in DTOs

---

### [DEC-004]: Soft Delete for Recipes and Logs

**Date:** 2024-12-22
**Status:** ✅ Accepted

**Context:**
Users might accidentally delete recipes. Variations reference parent recipes.

**Decision:**
Use soft delete (`deleted_at` timestamp) instead of hard delete for recipes and logs.

**Reason:**
- Preserve recipe lineage (variations still reference deleted parents)
- Allow recovery of accidental deletes
- Audit trail

**Alternatives Considered:**
- Hard delete: Simpler but loses data, breaks references
- Archive table: More complex, harder to query

**Consequences:**
- Positive: Data preservation, reference integrity
- Negative: Database grows, need `WHERE deleted_at IS NULL` everywhere
- Neutral: Need scheduled job to eventually hard-delete very old records

---

### [DEC-005]: Firebase Authentication with Backend JWT

**Date:** 2024-12-10
**Status:** ✅ Accepted

**Context:**
Need social login (Google, Apple) without managing OAuth ourselves.

**Decision:**
Use Firebase Auth for social login, exchange Firebase token for our own JWT.

**Reason:**
- Firebase handles OAuth complexity
- We control our own JWT for backend authorization
- Can add non-Firebase auth methods later

**Alternatives Considered:**
- Firebase only: Vendor lock-in for auth
- Self-hosted OAuth: Too complex to implement
- Auth0/Supabase: Additional cost, another dependency

**Consequences:**
- Positive: Easy social login, control over JWT
- Negative: Two auth systems to understand
- Neutral: Firebase free tier is generous

---

### [DEC-006]: Use Hive for Profile & Search Caching

**Date:** 2026-01-05
**Status:** ✅ Accepted

**Context:**
Profile tabs (My Recipes, My Logs, Saved) and search history need local caching for instant load times and offline access.

**Decision:**
Use Hive instead of Isar for profile and search caching.

**Reason:**
- Simpler key-value storage model for cache data
- Less boilerplate than Isar for simple cache scenarios
- Isar reserved for structured event queuing where queries are needed
- Hive boxes provide easy namespace separation per data type

**Alternatives Considered:**
- Isar: Already used for event queue, but overkill for simple cache
- SharedPreferences: No support for complex objects
- SQLite: Too low-level for cache scenarios

**Consequences:**
- Positive: Fast read/write, simple API for cache operations
- Negative: Two local storage solutions in the app (Isar + Hive)
- Neutral: Hive boxes need initialization at app startup

---

### [DEC-007]: Outbox Pattern for Event Tracking

**Date:** 2026-01-05
**Status:** ✅ Accepted

**Context:**
Analytics events need reliable delivery even with network issues. Events should not be lost if the app closes or network fails.

**Decision:**
Implement outbox pattern with Isar queue + background sync.

**Reason:**
- Events stored locally first (guaranteed persistence)
- Background sync handles network failures gracefully
- Idempotency keys prevent duplicate events on retry
- Works offline, syncs when connectivity returns

**Alternatives Considered:**
- Direct API calls: Events lost on network failure
- Firebase Analytics only: Vendor lock-in, limited custom events
- In-memory queue: Lost on app termination

**Consequences:**
- Positive: Reliable event delivery, offline support
- Negative: More complex architecture, eventual consistency
- Neutral: Small delay between event creation and server receipt

---

### [DEC-008]: Priority-Based Event Sync

**Date:** 2026-01-05
**Status:** ✅ Accepted

**Context:**
Write operations (recipe create) need immediate sync for data integrity. Analytics events can batch to reduce network calls.

**Decision:**
Use EventPriority enum (IMMEDIATE, HIGH, NORMAL, LOW) with different sync strategies.

**Reason:**
- IMMEDIATE: Critical writes sync instantly (recipe/log creation)
- HIGH: Important but can tolerate short delay
- NORMAL: Standard analytics, batched every few minutes
- LOW: Non-critical telemetry, batched on app close

**Alternatives Considered:**
- Single priority: All events treated same, wastes bandwidth or delays critical data
- Time-based only: No concept of importance

**Consequences:**
- Positive: Efficient bandwidth usage, fast critical operations
- Negative: More complex sync logic
- Neutral: Need to classify each event type appropriately

---

### [DEC-009]: Device-Aware Image Variants

**Date:** 2026-01-06
**Status:** ✅ Accepted

**Context:**
Mobile needs smaller images than web for bandwidth optimization. Different screens need different resolutions (thumbnails vs full-screen).

**Decision:**
Server generates 5 image variants (original, 1200px, 800px, 400px, 200px). Client selects optimal size based on displayWidth × devicePixelRatio.

**Reason:**
- Reduces bandwidth for mobile (often on cellular)
- Faster load times with appropriately sized images
- WebP format for better compression
- One-time server processing, reusable across clients

**Alternatives Considered:**
- Client-side resize: CPU intensive on mobile, still downloads full image
- Single thumbnail + original: Either too small or too large for most cases
- CDN image transformation (Cloudinary): $100+/month vs $20-35/month S3

**Consequences:**
- Positive: 60-80% bandwidth reduction for thumbnails, faster loads
- Negative: More S3 storage (5x per image), async processing delay
- Neutral: Client logic to select correct variant

---

### [DEC-010]: TTL-Based Cache Staleness Indicator

**Date:** 2026-01-05
**Status:** ✅ Accepted

**Context:**
Need to show cached data immediately for instant UX, but users should know if data might be outdated.

**Decision:**
Use CachedData<T> wrapper with cachedAt timestamp. Show orange banner for stale data (>5 min TTL). Refresh in background.

**Reason:**
- Cache-first provides instant perceived performance
- Staleness indicator maintains user trust (they know data might be old)
- Background refresh updates without blocking UI
- 5-minute TTL balances freshness vs network calls

**Alternatives Considered:**
- Network-first: Slower perceived performance, loading spinners
- No indicator: Users might think stale data is current
- Shorter TTL (1 min): Too many network requests

**Consequences:**
- Positive: Instant UI, transparent freshness, efficient updates
- Negative: Users see "오프라인 데이터" banner sometimes
- Neutral: Cache invalidation on create/update operations

---

# Decision Index

| ID | Decision | Date | Status |
|----|----------|------|--------|
| DEC-001 | Use Isar for Local Database | 2024-12-15 | ✅ Accepted |
| DEC-002 | Use Either<Failure, T> for Error Handling | 2024-12-20 | ✅ Accepted |
| DEC-003 | Use publicId (UUID) Instead of Internal ID | 2024-12-18 | ✅ Accepted |
| DEC-004 | Soft Delete for Recipes and Logs | 2024-12-22 | ✅ Accepted |
| DEC-005 | Firebase Auth with Backend JWT | 2024-12-10 | ✅ Accepted |
| DEC-006 | Use Hive for Profile & Search Caching | 2026-01-05 | ✅ Accepted |
| DEC-007 | Outbox Pattern for Event Tracking | 2026-01-05 | ✅ Accepted |
| DEC-008 | Priority-Based Event Sync | 2026-01-05 | ✅ Accepted |
| DEC-009 | Device-Aware Image Variants | 2026-01-06 | ✅ Accepted |
| DEC-010 | TTL-Based Cache Staleness Indicator | 2026-01-05 | ✅ Accepted |

---

See [TECHSPEC.md](TECHSPEC.md) for implementation details.
See [CLAUDE.md](CLAUDE.md) for coding rules.
