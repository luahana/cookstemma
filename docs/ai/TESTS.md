# TESTS.md — Pairing Planet

> Test case tracking. Claude Code adds entries after writing tests.

---

## Template

```markdown
### [TEST-XXX]: Suite Name

**Feature:** [FEAT-XXX]
**Type:** Unit | Widget | Integration
**File:** `test/[type]/[name]_test.dart`
**Status:** ✅ Passing | ❌ Failing

| # | Test Case | Status |
|---|-----------|--------|
| 1 | description | ✅ |
```

---

## Test Index

### Frontend Tests (Planned - Not Yet Implemented)

| ID | Suite | Feature | Type | Status |
|----|-------|---------|------|--------|
| TEST-001 | Auth Repository | AUTH-001 | Unit | 📋 Planned |
| TEST-002 | Auth Provider | AUTH-001 | Unit | 📋 Planned |
| TEST-003 | Recipe Repository | RCP-001 | Unit | 📋 Planned |
| TEST-004 | Recipe List Screen | RCP-001 | Widget | 📋 Planned |
| TEST-005 | Create Recipe Flow | RCP-003 | Integration | 📋 Planned |
| TEST-006 | Recipe Variation | RCP-004 | Unit | 📋 Planned |
| TEST-007 | Log Post Repository | LOG-001 | Unit | 📋 Planned |
| TEST-008 | Save Repository | SAVE-001 | Unit | 📋 Planned |

> **Note:** Frontend test files are documented as specifications but not yet implemented. Only `test/widget_test.dart` exists.

### Backend Tests (Implemented)

| ID | Suite | Feature | Type | Status |
|----|-------|---------|------|--------|
| TEST-B001 | Auth Controller | AUTH-001 | Integration | ✅ |
| TEST-B002 | Recipe Controller | RCP-001 | Integration | ✅ |
| TEST-B003 | User Controller | PROF-001 | Integration | ✅ |
| TEST-B004 | JWT Token Provider | AUTH-001 | Unit | ✅ |
| TEST-B005 | Security Config | AUTH-001 | Integration | ✅ |
| TEST-B006 | Saved Recipe Service | SAVE-001 | Unit | ✅ |

---

## Frontend Test Suites (Specifications - To Be Implemented)

> These test suites are documented as specifications for future implementation. The test files do not yet exist.

### [TEST-001]: Auth Repository (Planned)

**Feature:** [AUTH-001] **Type:** Unit **File:** `test/unit/repositories/auth_repository_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | socialLogin returns tokens on valid Firebase token | 📋 |
| 2 | socialLogin returns UnauthorizedFailure on invalid token | 📋 |
| 3 | refreshToken returns new access token | 📋 |
| 4 | logout clears stored tokens | 📋 |

---

### [TEST-002]: Auth Provider (Planned)

**Feature:** [AUTH-001] **Type:** Unit **File:** `test/unit/providers/auth_provider_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Initial state is unauthenticated | 📋 |
| 2 | Login success updates state to authenticated | 📋 |
| 3 | Logout resets state | 📋 |

---

### [TEST-003]: Recipe Repository (Planned)

**Feature:** [RCP-001], [RCP-002] **Type:** Unit **File:** `test/unit/repositories/recipe_repository_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | getRecipes returns paginated list | 📋 |
| 2 | getRecipes returns cached data when offline | 📋 |
| 3 | getRecipeDetail returns recipe with ingredients | 📋 |
| 4 | createRecipe returns created recipe | 📋 |

---

### [TEST-004]: Recipe List Screen (Planned)

**Feature:** [RCP-001] **Type:** Widget **File:** `test/widget/screens/home_screen_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Shows loading indicator initially | 📋 |
| 2 | Shows recipe cards after loading | 📋 |
| 3 | Pull-to-refresh triggers reload | 📋 |

---

### [TEST-005]: Create Recipe Flow (Planned)

**Feature:** [RCP-003] **Type:** Integration **File:** `integration_test/create_recipe_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Full flow: create recipe with all fields | 📋 |
| 2 | Validation error shown for empty title | 📋 |
| 3 | Created recipe appears in My Recipes | 📋 |

---

### [TEST-006]: Recipe Variation (Planned)

**Feature:** [RCP-004] **Type:** Unit **File:** `test/unit/repositories/recipe_variation_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | createVariation sets parentPublicId correctly | 📋 |
| 2 | createVariation sets rootPublicId to original | 📋 |

---

### [TEST-007]: Log Post Repository (Planned)

**Feature:** [LOG-001] **Type:** Unit **File:** `test/unit/repositories/log_post_repository_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | createLog returns created log | 📋 |
| 2 | createLog with SUCCESS/PARTIAL/FAILED outcome | 📋 |

---

### [TEST-008]: Save Repository (Planned)

**Feature:** [SAVE-001] **Type:** Unit **File:** `test/unit/repositories/save_repository_test.dart` **Status:** 📋

| # | Test Case | Status |
|---|-----------|--------|
| 1 | saveRecipe adds to saved list | 📋 |
| 2 | unsaveRecipe removes from list | 📋 |
| 3 | isSaved returns correct state | 📋 |

---

## Backend Test Suites (Implemented)

### [TEST-B001]: Auth Controller

**Feature:** [AUTH-001] **Type:** Integration **File:** `src/test/java/.../controller/AuthControllerTest.java` **Status:** ✅

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Social login with valid Firebase token | ✅ |
| 2 | Token reissue with valid refresh token | ✅ |
| 3 | Logout clears refresh token | ✅ |

---

### [TEST-B002]: Recipe Controller

**Feature:** [RCP-001] **Type:** Integration **File:** `src/test/java/.../controller/RecipeControllerTest.java` **Status:** ✅

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Get recipes returns paginated list | ✅ |
| 2 | Get recipe detail returns full recipe | ✅ |
| 3 | Create recipe requires authentication | ✅ |

---

### [TEST-B003]: User Controller

**Feature:** [PROF-001] **Type:** Integration **File:** `src/test/java/.../controller/UserControllerTest.java` **Status:** ✅

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Get user profile returns user data | ✅ |
| 2 | Update profile modifies user | ✅ |

---

### [TEST-B004]: JWT Token Provider

**Feature:** [AUTH-001] **Type:** Unit **File:** `src/test/java/.../security/JwtTokenProviderTest.java` **Status:** ✅

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Generate access token | ✅ |
| 2 | Validate valid token | ✅ |
| 3 | Reject expired token | ✅ |

---

### [TEST-B005]: Security Config

**Feature:** [AUTH-001] **Type:** Integration **File:** `src/test/java/.../security/SecurityConfigTest.java` **Status:** ✅

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Public endpoints accessible without auth | ✅ |
| 2 | Protected endpoints require valid token | ✅ |

---

### [TEST-B006]: Saved Recipe Service

**Feature:** [SAVE-001] **Type:** Unit **File:** `src/test/java/.../service/SavedRecipeServiceTest.java` **Status:** ✅

| # | Test Case | Status |
|---|-----------|--------|
| 1 | Save recipe creates record | ✅ |
| 2 | Unsave recipe removes record | ✅ |
| 3 | Is saved returns correct state | ✅ |

---

## Run Commands

```bash
flutter test                              # All tests
flutter test test/unit/                   # Unit only
flutter test --coverage                   # With coverage
flutter test integration_test/            # On emulator
```
