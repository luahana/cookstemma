"""
Suggestion Verifier Lambda Handler
Processes pending food and ingredient suggestions, validates them using Google Gemini,
and auto-approves valid items with translations or rejects invalid ones.
"""
import json
import logging
import os
from typing import Any

import boto3
import psycopg2
from psycopg2.extras import RealDictCursor

from ai_verifier import AIVerifier, TARGET_LOCALES

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Locale mapping: short code -> BCP47 format (20 languages)
LOCALE_MAP = {
    'en': 'en-US', 'zh': 'zh-CN', 'es': 'es-ES', 'ja': 'ja-JP',
    'de': 'de-DE', 'fr': 'fr-FR', 'pt': 'pt-BR', 'ko': 'ko-KR',
    'it': 'it-IT', 'ar': 'ar-SA', 'ru': 'ru-RU', 'id': 'id-ID',
    'vi': 'vi-VN', 'hi': 'hi-IN', 'th': 'th-TH', 'pl': 'pl-PL',
    'tr': 'tr-TR', 'nl': 'nl-NL', 'sv': 'sv-SE', 'fa': 'fa-IR'
}

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


def get_ai_verifier() -> AIVerifier:
    """Create AI verifier client using secrets."""
    gemini_secret = get_secret(os.environ['GEMINI_SECRET_ARN'])
    return AIVerifier(api_key=gemini_secret['api_key'])


def fetch_pending_foods(conn, limit: int = 50) -> list[dict]:
    """Fetch pending food suggestions."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, public_id, suggested_name, locale_code
            FROM user_suggested_foods
            WHERE status = 'PENDING'
            ORDER BY created_at ASC
            LIMIT %s
            FOR UPDATE SKIP LOCKED
        """, (limit,))
        return cur.fetchall()


def fetch_pending_ingredients(conn, limit: int = 50) -> list[dict]:
    """Fetch pending ingredient suggestions."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, public_id, suggested_name, ingredient_type, locale_code
            FROM user_suggested_ingredients
            WHERE status = 'PENDING'
            ORDER BY created_at ASC
            LIMIT %s
            FOR UPDATE SKIP LOCKED
        """, (limit,))
        return cur.fetchall()


def is_duplicate_food(conn, name: str) -> dict | None:
    """Check if food already exists in foods_master (search all locales)."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, name, is_verified FROM foods_master
            WHERE EXISTS (
                SELECT 1 FROM jsonb_each_text(name) AS t(locale, value)
                WHERE LOWER(value) = LOWER(%s)
            )
            LIMIT 1
        """, (name,))
        result = cur.fetchone()
        return result


def is_duplicate_ingredient(conn, name: str) -> dict | None:
    """Check if ingredient already exists in autocomplete_items (search all locales)."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, name FROM autocomplete_items
            WHERE type IN ('MAIN_INGREDIENT', 'SECONDARY_INGREDIENT', 'SEASONING')
            AND EXISTS (
                SELECT 1 FROM jsonb_each_text(name) AS t(locale, value)
                WHERE LOWER(value) = LOWER(%s)
            )
            LIMIT 1
        """, (name,))
        result = cur.fetchone()
        return result


def reject_food(conn, food_id: int, reason: str):
    """Mark a food suggestion as rejected with reason."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE user_suggested_foods
            SET status = 'REJECTED', rejection_reason = %s, updated_at = NOW()
            WHERE id = %s
        """, (reason[:500], food_id))
    logger.info(f"Rejected food suggestion {food_id}: {reason}")


def reject_ingredient(conn, ingredient_id: int, reason: str):
    """Mark an ingredient suggestion as rejected with reason."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE user_suggested_ingredients
            SET status = 'REJECTED', rejection_reason = %s, updated_at = NOW()
            WHERE id = %s
        """, (reason[:500], ingredient_id))
    logger.info(f"Rejected ingredient suggestion {ingredient_id}: {reason}")


