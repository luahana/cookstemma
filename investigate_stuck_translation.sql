-- Investigation: Stuck Translation for Log da0fd238-55fe-441d-bc17-5654cab08da8
-- URL: https://dev.cookstemma.com/ko/logs/da0fd238-55fe-441d-bc17-5654cab08da8

-- 1. Find the log post by public_id
SELECT id, public_id, creator_id, content, created_at, updated_at, deleted_at
FROM log_posts
WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8';

-- 2. Find all translation events for this log (get log_post.id from above query first)
-- Replace <LOG_POST_ID> with the actual id from the first query
SELECT
    id,
    entity_type,
    entity_id,
    status,
    target_locale,
    created_at,
    updated_at,
    error
FROM translation_events
WHERE entity_type = 'LOG_POST'
  AND entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
ORDER BY created_at DESC;

-- 3. Check for any PROCESSING translations that have been stuck for a long time
SELECT
    te.id,
    te.entity_type,
    te.entity_id,
    te.status,
    te.target_locale,
    te.created_at,
    te.updated_at,
    EXTRACT(EPOCH FROM (NOW() - te.updated_at))/60 AS minutes_since_update,
    te.error
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
  AND te.status = 'PROCESSING'
ORDER BY te.created_at DESC;

-- 4. Check for any PENDING translations that haven't been picked up
SELECT
    te.id,
    te.entity_type,
    te.entity_id,
    te.status,
    te.target_locale,
    te.created_at,
    te.updated_at,
    EXTRACT(EPOCH FROM (NOW() - te.created_at))/60 AS minutes_since_creation,
    te.error
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
  AND te.status = 'PENDING'
ORDER BY te.created_at DESC;

-- 5. Check the actual translations stored for this log
SELECT
    lt.id,
    lt.log_post_id,
    lt.locale,
    lt.translated_content,
    lt.created_at,
    lt.updated_at
FROM log_post_translations lt
WHERE lt.log_post_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
ORDER BY lt.locale;

-- 6. Summary: Count of translation events by status
SELECT
    te.status,
    COUNT(*) as count,
    MAX(te.updated_at) as latest_update
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
GROUP BY te.status
ORDER BY te.status;
