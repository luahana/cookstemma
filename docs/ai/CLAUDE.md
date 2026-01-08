# CLAUDE.md — Pairing Planet

> Flutter + Spring Boot recipe sharing app with offline-first architecture.

---

## ⚙️ MODEL CONFIGURATION

**Always use these settings in Claude Code:**

```yaml
model: opus                         # Always use best/opus model
thinking: extended                  # ALWAYS use extended thinking
permissions: skip                   # Skip permission prompts (dangerously)
```

**Model preference order:** `opus` > `sonnet` > `haiku`

**Claude Code CLI command:**
```bash
claude --dangerously-skip-permissions --model opus
```

**Project config file (`.claude/settings.json` in project root):**
```json
{
  "model": {
    "default": "opus",
    "preferBest": true
  },
  "thinking": {
    "enabled": true,
    "default": "extended"
  },
  "permissions": {
    "dangerouslySkipPermissions": true
  }
}
```
See `.claude/settings.json` for full configuration.

**Thinking levels by task:**

| Task Type | Thinking Level | How to Invoke |
|-----------|----------------|---------------|
| Simple fixes, typos | Standard | (default) |
| New features, bug fixes | Extended | `think hard about...` |
| Architecture, multi-file refactor | Maximum | `ultrathink` or `think deeply step by step` |
| Database schema, API design | Maximum | `ultrathink` |
| Complex debugging | Maximum | `think very carefully...` |

**Always use extended/maximum thinking for:**
- Any task from ROADMAP.md
- Creating new files
- Modifying more than 2 files
- Database migrations
- API endpoint changes
- State management logic
- Error handling implementation

**Claude Code startup command:**
```bash
# Full command with all flags
claude --dangerously-skip-permissions --model opus

# Or set alias in ~/.bashrc or ~/.zshrc
alias claude-dev="claude --dangerously-skip-permissions --model opus"
```

---

## 🔴 CRITICAL RULES

**MUST follow these on every task:**

0. **Model & Permissions** → Always use opus model with extended thinking and `--dangerously-skip-permissions` enabled.
1. **Before changing code** → Create branch from dev
2. **Before implementing feature** → Document in FEATURES.md (ASK)
3. **After implementing** → Write tests, document in TESTS.md (ASK)
4. **Before committing** → Verify docs are aligned (ASK for each):
   ```
   □ FEATURES.md — Status updated?
   □ TESTS.md — Test cases added?
   □ DECISIONS.md — Decisions documented?
   □ GLOSSARY.md — New terms added?
   □ ROADMAP.md — Task marked [x]? (auto)
   ```
5. **After modifying DTOs/Isar classes** → Run `dart run build_runner build --delete-conflicting-outputs`
6. **After `await`** → Check `if (!context.mounted) return;`
7. **API IDs** → Use `publicId` (UUID), never internal `id`
8. **Providers in callbacks** → Use `ref.read()`, not `ref.watch()`
9. **Entities** → Never import `json_annotation` or `isar`
10. **Backend Slice** → Field is `content`, not `items`
11. **Recipe variants** → Include `parentPublicId` + `rootPublicId`
12. **Error handling** → Return `Either<Failure, T>`, never throw
13. **Commits** → Conventional format: `feat|fix|docs|chore(scope): description`

---

## 📝 DOCUMENTATION RULES (ASK BEFORE UPDATING)

| File | When | Ask |
|------|------|-----|
| **FEATURES.md** | Before implementing | "Add to FEATURES.md?" |
| **TESTS.md** | After writing tests | "Document in TESTS.md?" |
| **BUGS.md** | When finding bugs | "Add to BUGS.md or quick fix?" |
| **DECISIONS.md** | Technical decisions | "Document in DECISIONS.md?" |
| **GLOSSARY.md** | New terms | "Add to GLOSSARY.md?" |
| **PROMPTS.md** | Effective prompts | "Save to PROMPTS.md?" |

**Auto-update (no asking):** ROADMAP.md, TECHSPEC.md, CHANGELOG.md

---

## 🤖 CLAUDE CODE INSTRUCTIONS

### Before Starting Any Task

**Enable extended thinking first:**
```
I'll use extended thinking for this task to ensure thorough analysis.
```

```bash
# 1. Check current branch
git branch --show-current

# 2. If on dev/staging/main, check ROADMAP.md for next task
cat ROADMAP.md | head -50  # View CURRENT SPRINT

# 3. Pick first uncompleted [ ] task from CURRENT SPRINT

# 4. Create feature/bugfix branch (Rule #1)
git checkout dev && git pull origin dev
git checkout -b feature/<task-name>

# 5. Document the feature in FEATURES.md BEFORE coding (Rule #2)
#    - Add feature entry with ID, description, acceptance criteria, test cases
#    - See FEATURES.md for template

# 6. If task has implementation spec in ROADMAP.md, read it

# 7. If task needs architecture context, read relevant TECHSPEC.md section

# 8. NOW start coding
```

### Documenting Features (Rule #2)

**Before writing any code for a new feature, add to FEATURES.md:**

```markdown
### [FEAT-XXX]: Feature Name

**Status:** 🟡 In Progress

**Branch:** `feature/feature-name`

**Description:**
What this feature does.

**User Story:**
As a [user], I want to [action], so that [benefit].

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

**Test Cases:**
- [ ] Test case 1
- [ ] Test case 2
- [ ] Test case 3
```

