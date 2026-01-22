#!/usr/bin/env python3
"""
Investigation script for stuck translation event
Log URL: https://dev.cookstemma.com/ko/logs/da0fd238-55fe-441d-bc17-5654cab08da8
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import json
from datetime import datetime

# Database connection parameters (via SSH tunnel on localhost:5433)
DB_CONFIG = {
    'host': 'localhost',
    'port': 5433,
    'database': 'cookstemma',
    'user': 'postgres',
    'password': '9B6gL4h3vA00kv5GITE4lDBFgORg'
}

LOG_PUBLIC_ID = 'da0fd238-55fe-441d-bc17-5654cab08da8'

def main():
    try:
        print(f"Connecting to database at {DB_CONFIG['host']}:{DB_CONFIG['port']}...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # 1. Find the log post
        print(f"\n{'='*80}")
        print(f"1. FINDING LOG POST: {LOG_PUBLIC_ID}")
        print(f"{'='*80}\n")

        cursor.execute("""
            SELECT id, public_id, creator_id,
                   LEFT(content, 100) as content_preview,
                   created_at, updated_at, deleted_at
            FROM log_posts
            WHERE public_id = %s
        """, (LOG_PUBLIC_ID,))

        log_post = cursor.fetchone()
        if not log_post:
            print(f"❌ Log post not found: {LOG_PUBLIC_ID}")
            return

        print(f"✅ Log post found:")
        print(f"   ID: {log_post['id']}")
        print(f"   Public ID: {log_post['public_id']}")
        print(f"   Creator ID: {log_post['creator_id']}")
        print(f"   Content Preview: {log_post['content_preview']}")
        print(f"   Created: {log_post['created_at']}")
        print(f"   Updated: {log_post['updated_at']}")
        print(f"   Deleted: {log_post['deleted_at']}")

        log_post_id = log_post['id']

        # 2. Find all translation events for this log
        print(f"\n{'='*80}")
        print(f"2. TRANSLATION EVENTS FOR LOG POST ID: {log_post_id}")
        print(f"{'='*80}\n")

        cursor.execute("""
            SELECT
                id,
                entity_type,
                entity_id,
                status,
                target_locale,
                created_at,
                updated_at,
                error,
                EXTRACT(EPOCH FROM (NOW() - updated_at))/60 AS minutes_since_update
            FROM translation_events
            WHERE entity_type = 'LOG_POST'
              AND entity_id = %s
            ORDER BY created_at DESC
            LIMIT 20
        """, (log_post_id,))

        events = cursor.fetchall()
        if not events:
            print(f"⚠️ No translation events found for log post {log_post_id}")
        else:
            print(f"Found {len(events)} translation events:\n")
            for event in events:
                print(f"   Event ID: {event['id']}")
                print(f"   Status: {event['status']}")
                print(f"   Target Locale: {event['target_locale']}")
                print(f"   Created: {event['created_at']}")
                print(f"   Updated: {event['updated_at']}")
                print(f"   Minutes Since Update: {event['minutes_since_update']:.1f}")
                if event['error']:
                    print(f"   ❌ Error: {event['error']}")
                print()

        # 3. Check for PROCESSING translations stuck for a while
        print(f"\n{'='*80}")
        print(f"3. STUCK PROCESSING TRANSLATIONS (> 10 minutes)")
        print(f"{'='*80}\n")

        cursor.execute("""
            SELECT
                id,
                status,
                target_locale,
                created_at,
                updated_at,
                EXTRACT(EPOCH FROM (NOW() - updated_at))/60 AS minutes_since_update,
                error
            FROM translation_events
            WHERE entity_type = 'LOG_POST'
              AND entity_id = %s
              AND status = 'PROCESSING'
              AND (NOW() - updated_at) > INTERVAL '10 minutes'
            ORDER BY created_at DESC
        """, (log_post_id,))

        stuck_events = cursor.fetchall()
        if not stuck_events:
            print(f"✅ No stuck PROCESSING translations found")
        else:
            print(f"⚠️ Found {len(stuck_events)} stuck PROCESSING translations:\n")
            for event in stuck_events:
                print(f"   Event ID: {event['id']}")
                print(f"   Target Locale: {event['target_locale']}")
                print(f"   Created: {event['created_at']}")
                print(f"   Updated: {event['updated_at']}")
                print(f"   🕐 Stuck for: {event['minutes_since_update']:.1f} minutes")
                if event['error']:
                    print(f"   Error: {event['error']}")
                print()

        # 4. Check for PENDING translations not picked up
        print(f"\n{'='*80}")
        print(f"4. PENDING TRANSLATIONS NOT PICKED UP (> 5 minutes)")
        print(f"{'='*80}\n")

        cursor.execute("""
            SELECT
                id,
                status,
                target_locale,
                created_at,
                updated_at,
                EXTRACT(EPOCH FROM (NOW() - created_at))/60 AS minutes_since_creation,
                error
            FROM translation_events
            WHERE entity_type = 'LOG_POST'
              AND entity_id = %s
              AND status = 'PENDING'
              AND (NOW() - created_at) > INTERVAL '5 minutes'
            ORDER BY created_at DESC
        """, (log_post_id,))

        pending_events = cursor.fetchall()
        if not pending_events:
            print(f"✅ No stuck PENDING translations found")
        else:
            print(f"⚠️ Found {len(pending_events)} PENDING translations not picked up:\n")
            for event in pending_events:
                print(f"   Event ID: {event['id']}")
                print(f"   Target Locale: {event['target_locale']}")
                print(f"   Created: {event['created_at']}")
                print(f"   🕐 Waiting for: {event['minutes_since_creation']:.1f} minutes")
                print()

        # 5. Check actual translations stored
        print(f"\n{'='*80}")
        print(f"5. STORED TRANSLATIONS FOR LOG POST")
        print(f"{'='*80}\n")

        cursor.execute("""
            SELECT
                id,
                log_post_id,
                locale,
                LEFT(translated_content, 100) as translated_content_preview,
                created_at,
                updated_at
            FROM log_post_translations
            WHERE log_post_id = %s
            ORDER BY locale
        """, (log_post_id,))

        translations = cursor.fetchall()
        if not translations:
            print(f"⚠️ No translations stored yet")
        else:
            print(f"Found {len(translations)} translations:\n")
            for trans in translations:
                print(f"   Locale: {trans['locale']}")
                print(f"   Content Preview: {trans['translated_content_preview']}")
                print(f"   Created: {trans['created_at']}")
                print(f"   Updated: {trans['updated_at']}")
                print()

        # 6. Summary by status
        print(f"\n{'='*80}")
        print(f"6. TRANSLATION EVENTS SUMMARY BY STATUS")
        print(f"{'='*80}\n")

        cursor.execute("""
            SELECT
                status,
                COUNT(*) as count,
                MAX(updated_at) as latest_update
            FROM translation_events
            WHERE entity_type = 'LOG_POST'
              AND entity_id = %s
            GROUP BY status
            ORDER BY status
        """, (log_post_id,))

        summary = cursor.fetchall()
        if summary:
            for row in summary:
                print(f"   Status: {row['status']:12} | Count: {row['count']:3} | Latest: {row['latest_update']}")

        print(f"\n{'='*80}")
        print(f"INVESTIGATION COMPLETE")
        print(f"{'='*80}\n")

        cursor.close()
        conn.close()

    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
