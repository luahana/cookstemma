# Recipe Visibility Investigation Guide

**Recipe ID:** `94f5fa4e-dbba-41e1-90d5-523d8f34f53d`
**Issue:** Recipe not appearing on recipes page in AWS dev web environment

---

## Quick Start

### Option 1: Use SQL Script (Fastest)
1. Connect to AWS dev RDS database (see connection instructions below)
2. Run the SQL script: `investigate_recipe_visibility.sql`
3. Review the output to identify the issue
4. Apply the recommended fix from the script

### Option 2: Use Lambda Function (For Translation Issues)
If the investigation reveals a translation issue, use the Lambda translator to auto-fix:
```bash
aws lambda invoke \
  --function-name cookstemma-dev-translator \
  --payload '{"entity_type":"RECIPE_FULL","entity_id":123,"recipePublicId":"94f5fa4e-dbba-41e1-90d5-523d8f34f53d"}' \
  --region us-east-2 \
  response.json
```

---

## Connecting to AWS RDS Database

### Prerequisites
- AWS CLI configured with dev environment credentials
- PostgreSQL client installed (`psql`)
- Access to bastion host or VPN

### Method 1: Via Bastion Host (SSH Tunnel)

```bash
# Step 1: Create SSH tunnel to bastion
ssh -i ~/.ssh/your-key.pem -L 5432:rds-endpoint:5432 ec2-user@bastion-host-ip

# Step 2: In a new terminal, connect to PostgreSQL
psql -h localhost -p 5432 -U cookstemma -d cookstemma_dev

# Step 3: Run the investigation script
\i investigate_recipe_visibility.sql
```

### Method 2: Via AWS RDS Proxy or VPN

```bash
# Connect directly if you have VPN access
psql -h rds-endpoint -p 5432 -U cookstemma -d cookstemma_dev
```

### Finding Database Credentials

Database credentials are stored in AWS Secrets Manager:

```bash
# Get database secret
aws secretsmanager get-secret-value \
  --secret-id cookstemma-dev-db-credentials \
  --region us-east-2 \
  --query SecretString \
  --output text | jq .

# Output will show:
# {
#   "host": "rds-endpoint",
#   "port": 5432,
#   "dbname": "cookstemma_dev",
#   "username": "cookstemma",
#   "password": "xxxx"
# }
```

---

## Investigation Steps

### Step 1: Run Comprehensive Check

Connect to database and run:

```sql
SELECT
    r.public_id,
    r.title,
    r.cooking_style,
    r.deleted_at,
    r.is_private,
    r.root_recipe_id,
    -- Check each visibility condition
    r.deleted_at IS NULL AS not_deleted,
    (r.is_private IS NULL OR r.is_private = false) AS not_private,
    (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en') AS has_en,
    (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'ko' OR r.title_translations ? 'ko') AS has_ko,
    -- Overall visibility for English
    (
        r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en')
    ) AS visible_for_en
FROM recipes r
WHERE r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';
```

**Expected:** All boolean columns should be `true` for recipe to be visible.

### Step 2: Identify the Problem

Based on the output from Step 1:

| Column | Value | Issue | Fix |
|--------|-------|-------|-----|
| `not_deleted` | false | Recipe is soft-deleted | Run Fix #1 below |
| `not_private` | false | Recipe is private | Run Fix #2 below |
| `has_en` | false | Missing English translation | Run Fix #3 below |
| `has_ko` | false | Missing Korean translation | Run Fix #3 below |
| `visible_for_en` | false | Multiple issues | Apply all relevant fixes |

---

## Fixes

### Fix #1: Restore Soft-Deleted Recipe

```sql
UPDATE recipes
SET deleted_at = NULL
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';
```

### Fix #2: Make Recipe Public

```sql
UPDATE recipes
SET is_private = false
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';
```

### Fix #3: Add Missing Translations

#### Option A: Use Lambda Function (Recommended)

This will automatically translate the recipe to all 19 languages:

```bash
# Step 1: Get the recipe's internal ID
psql -h localhost -p 5432 -U cookstemma -d cookstemma_dev -c \
  "SELECT id FROM recipes WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';"

# Step 2: Create translation event
psql -h localhost -p 5432 -U cookstemma -d cookstemma_dev -c \
  "INSERT INTO translation_events (entity_type, entity_id, source_locale, target_locales)
   VALUES ('RECIPE_FULL', <recipe_id_from_step_1>, 'ko',
   '[\"en\",\"zh\",\"es\",\"ja\",\"de\",\"fr\",\"pt\",\"it\",\"ar\",\"ru\",\"id\",\"vi\",\"hi\",\"th\",\"pl\",\"tr\",\"nl\",\"sv\",\"fa\"]'::jsonb);"

# Step 3: Invoke Lambda to process translation
aws lambda invoke \
  --function-name cookstemma-dev-translator \
  --region us-east-2 \
  response.json

# Step 4: Check response
cat response.json
```