**Why document first?**
1. Forces you to think through the feature before coding
2. Acceptance criteria become your checklist
3. Test cases can be written from this spec
4. Future reference for all project features

### Writing Tests (Rule #3)

**After implementing a feature, write tests in this order:**

```
1. Unit Tests (test/unit/)
   └── Test repository methods, providers, services
   
2. Widget Tests (test/widget/)
   └── Test UI components, screens
   
3. Integration Tests (integration_test/)
   └── Test complete user flows on emulator
```

**Test file naming:**
```
Feature: Recipe Detail
├── test/unit/repositories/recipe_repository_test.dart
├── test/widget/screens/recipe_detail_screen_test.dart
└── integration_test/recipe_detail_test.dart
```

**Minimum test coverage per feature:**

| Feature Type | Required Tests |
|--------------|----------------|
| Repository method | Unit test for success + failure cases |
| Provider | Unit test for state changes |
| Screen with form | Widget test for validation |
| User flow | Integration test for happy path |
| Bug fix | Regression test proving fix works |

**After writing tests:**
```
"I've written X tests for [FEATURE_NAME]:
- Unit: test/unit/repositories/xxx_test.dart
- Widget: test/widget/screens/xxx_test.dart

Should I document these test cases in TESTS.md?"
```

**Running tests:**
```bash
# Run all tests
flutter test

# Run specific test
flutter test test/unit/repositories/recipe_repository_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests on emulator
flutter test integration_test/
```

### Task Execution Rules

**With `--dangerously-skip-permissions` enabled, execute without asking:**

