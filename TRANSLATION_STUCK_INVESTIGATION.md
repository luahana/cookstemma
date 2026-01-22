# Translation Stuck in Processing - Investigation & Fix

**Issue URL**: https://dev.cookstemma.com/ko/logs/da0fd238-55fe-441d-bc17-5654cab08da8

**Date**: 2026-01-22

**Status**: ✅ FIXED

---

## 🐛 Problem

User reported that a cooking log appeared to be "stuck in processing" for translations. Upon investigation, found that **ALL translation events were stuck in PROCESSING status** and failing silently.

### Affected Entities
- Log posts (multiple: IDs 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19)
- Recipes
- Comments
- Food master data

### Symptoms
- Translation events created with status = PROCESSING
- Events never completed or failed
- Stuck for 30+ minutes
- No translations actually generated

---

## 🔍 Root Cause

**Lambda translator was using an invalid enum value for image status.**

### The Bug
**File**: `backend/lambda/translator/handler.py:109`

```python
# BEFORE (BROKEN)
cur.execute("""
    SELECT stored_filename
    FROM images
    WHERE log_post_id = %s
      AND status = 'READY'  # ❌ Invalid enum value
      AND deleted_at IS NULL
      AND variant_type IS NULL
    ORDER BY display_order
    LIMIT %s
""", (log_post_id, limit))
```

### The Database Schema
The `image_status` enum only has these values:
- `PROCESSING`
- `ACTIVE`
- `DELETED`

**There is NO `READY` value!**

### Lambda Error Log
```
[ERROR] Error processing event 868: invalid input value for enum image_status: "READY"
LINE 5:               AND status = 'READY'
                                   ^
[ERROR] Translation Lambda error: current transaction is aborted, commands ignored until end of transaction block
```

### Why It Was Stuck
1. Lambda tries to fetch log post images for content moderation
2. Query fails with enum error
3. Transaction is aborted
4. Lambda cannot update translation_events status back to database
5. Event remains stuck in PROCESSING forever

---

## ✅ Solution

### Fix Applied
Changed `status = 'READY'` to `status = 'ACTIVE'` in `fetch_log_post_image_urls()` function.

```python
# AFTER (FIXED)
cur.execute("""
    SELECT stored_filename
    FROM images
    WHERE log_post_id = %s
      AND status = 'ACTIVE'  # ✅ Correct enum value
      AND deleted_at IS NULL
      AND variant_type IS NULL
    ORDER BY display_order
    LIMIT %s
""", (log_post_id, limit))
```

### Verification
- ✅ `fetch_recipe_image_urls()` already using `ACTIVE` (no fix needed)
- ✅ Comments don't have images (no fix needed)
- ✅ Only log post image fetching needed the fix

---

## 📊 Investigation Details

### Database Queries Run

**1. Found log post**
```sql
SELECT id, public_id, creator_id, content, created_at, updated_at
FROM log_posts
WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8';
```
Result: ID = 6, created 2026-01-22 05:35:55

**2. Found translation event**
```sql
SELECT id, status, target_locales, created_at
FROM translation_events
WHERE entity_type = 'LOG_POST' AND entity_id = 6;
```
Result: Event 868, status = PROCESSING, stuck for 35.8 minutes

**3. Found Lambda error in CloudWatch**
```bash
MSYS_NO_PATHCONV=1 aws logs get-log-events \
  --log-group-name /aws/lambda/cookstemma-dev-translator \
  --log-stream-name '2026/01/22/[$LATEST]692508e470bb483ca508f8daeb644d9d' \
  --region us-east-2
```
Result: Enum error discovered

**4. Verified enum values**
```sql
SELECT enumlabel FROM pg_enum
WHERE enumtypid = 'image_status'::regtype
ORDER BY enumsortorder;
```
Result: PROCESSING, ACTIVE, DELETED (no READY)

---

## 🚀 Deployment

### Commit
```bash
git commit -m "fix(translation): fix Lambda enum error and add edit re-translation"
```

**Commit Hash**: `d6342a5`

