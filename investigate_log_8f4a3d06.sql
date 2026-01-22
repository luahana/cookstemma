-- Investigation for log post 8f4a3d06-7eaa-4c1d-9cb5-d95d3fdd41c3

\echo 'LOG POST DETAILS'
SELECT id, public_id, source_locale, content, created_at
FROM log_posts
WHERE public_id = '8f4a3d06-7eaa-4c1d-9cb5-d95d3fdd41c3';

\echo ''
\echo 'TRANSLATION EVENTS'
SELECT te.id, te.status, te.created_at, te.error
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = '8f4a3d06-7eaa-4c1d-9cb5-d95d3fdd41c3')
ORDER BY te.created_at DESC;

\echo ''
\echo 'TRANSLATION EVENT SUMMARY'
SELECT te.status, COUNT(*) as count
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = '8f4a3d06-7eaa-4c1d-9cb5-d95d3fdd41c3')
GROUP BY te.status;
