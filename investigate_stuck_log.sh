#!/bin/bash
# Investigation script for stuck translation
# Log URL: https://dev.cookstemma.com/ko/logs/da0fd238-55fe-441d-bc17-5654cab08da8

export PGPASSWORD='9B6gL4h3vA00kv5GITE4lDBFgORg'
DB_HOST='cookstemma-dev-db.chkg20sc21jl.us-east-2.rds.amazonaws.com'
DB_USER='postgres'
DB_NAME='cookstemma'
LOG_PUBLIC_ID='da0fd238-55fe-441d-bc17-5654cab08da8'

echo "================================================================================"
echo "1. FINDING LOG POST: $LOG_PUBLIC_ID"
echo "================================================================================"
echo ""

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT id, public_id, creator_id,
       LEFT(content, 100) as content_preview,
       created_at, updated_at, deleted_at
FROM log_posts
WHERE public_id = '$LOG_PUBLIC_ID';
EOF

echo ""
echo "================================================================================"
echo "2. TRANSLATION EVENTS FOR THIS LOG POST"
echo "================================================================================"
echo ""

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT
    te.id,
    te.entity_type,
    te.entity_id,
    te.status,
    te.target_locale,
    te.created_at,
    te.updated_at,
    te.error,
    EXTRACT(EPOCH FROM (NOW() - te.updated_at))/60 AS minutes_since_update
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = '$LOG_PUBLIC_ID')
ORDER BY te.created_at DESC
LIMIT 20;
EOF

echo ""
echo "================================================================================"
echo "3. STUCK PROCESSING TRANSLATIONS (> 10 minutes)"
echo "================================================================================"
echo ""

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT
    te.id,
    te.status,
    te.target_locale,
    te.created_at,
    te.updated_at,
    EXTRACT(EPOCH FROM (NOW() - te.updated_at))/60 AS minutes_since_update,
    te.error
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = '$LOG_PUBLIC_ID')
  AND te.status = 'PROCESSING'
  AND (NOW() - te.updated_at) > INTERVAL '10 minutes'
ORDER BY te.created_at DESC;
EOF

echo ""
echo "================================================================================"
echo "4. PENDING TRANSLATIONS NOT PICKED UP (> 5 minutes)"
echo "================================================================================"
echo ""

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT
    te.id,
    te.status,
    te.target_locale,
    te.created_at,
    EXTRACT(EPOCH FROM (NOW() - te.created_at))/60 AS minutes_since_creation
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = '$LOG_PUBLIC_ID')
  AND te.status = 'PENDING'
  AND (NOW() - te.created_at) > INTERVAL '5 minutes'
ORDER BY te.created_at DESC;
EOF

echo ""
echo "================================================================================"
echo "5. STORED TRANSLATIONS"
echo "================================================================================"
echo ""

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT
    lt.id,
    lt.log_post_id,
    lt.locale,
    LEFT(lt.translated_content, 100) as translated_content_preview,
    lt.created_at,
    lt.updated_at
FROM log_post_translations lt
WHERE lt.log_post_id = (SELECT id FROM log_posts WHERE public_id = '$LOG_PUBLIC_ID')
ORDER BY lt.locale;
EOF

echo ""
echo "================================================================================"
echo "6. TRANSLATION EVENTS SUMMARY BY STATUS"
echo "================================================================================"
echo ""

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << EOF
SELECT
    te.status,
    COUNT(*) as count,
    MAX(te.updated_at) as latest_update
FROM translation_events te
WHERE te.entity_type = 'LOG_POST'
  AND te.entity_id = (SELECT id FROM log_posts WHERE public_id = '$LOG_PUBLIC_ID')
GROUP BY te.status
ORDER BY te.status;
EOF

echo ""
echo "================================================================================"
echo "INVESTIGATION COMPLETE"
echo "================================================================================"