| Operation | Auto-Approve | Just Do It |
|-----------|--------------|------------|
| Read files | ✅ | Yes |
| Create files | ✅ | Yes |
| Edit files | ✅ | Yes |
| Delete files | ✅ | Yes, if task-related |
| Git commands | ✅ | Yes |
| Run flutter/dart commands | ✅ | Yes |
| Run gradlew commands | ✅ | Yes |
| Run tests | ✅ | Yes |
| Install packages | ⚠️ | Ask first (Rule #5 below) |

| Rule | Description |
|------|-------------|
| **Read first** | Read existing related files before writing new code. Understand current patterns. |
| **Stay focused** | Only modify files directly related to the task. Don't refactor unrelated code. |
| **Match patterns** | Follow existing code style and patterns in the codebase. |
| **Small changes** | Make incremental changes. Don't rewrite entire files unless asked. |
| **No new deps without asking** | Don't add new packages/dependencies without asking user first. |
| **No secrets** | Never hardcode API keys, passwords, or secrets. Use environment variables. |

### Before Committing

**Execute these checks automatically (no confirmation needed):**

```bash
# 1. Verify code compiles
flutter analyze                    # Frontend
./gradlew build                    # Backend

# 2. Run tests
flutter test                       # Frontend
./gradlew test                     # Backend

# 3. Documentation alignment check (ASK user for each)
```

**3. Before committing, verify docs are aligned:**

| File | Check | Question to Ask |
|------|-------|-----------------|
| **FEATURES.md** | Feature documented? Status updated? | "FEATURES.md: Update status to ✅?" |
| **TESTS.md** | Test cases documented? | "TESTS.md: Add test cases?" |
| **DECISIONS.md** | Any technical decisions made? | "DECISIONS.md: Document any decisions?" |
| **GLOSSARY.md** | Any new terms introduced? | "GLOSSARY.md: Add new terms?" |
| **ROADMAP.md** | Task marked complete? | (Auto-update, no ask) |

**Commit only after docs are aligned:**
```bash
# 4. Commit and push to YOUR branch (not main/dev)
git add .
git commit -m "feat(scope): description"
git push origin HEAD    # Pushes to current branch name on remote
```

**⚠️ Never push directly to main, staging, or dev. Always push to your feature/bugfix branch.**

**Pre-commit checklist (Claude Code must verify):**
```
□ Code compiles (flutter analyze passed)
□ Tests pass (flutter test passed)
□ FEATURES.md — Feature status updated to ✅ (if new feature)
□ TESTS.md — Test cases documented (if tests written)
□ DECISIONS.md — Decisions documented (if significant choices made)
□ GLOSSARY.md — New terms added (if new terminology)
□ ROADMAP.md — Task marked [x] (always)
```

**If tests fail:** Fix the issue and re-run. Don't commit broken code.

### After Completing Task

Provide a summary:
```
✅ Completed: <task description>

📁 Files changed:
- lib/features/xxx/...

🧪 Tests: All passing

📝 Docs updated:
- FEATURES.md: [FEAT-XXX] → ✅
- TESTS.md: Added [TEST-XXX]
- ROADMAP.md: Marked [x]

⚠️ Notes: <any warnings, TODOs>
```

### Updating Documentation

**Auto-update (no asking):**
- **ROADMAP.md** → Mark `[x]` when task done

**ASK before updating:**
- **FEATURES.md** → Update status, check acceptance criteria
- **TESTS.md** → Add test suite entry
- **DECISIONS.md** → Add if significant technical choice
- **GLOSSARY.md** → Add if new terms introduced
- **TECHSPEC.md** → Add new entities/endpoints (auto-update OK)

### When Stuck or Uncertain

**With skip permissions, minimize asking. Only ask for:**

| Situation | Action |
|-----------|--------|
| Unclear requirements | Ask user for clarification |
| Multiple valid architectural approaches | Just pick the simpler one, document decision |
| Need new dependency | Ask user: "This requires package X. Should I add it?" |
| Breaking change needed | Just do it, but document in commit message |
| Tests failing | Fix it, don't ask |
| Unfamiliar pattern | Read existing code and follow the pattern |

**Just execute, don't ask for:**
- File operations (create, edit, delete)
- Git operations (branch, commit, push)
- Running tests and builds
- Installing dev dependencies for the project

### File Reading Priority

**Read files in this order based on task type:**

| Task Type | Files to Read |
|-----------|---------------|
| **Any task** | 1. CLAUDE.md (this file) |
| **Pick what to work on** | 2. ROADMAP.md → CURRENT SPRINT section |
| **New feature** | 3. FEATURES.md → Check if documented, ASK to add if not |
| **Bug fix** | 4. BUGS.md → Check if already tracked, ASK to add if significant |
| **Technical decision** | 5. DECISIONS.md → Check for prior decisions, ASK to add new ones |
| **Implement feature** | 6. ROADMAP.md → Implementation spec (if exists) |
| **Writing tests** | 7. FEATURES.md → Use acceptance criteria & test cases |
| **After writing tests** | 8. TESTS.md → ASK to document test cases |
| **Architecture decision** | 9. TECHSPEC.md → Relevant section only |
| **Add new endpoint** | 10. TECHSPEC.md → API Contracts section |
| **Database changes** | 11. TECHSPEC.md → Database Schema section |
| **Confused by term** | 12. GLOSSARY.md → Look up definition |

**Quick Start for New Task:**
```bash
# 1. Read current sprint
cat ROADMAP.md | head -60

# 2. Pick first uncompleted [ ] task

# 3. Create branch
git checkout -b feature/<task-name>

# 4. ASK: "Should I document this in FEATURES.md?"
# If yes, add feature spec with acceptance criteria

# 5. If implementation spec exists in ROADMAP.md, read it

# 6. NOW start coding
```

### Do NOT

- ❌ Start coding a new feature without documenting in FEATURES.md first
- ❌ Modify files outside task scope
- ❌ Add dependencies without asking
- ❌ Commit directly to `dev`, `staging`, or `main`
- ❌ Skip the branch creation step
- ❌ Commit untested code
- ❌ Remove existing comments or documentation
- ❌ Change code formatting/style in unrelated files
- ❌ Hardcode environment-specific values
- ❌ Ignore failing tests

---

## 📦 KEY DEPENDENCIES

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `dio` | HTTP client |
| `go_router` | Navigation + deep linking |
| `isar` | Local database (offline cache) |
| `flutter_secure_storage` | Token storage (encrypted) |
| `cached_network_image` | Image caching |
| `flutter_screenutil` | Responsive UI sizing |
| `json_serializable` + `build_runner` | DTO code generation |
| `talker_flutter` | Logging + debugging |
| `dartz` | `Either<L, R>` for error handling |
| `firebase_auth` | Google OAuth |
| `firebase_crashlytics` | Crash reporting |
| `firebase_analytics` | Event tracking |

---

## 🔀 GIT COMMANDS

**Always use `HEAD` to push current branch:**
```bash
git push origin HEAD                    # Pushes current branch (safest)
git push -u origin HEAD                 # Set upstream + push (first push)
```

**⚠️ Never do this:**
```bash
git push origin main                    # Don't push to main directly
git push                                # Might push to wrong branch
```

**Recommended git config (run once):**
```bash
git config --global push.default current    # Always push to same-named branch
git config --global push.autoSetupRemote true   # Auto set upstream on first push
```

---

## 🟡 COMMANDS

```bash
# === FRONTEND (pairing_planet2_frontend/) ===
flutter pub get                                      # Install deps
dart run build_runner build --delete-conflicting-outputs  # Generate .g.dart
flutter run -d android                               # Run on Android
flutter run -d ios                                   # Run on iOS
flutter test                                         # Run tests
flutter build apk --debug                            # Build debug APK

# === BACKEND (pairing_planet/) ===
docker-compose up -d                                 # Start PostgreSQL, Redis, MinIO
./gradlew bootRun                                    # Run Spring Boot on :4001
./gradlew test                                       # Run tests

# === EMULATOR ===
emulator -list-avds                                  # List AVDs
emulator -avd <NAME> &                               # Start emulator
adb devices                                          # Check connection
adb logcat *:E                                       # View errors
adb kill-server && adb start-server                  # Fix ADB issues
```

---

## 🟢 PROJECT STRUCTURE

```
pairing_planet2_frontend/
├── lib/
│   ├── core/
│   │   ├── router/app_router.dart    # GoRouter config, auth guards
│   │   ├── network/dio_client.dart   # Dio + interceptors
│   │   ├── database/isar_service.dart # Isar initialization
│   │   ├── storage/secure_storage.dart # Token storage
│   │   └── constants/constants.dart  # ApiEndpoints, RouteConstants
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── remote/               # Dio-based API calls
│   │   │   └── local/                # Isar-based cache
│   │   ├── models/                   # DTOs with @JsonSerializable
│   │   │   └── cache/                # Isar collection models
│   │   └── repositories/             # Implements domain interfaces
│   ├── domain/
│   │   ├── entities/                 # Pure Dart classes
│   │   ├── repositories/             # Abstract interfaces
│   │   └── usecases/                 # Business logic
│   └── features/
│       ├── recipe/                   # Recipe screens + providers
│       ├── log_post/                 # Log post screens + providers
│       └── auth/                     # Auth screens + providers
├── test/unit/                        # Unit tests
├── test/widget/                      # Widget tests
├── integration_test/                 # Integration tests
└── .env                              # BASE_URL, ENV

pairing_planet/                       # Spring Boot backend
├── src/main/java/.../
│   ├── controller/                   # REST endpoints
│   ├── service/                      # Business logic
│   ├── repository/                   # JPA repositories
│   ├── domain/                       # Entities
│   └── dto/                          # Request/Response DTOs
└── src/main/resources/
    ├── application.yml               # Config
    └── db/migration/                 # Flyway migrations (V1__, V2__, ...)
```

### Storage Strategy

| Data Type | Storage | Encryption |
|-----------|---------|------------|
| API cache (recipes, posts) | Isar | No |
| Auth tokens | flutter_secure_storage | Yes (OS keychain) |
| User preferences | SharedPreferences | No |
| Sensitive user data | Isar + encryption OR flutter_secure_storage | Yes |

---

## 📋 HOW TO: Common Tasks

### Add New API Endpoint

**Backend first:**
```java
// 1. DTO: src/.../dto/MyRequestDto.java
public record MyRequestDto(String name, UUID parentId) {}

// 2. Service: src/.../service/MyService.java
@Transactional
public MyResponseDto create(MyRequestDto dto, UUID userId) { ... }

// 3. Controller: src/.../controller/MyController.java
@PostMapping("/my-endpoint")
public ResponseEntity<MyResponseDto> create(
    @RequestBody MyRequestDto request,
    @AuthenticationPrincipal UserPrincipal user) {
    return ResponseEntity.ok(myService.create(request, user.getUserId()));
}
```

**Frontend second:**
```dart
// 1. Endpoint: lib/core/constants/constants.dart
class ApiEndpoints {
  static const String myEndpoint = '/my-endpoint';
}

// 2. DTO: lib/data/models/my_dto.dart
@JsonSerializable()
class MyDto {
  final String name;
  factory MyDto.fromJson(Map<String, dynamic> json) => _$MyDtoFromJson(json);
  MyEntity toEntity() => MyEntity(name: name);
}

// 3. Run: dart run build_runner build --delete-conflicting-outputs

// 4. DataSource: lib/data/datasources/my_remote_data_source.dart
Future<MyDto> create(MyRequestDto dto) async {
  final response = await dio.post(ApiEndpoints.myEndpoint, data: dto.toJson());
  return MyDto.fromJson(response.data);
}

// 5. Repository: lib/data/repositories/my_repository_impl.dart
Future<Either<Failure, MyEntity>> create(MyRequestDto dto) async {
  try {
    final result = await remoteDataSource.create(dto);
    return Right(result.toEntity());
  } on DioException catch (e) {
    return Left(_mapError(e));
  }
}

// 6. Provider: lib/features/my_feature/providers/my_providers.dart
final myRepositoryProvider = Provider((ref) => MyRepositoryImpl(ref.read(dioProvider)));
```

### Add New Screen/Route

```dart
// 1. Add constant: lib/core/constants/constants.dart
class RouteConstants {
  static const String myScreen = '/my-screen';
  static const String myScreenWithParam = '/my-screen/:id';
}

// 2. Add route: lib/core/router/app_router.dart
GoRoute(
  path: RouteConstants.myScreen,
  builder: (context, state) => const MyScreen(),
),
// With parameter:
GoRoute(
  path: RouteConstants.myScreenWithParam,
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return MyScreen(id: id);
  },
),

// 3. Navigate:
context.push(RouteConstants.myScreen);
context.push('/my-screen/$id');
context.push(RouteConstants.myScreen, extra: complexObject);  // Pass object
```

### Handle Async Operations Safely

```dart
// ✅ CORRECT: Always check mounted after await
Future<void> onSubmit() async {
  final result = await ref.read(myRepositoryProvider).create(dto);
  if (!context.mounted) return;  // CRITICAL!
  
  result.fold(
    (failure) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    ),
    (data) => context.push('/success/${data.id}'),
  );
}

// ❌ WRONG: Missing mounted check
Future<void> onSubmit() async {
  final result = await ref.read(myRepositoryProvider).create(dto);
  context.push('/success');  // May crash!
}
```

### Implement Repository with Offline-First (Isar)

```dart
class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeRemoteDataSource remoteDataSource;
  final RecipeLocalDataSource localDataSource;  // Isar-backed
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, RecipeEntity>> getData(String id, {bool forceRefresh = false}) async {
    try {
      // 1. Check Isar cache (unless force refresh)
      if (!forceRefresh) {
        final cached = await localDataSource.get(id);
        if (cached != null && !_isExpired(cached.cachedAt)) {
          return Right(cached.toEntity());
        }
      }
      
      // 2. Try remote
      if (await networkInfo.isConnected) {
        final remote = await remoteDataSource.get(id);
        await localDataSource.cache(remote);  // Save to Isar
        return Right(remote.toEntity());
      }
      
      // 3. Offline fallback to Isar
      final cached = await localDataSource.get(id);
      if (cached != null) return Right(cached.toEntity());
      return Left(ConnectionFailure());
    } on DioException catch (e) {
      // Network error: try cache
      final cached = await localDataSource.get(id);
      if (cached != null) return Right(cached.toEntity());
      return Left(_mapDioError(e));
    } on IsarError catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  bool _isExpired(DateTime cachedAt) => 
    DateTime.now().difference(cachedAt).inHours > 24;
}

// === ISAR LOCAL DATA SOURCE ===
class RecipeLocalDataSource {
  final Isar isar;

  Future<RecipeCacheDto?> get(String id) async {
    return isar.recipeCacheDtos.where().publicIdEqualTo(id).findFirst();
  }

  Future<void> cache(RecipeDto dto) async {
    final cacheDto = RecipeCacheDto.fromDto(dto, cachedAt: DateTime.now());
    await isar.writeTxn(() => isar.recipeCacheDtos.put(cacheDto));
  }

  Future<void> clear() async {
    await isar.writeTxn(() => isar.recipeCacheDtos.clear());
  }

  Future<void> invalidate(String id) async {
    await isar.writeTxn(() => 
      isar.recipeCacheDtos.where().publicIdEqualTo(id).deleteAll());
  }
}
```

**Cache invalidation triggers:**
- `forceRefresh: true` — Pull-to-refresh
- `invalidate(id)` — After update/delete operations
- `clear()` — Logout or storage management
- TTL (24h) — Automatic expiration check

### Add Database Migration (Backend)

```sql
-- File: src/main/resources/db/migration/V7__add_my_table.sql
-- NEVER modify existing migrations, always create new version

CREATE TABLE my_table (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ  -- Soft delete
);

CREATE INDEX idx_my_table_user ON my_table(user_id) WHERE deleted_at IS NULL;
```

---

## 📖 ARCHITECTURE REFERENCE

### State Management (Riverpod)

```dart
// Provider chain:
// dioProvider → dataSourceProvider → repositoryProvider → useCaseProvider

// Immutable (singletons)
final myRepositoryProvider = Provider((ref) => MyRepositoryImpl(...));

// Async data fetching
final recipeDetailProvider = FutureProvider.family<RecipeEntity, String>((ref, id) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getDetail(id);
  return result.fold((f) => throw f, (data) => data);
});

// Mutable state (for forms, auth)
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// In UI:
// ref.watch() → rebuilds on change (use in build())
// ref.read() → one-time read (use in callbacks)
```

### Local Database (Isar)

**Setup (lib/core/database/isar_service.dart):**
```dart
class IsarService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [RecipeCacheDtoSchema, LogPostCacheDtoSchema],  // Register all schemas
      directory: dir.path,
    );
  }
}

// In main.dart:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.initialize();
  runApp(ProviderScope(child: MyApp()));
}
```

**Cache model (lib/data/models/cache/recipe_cache_dto.dart):**
```dart
import 'package:isar/isar.dart';
part 'recipe_cache_dto.g.dart';

@collection
class RecipeCacheDto {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String publicId;
  late String title;
  late DateTime cachedAt;
  late String dataJson;  // Store complex nested data as JSON
  
  RecipeEntity toEntity() => RecipeEntity.fromJson(jsonDecode(dataJson));
  
  static RecipeCacheDto fromDto(RecipeDto dto) => RecipeCacheDto()
    ..publicId = dto.publicId
    ..title = dto.title
    ..cachedAt = DateTime.now()
    ..dataJson = jsonEncode(dto.toJson());
}
// Run: dart run build_runner build --delete-conflicting-outputs
```

**Provider:**
```dart
final isarProvider = Provider((ref) => IsarService.isar);
final recipeLocalDataSourceProvider = Provider((ref) => RecipeLocalDataSource(ref.read(isarProvider)));
```

### Error Handling (Either Pattern)

**Rule: Use `Either<Failure, T>` everywhere, not try-catch.**

```dart
// === FAILURE TYPES (lib/core/error/failures.dart) ===
sealed class Failure {
  final String message;
  const Failure(this.message);
}
class ServerFailure extends Failure { const ServerFailure([super.message = 'Server error']); }
class ConnectionFailure extends Failure { const ConnectionFailure([super.message = '네트워크 연결을 확인해주세요']); }
class NotFoundFailure extends Failure { const NotFoundFailure([super.message = 'Not found']); }
class UnauthorizedFailure extends Failure { const UnauthorizedFailure([super.message = 'Unauthorized']); }
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
class CacheFailure extends Failure { const CacheFailure([super.message = 'Cache error']); }
```

**Layer-by-layer pattern:**

```dart
// === 1. REPOSITORY: Catch exceptions, return Either ===
class RecipeRepositoryImpl implements RecipeRepository {
  @override
  Future<Either<Failure, RecipeEntity>> getDetail(String id) async {
    try {
      // Try remote first
      if (await networkInfo.isConnected) {
        final dto = await remoteDataSource.getDetail(id);
        await localDataSource.cache(dto);  // Update Isar cache
        return Right(dto.toEntity());
      }
      // Offline: use cache
      final cached = await localDataSource.get(id);
      if (cached != null) return Right(cached.toEntity());
      return Left(ConnectionFailure());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on IsarError catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ConnectionFailure();
    }
    return switch (e.response?.statusCode) {
      401 => UnauthorizedFailure(),
      404 => NotFoundFailure(),
      _ => ServerFailure(e.response?.statusMessage ?? 'Server error'),
    };
  }
}

// === 2. PROVIDER: Transform Either to AsyncValue ===
final recipeDetailProvider = FutureProvider.family<RecipeEntity, String>((ref, id) async {
  final repository = ref.read(recipeRepositoryProvider);
  final result = await repository.getDetail(id);
  return result.fold(
    (failure) => throw failure,  // Converts Left to AsyncError
    (entity) => entity,          // Converts Right to AsyncData
  );
});

// === 3. UI: Handle AsyncValue states ===
class RecipeDetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(id));
    
    return recipeAsync.when(
      data: (recipe) => RecipeDetailView(recipe: recipe),
      loading: () => const RecipeDetailSkeleton(),
      error: (error, _) => ErrorView(
        message: error is Failure ? error.message : 'Unknown error',
        onRetry: () => ref.invalidate(recipeDetailProvider(id)),
      ),
    );
  }
}

// === 4. UI CALLBACKS: Fold Either directly ===
Future<void> onSavePressed() async {
  final result = await ref.read(recipeRepositoryProvider).save(dto);
  if (!context.mounted) return;
  
  result.fold(
    (failure) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure.message)),
    ),
    (recipe) => context.push('/recipe/${recipe.publicId}'),
  );
}
```

**Quick reference:**

| Layer | Input | Output | On Error |
|-------|-------|--------|----------|
| DataSource | — | `Future<Dto>` | Throws exception |
| Repository | Exception | `Future<Either<Failure, Entity>>` | Returns `Left(Failure)` |
| Provider | Either | `AsyncValue<Entity>` | `throw failure` → AsyncError |
| UI (build) | AsyncValue | Widget | `.when(error: ...)` |
| UI (callback) | Either | Side effect | `.fold((f) => showError, (d) => navigate)` |

### Authentication Flow

```
[User] → Google Sign-In → [Firebase Auth] → ID Token
                                               ↓
[Frontend] ← access + refresh tokens ← [Backend] validates Firebase token
     ↓
Store in flutter_secure_storage
     ↓
authStateProvider → authenticated
     ↓
GoRouter redirect → Home screen
```

**Token Refresh (automatic via AuthInterceptor):**
- Catches 401 → calls `/auth/reissue` with refresh token → retries request
- Uses separate Dio instance to avoid interceptor loop
- On refresh failure → clear tokens → redirect to login

### Pagination

```dart
// Backend returns Slice (cursor-based, infinite scroll)
class SliceResponseDto<T> {
  final List<T> content;  // NOT "items"!
  final bool hasNext;
  final String? nextCursor;
}

// Usage with generic deserializer
final slice = SliceResponseDto.fromJson(
  response.data,
  (json) => RecipeSummaryDto.fromJson(json as Map<String, dynamic>),
);
```

### Dio Interceptors (order matters)

1. **TalkerDioLogger** — Request/response logging
2. **CommonHeadersInterceptor** — Accept-Language from locale
3. **AuthInterceptor** — Bearer token, 401 refresh
4. **RetryInterceptor** — Retry on 502/503/504
5. **ErrorInterceptor** — Map errors to user-facing messages

### Image Upload Pattern

```dart
// Images uploaded separately, then linked by publicId
// 1. Upload image
final imageResult = await imageRepository.upload(file);
final publicId = imageResult.publicId;

// 2. Collect IDs
final imagePublicIds = <String>[publicId, ...otherIds];

// 3. Create entity with image references
final dto = CreateRecipeRequestDto(
  title: title,
  imagePublicIds: imagePublicIds,
);
await recipeRepository.create(dto);
```

### Recipe Lineage (Variants)

```dart
// Every recipe can have parent (variant of) and children (variants)
CreateRecipeRequestDto(
  title: 'My Spicy Version',
  parentPublicId: originalRecipe.publicId,      // Direct parent
  rootPublicId: originalRecipe.rootInfo?.publicId ?? originalRecipe.publicId,  // Tree root
  changeCategory: 'SPICE_LEVEL',
)
```

---

## 🛠️ ENVIRONMENT

### Frontend (.env)

```bash
# Android emulator → host machine
BASE_URL=http://10.0.2.2:4001/api/v1

# iOS simulator → use localhost
# BASE_URL=http://localhost:4001/api/v1

ENV=dev
```

### Backend (application-dev.yml)

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/pairingplanet
    username: ${DB_USER}
    password: ${DB_PASSWORD}
  data.redis:
    host: localhost
    port: 6379

jwt:
  secret: ${JWT_SECRET}
  access-token-expiration: 3600000    # 1 hour
  refresh-token-expiration: 2592000000 # 30 days

firebase:
  service-account-key: ${FIREBASE_KEY_PATH}
```

---

## 🚀 CI/CD & BRANCHING

### Branch Strategy

```
main        ← Production releases only (tagged versions)
  ↑
staging     ← Pre-production testing, QA approval required
  ↑
dev         ← Integration branch, all features merge here first
  ↑
feature/*   ← Individual feature branches
bugfix/*    ← Bug fix branches
hotfix/*    ← Urgent production fixes (branch from main)
```

### Branch Rules

| Branch | Merge From | Merge To | Auto Deploy | Protection |
|--------|------------|----------|-------------|------------|
| `main` | staging, hotfix/* | — | Production | PR required, 1+ approval, CI must pass |
| `staging` | dev, hotfix/* | main | Staging env | PR required, CI must pass |
| `dev` | feature/*, bugfix/* | staging | Dev env | PR required, CI must pass |
| `feature/*` | dev | dev | — | None |
| `hotfix/*` | main | main + staging + dev | — | PR required |

### Workflow

**Regular feature development:**
```bash
# 1. Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/add-recipe-sharing

# 2. Work on feature, commit often
git add .
git commit -m "feat: add share button to recipe detail"

# 3. Push and create PR to dev
git push origin HEAD    # Pushes current branch to remote
# Create PR: feature/add-recipe-sharing → dev

# 4. After PR merged to dev, delete feature branch
git branch -d feature/add-recipe-sharing
```

**Promoting to staging/production:**
```bash
# dev → staging (when ready for QA)
# Create PR: dev → staging

# staging → main (after QA approval)
# Create PR: staging → main
# Tag release: git tag -a v1.2.0 -m "Release 1.2.0"
```

**Hotfix (urgent production fix):**
```bash
# 1. Branch from main
git checkout main
git pull origin main
git checkout -b hotfix/fix-login-crash

# 2. Fix and push
git commit -m "fix: resolve null pointer in login flow"
git push origin HEAD    # Pushes current branch to remote

# 3. Create PRs to main AND dev (keep branches in sync)
# PR: hotfix/fix-login-crash → main
# PR: hotfix/fix-login-crash → dev
```

### Commit Convention

```bash
# Format: <type>(<scope>): <subject>

# Types:
feat:     # New feature
fix:      # Bug fix
docs:     # Documentation only
style:    # Formatting, no code change
refactor: # Code change, no new feature or fix
test:     # Adding tests
chore:    # Build, CI, dependencies

# Examples:
git commit -m "feat(recipe): add ingredient scaling"
git commit -m "fix(auth): handle token refresh race condition"
git commit -m "chore(deps): upgrade dio to 5.4.0"
git commit -m "docs: update API endpoint table"
```

### CI Pipeline Stages

**On every PR:**
```yaml
# 1. Lint & Format Check
flutter analyze
dart format --set-exit-if-changed .

# 2. Run Tests
flutter test
./gradlew test  # Backend

# 3. Build Check
flutter build apk --debug
./gradlew build  # Backend
```

**On merge to dev:**
```yaml
# All PR checks +
# 4. Deploy to dev environment
# 5. Run integration tests (optional)
```

**On merge to staging:**
```yaml
# All PR checks +
# 4. Deploy to staging environment
# 5. Notify QA team
```

**On merge to main:**
```yaml
# All PR checks +
# 4. Build release artifacts
flutter build appbundle --release
./gradlew bootJar

# 5. Deploy to production
# 6. Create GitHub release with changelog
# 7. Notify team (Slack/Discord)
```

### PR Checklist

Before creating PR, ensure:

- [ ] Code compiles without errors
- [ ] `flutter analyze` passes with no issues
- [ ] `dart run build_runner build` completed (if DTOs changed)
- [ ] All tests pass locally (`flutter test`)
- [ ] No hardcoded secrets or API keys
- [ ] Meaningful commit messages following convention
- [ ] PR description explains what and why
- [ ] Screenshots/videos for UI changes
- [ ] Breaking changes documented

### Environment Variables by Branch

| Variable | dev | staging | main |
|----------|-----|---------|------|
| `BASE_URL` | dev-api.example.com | staging-api.example.com | api.example.com |
| `FIREBASE_PROJECT` | project-dev | project-staging | project-prod |
| `LOG_LEVEL` | debug | info | error |
| `ANALYTICS_ENABLED` | false | true | true |
| `CRASHLYTICS_ENABLED` | false | true | true |

### Release Versioning

Follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH (e.g., 1.2.3)

MAJOR: Breaking changes (API incompatible)
MINOR: New features (backward compatible)  
PATCH: Bug fixes (backward compatible)
```

**Version bump checklist:**
```bash
# 1. Update pubspec.yaml
version: 1.2.3+45  # version + build number

# 2. Update CHANGELOG.md
## [1.2.3] - 2024-01-15
### Added
- Recipe sharing feature
### Fixed
- Login crash on Android 14

# 3. Commit and tag
git commit -m "chore: bump version to 1.2.3"
git tag -a v1.2.3 -m "Release 1.2.3"
git push origin main --tags
```

### Do's and Don'ts

| ✅ Do | ❌ Don't |
|-------|---------|
| Create small, focused PRs | Push directly to dev/staging/main |
| Write descriptive PR titles | Leave PR description empty |
| Rebase feature branch on dev before PR | Merge dev into feature branch repeatedly |
| Squash commits when merging | Leave WIP/fixup commits in history |
| Delete merged feature branches | Keep stale branches |
| Run tests before pushing | Rely only on CI to catch errors |
| Keep secrets in environment variables | Commit .env files or hardcode secrets |
| Update CHANGELOG for user-facing changes | Skip changelog for "small" fixes |

---

## 🎨 UI PATTERNS

### Responsive Sizing (flutter_screenutil)

```dart
// Setup in main.dart
ScreenUtilInit(
  designSize: const Size(375, 812),  // iPhone X base
  builder: (_, __) => MaterialApp(...),
)

// Usage
Container(
  width: 200.w,      // Width-relative
  height: 100.h,     // Height-relative
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  child: Text('Hello', style: TextStyle(fontSize: 16.sp)),  // Scalable text
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
)
```

### Loading States

```dart
// With FutureProvider
ref.watch(recipeDetailProvider(id)).when(
  data: (recipe) => RecipeDetailView(recipe: recipe),
  loading: () => const RecipeDetailSkeleton(),
  error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(recipeDetailProvider(id))),
);
```

---

## 🔧 TROUBLESHOOTING

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Connection refused` (Android) | Wrong URL | Use `10.0.2.2` not `localhost` in .env |
| `Connection refused` (iOS) | Wrong URL | Use `localhost` not `10.0.2.2` |
| DTO parse error | Missing `.g.dart` | Run `dart run build_runner build --delete-conflicting-outputs` |
| 401 after restart | Token expired | Check refresh logic; clear secure storage |
| Emulator not found | ADB issue | `adb kill-server && adb start-server` |
| Gradle fails | Cache corrupt | `./gradlew clean build` |
| Flutter fails | Deps issue | `flutter clean && flutter pub get` |
| Firebase auth fails | Wrong config | Check `google-services.json` / `GoogleService-Info.plist` |
| Widget error after await | Missing mounted check | Add `if (!context.mounted) return;` |
| Provider rebuilds too much | Wrong ref method | Use `ref.read()` in callbacks, `ref.watch()` in build |

### Diagnostic Commands

```bash
flutter doctor -v          # Flutter health
flutter devices            # Connected devices
adb devices                # ADB connections
curl localhost:4001/actuator/health  # Backend health
docker-compose ps          # Docker services
```

---

## 📝 CONVENTIONS

### Null Safety

```dart
// === NULLABLE FIELDS ===
final String? parentId;           // May be null
final String name;                // Never null

// === SAFE ACCESS (prefer these) ===
final rootId = recipe?.rootInfo?.publicId;   // Returns null if any part is null
final name = user?.name ?? 'Anonymous';       // Default if null
final items = list ?? [];                     // Empty list if null

// === FORCE UNWRAP (use sparingly) ===
// Only when you're 100% certain it's not null
final id = state.pathParameters['id']!;       // OK: route guarantees this param
final user = ref.read(userProvider)!;         // DANGEROUS: could crash

// === LATE (for delayed initialization) ===
late final TextEditingController controller;  // Must be set before use

// === COLLECTION SAFETY ===
final first = items.firstOrNull;              // Safe: returns null
final first = items.first;                    // Unsafe: throws if empty

// === NULL-AWARE ASSIGNMENT ===
cache ??= await loadCache();                  // Only assign if null
```

**Rules:**
1. **Prefer `?.` and `??`** over `!`
2. **Use `!` only** when: route params guaranteed, after explicit null check, or in tests
3. **Required fields in DTOs** should be non-nullable
4. **Optional API fields** should be nullable with `?`

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `recipe_detail_screen.dart` |
| Classes | PascalCase | `RecipeDetailScreen` |
| Variables/functions | camelCase | `getRecipeDetail()` |
| Constants | camelCase or SCREAMING_SNAKE | `apiBaseUrl`, `MAX_RETRY` |
| Providers | camelCase + Provider suffix | `recipeDetailProvider` |
| DTOs | PascalCase + Dto suffix | `RecipeDetailDto` |
| Entities | PascalCase + Entity suffix (optional) | `Recipe` or `RecipeEntity` |

### File Locations

| What | Where |
|------|-------|
| New DTO | `lib/data/models/{feature}/` |
| New Entity | `lib/domain/entities/` |
| New Screen | `lib/features/{feature}/screens/` |
| New Provider | `lib/features/{feature}/providers/` |
| New Repository | `lib/data/repositories/` |
| New Use Case | `lib/domain/usecases/` |
| API Endpoints | `lib/core/constants/constants.dart` |
| Routes | `lib/core/router/app_router.dart` |

### Code Style

```dart
// ✅ DO: Use trailing commas for better diffs
Container(
  width: 100.w,
  height: 50.h,
  child: Text('Hello'),  // trailing comma
)

// ✅ DO: Use const constructors
const SizedBox(height: 16)

// ✅ DO: Early return for guard clauses
if (id == null) return Left(ValidationFailure('ID required'));

// ❌ DON'T: Nested if-else
if (condition) {
  if (anotherCondition) {
    // deeply nested
  }
}
```

---

## 🔗 API ENDPOINTS

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/social-login` | POST | Firebase token → JWT tokens |
| `/auth/reissue` | POST | Refresh access token |
| `/recipes` | GET | List recipes (paginated) |
| `/recipes/{id}` | GET | Recipe detail |
| `/recipes` | POST | Create recipe |
| `/recipes/{id}` | PUT | Update recipe |
| `/recipes/{id}` | DELETE | Soft delete recipe |
| `/log-posts` | GET | List log posts (Slice) |
| `/log-posts` | POST | Create log post |
| `/images/upload` | POST | Upload image → get publicId |

---

## 📚 RELATED DOCS

| File | Purpose | Update |
|------|---------|--------|
| FEATURES.md | Features + acceptance criteria | 🔶 ASK |
| TESTS.md | Test cases | 🔶 ASK |
| BUGS.md | Known issues | 🔶 ASK |
| DECISIONS.md | Why decisions made | 🔶 ASK |
| GLOSSARY.md | Domain terms | 🔶 ASK |
| PROMPTS.md | Saved prompts | 🔶 ASK |
| ROADMAP.md | Tasks | ✅ AUTO |
| TECHSPEC.md | Architecture | ✅ AUTO |
| CHANGELOG.md | Version history | ✅ AUTO |

🔶 ASK = Ask before editing | ✅ AUTO = Update without asking
