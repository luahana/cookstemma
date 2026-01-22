-- Investigation Script for Recipe 94f5fa4e-dbba-41e1-90d5-523d8f34f53d Visibility
-- Run this script against the AWS dev database

-- ============================================
-- STEP 1: Verify Recipe Exists
-- ============================================
SELECT
    public_id,
    title,
    created_at
FROM recipes
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Expected: Should return 1 row
-- If no rows: Recipe doesn't exist or was hard-deleted

-- ============================================
-- STEP 2: Check Soft Delete Status
-- ============================================
SELECT
    public_id,
    title,
    deleted_at,
    CASE
        WHEN deleted_at IS NULL THEN '✅ NOT DELETED'
        ELSE '❌ SOFT DELETED'
    END AS delete_status
FROM recipes
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Expected: deleted_at should be NULL
-- If NOT NULL: Recipe was soft-deleted
-- Fix: UPDATE recipes SET deleted_at = NULL WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- ============================================
-- STEP 3: Check Privacy Flag
-- ============================================
SELECT
    public_id,
    title,
    is_private,
    CASE
        WHEN is_private IS NULL OR is_private = false THEN '✅ PUBLIC'
        ELSE '❌ PRIVATE'
    END AS privacy_status
FROM recipes
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Expected: is_private should be NULL or false
-- If true: Recipe is marked private
-- Fix: UPDATE recipes SET is_private = false WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- ============================================
-- STEP 4: Check Language/Translation Configuration
-- ============================================
SELECT
    public_id,
    title,
    cooking_style,
    title_translations,
    description_translations,
    -- Check which languages are available
    CASE
        WHEN SUBSTRING(cooking_style FROM 1 FOR 2) = 'en' THEN '✅ Source is EN'
        WHEN SUBSTRING(cooking_style FROM 1 FOR 2) = 'ko' THEN '✅ Source is KO'
        ELSE '⚠️ Other language: ' || SUBSTRING(cooking_style FROM 1 FOR 2)
    END AS source_language,
    CASE
        WHEN title_translations ? 'en' THEN '✅ Has EN translation'
        ELSE '❌ No EN translation'
    END AS has_en_translation,
    CASE
        WHEN title_translations ? 'ko' THEN '✅ Has KO translation'
        ELSE '❌ No KO translation'
    END AS has_ko_translation,
    -- Check if recipe will be visible for EN requests
    CASE
        WHEN SUBSTRING(cooking_style FROM 1 FOR 2) = 'en' OR title_translations ? 'en' THEN '✅ VISIBLE for EN'
        ELSE '❌ HIDDEN for EN'
    END AS en_visibility,
    -- Check if recipe will be visible for KO requests
    CASE
        WHEN SUBSTRING(cooking_style FROM 1 FOR 2) = 'ko' OR title_translations ? 'ko' THEN '✅ VISIBLE for KO'
        ELSE '❌ HIDDEN for KO'
    END AS ko_visibility
FROM recipes
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Expected: Recipe should be visible for at least one language (likely EN if web is in English)
-- If hidden for target language: Translation is missing
-- Note: The web query checks: (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode OR jsonb_exists(r.title_translations, :langCode))

-- ============================================
-- STEP 5: Check Recipe Type (Original vs Variant)
-- ============================================
SELECT
    public_id,
    title,
    root_recipe_id,
    parent_recipe_id,
    CASE
        WHEN root_recipe_id IS NULL AND parent_recipe_id IS NULL THEN '✅ ORIGINAL (will show in "Originals" filter)'
        WHEN root_recipe_id IS NOT NULL THEN '✅ VARIANT (will show in "Variants" filter)'
        ELSE '⚠️ Unknown type'
    END AS recipe_type
FROM recipes
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Expected: Depends on what user expects to see
-- If filter is "Originals only": root_recipe_id should be NULL
-- If filter is "Variants only": root_recipe_id should NOT be NULL

-- ============================================
-- STEP 6: Check Image Status
-- ============================================
SELECT
    i.public_id as image_id,
    i.image_type,
    i.status,
    i.created_at,
    i.deleted_at,
    CASE
        WHEN i.status = 'ACTIVE' AND i.deleted_at IS NULL THEN '✅ READY'
        WHEN i.status = 'PROCESSING' THEN '⏳ PROCESSING'
        WHEN i.deleted_at IS NOT NULL THEN '❌ DELETED'
        ELSE '⚠️ ' || i.status
    END AS image_status
FROM images i
JOIN recipe_images ri ON i.id = ri.image_id
JOIN recipes r ON ri.recipe_id = r.id
WHERE r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
ORDER BY i.created_at DESC;

-- Expected: Cover images should have status = 'ACTIVE' and deleted_at = NULL
-- If PROCESSING: Images may not display, but recipe should still appear in list
-- If no images: Recipe should still appear, just without thumbnail