#### Option B: Manual Translation (Quick Fix for Single Language)

Add English translation manually:

```sql
-- Replace "Your English Title Here" with actual translation
UPDATE recipes
SET title_translations = jsonb_set(
    COALESCE(title_translations, '{}'::jsonb),
    '{en-US}',
    '"Your English Title Here"'
),
description_translations = jsonb_set(
    COALESCE(description_translations, '{}'::jsonb),
    '{en-US}',
    '"Your English description here"'
)
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';
```

**Note:** Translation keys use BCP47 format (e.g., `en-US`, `ko-KR`).

### Fix #4: Fix Stuck Image Processing

If images are stuck in `PROCESSING` status:

```sql
UPDATE images
SET status = 'ACTIVE'
WHERE id IN (
    SELECT i.id
    FROM images i
    JOIN recipe_images ri ON i.id = ri.image_id
    JOIN recipes r ON ri.recipe_id = r.id
    WHERE r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
    AND i.status = 'PROCESSING'
);
```

---

## Verification

After applying fixes, verify the recipe is now visible:

### 1. Re-run Comprehensive Check
```sql
-- Should return visible_for_en = true
SELECT
    r.public_id,
    r.title,
    (
        r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en' OR r.title_translations ? 'en')
    ) AS visible_for_en
FROM recipes r
WHERE r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';
```

### 2. Test Web Query
```sql
-- This mimics the exact query used by web for All Recipes (English)
SELECT r.public_id, r.title, r.created_at
FROM recipes r
WHERE r.deleted_at IS NULL
AND (r.is_private IS NULL OR r.is_private = false)
AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = 'en'
     OR r.title_translations ? 'en')
AND r.public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d'
ORDER BY r.created_at DESC;
```

**Expected:** Should return 1 row with recipe details.

### 3. Test via API
```bash
# Get access token (replace with actual token)
ACCESS_TOKEN="your-dev-token"

# Test recipe detail endpoint
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
     "https://dev-api.cookstemma.com/api/v1/recipes/94f5fa4e-dbba-41e1-90d5-523d8f34f53d"

# Test recipes listing (check if recipe appears in list)
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
     "https://dev-api.cookstemma.com/api/v1/recipes?locale=en&page=0&size=20"
```

### 4. Verify on Web UI
1. Open AWS dev web environment
2. Navigate to recipes page
3. Search for the recipe by title or scroll through list
4. Verify recipe appears with correct title and thumbnail

---

## Understanding Recipe Visibility Logic

A recipe appears in the public listing if **ALL** of these conditions are true:

### Core Visibility Conditions

| # | Condition | Database Check | Purpose |
|---|-----------|----------------|---------|
| 1 | Not deleted | `deleted_at IS NULL` | Filter out soft-deleted recipes |
| 2 | Not private | `is_private IS NULL OR is_private = false` | Filter out private recipes |
| 3 | Has translation | `SUBSTRING(cooking_style FROM 1 FOR 2) = :langCode OR title_translations ? :langCode` | Show only recipes available in requested language |

### Additional Filter Conditions (Optional)

| Filter | Database Check | When Applied |
|--------|----------------|--------------|
| Originals only | `root_recipe_id IS NULL` | When user selects "Originals" filter |
| Variants only | `root_recipe_id IS NOT NULL` | When user selects "Variants" filter |
| Search keyword | Full-text search on title, description, ingredients, steps | When user searches |
| Hashtag | `JOIN hashtags` | When browsing by hashtag |

### Translation Logic (IMPORTANT)

The web uses offset-based pagination with this query pattern:

```sql
WHERE r.deleted_at IS NULL
  AND (r.is_private IS NULL OR r.is_private = false)
  AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
       OR jsonb_exists(r.title_translations, :langCode))
```

This means a recipe is visible for a locale if **EITHER**:
- The `cooking_style` field starts with the locale code (e.g., `ko-KR` for Korean)
- **OR** the `title_translations` JSONB has a key for that locale (e.g., `en-US` for English)

