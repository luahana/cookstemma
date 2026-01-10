# CLAUDE.md — Pairing Planet

> Flutter + Spring Boot recipe sharing app. Offline-first architecture.
> **This file is auto-read by Claude Code from project root.**

---

## 📂 FILE LOCATIONS

```
project-root/
├── CLAUDE.md                    ← THIS FILE (auto-read by Claude Code)
├── docs/ai/
│   ├── FEATURES.md              ← Features, tasks, status
│   ├── TECHSPEC.md              ← Technical specification
│   └── CHANGELOG.md             ← Version history
├── frontend_mobile/
└── backend/
```

---

## 🚀 SESSION START

```
1. Claude Code auto-reads this file (CLAUDE.md)
2. Check: git branch --show-current
3. Check: git status
4. Read docs/ai/FEATURES.md → See current tasks
5. Wait for user to request a feature or ask what to work on
```

---

## ⚙️ SETUP

```bash
claude --dangerously-skip-permissions --model opus
```

---

## 🔴 CRITICAL RULES

0. **Model** → Use opus with extended thinking
1. **Before coding** → Create branch from dev
2. **Plan with ultrathink** → Research best practices before implementing
3. **After plan mode** → Check docs/ai/FEATURES.md: if feature exists, ask user "Should I update FEATURES.md with the planned changes?" If not there, ask "Should I document this new feature to FEATURES.md?"
4. **Feature = Code + unit tests and integration tests** → A feature is NOT complete until tests are written and passing. No PR without tests.
5. **Before commit** → Run pre-commit checklist
6. **Push & PR** → `git push origin HEAD` then `gh pr create --base dev`
7. **Run app** → Android: `--flavor dev -t lib/main_dev.dart` | iOS: `-t lib/main_dev.dart` (no --flavor, Flutter bug)
8. **UI strings** → Use `.tr`, add to BOTH en.json AND ko.json
9. **UI sizes** → **EVERY numeric value** for width, height, padding, margin, fontSize, radius MUST use `.w`, `.h`, `.sp`, `.r`. Zero exceptions. Check with grep before commit.
10. **Buttons** → Debounce 300ms, check state before API call
11. **After DTOs/Isar** → Run build_runner
12. **After await** → Check `if (!context.mounted) return;`
13. **API IDs** → Use `publicId` (UUID), never internal `id`
14. **Providers in callbacks** → `ref.read()`, not `ref.watch()`
15. **Entities** → Never import `json_annotation` or `isar`
16. **Backend Slice** → Field is `content`, not `items`
17. **Error handling** → Return `Either<Failure, T>`, never throw
18. **Commits** → `feat|fix|docs|chore(scope): description`

---

## 🧠 PLANNING WITH ULTRATHINK

**Before implementing ANY feature:**

```
1. UNDERSTAND: What, why, edge cases?
2. RESEARCH: How do Instagram/Twitter/etc do this?
3. DESIGN: Models, APIs, UI flow
4. PLAN: Implementation steps
5. TEST PLAN: What tests will prove this works?
   - List test cases for happy path
   - List test cases for error cases
   - List edge cases to cover
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

## 🧪 TESTING (REQUIRED)

**A feature without unit tests and integration test is not a feature. It's a liability.**

### What Needs Tests
| Change Type | Required Tests |
|-------------|----------------|
| New API endpoint | Unit test for controller + service |
| New repository method | Unit test with mock |
| New UI widget | Widget test |
| Business logic | Unit test |
| Bug fix | Regression test (proves bug is fixed) |

### Test File Naming
```
lib/features/recipe/recipe_service.dart
→ test/features/recipe/recipe_service_test.dart