def create_food_master(conn, translations: dict[str, str], source_locale: str) -> int:
    """Create a new FoodMaster entry with translations."""
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO foods_master (name, is_verified, created_at, updated_at)
            VALUES (%s, TRUE, NOW(), NOW())
            RETURNING id
        """, (json.dumps(translations),))
        result = cur.fetchone()
        return result['id']


def update_food_master_verified(conn, food_id: int, translations: dict[str, str]) -> None:
    """Update existing FoodMaster with translations and mark as verified."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE foods_master
            SET name = %s, is_verified = TRUE, updated_at = NOW()
            WHERE id = %s
        """, (json.dumps(translations), food_id))
    logger.info(f"Updated FoodMaster {food_id} with translations, marked as verified")


def approve_food(conn, food_id: int, food_master_id: int):
    """Mark a food suggestion as approved and link to FoodMaster."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE user_suggested_foods
            SET status = 'APPROVED', master_food_id_ref = %s, updated_at = NOW()
            WHERE id = %s
        """, (food_master_id, food_id))
    logger.info(f"Approved food suggestion {food_id} -> FoodMaster {food_master_id}")


def get_ingredient_type_enum(ingredient_type: str) -> str:
    """Map ingredient type to autocomplete item type enum."""
    mapping = {
        'MAIN': 'MAIN_INGREDIENT',
        'SECONDARY': 'SECONDARY_INGREDIENT',
        'SEASONING': 'SEASONING'
    }
    return mapping.get(ingredient_type, 'MAIN_INGREDIENT')


def create_autocomplete_item(conn, translations: dict[str, str], item_type: str) -> int:
    """Create a new AutocompleteItem entry with translations."""
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO autocomplete_items (name, type, created_at, updated_at)
            VALUES (%s, %s, NOW(), NOW())
            RETURNING id
        """, (json.dumps(translations), item_type))
        result = cur.fetchone()
        return result['id']


def approve_ingredient(conn, ingredient_id: int, autocomplete_item_id: int):
    """Mark an ingredient suggestion as approved and link to AutocompleteItem."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE user_suggested_ingredients
            SET status = 'APPROVED', autocomplete_item_id = %s, updated_at = NOW()
            WHERE id = %s
        """, (autocomplete_item_id, ingredient_id))
    logger.info(f"Approved ingredient {ingredient_id} -> AutocompleteItem {autocomplete_item_id}")


def get_existing_name_for_locale(name_json: dict, existing_name: str) -> str:
    """Get a human-readable name from existing JSONB for rejection message."""
    if isinstance(name_json, dict):
        # Prefer English name if available
        for locale in ['en-US', 'en']:
            if locale in name_json:
                return name_json[locale]
        # Otherwise return first available
        for value in name_json.values():
            if value:
                return value
    return existing_name


def has_all_translations(name_json: dict) -> bool:
    """Check if the name JSONB has all 20 required locale translations."""
    if not isinstance(name_json, dict):
        return False
    for locale in TARGET_LOCALES:
        if locale not in name_json or not name_json[locale]:
            return False
    return True


def process_suggested_foods(conn, verifier: AIVerifier) -> dict:
    """Fetch and process pending food suggestions."""
    stats = {'processed': 0, 'approved': 0, 'rejected': 0, 'errors': 0}

    pending = fetch_pending_foods(conn, limit=50)
    logger.info(f"Found {len(pending)} pending food suggestions")

    for suggestion in pending:
        stats['processed'] += 1
        try:
            suggested_name = suggestion['suggested_name']
            locale_code = suggestion['locale_code']

            # 1. Check for duplicates
            existing = is_duplicate_food(conn, suggested_name)
            if existing:
                # Check if verified AND has all 20 translations
                if existing['is_verified'] and has_all_translations(existing['name']):
                    # Fully complete - reject as true duplicate
                    existing_name = get_existing_name_for_locale(
                        existing['name'], suggested_name
                    )
                    reject_food(conn, suggestion['id'],
                        f"Already exists in database as '{existing_name}'")
                    stats['rejected'] += 1
                    continue
                else:
                    # Either unverified OR missing translations - update with full translations
                    result = verifier.verify_name(
                        name=suggested_name,
                        locale=locale_code,
                        item_type='FOOD'
                    )

                    if not result['is_valid']:
                        reject_food(conn, suggestion['id'], result['rejection_reason'])
                        stats['rejected'] += 1
                        continue

                    canonical_name = result.get('canonical_name', suggested_name)
                    translations = verifier.translate_to_all_locales(
                        name=canonical_name,
                        source_locale=locale_code
                    )

                    update_food_master_verified(conn, existing['id'], translations)
                    approve_food(conn, suggestion['id'], existing['id'])
                    logger.info(f"Updated FoodMaster {existing['id']} with 20 translations")
                    stats['approved'] += 1
                    continue

            # 2. AI verification (for new foods not in database)
            result = verifier.verify_name(
                name=suggested_name,
                locale=locale_code,
                item_type='FOOD'
            )

            if not result['is_valid']:
                reject_food(conn, suggestion['id'], result['rejection_reason'])
                stats['rejected'] += 1
                continue

            # 3. Translate and create FoodMaster
            canonical_name = result.get('canonical_name', suggested_name)
            translations = verifier.translate_to_all_locales(
                name=canonical_name,
                source_locale=locale_code
            )

            food_master_id = create_food_master(conn, translations, locale_code)
            approve_food(conn, suggestion['id'], food_master_id)
            stats['approved'] += 1

        except Exception as e:
            logger.error(f"Error processing food {suggestion['id']}: {e}")
            stats['errors'] += 1
            conn.rollback()  # Recover from transaction error

    conn.commit()
    return stats


