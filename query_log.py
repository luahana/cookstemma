#!/usr/bin/env python3
import psycopg2
from psycopg2.extras import RealDictCursor

DB_CONFIG = {
    'host': 'cookstemma-dev-db.chkg20sc21jl.us-east-2.rds.amazonaws.com',
    'port': 5432,
    'database': 'cookstemma',
    'user': 'postgres',
    'password': '9B6gL4h3vA00kv5GITE4lDBFgORg'
}

LOG_PUBLIC_ID = 'da0fd238-55fe-441d-bc17-5654cab08da8'

try:
    print(f"Connecting to {DB_CONFIG['host']}...")
    conn = psycopg2.connect(**DB_CONFIG, connect_timeout=10)
    cursor = conn.cursor(cursor_factory=RealDictCursor)

    # 1. Get log post
    cursor.execute("""
        SELECT id, public_id, creator_id, LEFT(content, 100) as content
        FROM log_posts
        WHERE public_id = %s
    """, (LOG_PUBLIC_ID,))
    log = cursor.fetchone()

    if not log:
        print("Log post not found!")
    else:
        print(f"\nLog Post ID: {log['id']}")
        print(f"Content: {log['content']}\n")

        # 2. Get translation events
        cursor.execute("""
            SELECT id, status, target_locale, created_at, updated_at,
                   ROUND(EXTRACT(EPOCH FROM (NOW() - updated_at))/60::numeric, 1) as mins_ago,
                   error
            FROM translation_events
            WHERE entity_type = 'LOG_POST' AND entity_id = %s
            ORDER BY created_at DESC
            LIMIT 20
        """, (log['id'],))

        events = cursor.fetchall()
        print(f"Translation Events ({len(events)}):")
        print("-" * 120)
        for e in events:
            print(f"ID: {e['id']:5} | Status: {e['status']:10} | Locale: {e['target_locale']:6} | "
                  f"Mins ago: {e['mins_ago']:6.1f} | Error: {e['error'] or ''}")

        # 3. Summary by status
        cursor.execute("""
            SELECT status, COUNT(*) as count
            FROM translation_events
            WHERE entity_type = 'LOG_POST' AND entity_id = %s
            GROUP BY status
            ORDER BY status
        """, (log['id'],))

        summary = cursor.fetchall()
        print(f"\nSummary:")
        for s in summary:
            print(f"  {s['status']}: {s['count']}")

    cursor.close()
    conn.close()

except Exception as e:
    print(f"Error: {e}")