-- ============================================
-- STEP 7: Comprehensive Visibility Check (ALL CONDITIONS)
-- ============================================
-- This simulates the backend filter logic for English locale
SELECT
    r.public_id,
    r.title,
    r.cooking_style,
    r.title_translations,
    r.root_recipe_id,
    r.deleted_at,
    r.is_private,
    -- Check each condition
    r.deleted_at IS NULL AS check_not_deleted,
    (r.is_private IS NULL OR r.is_private = false) AS check_not_private,
    (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en') AS check_has_en,
    (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'ko' OR r.title_translations ? 'ko') AS check_has_ko,
    r.root_recipe_id IS NULL AS check_is_original,
    -- Overall visibility
    (
        r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en')
    ) AS visible_for_en_all_recipes,
    (
        r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en')
        AND r.root_recipe_id IS NULL
    ) AS visible_for_en_originals_only,
    (
        r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en')
        AND r.root_recipe_id IS NOT NULL
    ) AS visible_for_en_variants_only,
    (
        r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'ko' OR r.title_translations ? 'ko')
    ) AS visible_for_ko_all_recipes
FROM recipes r
WHERE r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Expected: All check_* columns should be true for recipe to be visible
-- visible_for_en_all_recipes should be true if web is requesting English without filters
-- visible_for_en_originals_only should be true if web has "Originals" filter active
-- visible_for_en_variants_only should be true if web has "Variants" filter active

-- ============================================
-- STEP 8: Test Web Query (All Recipes, EN)
-- ============================================
-- This is the EXACT query used by web for offset-based pagination
SELECT r.* FROM recipes r
WHERE r.deleted_at IS NULL
AND (r.is_private IS NULL OR r.is_private = false)
AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en'
     OR r.title_translations ? 'en')
AND r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
ORDER BY r.created_at DESC;

-- Expected: Should return 1 row if recipe is visible
-- If no rows: Recipe fails at least one visibility condition

-- ============================================
-- STEP 9: Test Web Query (All Recipes, KO)
-- ============================================
SELECT r.* FROM recipes r
WHERE r.deleted_at IS NULL
AND (r.is_private IS NULL OR r.is_private = false)
AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'ko'
     OR r.title_translations ? 'ko')
AND r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
ORDER BY r.created_at DESC;

-- Expected: Should return 1 row if recipe is visible for Korean

-- ============================================
-- STEP 10: Test Web Query (Originals Only, EN)
-- ============================================
SELECT r.* FROM recipes r
WHERE r.root_recipe_id IS NULL
AND r.deleted_at IS NULL
AND (r.is_private IS NULL OR r.is_private = false)
AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en'
     OR r.title_translations ? 'en')
AND r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
ORDER BY r.created_at DESC;

-- Expected: Should return 1 row if recipe is an original and visible

-- ============================================
-- STEP 11: Test Web Query (Variants Only, EN)
-- ============================================
SELECT r.* FROM recipes r
WHERE r.root_recipe_id IS NOT NULL
AND r.deleted_at IS NULL
AND (r.is_private IS NULL OR r.is_private = false)
AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en'
     OR r.title_translations ? 'en')
AND r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
ORDER BY r.created_at DESC;

-- Expected: Should return 1 row if recipe is a variant and visible

-- ============================================
-- RECOMMENDED FIXES
-- ============================================

-- FIX 1: If recipe is soft-deleted (deleted_at IS NOT NULL)
-- UNCOMMENT AND RUN:
-- UPDATE recipes
-- SET deleted_at = NULL
-- WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- FIX 2: If recipe is private (is_private = true)
-- UNCOMMENT AND RUN:
-- UPDATE recipes
-- SET is_private = false
-- WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- FIX 3: If recipe is missing English translation
-- Option A: Add manual translation
-- UNCOMMENT AND RUN (replace with actual English title):
-- UPDATE recipes
-- SET title_translations = jsonb_set(
--     COALESCE(title_translations, '{}'::jsonb),
--     '{en}',
--     '"Your English Title Here"'
-- )
-- WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';

-- Option B: Use Lambda function to auto-translate
-- Call the Lambda function: save_full_recipe_translations
-- Payload: {"recipePublicId": "94f5fa4e-dbba-41e1-90d5-523d8f34f53d"}

-- FIX 4: If images are stuck in PROCESSING status
-- UNCOMMENT AND RUN:
-- UPDATE images
-- SET status = 'ACTIVE'
-- WHERE id IN (
--     SELECT i.id
--     FROM images i
--     JOIN recipe_images ri ON i.id = ri.image_id
--     JOIN recipes r ON ri.recipe_id = r.id
--     WHERE r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
--     AND i.status = 'PROCESSING'
-- );

-- ============================================
-- VERIFICATION AFTER FIX
-- ============================================
-- After applying a fix, re-run STEP 7 to verify all checks pass
-- Then test the web query (STEP 8, 9, 10, or 11) to confirm recipe appears