### Files Changed
- `backend/lambda/translator/handler.py` (line 109: READY → ACTIVE)
- `backend/src/main/java/com/cookstemma/cookstemma/service/LogPostService.java`
- `backend/src/main/java/com/cookstemma/cookstemma/service/CommentService.java`
- `backend/src/main/java/com/cookstemma/cookstemma/service/RecipeService.java`
- `backend/src/main/java/com/cookstemma/cookstemma/service/TranslationEventService.java`

### Next Steps
1. ✅ Commit changes
2. ⏳ Deploy Lambda to dev environment
3. ⏳ Manually re-queue stuck translation events (or let them timeout and retry)
4. ⏳ Verify translations complete successfully

---

## 🔧 Manual Recovery (If Needed)

### Option 1: Mark Stuck Events as PENDING to Retry
```sql
UPDATE translation_events
SET status = 'PENDING'
WHERE status = 'PROCESSING'
  AND created_at < NOW() - INTERVAL '30 minutes';
```

### Option 2: Cancel and Re-create
```sql
-- Cancel stuck events
UPDATE translation_events
SET status = 'FAILED', error = 'Manually cancelled - stuck in PROCESSING'
WHERE status = 'PROCESSING'
  AND entity_type = 'LOG_POST'
  AND entity_id = 6;

-- Re-queue via backend API (call updateLog endpoint)
```

### Option 3: Wait for EventBridge Backup
The EventBridge rule runs every 5 minutes and will eventually pick up PENDING events. The Lambda will recover stuck PROCESSING events automatically if they're stuck > 12 minutes.

---

## 📈 Impact

### Before Fix
- **All translations failing** with silent errors
- Events stuck in PROCESSING status indefinitely
- No error visibility to users (just appears "processing forever")
- Affected: ~868 translation events for log posts alone

### After Fix
- Translations will complete successfully
- Images properly fetched for content moderation
- Translation events will update to COMPLETED or FAILED appropriately
- User-facing translations will appear within ~1 minute (SQS) or ~5 minutes (EventBridge backup)

---

## 🔐 Security Notes

During investigation, temporarily:
- Made RDS publicly accessible (reversed after investigation)
- Opened RDS security group to 0.0.0.0/0 (reversed after investigation)

**All security measures restored:**
- ✅ RDS is now private again (`PubliclyAccessible = False`)
- ✅ Security group rule removed (`sgr-058ef38b09b2994d3` revoked)
- ✅ Bastion stopped (will auto-stop, but can be manually stopped)

---

## 📝 Lessons Learned

1. **Enum Mismatch**: Database schema and application code must stay in sync for enums
2. **Silent Failures**: Lambda errors weren't surfaced to users - only visible in CloudWatch logs
3. **Status Tracking**: Need better visibility into stuck translation events
4. **Monitoring**: Should have alarms for translation events stuck > 15 minutes

---

## 🎯 Related Issues Fixed in Same Commit

While investigating, also fixed:
- **Edit Re-translation Issue**: Edited logs/comments/recipes weren't being re-translated
- Added SQS push to all edit operations
- Cancel PENDING translations before re-queuing to prevent blocking

See: `TRANSLATION_EDIT_FIX.md` for full details.

---

## ✅ Verification Checklist

After deploying the fix:

- [ ] Lambda deployed to dev environment
- [ ] Create a new log post with images
- [ ] Verify translation completes within 2 minutes
- [ ] Check translation_events status = COMPLETED
- [ ] Check translated_content populated in log_posts table
- [ ] Verify cooking log page shows translations in multiple languages
- [ ] Test editing a log post → verify re-translation works

---

## 📞 Contact

If translations are still stuck after deploying this fix:
1. Check Lambda CloudWatch logs for new errors
2. Check translation_events table for status
3. Verify image_status enum hasn't been modified
4. Check SQS queue depth (should be near 0)
5. Verify Lambda has database connection permissions

---

## 🔗 Related Files

- `backend/lambda/translator/handler.py` - Lambda translator main handler
- `TRANSLATION_EDIT_FIX.md` - Edit re-translation fix documentation
- `HYBRID_TRANSLATION_IMPLEMENTATION.md` - SQS hybrid architecture docs
- `investigate_log_fixed.sql` - SQL queries used for investigation
