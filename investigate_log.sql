-- Investigation: Stuck Translation for Log da0fd238-55fe-441d-bc17-5654cab08da8

\echo '================================================================================'
\echo '1. LOG POST DETAILS'
\echo '================================================================================'
\echo ''

SELECT id, public_id, creator_id,
       LEFT(content, 100) as content_preview,
       created_at, updated_at, deleted_at
FROM log_posts
WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8';

\echo ''
\echo '================================================================================'
\echo '2. TRANSLATION EVENTS (Last 20)'
\echo '================================================================================'
\echo ''

SELECT
    te.id,
    te.status,
    te.target_locale,
    te.created_at,
    te.updated_at,
    ROUND(EXTRACT(EPOCH FROM (NOW() - te.updated_at))/60::numeric, 1) AS minutes_since_update,
    te.error
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
ORDER BY te.created_at DESC
LIMIT 20;

\echo ''
\echo '================================================================================'
\echo '3. STUCK PROCESSING TRANSLATIONS (> 10 minutes)'
\echo '================================================================================'
\echo ''

SELECT
    te.id,
    te.status,
    te.target_locale,
    te.created_at,
    te.updated_at,
    ROUND(EXTRACT(EPOCH FROM (NOW() - te.updated_at))/60::numeric, 1) AS minutes_stuck,
    te.error
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
  AND te.status = 'PROCESSING'
  AND (NOW() - te.updated_at) > INTERVAL '10 minutes'
ORDER BY te.created_at DESC;

\echo ''
\echo '================================================================================'
\echo '4. PENDING TRANSLATIONS NOT PICKED UP (> 5 minutes)'
\echo '================================================================================'
\echo ''

SELECT
    te.id,
    te.status,
    te.target_locale,
    te.created_at,
    ROUND(EXTRACT(EPOCH FROM (NOW() - te.created_at))/60::numeric, 1) AS minutes_waiting
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
  AND te.status = 'PENDING'
  AND (NOW() - te.created_at) > INTERVAL '5 minutes'
ORDER BY te.created_at DESC;

\echo ''
\echo '================================================================================'
\echo '5. STORED TRANSLATIONS'
\echo '================================================================================'
\echo ''

SELECT
    lt.id,
    lt.locale,
    LEFT(lt.translated_content, 100) as content_preview,
    lt.created_at,
    lt.updated_at
FROM log_post_translations lt
WHERE lt.log_post_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
ORDER BY lt.locale;

\echo ''
\echo '================================================================================'
\echo '6. SUMMARY BY STATUS'
\echo '================================================================================'
\echo ''

SELECT
    te.status,
    COUNT(*) as count,
    MAX(te.updated_at) as latest_update
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8')
GROUP BY te.status
ORDER BY te.status;
