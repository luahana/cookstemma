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
\echo '2. ALL TRANSLATION EVENTS FOR THIS LOG'
\echo '================================================================================'
\echo ''

SELECT
    te.id,
    te.entity_type,
    te.entity_id,
    te.status,
    te.source_locale,
    te.target_locales,
    te.created_at,
    te.error,
    ROUND(EXTRACT(EPOCH FROM (NOW() - te.created_at))/60::numeric, 1) AS minutes_since_creation
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = 6
ORDER BY te.created_at DESC
LIMIT 20;

\echo ''
\echo '================================================================================'
\echo '3. COUNT OF TRANSLATION EVENTS BY STATUS'
\echo '================================================================================'
\echo ''

SELECT
    te.status,
    COUNT(*) as count
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = 6
GROUP BY te.status
ORDER BY te.status;

\echo ''
\echo '================================================================================'
\echo '4. CHECK TRANSLATION COLUMNS IN LOG POST'
\echo '================================================================================'
\echo ''

SELECT
    id,
    public_id,
    source_locale,
    translated_content,
    created_at,
    updated_at
FROM log_posts
WHERE public_id = 'da0fd238-55fe-441d-bc17-5654cab08da8';

\echo ''
\echo '================================================================================'
\echo '5. RECENT TRANSLATION EVENTS (All entities, last 10)'
\echo '================================================================================'
\echo ''

SELECT
    te.id,
    te.entity_type,
    te.entity_id,
    te.status,
    te.created_at
FROM translation_events te
ORDER BY te.created_at DESC
LIMIT 10;
