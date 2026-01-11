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
4. **Feature = Code + Tests** → A feature is NOT complete until unit tests and integration tests are written and passing. No PR without tests.
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
19. **DRY** → Code used 2+ times? Extract to shared location. No copy-paste.
20. **File size** → Max 300 lines per file. Split by responsibility if exceeded.
21. **Function size** → Max 50 lines per function. Extract helpers if exceeded.

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

## 🧹 CODE QUALITY RULES

### DRY: Don't Repeat Yourself
**If code appears 2+ times → Extract to shared function/widget**

```dart
// ❌ BAD: Same padding used in 3 places
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h))
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h))
Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h))

// ✅ GOOD: Extract to constant or widget
// In lib/core/constants/app_spacing.dart
class AppSpacing {
  static EdgeInsets get cardPadding => EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h);
}

// Usage
Padding(padding: AppSpacing.cardPadding)
```

### Where to Put Shared Code
| Type | Location | Example |
|------|----------|---------|
| Constants | `lib/core/constants/` | `app_colors.dart`, `app_spacing.dart` |
| Shared widgets | `lib/core/widgets/` | `app_button.dart`, `app_card.dart` |
| Utilities | `lib/core/utils/` | `date_utils.dart`, `string_utils.dart` |
| Extensions | `lib/core/extensions/` | `string_extensions.dart` |
| Shared services | `lib/core/services/` | `storage_service.dart` |
| Feature-specific shared | `lib/features/[feature]/widgets/` | Reused within feature only |

### File Size Limits
| Metric | Limit | Action When Exceeded |
|--------|-------|----------------------|
| Lines per file | **300 max** | Split by responsibility |
| Lines per function/method | **50 max** | Extract helper methods |
| Lines per widget build() | **100 max** | Extract sub-widgets |
| Parameters per function | **5 max** | Use object/class |

### When to Split Files
```
// File too long? Ask:
1. Does this file have multiple responsibilities? → Split by responsibility
2. Is one class doing too much? → Extract classes
3. Are there reusable widgets? → Move to widgets/ folder
4. Are there utility functions? → Move to utils/

// Example split:
// BEFORE: recipe_screen.dart (500 lines)
// AFTER:
//   recipe_screen.dart (150 lines) - main screen
//   widgets/recipe_header.dart (80 lines)
//   widgets/recipe_ingredients.dart (100 lines)
//   widgets/recipe_steps.dart (120 lines)
```

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `recipe_card.dart` |
| Classes | PascalCase | `RecipeCard` |
| Functions/methods | camelCase | `getRecipeById()` |
| Constants | camelCase or SCREAMING_SNAKE | `defaultPadding`, `MAX_RETRY` |
| Private | prefix with _ | `_buildHeader()` |
| Boolean | prefix with is/has/can/should | `isLoading`, `hasError` |

### Function Rules
```dart
// ❌ BAD: Function does too much
Future<void> loadAndDisplayAndCacheRecipes() async { ... }

// ✅ GOOD: Single responsibility
Future<List<Recipe>> loadRecipes() async { ... }
void displayRecipes(List<Recipe> recipes) { ... }
Future<void> cacheRecipes(List<Recipe> recipes) async { ... }
```

### Widget Extraction Rules
```dart
// ❌ BAD: Giant build method
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // 50 lines of header code
      // 50 lines of body code  
      // 50 lines of footer code
    ],
  );
}

// ✅ GOOD: Extracted widgets
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      _buildBody(),
      _buildFooter(),
    ],
  );
}

// Or even better - separate widget files if reusable
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      RecipeHeader(recipe: recipe),
      RecipeBody(recipe: recipe),
      RecipeFooter(recipe: recipe),
    ],
  );
}
```

### Avoid Deep Nesting (Max 3 levels)
```dart
// ❌ BAD: Deep nesting
if (user != null) {
  if (user.isActive) {
    if (user.hasPermission) {
      if (recipe != null) {
        // do something
      }
    }
  }
}

// ✅ GOOD: Early returns
if (user == null) return;
if (!user.isActive) return;
if (!user.hasPermission) return;
if (recipe == null) return;
// do something
```

### No Magic Numbers/Strings
```dart
// ❌ BAD
await Future.delayed(Duration(milliseconds: 300));
if (retryCount > 3) { ... }
padding: EdgeInsets.all(16.r)  // What is 16?

// ✅ GOOD
// In constants file
class AppConstants {
  static const debounceMs = 300;
  static const maxRetries = 3;
}

class AppSpacing {
  static double get medium => 16.r;
}

// Usage
await Future.delayed(Duration(milliseconds: AppConstants.debounceMs));
if (retryCount > AppConstants.maxRetries) { ... }
padding: EdgeInsets.all(AppSpacing.medium)
```

### Const Everything Possible
```dart
// ❌ BAD
Container(
  child: Text('Hello'),
)

// ✅ GOOD
const SizedBox(height: 8)  // Use const for stateless widgets
const Text('Hello')
const Icon(Icons.star)
```

---

## 🧪 TESTING (REQUIRED)

**A feature without unit tests and integration tests is not a feature. It's a liability.**

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
□ Code quality checks:
  - No code repeated 2+ times (extract if found)
  - No file > 300 lines (split if found)
  - No function > 50 lines (extract helpers)
  - No nesting > 3 levels (use early returns)
  - No magic numbers (use constants)
  - Added const where possible
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

# Check file sizes (should be < 300 lines)
find lib -name "*.dart" -exec wc -l {} + | sort -n | tail -20
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
│   │   ├── constants/        # App-wide constants
│   │   ├── extensions/       # Dart extensions
│   │   ├── utils/            # Utility functions
│   │   ├── widgets/          # Shared widgets
│   │   └── services/         # Shared services
│   ├── data/
│   ├── domain/
│   └── features/
│       └── [feature]/
│           ├── screens/
│           ├── widgets/      # Feature-specific widgets
│           ├── providers/
│           └── models/
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

**Base URL:** `http://localhost:4001/api/v1`
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
5. Refactor:
   a. Any code repeated 2+ times? → Extract
   b. Any file > 300 lines? → Split
   c. Any function > 50 lines? → Extract helpers
6. Run pre-commit checklist
7. git push origin HEAD
8. gh pr create --base dev
9. Update docs/ai/FEATURES.md if needed
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
- [ ] No repeated code? (extract if 2+ times)
- [ ] No large files? (split if > 300 lines)
- [ ] No large functions? (extract if > 50 lines)
- [ ] FEATURES.md updated if needed?
