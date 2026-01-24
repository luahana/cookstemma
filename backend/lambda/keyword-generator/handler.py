"""
Keyword Generator Lambda Handler
Generates multilingual search keywords for foods_master using Google Gemini AI.
"""
import json
import logging
import os
from typing import Any

import boto3
import psycopg2
from psycopg2.extras import RealDictCursor

from gemini_keywords import GeminiKeywordGenerator, SUPPORTED_LOCALES

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')

# Cache for secrets
_secrets_cache: dict[str, Any] = {}


def get_secret(secret_name: str) -> dict:
    """Retrieve and cache secrets from AWS Secrets Manager."""
    if secret_name not in _secrets_cache:
        response = secrets_client.get_secret_value(SecretId=secret_name)
        _secrets_cache[secret_name] = json.loads(response['SecretString'])
    return _secrets_cache[secret_name]


def get_db_connection():
    """Create database connection using secrets."""
    db_secret = get_secret(os.environ['DATABASE_SECRET_ARN'])

    return psycopg2.connect(
        host=db_secret['host'],
        port=db_secret['port'],
        dbname=db_secret['dbname'],
        user=db_secret['username'],
        password=db_secret['password'],
        cursor_factory=RealDictCursor
    )


def get_gemini_client() -> GeminiKeywordGenerator:
    """Create Gemini keyword generator client using secrets."""
    gemini_secret = get_secret(os.environ['GEMINI_SECRET_ARN'])
    return GeminiKeywordGenerator(api_key=gemini_secret['api_key'])


def fetch_foods_needing_keywords(conn, limit: int = 20) -> list[dict]:
    """
    Fetch verified foods that need keyword generation.

    Includes:
    - Foods with NULL search_keywords
    - Foods with empty {} search_keywords
    - Foods with incomplete locales (< 20 languages)
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, public_id, name, description, search_keywords
            FROM foods_master
            WHERE is_verified = true
              AND (
                search_keywords IS NULL
                OR search_keywords = '{}'::jsonb
                OR (
                    SELECT COUNT(*)
                    FROM jsonb_object_keys(COALESCE(search_keywords, '{}'::jsonb))
                ) < %s
              )
            ORDER BY created_at ASC
            LIMIT %s
            FOR UPDATE SKIP LOCKED
        """, (len(SUPPORTED_LOCALES), limit))
        return cur.fetchall()


def update_food_keywords(conn, food_id: int, keywords: dict[str, str]):
    """
    Update food with generated keywords using atomic JSONB merge.

    Uses PostgreSQL || operator to merge new keywords with existing ones,
    preventing race conditions with concurrent updates.
    """
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE foods_master
            SET search_keywords = COALESCE(search_keywords, '{}'::jsonb) || %s::jsonb,
                updated_at = NOW()
            WHERE id = %s
            RETURNING id
        """, (json.dumps(keywords), food_id))

        result = cur.fetchone()
        if not result:
            raise ValueError(f"Food {food_id} not found in database")


def process_food(conn, generator: GeminiKeywordGenerator, food: dict) -> bool:
    """
    Process a single food item and generate keywords.

    Args:
        conn: Database connection
        generator: Gemini keyword generator
        food: Food record from database

    Returns:
        True if successful, False otherwise
    """
    food_id = food['id']
    public_id = food['public_id']
    name = food['name'] or {}
    description = food['description'] or {}
    existing_keywords = food['search_keywords'] or {}

    # Get display name for logging
    display_name = name.get('en') or name.get('ko') or next(iter(name.values()), 'Unknown')

    # Check which locales are missing
    existing_locales = set(existing_keywords.keys()) if existing_keywords else set()
    missing_locales = set(SUPPORTED_LOCALES.keys()) - existing_locales

    if not missing_locales:
        logger.info(f"Food {public_id} already has all {len(SUPPORTED_LOCALES)} locale keywords")
        return True

    logger.info(f"Generating keywords for food {public_id} ({display_name}): "
                f"missing {len(missing_locales)} locales")

    try:
        # Generate keywords for all languages
        keywords = generator.generate_keywords(name=name, description=description)

        # Only update with keywords for missing locales to preserve manual overrides
        new_keywords = {k: v for k, v in keywords.items() if k in missing_locales}

        if new_keywords:
            update_food_keywords(conn, food_id, new_keywords)
            logger.info(f"Updated food {public_id} with {len(new_keywords)} new locale keywords")
        else:
            logger.warning(f"No new keywords generated for food {public_id}")

        return True

    except Exception as e:
        logger.error(f"Failed to generate keywords for food {public_id}: {e}")
        return False


def handler(event: dict, context) -> dict:
    """
    Lambda handler for keyword generation.

    Can be triggered by:
    - Scheduled EventBridge rule (every 5 minutes for testing, every 6 hours for production)
    - Manual invocation for testing

    Event parameters:
    - test_mode: If True, run test generation without database
    - limit: Number of foods to process (default: 20)
    """
    logger.info(f"Keyword Generator Lambda invoked with event: {json.dumps(event)}")

    # Test mode - generate keywords without database
    if event.get('test_mode'):
        logger.info("Running in test mode")
        try:
            gemini_secret = get_secret(os.environ['GEMINI_SECRET_ARN'])
            generator = GeminiKeywordGenerator(api_key=gemini_secret['api_key'])

            test_name = event.get('test_name', {
                'en': 'Kimchi Stew',
                'ko': '김치찌개'
            })
            test_desc = event.get('test_description', {
                'en': 'Spicy Korean stew with fermented cabbage and pork',
                'ko': '발효 배추와 돼지고기로 만든 매운 한국 찌개'
            })

            keywords = generator.generate_keywords(name=test_name, description=test_desc)

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'test_mode': True,
                    'name': test_name,
                    'locale_count': len(keywords),
                    'keywords': keywords
                }, ensure_ascii=False)
            }
        except Exception as e:
            logger.error(f"Test mode failed: {e}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e), 'test_mode': True})
            }

    # Production mode - process foods from database
    conn = None
    try:
        conn = get_db_connection()
        generator = get_gemini_client()

        limit = event.get('limit', 20)
        foods = fetch_foods_needing_keywords(conn, limit=limit)

        logger.info(f"Found {len(foods)} foods needing keyword generation")

        processed = 0
        failed = 0

        for food in foods:
            try:
                success = process_food(conn, generator, food)
                if success:
                    processed += 1
                else:
                    failed += 1
            except Exception as e:
                logger.error(f"Error processing food {food['public_id']}: {e}")
                failed += 1

            # Commit after each food to release locks
            conn.commit()

        result = {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed,
                'failed': failed,
                'total_found': len(foods),
                'message': f'Generated keywords for {processed} foods, {failed} failed'
            })
        }
        logger.info(f"Keyword Generator Lambda completed: {result}")
        return result

    except Exception as e:
        logger.error(f"Keyword Generator Lambda error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if conn:
            conn.close()
