# CLAUDE.md — Pairing Planet

> Flutter + Spring Boot recipe sharing app. Offline-first architecture.
> **This file is auto-read by Claude Code from project root.**

---

## 📂 FILE LOCATIONS

```
project-root/
├── CLAUDE.md                    ← THIS FILE (auto-read by Claude Code)
├── docs/ai/
│   ├── FEATURES.md              ← Features, tasks, locks
│   ├── TECHSPEC.md              ← Technical specification
│   └── CHANGELOG.md             ← Version history
├── frontend_mobile/
└── backend/
```

---

## 🚀 SESSION START

```
1. Claude Code auto-reads this file (CLAUDE.md)
2. Check: pwd → Which instance am I?
3. Check: git branch --show-current
4. Check: git status
5. Read docs/ai/FEATURES.md → Check for my existing 🟡 lock
6. If I have a lock → Resume that work
7. If no lock → Wait for user to request a feature
```

---

## ⚙️ SETUP

```bash
claude --dangerously-skip-permissions --model opus
```

---

## 👥 MULTI-INSTANCE SETUP (Git Worktree)

### Human Creates Worktrees (One-Time Setup)
```bash
# Human runs this ONCE to create 4 workspaces
cd ~/projects/pairing-planet
git worktree add ../pairing-planet-2 dev
git worktree add ../pairing-planet-3 dev
git worktree add ../pairing-planet-4 dev
```

### Human Launches Claude Code Instances
```bash
# Human opens 4 terminals and runs:
cd ~/projects/pairing-planet && claude      # Instance 1
cd ~/projects/pairing-planet-2 && claude    # Instance 2
cd ~/projects/pairing-planet-3 && claude    # Instance 3
cd ~/projects/pairing-planet-4 && claude    # Instance 4
```

### Claude Code Identifies Itself
```bash
pwd
# ~/projects/pairing-planet   → I am Claude-1, port 4001
# ~/projects/pairing-planet-2 → I am Claude-2, port 4002
# ~/projects/pairing-planet-3 → I am Claude-3, port 4003
# ~/projects/pairing-planet-4 → I am Claude-4, port 4004
```

### Instance Assignment
| Instance | Directory | Backend Port |
|----------|-----------|--------------|
| Claude-1 | `pairing-planet/` | 4001 |
| Claude-2 | `pairing-planet-2/` | 4002 |
| Claude-3 | `pairing-planet-3/` | 4003 |
| Claude-4 | `pairing-planet-4/` | 4004 |

---

## 🔒 FEATURE LOCK

**When user says "implement/work on [feature]":**

### Step 1: Check locks (in main worktree)
```bash
cd ~/projects/pairing-planet
git pull origin dev
grep "Locked by" docs/ai/FEATURES.md
```

### Step 2: If free, lock it
Update `docs/ai/FEATURES.md`:
```markdown
**Status:** 🟡 In Progress
**Locked by:** Claude-2 (pairing-planet-2)
**Lock time:** 2025-01-08 14:30 UTC
**Server port:** 4002
```

### Step 3: Push lock immediately
```bash
cd ~/projects/pairing-planet
git add docs/ai/FEATURES.md
git commit -m "docs: lock FEAT-XXX (Claude-2)"
git push origin dev
```

### Step 4: Work in YOUR worktree
```bash
cd ~/projects/pairing-planet-2
git fetch origin
git checkout -b feature/xxx origin/dev
./gradlew bootRun --args='--server.port=4002'
# Start coding...
```

### Step 5: When done, unlock (in main worktree)
```bash
cd ~/projects/pairing-planet
git pull origin dev
# Update FEATURES.md: Status → ✅, remove lock lines
git commit -m "docs: unlock FEAT-XXX (done)"
git push origin dev
```

---

## 🔴 CRITICAL RULES

0. **Model** → Use opus with extended thinking
1. **Before coding** → Create branch from dev in YOUR worktree
2. **When user says "implement [feature]"** → Lock first, push, THEN code
3. **Plan with ultrathink** → Research best practices before implementing
4. **After plan mode** → Check docs/ai/FEATURES.md: if feature exists, ask user "Should I update FEATURES.md with the planned changes?" If not there, ask "Should I document this new feature to FEATURES.md?"
5. **After feature/bugfix** → ALWAYS write tests, then run all tests (must pass)
6. **Before commit** → Run pre-commit checklist
7. **Push & PR** → `git push origin HEAD` then `gh pr create --base dev`
8. **Run app** → Android: `--flavor dev -t lib/main_dev.dart` | iOS: `-t lib/main_dev.dart` (no --flavor, Flutter bug)
9. **UI strings** → Use `.tr`, add to BOTH en.json AND ko.json
10. **UI sizes** → Use `.w`, `.h`, `.sp`, `.r` (NEVER hardcode pixels)
11. **Buttons** → Debounce 300ms, check state before API call
12. **After DTOs/Isar** → Run build_runner
13. **After await** → Check `if (!context.mounted) return;`
14. **API IDs** → Use `publicId` (UUID), never internal `id`
15. **Providers in callbacks** → `ref.read()`, not `ref.watch()`
16. **Entities** → Never import `json_annotation` or `isar`
17. **Backend Slice** → Field is `content`, not `items`
18. **Error handling** → Return `Either<Failure, T>`, never throw
19. **Commits** → `feat|fix|docs|chore(scope): description`
20. **When done** → Remove lock, mark ✅ Done
21. **Backend port** → Use YOUR assigned port (4001-4004)

---

## 🧠 PLANNING WITH ULTRATHINK

**Before implementing ANY feature:**

```
1. UNDERSTAND: What, why, edge cases?
2. RESEARCH: How do Instagram/Twitter/etc do this?
3. DESIGN: Models, APIs, UI flow
4. PLAN: Implementation steps, tests
```

