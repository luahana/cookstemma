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
2. **Before ANY feature** → Document in FEATURES.md first:
   - If feature exists → Update status to 🟡 In Progress
   - If feature is NEW → Write full spec, get approval, THEN implement
3. **After feature** → Write and run tests (must pass)
4. **Before commit** → Run pre-commit checklist (see below)
5. **Push & PR** → `git push origin HEAD` then `gh pr create --base dev`
6. **After DTOs/Isar** → Run `dart run build_runner build --delete-conflicting-outputs`
7. **After `await`** → Check `if (!context.mounted) return;`
8. **API IDs** → Use `publicId` (UUID), never internal `id`
9. **Providers in callbacks** → `ref.read()`, not `ref.watch()`
10. **Entities** → Never import `json_annotation` or `isar`
11. **Backend Slice** → Field is `content`, not `items`
12. **Recipe variants** → Include `parentPublicId` + `rootPublicId`
13. **Error handling** → Return `Either<Failure, T>`, never throw
14. **Commits** → `feat|fix|docs|chore(scope): description`

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

**If any fail → Fix before committing**

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

**Why backend first?** API contract must be stable before frontend consumes it.

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

**If import error → Wrong layer direction**

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

**If branch out of date:**
```
1. git fetch origin dev
2. git rebase origin/dev
3. Resolve conflicts if any
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

# Debug
flutter logs                         # Frontend logs
./gradlew bootRun 2>&1 | tee log.txt # Backend logs
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
if (!context.mounted) return;  // ALWAYS CHECK
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

IMPLEMENTATION:
4. If no branch → git checkout -b feature/xxx
5. If full-stack → Backend first, frontend second
6. Code → Test → Fix → Repeat

PRE-COMMIT:
7. flutter analyze (no errors)
8. flutter test (all pass)
9. ./gradlew test (if backend)
10. Update FEATURES.md → ✅ Done

COMMIT & PUSH:
11. git add . && git commit -m "feat(scope): description"
12. git push origin HEAD
13. gh pr create --base dev
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

## 🆕 NEW FEATURES

**If user requests a feature NOT in FEATURES.md:**
```
1. STOP - Don't code yet
2. Write spec: ID, description, acceptance criteria
3. Ask: "Here's the spec. Approve?"
4. Wait for approval
5. Add to FEATURES.md
6. THEN implement
```

---

## 💡 PROMPTS

```
Implement [FEAT-XXX] from FEATURES.md.
Fix: [description]. Create GitHub issue if significant.
Debug [issue]. Check logs, find root cause before fixing.
Review [file] for: error handling, null safety, context.mounted.
Continue from last session. Check git status first.
```

---

## 🛑 STOP AND CHECK

**Before writing code, verify:**
- [ ] Am I on the correct branch?
- [ ] Is the feature documented in FEATURES.md?
- [ ] Do I understand the acceptance criteria?

**Before committing, verify:**
- [ ] All tests pass?
- [ ] No print/console.log left?
- [ ] FEATURES.md updated?
- [ ] Commit message follows convention?