lib/features/recipe/widgets/recipe_card.dart
→ test/features/recipe/widgets/recipe_card_test.dart
```

### Minimum Coverage
- New code must have tests
- Don't merge if tests fail
- Run `flutter test --coverage` to check

### Test Structure
```dart
void main() {
  group('RecipeService', () {
    late RecipeService service;
    late MockRecipeRepository mockRepository;

    setUp(() {
      mockRepository = MockRecipeRepository();
      service = RecipeService(mockRepository);
    });

    test('getRecipe returns recipe when found', () async {
      // Arrange
      when(mockRepository.getById(any)).thenAnswer((_) async => Right(testRecipe));
      
      // Act
      final result = await service.getRecipe('123');
      
      // Assert
      expect(result.isRight(), true);
    });

    test('getRecipe returns failure when not found', () async {
      // Arrange
      when(mockRepository.getById(any)).thenAnswer((_) async => Left(NotFoundFailure()));
      
      // Act
      final result = await service.getRecipe('invalid');
      
      // Assert
      expect(result.isLeft(), true);
    });
  });
}
```

---

## 📏 RESPONSIVE UI (REQUIRED)

**⚠️ NEVER hardcode pixel values. ALWAYS use ScreenUtil extensions.**

| Extension | Use For | Example |
|-----------|---------|---------|
| `.w` | Width, horizontal padding/margin | `width: 16.w`, `EdgeInsets.symmetric(horizontal: 20.w)` |
| `.h` | Height, vertical padding/margin | `height: 200.h`, `EdgeInsets.only(top: 10.h)` |
| `.sp` | Font sizes | `fontSize: 14.sp` |
| `.r` | Border radius, equal padding | `BorderRadius.circular(8.r)`, `EdgeInsets.all(8.r)` |

### ❌ BAD (will be rejected)
```dart
Container(width: 16, height: 200)
Padding(padding: EdgeInsets.all(8))
Text('Hi', style: TextStyle(fontSize: 14))
BorderRadius.circular(8)
SizedBox(width: 10, height: 20)
Icon(Icons.star, size: 24)
```

### ✅ GOOD
```dart
Container(width: 16.w, height: 200.h)
Padding(padding: EdgeInsets.all(8.r))
Text('Hi', style: TextStyle(fontSize: 14.sp))
BorderRadius.circular(8.r)
SizedBox(width: 10.w, height: 20.h)
Icon(Icons.star, size: 24.sp)
```

### Edge Cases
```dart
// Aspect ratios - use .w for both to maintain ratio
Container(width: 100.w, height: 100.w)  // Square

// EdgeInsets
EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h)
EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h)

// Icon sizes
Icon(Icons.star, size: 24.sp)

// Divider/line thickness
Divider(thickness: 1.h)
Container(height: 1.h)  // Horizontal line
```

---

## ✅ PRE-COMMIT CHECKLIST

```
□ flutter analyze                    → No errors
□ flutter test                       → All pass
□ ./gradlew test (if backend)        → All pass
□ No print() or console.log
□ No hardcoded UI strings (use .tr)
□ No hardcoded pixels (run these checks):
  grep -rn "width: [0-9]" --include="*.dart" lib/ | grep -v "\\.w" | grep -v "\\.r"
  grep -rn "height: [0-9]" --include="*.dart" lib/ | grep -v "\\.h" | grep -v "\\.r"
  grep -rn "fontSize: [0-9]" --include="*.dart" lib/ | grep -v "\\.sp"
  grep -rn "circular([0-9]" --include="*.dart" lib/ | grep -v "\\.r"
  grep -rn "size: [0-9]" --include="*.dart" lib/ | grep -v "\\.sp" | grep -v "\\.w" | grep -v "\\.h"
  → ALL should return empty (no matches)
□ New text in BOTH en.json AND ko.json
□ Buttons debounced
□ docs/ai/FEATURES.md updated if needed
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

**Commands:**
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
# Run backend
./gradlew bootRun

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

# Docker
docker-compose up -d

# Check for hardcoded pixels (run before commit)
grep -rn "width: [0-9]" --include="*.dart" lib/ | grep -v "\\.w" | grep -v "\\.r"
grep -rn "height: [0-9]" --include="*.dart" lib/ | grep -v "\\.h" | grep -v "\\.r"
grep -rn "fontSize: [0-9]" --include="*.dart" lib/ | grep -v "\\.sp"
grep -rn "circular([0-9]" --include="*.dart" lib/ | grep -v "\\.r"
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

**Base URL:** `http://localhost:8080/api/v1`
**Auth:** `Authorization: Bearer $accessToken`
**Pagination:** `{ "content": [...], "last": false }`

---

## ✅ WORKFLOW SUMMARY

```
1. git fetch origin
2. git checkout -b feature/xxx origin/dev
3. Plan with ultrathink (include test cases in plan)
4. Implement:
   a. Write feature code
   b. Write tests (unit + widget/integration as needed)
   c. Run tests → Must pass
   d. Fix until green
5. Run pre-commit checklist
6. git push origin HEAD
7. gh pr create --base dev
8. Update docs/ai/FEATURES.md if needed
```

---

## 🛑 STOP AND CHECK

**Before starting feature:**
- [ ] On correct branch?
- [ ] Branch created from latest dev?
- [ ] Test cases planned?

**Before committing:**
- [ ] Tests written?
- [ ] Tests pass? (`flutter test`, `./gradlew test`)
- [ ] No hardcoded strings?
- [ ] No hardcoded pixels? (run grep commands)
- [ ] FEATURES.md updated if needed?