---

## 🔍 BEST PRACTICES RESEARCH

| Feature Type | Research These Apps |
|--------------|---------------------|
| Follow system | Instagram, Twitter, TikTok |
| Notifications | Slack, Discord, WhatsApp |
| Search | Pinterest, Spotify, YouTube |
| Feed/List | Instagram, Reddit, TikTok |
| Profile | Instagram, LinkedIn |
| Image upload | Instagram, WhatsApp |

---

## ✅ PRE-COMMIT CHECKLIST

```
□ flutter analyze                    → No errors
□ flutter test                       → All pass
□ ./gradlew test (if backend)        → All pass
□ No print() or console.log
□ No hardcoded UI strings (use .tr)
□ No hardcoded pixels (use .w .h .sp .r)
□ New text in BOTH en.json AND ko.json
□ Buttons debounced
□ docs/ai/FEATURES.md updated (in main worktree):
  - Status → ✅ Done
  - Remove lock lines
```

---

## 🔀 GIT

**Branch strategy:**
```
main ← staging ← dev ← feature/*
                     ← bugfix/*
```

**PR targets:**
| From | To |
|------|----|
| feature/* | dev |
| bugfix/* | dev |
| dev | staging |
| staging | main |

**Commands (in your worktree):**
```bash
git fetch origin
git checkout -b feature/xxx origin/dev
git push origin HEAD
gh pr create --base dev
```

---

## 🔥 FIREBASE ENVIRONMENTS

| Env | Project | Flavor |
|-----|---------|--------|
| Dev | pairing-planet-dev | dev |
| Staging | pairing-planet-stg | staging |
| Prod | pairing-planet-prod | prod |

**❌ NEVER create main.dart** - Use flavored entry points only.

---

## 🛠️ COMMANDS

```bash
# Identify yourself
pwd

# Run backend on YOUR port
./gradlew bootRun --args='--server.port=4001'  # Claude-1
./gradlew bootRun --args='--server.port=4002'  # Claude-2
./gradlew bootRun --args='--server.port=4003'  # Claude-3
./gradlew bootRun --args='--server.port=4004'  # Claude-4

# Run frontend
# Android:
flutter run --flavor dev -t lib/main_dev.dart
# iOS (no --flavor due to Flutter 3.38.5 native_assets bug):
flutter run -t lib/main_dev.dart

# Testing
flutter analyze
flutter test --coverage
./gradlew test

# Build runner
dart run build_runner build --delete-conflicting-outputs

# Docker (shared)
docker-compose up -d
```

---

## 📐 ARCHITECTURE

```
frontend_mobile/
├── assets/translations/
│   ├── en.json
│   └── ko.json
├── lib/
│   ├── main_dev.dart         # USE THIS
│   ├── main_staging.dart
│   ├── main_prod.dart
│   ├── core/
│   ├── data/
│   ├── domain/
│   └── features/
```

---

## 🌍 TRANSLATIONS

```dart
Text('home.title'.tr)
Text('recipe.by'.tr(args: [name]))
```

- NEVER hardcode strings
- Add to BOTH en.json AND ko.json

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

// In callbacks - one-time
onTap: () => ref.read(recipesProvider.notifier).refresh();
```

### Context Check After Await
```dart
await someAsyncOperation();
if (!context.mounted) return;
Navigator.pop(context);
```

---

## 📏 RESPONSIVE UI

```dart
Container(width: 16.w, height: 200.h)
Text('Hi', style: TextStyle(fontSize: 14.sp))
BorderRadius.circular(8.r)
```

---

## 💾 CACHING

- TTL: 24 hours
- Pull-to-refresh: Bypass cache
- Image cache: 30 days

---

## ⚡ IDEMPOTENCY

```dart
Timer? _debounce;
void onTap() {
  _debounce?.cancel();
  _debounce = Timer(Duration(milliseconds: 300), () {
    if (!state.isFollowing) follow(userId);
  });
}
```

---

## 🌐 API

**Base URL:** `http://localhost:400X/api/v1` (X = your instance)
**Auth:** `Authorization: Bearer $accessToken`
**Pagination:** `{ "content": [...], "last": false }`

---

## ✅ WORKFLOW SUMMARY

```
HUMAN: Creates worktrees, launches Claude in each directory

CLAUDE CODE:
1. pwd → Which instance am I? (pairing-planet-X = Claude-X)
2. My port is 400X

LOCK (in main worktree ~/projects/pairing-planet):
3. git pull origin dev
4. Check/add lock in docs/ai/FEATURES.md
5. git commit && git push origin dev

IMPLEMENT (in your worktree):
6. cd ~/projects/pairing-planet-X
7. git checkout -b feature/xxx origin/dev
8. ./gradlew bootRun --args='--server.port=400X'
9. Android: flutter run --flavor dev -t lib/main_dev.dart
   iOS: flutter run -t lib/main_dev.dart (no --flavor, Flutter bug)
10. Code → Test → Fix

PR:
11. git push origin HEAD
12. gh pr create --base dev

UNLOCK (in main worktree):
13. cd ~/projects/pairing-planet
14. Update docs/ai/FEATURES.md → ✅ Done, remove lock
15. git commit && git push origin dev
```

---

## 🛑 STOP AND CHECK

**Before starting feature:**
- [ ] Which instance am I? (`pwd`)
- [ ] What's my port? (400X)
- [ ] Is feature locked? (check docs/ai/FEATURES.md)
- [ ] Did I lock and push?

**Before committing:**
- [ ] Tests pass?
- [ ] No hardcoded strings/pixels?
- [ ] docs/ai/FEATURES.md updated?
