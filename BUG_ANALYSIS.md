# Bug Analysis: Recipe Not Showing Despite Translation Complete

## Summary
Recipes with completed translations are not appearing on the recipe list page due to a **translation key format mismatch** between the database query and stored translation data.

## Root Cause

### The Problem
1. **Database queries** check for translations using **short language codes** (`"en"`, `"ko"`)
2. **Lambda translator** stores translations using **BCP47 format keys** (`"en-US"`, `"ko-KR"`)
3. PostgreSQL `jsonb_exists()` checks for exact key match, so `jsonb_exists(title_translations, 'en')` returns `FALSE` when keys are `"en-US"`

### Timeline of Introduction
- **Jan 20, 2026 (commit 0c61c26)**: Added translation availability filter to queries:
  ```sql
  AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
       OR jsonb_exists(r.title_translations, :langCode))
  ```
  - `langCode` parameter receives short codes like `"en"`, `"ko"`

- **Jan 21, 2026 (commit 7d80d69)**: Standardized Lambda translator to use BCP47 format:
  ```python
  target_bcp47 = to_bcp47(target_locale)  # "en" -> "en-US"
  existing_title[target_bcp47] = translated['title']  # Key is "en-US"
  ```

## Code Flow Analysis

### 1. Controller (RecipeController.java:42-66)
```java
@GetMapping
public ResponseEntity<UnifiedPageResponse<RecipeSummaryDto>> getRecipes(...) {
    // Get locale from Accept-Language header
    String contentLocale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
    // contentLocale = "en-US" (BCP47 format)

    return ResponseEntity.ok(recipeService.findRecipesUnified(..., contentLocale));
}
```

### 2. Service (RecipeService.java:1150-1183)
```java
private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithOffset(..., String contentLocale) {
    // Extract language code (strips region code)
    String langCode = LocaleUtils.getLanguageCode(LocaleUtils.normalizeLocale(contentLocale));
    // contentLocale "en-US" -> langCode "en" ❌

    Page<Recipe> recipes;
    recipes = recipeRepository.findPublicRecipesPage(langCode, pageable);
    // Passes short code "en" to repository
}
```

### 3. LocaleUtils (LocaleUtils.java:191-197)
```java
public static String getLanguageCode(String locale) {
    if (locale == null) {
        return null;
    }
    int dashIndex = locale.indexOf('-');
    return dashIndex > 0 ? locale.substring(0, dashIndex) : locale;
    // "en-US" -> "en"
    // "ko-KR" -> "ko"
}
```

### 4. Repository (RecipeRepository.java:307-321)
```sql
@Query(value = """
    SELECT r.* FROM recipes r
    WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
    AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
         OR jsonb_exists(r.title_translations, :langCode))
    -- :langCode = "en" ❌
    -- But keys are "en-US", "ko-KR" ❌
    -- jsonb_exists returns FALSE ❌
    ORDER BY r.created_at DESC
    """, nativeQuery = true)
Page<Recipe> findPublicRecipesPage(@Param("langCode") String langCode, Pageable pageable);
```

### 5. Lambda Translator (handler.py:546-577)
```python
def save_full_recipe_translations(conn, recipe_id: int, full_recipe: dict,
                                   translated: dict, target_locale: str):
    # Convert locale to BCP47 for ALL translation keys
    target_bcp47 = to_bcp47(target_locale)  # "en" -> "en-US" ✓

    existing_title[target_bcp47] = translated['title']  # Key: "en-US" ✓

    cur.execute("""
        UPDATE recipes
        SET title_translations = %s, description_translations = %s
        WHERE id = %s
    """, (json.dumps(existing_title), ...))
```

## Example Scenario

### Recipe Data in Database
```json
{
  "id": 123,
  "public_id": "94f5fa4e-dbba-41e1-90d5-523d8f34f53d",
  "title": "비빔밥",
  "cooking_style": "ko-KR",
  "title_translations": {
    "en-US": "Bibimbap",
    "ja-JP": "ビビンバ",
    "zh-CN": "拌饭"
  }
}
```

### Web Request Flow
1. User requests recipes page in English
2. Accept-Language header: `en-US`
3. Controller receives `contentLocale = "en-US"`
4. Service extracts `langCode = "en"` ❌
5. Repository query: `jsonb_exists(title_translations, 'en')` → `FALSE` ❌
6. Recipe is filtered out ❌

### Expected Flow
1. User requests recipes page in English
2. Accept-Language header: `en-US`
3. Controller receives `contentLocale = "en-US"`
4. Service passes `langCode = "en-US"` ✓ (or checks for both "en" and "en-US")
5. Repository query: `jsonb_exists(title_translations, 'en-US')` → `TRUE` ✓
6. Recipe appears in list ✓

## Impact

### Affected Queries
All native queries in `RecipeRepository.java` and `LogPostRepository.java` that use:
```sql
jsonb_exists(r.title_translations, :langCode)
```

**Recipe queries (17 affected):**
- `findPublicRecipesWithCursorInitial`
- `findPublicRecipesWithCursor`
- `findOriginalRecipesWithCursorInitial`
- `findOriginalRecipesWithCursor`
- `findVariantRecipesWithCursorInitial`
- `findVariantRecipesWithCursor`
- `findPublicRecipesPage`
- `findOriginalRecipesPage`
- `findVariantRecipesPage`
- `searchRecipes` (cursor)
- `searchRecipesPage` (offset)
- `findRecipesOrderByVariantCount`
- `findRecipesOrderByTrending`
- `findRecipesOrderByPopular`
- `findByHashtagWithCursorInitial`
- `findByHashtagWithCursor`
- `findByHashtagPage`