def process_suggested_ingredients(conn, verifier: AIVerifier) -> dict:
    """Fetch and process pending ingredient suggestions."""
    stats = {'processed': 0, 'approved': 0, 'rejected': 0, 'errors': 0}

    pending = fetch_pending_ingredients(conn, limit=50)
    logger.info(f"Found {len(pending)} pending ingredient suggestions")

    for suggestion in pending:
        stats['processed'] += 1
        try:
            suggested_name = suggestion['suggested_name']
            ingredient_type = suggestion['ingredient_type']
            locale_code = suggestion['locale_code']

            # 1. Check for duplicates
            existing = is_duplicate_ingredient(conn, suggested_name)
            if existing:
                existing_name = get_existing_name_for_locale(
                    existing['name'], suggested_name
                )
                reject_ingredient(conn, suggestion['id'],
                    f"Already exists in database as '{existing_name}'")
                stats['rejected'] += 1
                continue

            # 2. AI verification
            result = verifier.verify_name(
                name=suggested_name,
                locale=locale_code,
                item_type=ingredient_type
            )

            if not result['is_valid']:
                reject_ingredient(conn, suggestion['id'], result['rejection_reason'])
                stats['rejected'] += 1
                continue

            # 3. Translate and create AutocompleteItem
            canonical_name = result.get('canonical_name', suggested_name)
            translations = verifier.translate_to_all_locales(
                name=canonical_name,
                source_locale=locale_code
            )

            item_type_enum = get_ingredient_type_enum(ingredient_type)
            autocomplete_id = create_autocomplete_item(conn, translations, item_type_enum)
            approve_ingredient(conn, suggestion['id'], autocomplete_id)
            stats['approved'] += 1

        except Exception as e:
            logger.error(f"Error processing ingredient {suggestion['id']}: {e}")
            stats['errors'] += 1
            conn.rollback()  # Recover from transaction error

    conn.commit()
    return stats


def handler(event: dict, context) -> dict:
    """
    Lambda handler - runs daily via EventBridge.
    Processes PENDING suggestions from both tables.
    """
    logger.info(f"Suggestion Verifier Lambda invoked with event: {json.dumps(event)}")

    conn = None
    try:
        conn = get_db_connection()
        verifier = get_ai_verifier()

        # Process suggested foods
        foods_stats = process_suggested_foods(conn, verifier)
        logger.info(f"Foods processing complete: {foods_stats}")

        # Process suggested ingredients
        ingredients_stats = process_suggested_ingredients(conn, verifier)
        logger.info(f"Ingredients processing complete: {ingredients_stats}")

        result = {
            'statusCode': 200,
            'body': json.dumps({
                'foods': foods_stats,
                'ingredients': ingredients_stats,
                'message': (
                    f"Foods: {foods_stats['approved']} approved, {foods_stats['rejected']} rejected. "
                    f"Ingredients: {ingredients_stats['approved']} approved, {ingredients_stats['rejected']} rejected."
                )
            })
        }
        logger.info(f"Suggestion Verifier Lambda completed: {result}")
        return result

    except Exception as e:
        logger.error(f"Suggestion Verifier Lambda error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if conn:
            conn.close()
