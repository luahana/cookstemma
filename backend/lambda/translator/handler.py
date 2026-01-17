"""
Translation Lambda Handler
Processes translation events from the database and uses OpenAI GPT to translate content.
"""
import json
import logging
import os
from typing import Any

import boto3
import psycopg2
from psycopg2.extras import RealDictCursor

from openai_translator import OpenAITranslator

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


def run_bot_system_migrations(conn):
    """Create bot_personas and bot_api_keys tables (V5 migration)."""
    with conn.cursor() as cur:
        logger.info("Creating bot system enums...")

        # Create enums
        cur.execute("""
            DO $$ BEGIN
                CREATE TYPE bot_tone AS ENUM (
                    'professional', 'casual', 'warm', 'enthusiastic', 'educational', 'motivational'
                );
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        cur.execute("""
            DO $$ BEGIN
                CREATE TYPE bot_skill_level AS ENUM ('professional', 'intermediate', 'beginner', 'home_cook');
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        cur.execute("""
            DO $$ BEGIN
                CREATE TYPE bot_vocabulary_style AS ENUM ('technical', 'simple', 'conversational');
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)

        logger.info("Creating bot_personas table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS bot_personas (
                id              BIGSERIAL PRIMARY KEY,
                public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
                name            VARCHAR(50) NOT NULL UNIQUE,
                display_name    JSONB NOT NULL DEFAULT '{}'::jsonb,
                tone            bot_tone NOT NULL,
                skill_level     bot_skill_level NOT NULL,
                dietary_focus   VARCHAR(50),
                vocabulary_style bot_vocabulary_style NOT NULL,
                locale          VARCHAR(10) NOT NULL,
                culinary_locale VARCHAR(10) NOT NULL,
                kitchen_style_prompt TEXT NOT NULL,
                is_active       BOOLEAN NOT NULL DEFAULT TRUE,
                created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_by_id   BIGINT REFERENCES users(id)
            )
        """)

        # Add persona_id to users if not exists
        cur.execute("""
            ALTER TABLE users ADD COLUMN IF NOT EXISTS persona_id BIGINT REFERENCES bot_personas(id) ON DELETE SET NULL
        """)
        cur.execute("""
            ALTER TABLE users ADD COLUMN IF NOT EXISTS is_bot BOOLEAN DEFAULT FALSE
        """)

        logger.info("Creating bot_api_keys table...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS bot_api_keys (
                id              BIGSERIAL PRIMARY KEY,
                public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
                bot_user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                key_prefix      VARCHAR(8) NOT NULL,
                key_hash        VARCHAR(64) NOT NULL UNIQUE,
                name            VARCHAR(100) NOT NULL,
                is_active       BOOLEAN NOT NULL DEFAULT TRUE,
                last_used_at    TIMESTAMPTZ,
                expires_at      TIMESTAMPTZ,
                created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
        """)

        # Create indexes
        cur.execute("CREATE INDEX IF NOT EXISTS idx_bot_personas_name ON bot_personas(name)")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_bot_api_keys_hash ON bot_api_keys(key_hash)")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_bot_api_keys_bot_user ON bot_api_keys(bot_user_id)")
        cur.execute("CREATE INDEX IF NOT EXISTS idx_users_persona ON users(persona_id) WHERE persona_id IS NOT NULL")

        conn.commit()
        logger.info("V5 bot system migrations completed successfully")


def run_migrations(conn):
    """Run database migrations if tables don't exist."""
    with conn.cursor() as cur:
        # Check if bot_api_keys table exists (V5 migration)
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = 'bot_api_keys'
            )
        """)
        if not cur.fetchone()['exists']:
            logger.info("Running V5 bot system migrations...")
            run_bot_system_migrations(conn)

        # Check if translation_events table exists
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = 'translation_events'
            )
        """)
        if cur.fetchone()['exists']:
            logger.info("translation_events table already exists")
            return

        logger.info("Running V8 translation migrations...")

        # Create enums if they don't exist
        cur.execute("""
            DO $$ BEGIN
                CREATE TYPE translation_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        cur.execute("""
            DO $$ BEGIN
                CREATE TYPE translatable_entity AS ENUM ('RECIPE', 'RECIPE_STEP', 'RECIPE_INGREDIENT', 'LOG_POST');
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)

        # Add translation columns to tables
        migration_sql = """
        -- RECIPES
        ALTER TABLE recipes ADD COLUMN IF NOT EXISTS title_translations JSONB DEFAULT '{}';
        ALTER TABLE recipes ADD COLUMN IF NOT EXISTS description_translations JSONB DEFAULT '{}';

        -- RECIPE STEPS
        ALTER TABLE recipe_steps ADD COLUMN IF NOT EXISTS description_translations JSONB DEFAULT '{}';

        -- RECIPE INGREDIENTS
        ALTER TABLE recipe_ingredients ADD COLUMN IF NOT EXISTS name_translations JSONB DEFAULT '{}';

        -- LOG POSTS
        ALTER TABLE log_posts ADD COLUMN IF NOT EXISTS title_translations JSONB DEFAULT '{}';
        ALTER TABLE log_posts ADD COLUMN IF NOT EXISTS content_translations JSONB DEFAULT '{}';

        -- TRANSLATION EVENTS TABLE
        CREATE TABLE IF NOT EXISTS translation_events (
            id              BIGSERIAL PRIMARY KEY,
            public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
            entity_type     translatable_entity NOT NULL,
            entity_id       BIGINT NOT NULL,
            source_locale   VARCHAR(5) NOT NULL,
            status          translation_status NOT NULL DEFAULT 'PENDING',
            target_locales  JSONB NOT NULL,
            completed_locales JSONB DEFAULT '[]',
            retry_count     INTEGER NOT NULL DEFAULT 0,
            last_error      TEXT,
            created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            started_at      TIMESTAMPTZ,
            completed_at    TIMESTAMPTZ
        );

        -- Indexes
        CREATE INDEX IF NOT EXISTS idx_translation_events_pending ON translation_events(status, created_at)
            WHERE status IN ('PENDING', 'FAILED');
        CREATE INDEX IF NOT EXISTS idx_translation_events_entity ON translation_events(entity_type, entity_id);
        """
        cur.execute(migration_sql)
        conn.commit()
        logger.info("V8 translations migrations completed successfully")