**Log post queries:** Similar patterns in `LogPostRepository.java`

### User Impact
- Recipes with completed translations appear missing
- Users see incomplete recipe listings
- Translation system appears broken despite working correctly
- Content creators may think their recipes are not published

## Solution Options

### Option 1: Pass BCP47 to Query (Recommended)
**Change service layer to pass full BCP47 locale instead of extracting language code.**

**Pros:**
- Matches how translations are actually stored
- Consistent with Lambda translator
- Clean, simple fix

**Cons:**
- Need to update service methods

**Implementation:**
```java
// RecipeService.java
private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithOffset(..., String contentLocale) {
    // Pass full BCP47 locale instead of extracting language code
    String langCode = LocaleUtils.toBcp47(contentLocale);  // "en" -> "en-US"

    Page<Recipe> recipes = recipeRepository.findPublicRecipesPage(langCode, pageable);
}
```

### Option 2: Check Both Formats in Query
**Update repository queries to check for both short and BCP47 keys.**

**Pros:**
- Backwards compatible with old data
- No service layer changes

**Cons:**
- More complex SQL
- Need to update all 17+ queries
- Redundant checks

**Implementation:**
```sql
AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = LEFT(:langCode, 2)
     OR jsonb_exists(r.title_translations, :langCode)
     OR EXISTS (
         SELECT 1 FROM jsonb_object_keys(r.title_translations) k
         WHERE k LIKE LEFT(:langCode, 2) || '%'
     ))
```

### Option 3: Change Lambda to Use Short Codes
**Change Lambda translator to use short codes like "en", "ko".**

**Pros:**
- Matches current query expectations

**Cons:**
- Inconsistent with BCP47 standard
- Need to migrate existing data
- May cause issues with regional variants (en-US vs en-GB)

## Recommended Fix

**Option 1** is recommended because:
1. BCP47 is the correct standard for locale identification
2. Lambda translator already uses BCP47 (standardized in commit 7d80d69)
3. Frontend likely uses BCP47 for Accept-Language headers
4. LocaleUtils already has `toBcp47()` method
5. Minimal code changes required

## Implementation Plan

1. Update `RecipeService.java`:
   - Replace `LocaleUtils.getLanguageCode()` with `LocaleUtils.toBcp47()`
   - Apply to all methods that call repository queries with `langCode`

2. Update `LogPostService.java`:
   - Same changes for log post queries

3. Update `HashtagService.java`:
   - Same changes for hashtag queries

4. Update tests:
   - Ensure tests use BCP47 format locales

5. Verify fix:
   - Check recipe `94f5fa4e-dbba-41e1-90d5-523d8f34f53d` appears in list
   - Test with different locales (en-US, ko-KR, ja-JP)
   - Verify search and filters work

## Files to Modify

```
backend/src/main/java/com/cookstemma/cookstemma/service/RecipeService.java
backend/src/main/java/com/cookstemma/cookstemma/service/LogPostService.java
backend/src/main/java/com/cookstemma/cookstemma/service/HashtagService.java
backend/src/test/java/com/cookstemma/cookstemma/service/RecipeServiceTest.java
backend/src/test/java/com/cookstemma/cookstemma/controller/RecipeControllerTest.java
```

## Testing Plan

### Unit Tests
```java
@Test
void findRecipes_withBcp47Locale_returnsTranslatedRecipes() {
    // Given: Recipe with en-US translation
    Recipe recipe = createRecipeWithTranslation("en-US", "Bibimbap");

    // When: Request recipes with en-US locale
    UnifiedPageResponse<RecipeSummaryDto> result =
        recipeService.findRecipesUnified(null, null, null, null, null, null, null, 0, 20, "en-US");

    // Then: Recipe appears in results
    assertThat(result.getContent()).contains(recipe);
}
```

### Integration Test
1. Create recipe with Korean as source (`cooking_style = "ko-KR"`)
2. Run Lambda translator to add English translation
3. Query recipes with `locale=en-US`
4. Verify recipe appears in results

### Manual Verification
```bash
# 1. Check recipe in database
psql -h localhost -p 5432 -U cookstemma -d cookstemma_dev -c \
  "SELECT public_id, title, cooking_style, title_translations
   FROM recipes
   WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';"

# 2. Test API endpoint
curl -H "Authorization: Bearer $TOKEN" \
     -H "Accept-Language: en-US" \
     "https://dev-api.cookstemma.com/api/v1/recipes?page=0&size=20"

# 3. Verify recipe appears in response
```

## Prevention

To prevent similar issues in the future:
1. Add integration tests that verify translation key format consistency
2. Document translation key format standard (BCP47) in code comments
3. Create utility method that validates translation JSONB structure
4. Add database constraint or check to enforce BCP47 keys
5. Monitor translation query performance and accuracy

## Related Commits
- 0c61c26: "feat(backend): filter recipes and logs by translation availability" (Jan 20, 2026)
- 7d80d69: "refactor(backend): standardize all locale keys to BCP47 format" (Jan 21, 2026)

## References
- [BCP47 Locale Standard](https://tools.ietf.org/html/bcp47)
- [PostgreSQL JSONB Functions](https://www.postgresql.org/docs/current/functions-json.html)