**Example:**
- Recipe with `cooking_style = 'ko-KR'` and no translations → Only visible in Korean
- Recipe with `cooking_style = 'ko-KR'` and `title_translations = {"en-US": "..."}` → Visible in both Korean and English
- Recipe with `cooking_style = 'ko-KR'` and 19 translations → Visible in all 20 languages

---

## Translation System Overview

### Supported Languages (20 total)

| Code | Language | BCP47 Format |
|------|----------|--------------|
| en | English | en-US |
| ko | Korean | ko-KR |
| zh | Chinese | zh-CN |
| es | Spanish | es-ES |
| ja | Japanese | ja-JP |
| de | German | de-DE |
| fr | French | fr-FR |
| pt | Portuguese | pt-BR |
| it | Italian | it-IT |
| ar | Arabic | ar-SA |
| ru | Russian | ru-RU |
| id | Indonesian | id-ID |
| vi | Vietnamese | vi-VN |
| hi | Hindi | hi-IN |
| th | Thai | th-TH |
| pl | Polish | pl-PL |
| tr | Turkish | tr-TR |
| nl | Dutch | nl-NL |
| sv | Swedish | sv-SE |
| fa | Persian | fa-IR |

### Translation Keys Format

**IMPORTANT:** All translation JSONB keys use **BCP47 format** (e.g., `en-US`, `ko-KR`), not short codes.

```json
{
  "title_translations": {
    "en-US": "Delicious Bibimbap",
    "ko-KR": "맛있는 비빔밥",
    "ja-JP": "おいしいビビンバ"
  }
}
```

### Lambda Translator

The Lambda function (`cookstemma-dev-translator`) uses Google Gemini to:
1. Translate recipe title, description, steps, and ingredients
2. Propagate translations to `foods_master` table (food names)
3. Propagate translations to `autocomplete_items` table (ingredient names)
4. Perform content moderation (text + images) before translation
5. Save all translations using BCP47 format keys

---

## Troubleshooting

### Issue: "Connection refused" when connecting to database

**Cause:** Bastion host or VPN not configured.

**Fix:**
1. Verify you have SSH access to bastion host
2. Check that bastion security group allows SSH from your IP
3. Verify RDS security group allows connections from bastion

### Issue: "Recipe still not appearing after fix"

**Possible causes:**
1. Browser cache - try hard refresh (Ctrl+Shift+R)
2. Multiple issues - re-run comprehensive check to verify all conditions
3. Wrong locale - verify web is requesting the locale you translated to
4. Filter active - check if web has "Originals" or "Variants" filter enabled

### Issue: "Lambda translation failed"

**Check Lambda logs:**
```bash
aws logs tail /aws/lambda/cookstemma-dev-translator \
  --follow \
  --region us-east-2
```

**Common errors:**
- Content moderation failure (inappropriate content or images)
- Gemini API rate limit (wait and retry)
- Missing source content (check that recipe has title/description)
- Database connection timeout (check RDS availability)

### Issue: "Translation keys not showing up"

**Verify BCP47 format:**
```sql
-- Check translation keys format
SELECT
    public_id,
    title,
    jsonb_object_keys(title_translations) as translation_keys
FROM recipes
WHERE public_id = '94f5fa4e-dbba-41e1-90d5-523d8f34f53d';
```

**Expected:** Keys should be `en-US`, `ko-KR`, etc., not `en`, `ko`.

---

## Most Likely Root Cause

Based on recent commits related to translation system:
- **d002763:** Reverted translation status endpoint
- **a566e5c:** Removed translation fallbacks
- **4d34f81:** Added strict validation

**Primary Suspect: Translation Mismatch**
- Recipe likely has `cooking_style = 'ko-KR'` (Korean source)
- Web is requesting English (`locale=en`)
- No English translation in `title_translations`
- Therefore: Recipe is filtered out by translation check

**Fix:** Run Lambda translator to add English translation (see Fix #3, Option A above).

---

## Contact

If you need help with this investigation, provide:
1. Output from Step 1 (comprehensive check)
2. Recipe title and creation date
3. Expected language/locale
4. Screenshot of web UI showing issue

---

## Related Files

- `investigate_recipe_visibility.sql` - SQL script with all diagnostic queries
- `backend/lambda/translator/handler.py` - Lambda translator implementation
- `backend/src/main/java/com/cookstemma/cookstemma/repository/recipe/RecipeRepository.java` - Recipe query logic