def get_openai_client() -> OpenAITranslator:
    """Create OpenAI translator client using secrets."""
    openai_secret = get_secret(os.environ['OPENAI_SECRET_ARN'])
    return OpenAITranslator(api_key=openai_secret['api_key'])


def fetch_pending_events(conn, limit: int = 10) -> list[dict]:
    """Fetch pending or retryable translation events."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, entity_type, entity_id, source_locale, target_locales, completed_locales
            FROM translation_events
            WHERE status = 'PENDING'
               OR (status = 'FAILED' AND retry_count < 3)
            ORDER BY created_at ASC
            LIMIT %s
            FOR UPDATE SKIP LOCKED
        """, (limit,))
        return cur.fetchall()


def mark_event_processing(conn, event_id: int):
    """Mark event as processing."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE translation_events
            SET status = 'PROCESSING', started_at = NOW()
            WHERE id = %s
        """, (event_id,))


def mark_event_completed(conn, event_id: int):
    """Mark event as completed."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE translation_events
            SET status = 'COMPLETED', completed_at = NOW()
            WHERE id = %s
        """, (event_id,))


def mark_event_failed(conn, event_id: int, error: str):
    """Mark event as failed with error."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE translation_events
            SET status = 'FAILED', last_error = %s, retry_count = retry_count + 1
            WHERE id = %s
        """, (error[:500], event_id))


def update_completed_locales(conn, event_id: int, completed_locales: list[str]):
    """Update completed locales for an event."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE translation_events
            SET completed_locales = %s
            WHERE id = %s
        """, (json.dumps(completed_locales), event_id))


