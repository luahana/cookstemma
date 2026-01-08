# CLAUDE.md — Pairing Planet

> Flutter + Spring Boot recipe sharing app. Offline-first architecture.

---

## 📂 FILE LOCATIONS

**All documentation files are in `docs/ai/`:**
```
project-root/
└── docs/ai/
    ├── CLAUDE.md                ← This file (rules) - READ FIRST
    ├── FEATURES.md              ← Features, tasks, decisions - READ SECOND
    ├── TECHSPEC.md              ← Technical specification
    └── CHANGELOG.md             ← Version history
```

---

## 🚀 SESSION START

**Every new session, do this first:**
```
1. Read CLAUDE.md (this file)
2. Check current branch: git branch --show-current
3. Check status: git status
4. Read FEATURES.md → Find current task (🟡 In Progress)
5. If no 🟡 task → Ask user what to work on
```

---

## ⚙️ SETUP

```bash
claude --dangerously-skip-permissions --model opus
```

---

## 🔴 CRITICAL RULES

0. **Model** → Use opus with extended thinking, skip permissions
1. **Before coding** → Create branch from dev
2. **Before ANY feature** → Plan with ultrathink + research best practices (see below)
3. **After planning** → Document in FEATURES.md, get approval
4. **After feature** → Write and run tests (must pass)
5. **Before commit** → Run pre-commit checklist
6. **Push & PR** → `git push origin HEAD` then `gh pr create --base dev`
7. **After DTOs/Isar** → Run `dart run build_runner build --delete-conflicting-outputs`
8. **After `await`** → Check `if (!context.mounted) return;`
9. **API IDs** → Use `publicId` (UUID), never internal `id`
10. **Providers in callbacks** → `ref.read()`, not `ref.watch()`
11. **Entities** → Never import `json_annotation` or `isar`
12. **Backend Slice** → Field is `content`, not `items`
13. **Recipe variants** → Include `parentPublicId` + `rootPublicId`
14. **Error handling** → Return `Either<Failure, T>`, never throw
15. **Commits** → `feat|fix|docs|chore(scope): description`

---

## 🧠 PLANNING WITH ULTRATHINK

**Before implementing ANY feature, use extended thinking to:**

```
1. UNDERSTAND the feature deeply
   - What problem does it solve?
   - Who uses it and how?
   - What are edge cases?

2. RESEARCH best practices
   - How do successful apps implement this?
   - What are industry standards?
   - What mistakes should we avoid?

3. DESIGN the solution
   - Data models needed
   - API endpoints needed
   - UI/UX flow
   - Error handling

4. PLAN implementation steps
   - What order to build?
   - What tests to write?
   - What could go wrong?
```

**Always think deeply before writing code.**

---

## 🔍 BEST PRACTICES RESEARCH

**Before implementing a feature, research how real-world apps do it:**

### What to Research
| Feature Type | Research These Apps | Look For |
|--------------|---------------------|----------|
| Follow system | Instagram, Twitter, TikTok | Optimistic UI, follower counts, mutual follows |
| Notifications | Slack, Discord, WhatsApp | Grouping, read/unread, push vs in-app |
| Search | Pinterest, Spotify, YouTube | Autocomplete, filters, recent searches |
| Feed/List | Instagram, Reddit, TikTok | Infinite scroll, caching, pull-to-refresh |
| Profile | Instagram, LinkedIn, Twitter | Tabs, edit flow, stats display |
| Image upload | Instagram, WhatsApp, Imgur | Compression, progress, retry |
| Caching | Any offline-first app | TTL, invalidation, sync strategy |
| Auth | Any modern app | Token refresh, session management, logout |

### Research Checklist
```
□ How do top 3 apps implement this feature?
□ What UX patterns are standard?
□ What are common pitfalls to avoid?
□ What accessibility concerns exist?
□ What performance optimizations are used?
□ How is error handling done?
□ What edge cases do they handle?
```

### Example: Planning Follow System

**Research findings:**
```
Instagram/Twitter patterns:
- Optimistic UI: Button changes immediately, reverts on failure
- Counts update instantly (local), sync with server later
- Mutual follow detection ("Follows you" badge)
- Rate limiting to prevent spam
- Block list check before allowing follow

Common pitfalls:
- Race conditions with rapid tap
- Count inconsistency between screens
- Stale data after unfollow
- Not handling blocked users

Our implementation should:
- Use optimistic updates with rollback
- Cache follower counts locally
- Debounce rapid taps
- Show loading state on failure
- Sync counts on screen focus
```