def fetch_entity_content(conn, entity_type: str, entity_id: int) -> dict | None:
    """Fetch content to translate based on entity type."""
    with conn.cursor() as cur:
        if entity_type == 'RECIPE':
            cur.execute("""
                SELECT id, title, description, title_translations, description_translations
                FROM recipes WHERE id = %s
            """, (entity_id,))
        elif entity_type == 'RECIPE_STEP':
            cur.execute("""
                SELECT id, description, description_translations
                FROM recipe_steps WHERE id = %s
            """, (entity_id,))
        elif entity_type == 'RECIPE_INGREDIENT':
            cur.execute("""
                SELECT id, name, name_translations
                FROM recipe_ingredients WHERE id = %s
            """, (entity_id,))
        elif entity_type == 'LOG_POST':
            cur.execute("""
                SELECT id, title, content, title_translations, content_translations
                FROM log_posts WHERE id = %s
            """, (entity_id,))
        else:
            return None

        return cur.fetchone()


def save_translations(conn, entity_type: str, entity_id: int, translations: dict):
    """Save translations back to the entity."""
    with conn.cursor() as cur:
        if entity_type == 'RECIPE':
            cur.execute("""
                UPDATE recipes
                SET title_translations = %s, description_translations = %s
                WHERE id = %s
            """, (
                json.dumps(translations.get('title', {})),
                json.dumps(translations.get('description', {})),
                entity_id
            ))
        elif entity_type == 'RECIPE_STEP':
            cur.execute("""
                UPDATE recipe_steps
                SET description_translations = %s
                WHERE id = %s
            """, (json.dumps(translations.get('description', {})), entity_id))
        elif entity_type == 'RECIPE_INGREDIENT':
            cur.execute("""
                UPDATE recipe_ingredients
                SET name_translations = %s
                WHERE id = %s
            """, (json.dumps(translations.get('name', {})), entity_id))
        elif entity_type == 'LOG_POST':
            cur.execute("""
                UPDATE log_posts
                SET title_translations = %s, content_translations = %s
                WHERE id = %s
            """, (
                json.dumps(translations.get('title', {})),
                json.dumps(translations.get('content', {})),
                entity_id
            ))


def process_event(conn, translator: OpenAITranslator, event: dict) -> bool:
    """Process a single translation event."""
    entity_type = event['entity_type']
    entity_id = event['entity_id']
    source_locale = event['source_locale']
    target_locales = event['target_locales'] or []
    completed_locales = event['completed_locales'] or []

    # Filter out already completed locales
    pending_locales = [loc for loc in target_locales if loc not in completed_locales]

    if not pending_locales:
        return True

    # Fetch entity content
    entity = fetch_entity_content(conn, entity_type, entity_id)
    if not entity:
        logger.warning(f"Entity not found: {entity_type}:{entity_id}")
        return False

    # Prepare content for translation
    content_to_translate = {}
    existing_translations = {}

    if entity_type == 'RECIPE':
        content_to_translate = {
            'title': entity['title'],
            'description': entity['description'] or ''
        }
        existing_translations = {
            'title': entity['title_translations'] or {},
            'description': entity['description_translations'] or {}
        }
    elif entity_type == 'RECIPE_STEP':
        content_to_translate = {'description': entity['description']}
        existing_translations = {'description': entity['description_translations'] or {}}
    elif entity_type == 'RECIPE_INGREDIENT':
        content_to_translate = {'name': entity['name']}
        existing_translations = {'name': entity['name_translations'] or {}}
    elif entity_type == 'LOG_POST':
        content_to_translate = {
            'title': entity['title'] or '',
            'content': entity['content'] or ''
        }
        existing_translations = {
            'title': entity['title_translations'] or {},
            'content': entity['content_translations'] or {}
        }

    # Translate to each pending locale
    new_completed = list(completed_locales)

    for target_locale in pending_locales:
        try:
            translated = translator.translate_content(
                content=content_to_translate,
                source_locale=source_locale,
                target_locale=target_locale,
                context=f"cooking recipe {'step' if entity_type == 'RECIPE_STEP' else 'content'}"
            )

            # Merge translations
            for field, value in translated.items():
                if field not in existing_translations:
                    existing_translations[field] = {}
                existing_translations[field][target_locale] = value

            new_completed.append(target_locale)
            logger.info(f"Translated {entity_type}:{entity_id} to {target_locale}")

        except Exception as e:
            logger.error(f"Failed to translate {entity_type}:{entity_id} to {target_locale}: {e}")
            # Continue with other locales

    # Save all translations
    save_translations(conn, entity_type, entity_id, existing_translations)

    # Update completed locales
    update_completed_locales(conn, event['id'], new_completed)

    # Return True if all locales are done
    return set(new_completed) >= set(target_locales)


def handler(event: dict, context) -> dict:
    """
    Lambda handler for translation processing.

    Can be triggered by:
    - Scheduled EventBridge rule (batch processing)
    - SQS message (specific event processing)
    """
    logger.info(f"Translation Lambda invoked with event: {json.dumps(event)}")

    conn = None
    try:
        conn = get_db_connection()

        # Run migrations if needed (creates translation tables)
        run_migrations(conn)

        translator = get_openai_client()

        # Test mode: create and process a test translation
        if event.get('test_mode'):
            logger.info("Running in test mode")
            test_content = event.get('test_content', {
                'title': 'Delicious Korean Bibimbap',
                'description': 'A colorful rice bowl with vegetables and gochujang sauce.'
            })
            test_source = event.get('test_source_locale', 'en')
            test_target = event.get('test_target_locale', 'ko')

            try:
                translated = translator.translate_content(
                    content=test_content,
                    source_locale=test_source,
                    target_locale=test_target,
                    context="cooking recipe content"
                )
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'test_mode': True,
                        'source_locale': test_source,
                        'target_locale': test_target,
                        'original': test_content,
                        'translated': translated
                    })
                }
            except Exception as e:
                logger.error(f"Test translation failed: {e}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({'error': str(e), 'test_mode': True})
                }

        # Check if this is an SQS trigger with specific event IDs
        event_ids = []
        if 'Records' in event:
            for record in event['Records']:
                body = json.loads(record['body'])
                if 'event_id' in body:
                    event_ids.append(body['event_id'])

        processed = 0
        failed = 0

        if event_ids:
            # Process specific events from SQS
            for event_id in event_ids:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT id, entity_type, entity_id, source_locale, target_locales, completed_locales
                        FROM translation_events
                        WHERE id = %s
                        FOR UPDATE
                    """, (event_id,))
                    translation_event = cur.fetchone()

                if translation_event:
                    mark_event_processing(conn, event_id)
                    conn.commit()

                    try:
                        success = process_event(conn, translator, translation_event)
                        if success:
                            mark_event_completed(conn, event_id)
                            processed += 1
                        else:
                            mark_event_failed(conn, event_id, "Partial translation failure")
                            failed += 1
                    except Exception as e:
                        mark_event_failed(conn, event_id, str(e))
                        failed += 1

                    conn.commit()
        else:
            # Batch processing - fetch pending events
            events = fetch_pending_events(conn, limit=10)

            for translation_event in events:
                event_id = translation_event['id']
                mark_event_processing(conn, event_id)
                conn.commit()

                try:
                    success = process_event(conn, translator, translation_event)
                    if success:
                        mark_event_completed(conn, event_id)
                        processed += 1
                    else:
                        mark_event_failed(conn, event_id, "Partial translation failure")
                        failed += 1
                except Exception as e:
                    logger.error(f"Error processing event {event_id}: {e}")
                    mark_event_failed(conn, event_id, str(e))
                    failed += 1

                conn.commit()

        result = {
            'statusCode': 200,
            'body': json.dumps({
                'processed': processed,
                'failed': failed,
                'message': f'Processed {processed} translations, {failed} failed'
            })
        }
        logger.info(f"Translation Lambda completed: {result}")
        return result

    except Exception as e:
        logger.error(f"Translation Lambda error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if conn:
            conn.close()