---

## 🆕 NEW FEATURE WORKFLOW

**When user requests a new feature:**

```
PHASE 1: UNDERSTAND (ultrathink)
1. What exactly is the user asking for?
2. Why do they need this?
3. What's the scope?

PHASE 2: RESEARCH (best practices)
4. How do Instagram/Twitter/Pinterest do this?
5. What are industry-standard UX patterns?
6. What are common mistakes to avoid?

PHASE 3: PLAN (ultrathink)
7. Design data models
8. Design API endpoints
9. Design UI/UX flow
10. Identify edge cases
11. Plan error handling

PHASE 4: DOCUMENT
12. Write feature spec with:
    - Description
    - Acceptance criteria (from research)
    - Technical notes (from planning)
    - Edge cases identified
13. Ask: "Here's the spec based on research. Approve?"

PHASE 5: IMPLEMENT (only after approval)
14. Create branch
15. Backend first, frontend second
16. Write tests
17. Update FEATURES.md → ✅
```

---

## 📝 FEATURE SPEC TEMPLATE (After Research)

```markdown
### [FEAT-XXX]: Feature Name

**Status:** 📋 Planned
**Branch:** `feature/xxx`

**Description:** What it does

**Research Findings:**
- Instagram does X
- Twitter does Y
- Common pattern: Z
- Pitfall to avoid: W

**Acceptance Criteria:**
- [ ] Criterion based on best practices
- [ ] Edge case handling
- [ ] Error handling
- [ ] Performance consideration

**Technical Notes:**
- Backend: endpoints, models
- Frontend: screens, providers
- Caching strategy
- Error handling approach

**Edge Cases:**
- What if network fails?
- What if user does X rapidly?
- What if data is stale?
```

---

## ✅ PRE-COMMIT CHECKLIST

**Run before EVERY commit:**
```
□ flutter analyze                    → No errors
□ flutter test                       → All pass
□ ./gradlew test (if backend)        → All pass
□ No print() or console.log left
□ No TODO comments (fix or remove)
□ No hardcoded strings (use constants)
□ Imports clean (no unused)
□ FEATURES.md updated:
  - Status → ✅ Done
  - Criteria → [x] checked
```

---

## 🔀 GIT

**Branch strategy:**
```
main ← staging ← dev ← feature/*
                     ← bugfix/*
```

**PR targets:**
| From | PR to | NOT to |
|------|-------|--------|
| `feature/*` | `dev` | ❌ staging, ❌ main |
| `bugfix/*` | `dev` | ❌ staging, ❌ main |
| `dev` | `staging` | ❌ main |
| `staging` | `main` | - |

**Commands:**
```bash
git checkout dev && git pull origin dev
git checkout -b feature/<name>
git push origin HEAD
gh pr create --base dev --title "feat(scope): description"
```

---

## 🔄 FULL-STACK FEATURES

**When feature needs BOTH frontend AND backend:**

```
1. Backend first:
   - Create migration (if needed)
   - Create/update DTOs
   - Create/update Controller, Service, Repository
   - Write backend tests
   - Test with curl/Postman

2. Frontend second:
   - Create/update DTOs (match backend)
   - Run build_runner
   - Create/update Repository
   - Create/update Provider
   - Create/update UI
   - Write frontend tests

3. Integration:
   - Test full flow end-to-end
   - Check error handling
```

---

## 🏗️ IMPORT RULES BY LAYER

```
┌─────────────────────────────────────────────────────┐
│ LAYER          │ CAN IMPORT              │ CANNOT   │
├─────────────────────────────────────────────────────┤
│ domain/entities │ dart:core only         │ packages │
│ domain/repos    │ entities, dartz        │ data/*   │
│ data/models     │ json_annotation, isar  │ domain/* │
│ data/repos      │ everything in data/*   │ features │
│ features/*      │ everything             │ -        │
└─────────────────────────────────────────────────────┘
```

---

## 🧪 TESTING

```bash
# Frontend
flutter test --coverage

# Backend
./gradlew test jacocoTestReport
```

| Changed | Test Type |
|---------|-----------|
| Repository | Unit: success + failure |
| API endpoint | Controller test |
| Service | Mock test |
| Provider | State test |
| Screen | Widget test |
| Bug fix | Regression test |

---

## 🔥 ERROR RECOVERY

**If tests fail:**
```
1. Read error message carefully
2. Fix the issue
3. Re-run tests
4. Only commit when ALL pass
```

**If build fails:**
```
1. flutter clean && flutter pub get
2. dart run build_runner build --delete-conflicting-outputs
3. If still fails → check error, fix imports/syntax
```

**If PR rejected:**
```
1. Read reviewer feedback
2. Make changes on same branch
3. git add . && git commit --amend
4. git push origin HEAD --force
```

---

## 📦 DATABASE MIGRATIONS

**Location:** `src/main/resources/db/migration/`

**Naming:** `V{number}__{description}.sql`

**Rules:**
- NEVER modify applied migrations
- Always create new versioned file
- Use soft delete (`deleted_at`)

---

## 🛠️ COMMANDS

```bash
# Frontend
flutter pub get
flutter analyze
flutter test --coverage
flutter run -d android
dart run build_runner build --delete-conflicting-outputs

# Backend
docker-compose up -d
./gradlew bootRun
./gradlew test jacocoTestReport

# Emulator
emulator -avd $(emulator -list-avds | head -1) &
adb logcat *:E
```

---

## 📐 ARCHITECTURE

```
lib/
├── core/
│   ├── network/dio_client.dart
│   ├── database/isar_service.dart
│   └── router/app_router.dart
├── data/
│   ├── datasources/remote/
│   ├── datasources/local/
│   ├── models/                      # DTOs (@JsonSerializable)
│   └── repositories/
├── domain/
│   ├── entities/                    # Pure Dart only
│   └── repositories/
└── features/<feature>/
    ├── screens/
    ├── widgets/
    └── providers/
```

---

## 🔑 KEY PATTERNS

### Either for Error Handling
```dart
Future<Either<Failure, Recipe>> getRecipe(String id) async {
  try {
    final response = await api.get('/recipes/$id');
    return Right(RecipeDto.fromJson(response.data).toEntity());
  } on DioException catch (e) {
    return Left(ServerFailure(e.message));
  }
}
```

### Provider Usage
```dart
// In build() - reactive
final recipes = ref.watch(recipesProvider);

// In callbacks - one-time read
onTap: () => ref.read(recipesProvider.notifier).refresh();
```

### Context Check After Await
```dart
await someAsyncOperation();
if (!context.mounted) return;
Navigator.pop(context);
```

---

## 🌐 API

**Base URL:** `http://localhost:4001/api/v1`
**Auth:** `Authorization: Bearer $accessToken`
**Pagination:** `{ "content": [...], "last": false, "number": 0, "size": 20 }`

---

## ✅ WORKFLOW SUMMARY

```
SESSION START:
1. git branch --show-current
2. git status
3. Read FEATURES.md → Find 🟡 task

NEW FEATURE (with ultrathink + research):
4. UNDERSTAND: What, why, scope?
5. RESEARCH: How do Instagram/Twitter/etc do this?
6. PLAN: Models, APIs, UI, edge cases
7. DOCUMENT: Write spec with research findings
8. GET APPROVAL: "Here's the spec. Approve?"

IMPLEMENTATION:
9. Create branch from dev
10. Backend first, frontend second
11. Code → Test → Fix → Repeat

PRE-COMMIT:
12. flutter analyze (no errors)
13. flutter test (all pass)
14. Update FEATURES.md → ✅ Done

COMMIT & PUSH:
15. git add . && git commit
16. git push origin HEAD
17. gh pr create --base dev
```

---

## 🐛 BUG TRACKING

```bash
gh issue create --title "Bug: description" --label "bug"
gh issue list --label "bug"
gh issue close <number>
```

---

## 📁 DOCUMENTATION

| File | When to Update |
|------|----------------|
| **CLAUDE.md** | Human only |
| **FEATURES.md** | Before every commit |
| **TECHSPEC.md** | When adding entities/endpoints |
| **CHANGELOG.md** | On release |

---

## 💡 PROMPTS

```
Implement [FEAT-XXX] from FEATURES.md.
Fix: [description]. Create GitHub issue if significant.
Debug [issue]. Check logs, find root cause before fixing.
Continue from last session. Check git status first.

Plan [feature]. Research best practices, then write spec.
Research how [Instagram/Twitter/etc] implements [feature].
```

---

## 🛑 STOP AND CHECK

**Before planning, verify:**
- [ ] Do I understand the feature fully?
- [ ] Have I researched how other apps do this?
- [ ] Have I identified edge cases?

**Before coding, verify:**
- [ ] Is the spec approved?
- [ ] Am I on the correct branch?
- [ ] Do I understand acceptance criteria?

**Before committing, verify:**
- [ ] All tests pass?
- [ ] FEATURES.md updated?
- [ ] Commit message follows convention?
