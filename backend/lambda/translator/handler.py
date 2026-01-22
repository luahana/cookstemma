"""
Translation Lambda Handler
Processes translation events from the database and uses Google Gemini to translate content.
"""
import json
import logging
import os
from typing import Any

import boto3
import psycopg2
from psycopg2.extras import RealDictCursor

from gemini_translator import GeminiTranslator

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


def to_bcp47(locale: str) -> str:
    """
    Convert locale to BCP47 format.
    If already BCP47, returns as-is. If short code, converts to BCP47.

    Examples:
        'ko' -> 'ko-KR'
        'ko-KR' -> 'ko-KR'
        'en' -> 'en-US'
    """
    if not locale:
        return 'en-US'

    # Already BCP47 format
    if '-' in locale:
        return locale

    # Convert short code to BCP47
    return LOCALE_MAP.get(locale, f"{locale}-{locale.upper()}")

# Map RecipeIngredient.type to AutocompleteItem.type
INGREDIENT_TO_AUTOCOMPLETE_TYPE = {
    'MAIN': 'MAIN_INGREDIENT',
    'SECONDARY': 'SECONDARY_INGREDIENT',
    'SEASONING': 'SEASONING'
}

# CDN URL prefix for image URLs (set via environment variable)
CDN_URL_PREFIX = os.environ.get('CDN_URL_PREFIX', '')


def map_ingredient_to_autocomplete_type(ingredient_type: str | None) -> str | None:
    """Map RecipeIngredient.type to AutocompleteItem.type for propagation."""
    if not ingredient_type:
        return None
    return INGREDIENT_TO_AUTOCOMPLETE_TYPE.get(ingredient_type)


def fetch_recipe_image_urls(conn, recipe_id: int, limit: int = 3) -> list[str]:
    """
    Fetch image URLs for a recipe for content moderation.
    Returns up to `limit` image URLs (default 3 for moderation efficiency).
    """
    if not CDN_URL_PREFIX:
        logger.warning("CDN_URL_PREFIX not set, skipping image moderation")
        return []

    with conn.cursor() as cur:
        # Fetch cover images via recipe_image_map join table
        cur.execute("""
            SELECT i.stored_filename
            FROM recipe_image_map rim
            JOIN images i ON rim.image_id = i.id
            WHERE rim.recipe_id = %s
              AND i.status = 'ACTIVE'
              AND i.deleted_at IS NULL
              AND i.variant_type IS NULL
            ORDER BY rim.display_order
            LIMIT %s
        """, (recipe_id, limit))
        images = cur.fetchall()

    return [f"{CDN_URL_PREFIX}/{img['stored_filename']}" for img in images if img['stored_filename']]


def fetch_log_post_image_urls(conn, log_post_id: int, limit: int = 3) -> list[str]:
    """
    Fetch image URLs for a log post for content moderation.
    Returns up to `limit` image URLs (default 3 for moderation efficiency).
    """
    if not CDN_URL_PREFIX:
        logger.warning("CDN_URL_PREFIX not set, skipping image moderation")
        return []

    with conn.cursor() as cur:
        cur.execute("""
            SELECT stored_filename
            FROM images
            WHERE log_post_id = %s
              AND status = 'READY'
              AND deleted_at IS NULL
              AND variant_type IS NULL
            ORDER BY display_order
            LIMIT %s
        """, (log_post_id, limit))
        images = cur.fetchall()

    return [f"{CDN_URL_PREFIX}/{img['stored_filename']}" for img in images if img['stored_filename']]


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
                CREATE TYPE translatable_entity AS ENUM ('RECIPE', 'RECIPE_STEP', 'RECIPE_INGREDIENT', 'RECIPE_FULL', 'LOG_POST', 'FOOD_MASTER', 'AUTOCOMPLETE_ITEM');
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        # Add RECIPE_FULL to existing enum if it doesn't exist
        cur.execute("""
            DO $$ BEGIN
                ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'RECIPE_FULL';
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        # Add FOOD_MASTER, AUTOCOMPLETE_ITEM, and USER to existing enum if they don't exist
        cur.execute("""
            DO $$ BEGIN
                ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'FOOD_MASTER';
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        cur.execute("""
            DO $$ BEGIN
                ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'AUTOCOMPLETE_ITEM';
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        cur.execute("""
            DO $$ BEGIN
                ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'USER';
            EXCEPTION WHEN duplicate_object THEN null;
            END $$
        """)
        cur.execute("""
            DO $$ BEGIN
                ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'COMMENT';
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

        -- COMMENTS
        ALTER TABLE comments ADD COLUMN IF NOT EXISTS content_translations JSONB DEFAULT '{}';
        ALTER TABLE comments ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT FALSE;
        ALTER TABLE comments ADD COLUMN IF NOT EXISTS hidden_reason TEXT;

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

        -- Composite index for efficient duplicate detection (isTranslationPending query)
        CREATE INDEX IF NOT EXISTS idx_translation_events_entity_status
            ON translation_events(entity_type, entity_id, status);
        """
        cur.execute(migration_sql)
        conn.commit()
        logger.info("V8 translations migrations completed successfully")


def get_gemini_client() -> GeminiTranslator:
    """Create Gemini translator client using secrets."""
    gemini_secret = get_secret(os.environ['GEMINI_SECRET_ARN'])
    return GeminiTranslator(api_key=gemini_secret['api_key'])


def fetch_pending_events(conn, limit: int = 10) -> list[dict]:
    """
    Fetch pending or retryable translation events.

    Includes:
    - PENDING events
    - FAILED events with retry_count < 3
    - PROCESSING events stuck for >3 minutes (likely from crashed Lambda)
    """
    with conn.cursor() as cur:
        cur.execute("""
            SELECT id, entity_type, entity_id, source_locale, target_locales, completed_locales, status, started_at
            FROM translation_events
            WHERE status = 'PENDING'
               OR (status = 'FAILED' AND retry_count < 3)
               OR (status = 'PROCESSING' AND started_at < NOW() - INTERVAL '3 minutes')
            ORDER BY created_at ASC
            LIMIT %s
            FOR UPDATE SKIP LOCKED
        """, (limit,))
        events = cur.fetchall()

        # Log if we're recovering stuck PROCESSING events
        for event in events:
            if event.get('status') == 'PROCESSING':
                logger.warning(f"Recovering stuck PROCESSING event {event['id']} "
                              f"(entity_type: {event['entity_type']}, entity_id: {event['entity_id']}, "
                              f"started_at: {event.get('started_at')})")

        return events


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
        elif entity_type == 'FOOD_MASTER':
            cur.execute("""
                SELECT id, name, description
                FROM foods_master WHERE id = %s
            """, (entity_id,))
        elif entity_type == 'AUTOCOMPLETE_ITEM':
            cur.execute("""
                SELECT id, name
                FROM autocomplete_items WHERE id = %s
            """, (entity_id,))
        elif entity_type == 'USER':
            cur.execute("""
                SELECT id, bio, bio_translations
                FROM users WHERE id = %s
            """, (entity_id,))
        elif entity_type == 'COMMENT':
            cur.execute("""
                SELECT c.id, c.content, c.content_translations, c.creator_id,
                       u.locale as creator_locale
                FROM comments c
                JOIN users u ON c.creator_id = u.id
                WHERE c.id = %s AND c.deleted_at IS NULL AND c.is_hidden = FALSE
            """, (entity_id,))
        else:
            return None

        return cur.fetchone()


def fetch_full_recipe(conn, recipe_id: int, source_locale: str) -> dict | None:
    """
    Fetch recipe with FoodMaster, steps, and ingredients for context-aware translation.
    Includes FoodMaster name and ingredient types for propagation to master tables.
    """
    # Convert source locale to BCP47 for FoodMaster lookup
    source_bcp47 = LOCALE_MAP.get(source_locale, f"{source_locale}-{source_locale.upper()}")

    with conn.cursor() as cur:
        # Fetch recipe with FoodMaster
        cur.execute("""
            SELECT r.id, r.title, r.description, r.title_translations, r.description_translations,
                   r.food_master_id,
                   fm.id as fm_id, fm.name as fm_name
            FROM recipes r
            LEFT JOIN foods_master fm ON r.food_master_id = fm.id
            WHERE r.id = %s
        """, (recipe_id,))
        recipe = cur.fetchone()

        if not recipe:
            return None

        # Fetch steps
        cur.execute("""
            SELECT id, step_number, description, description_translations
            FROM recipe_steps WHERE recipe_id = %s
            ORDER BY step_number
        """, (recipe_id,))
        steps = cur.fetchall()

        # Fetch ingredients WITH TYPE for autocomplete matching
        cur.execute("""
            SELECT id, name, display_order, name_translations, type
            FROM recipe_ingredients WHERE recipe_id = %s
            ORDER BY display_order
        """, (recipe_id,))
        ingredients = cur.fetchall()

    # Extract FoodMaster source name from JSONB
    fm_name_json = recipe['fm_name'] or {}
    fm_source_name = fm_name_json.get(source_bcp47) or fm_name_json.get(source_locale)
    if not fm_source_name and fm_name_json:
        # Fallback: use first available name
        fm_source_name = next(iter(fm_name_json.values()), '')

    return {
        'recipe': recipe,
        'food_master': {
            'id': recipe['fm_id'],
            'name': fm_source_name or '',
            'name_json': fm_name_json
        },
        'steps': steps,
        'ingredients': ingredients,  # Now includes 'type' field
        'source_bcp47': source_bcp47
    }


def save_full_recipe_translations(conn, recipe_id: int, full_recipe: dict,
                                   translated: dict, target_locale: str):
    """
    Save translations for recipe, steps, ingredients AND propagate to master tables.
    - FoodMaster name is propagated from food_name translation
    - AutocompleteItem names are propagated from ingredient translations (matched by name + type)
    - All translation keys use BCP47 format for consistency
    """
    # Convert locale to BCP47 for ALL translation keys (standardized format)
    target_bcp47 = to_bcp47(target_locale)
    source_bcp47 = full_recipe.get('source_bcp47', 'ko-KR')

    with conn.cursor() as cur:
        # 1. Update recipe title and description (use BCP47 keys)
        # STRICT: No fallbacks - fail if translation missing
        if 'title' not in translated or not translated['title']:
            raise ValueError(f"Translation missing required 'title' for locale {target_locale}")
        if 'description' not in translated:
            raise ValueError(f"Translation missing 'description' for locale {target_locale}")

        existing_title = full_recipe['recipe']['title_translations'] or {}
        existing_desc = full_recipe['recipe']['description_translations'] or {}

        existing_title[target_bcp47] = translated['title']
        existing_desc[target_bcp47] = translated['description']  # Can be empty string

        cur.execute("""
            UPDATE recipes
            SET title_translations = %s,
                description_translations = %s
            WHERE id = %s
        """, (
            json.dumps(existing_title),
            json.dumps(existing_desc),
            recipe_id
        ))

        if cur.rowcount == 0:
            raise ValueError(f"Recipe {recipe_id} not found - UPDATE affected 0 rows")

        # 2. Propagate FoodMaster name translation
        food_master = full_recipe.get('food_master', {})
        translated_food_name = translated.get('food_name')
        if translated_food_name and food_master.get('id'):
            cur.execute("""
                UPDATE foods_master
                SET name = name || %s
                WHERE id = %s
            """, (
                json.dumps({target_bcp47: translated_food_name}),
                food_master['id']
            ))
            logger.info(f"Propagated food_name translation to FoodMaster {food_master['id']} ({target_bcp47})")

        # 3. Update each step (use BCP47 keys)
        # STRICT: Verify steps exist and match count
        if 'steps' not in translated:
            raise ValueError(f"Translation missing required 'steps' for locale {target_locale}")
        translated_steps = translated['steps']
        if len(translated_steps) != len(full_recipe['steps']):
            raise ValueError(f"Step count mismatch: expected {len(full_recipe['steps'])}, got {len(translated_steps)}")

        steps_updated = 0
        for i, step in enumerate(full_recipe['steps']):
            if not translated_steps[i]:
                raise ValueError(f"Step {i} translation is empty for locale {target_locale}")

            existing_step_trans = step['description_translations'] or {}
            existing_step_trans[target_bcp47] = translated_steps[i]
            cur.execute("""
                UPDATE recipe_steps
                SET description_translations = %s
                WHERE id = %s
            """, (json.dumps(existing_step_trans), step['id']))

            if cur.rowcount > 0:
                steps_updated += 1
            else:
                raise ValueError(f"Step {step['id']} not found in database")

        logger.info(f"Updated {steps_updated}/{len(full_recipe['steps'])} steps for recipe {recipe_id}")

        # 4. Update each ingredient + propagate to autocomplete_items (use BCP47 keys)
        # STRICT: Verify ingredients exist and match count
        if 'ingredients' not in translated:
            raise ValueError(f"Translation missing required 'ingredients' for locale {target_locale}")
        translated_ingredients = translated['ingredients']
        if len(translated_ingredients) != len(full_recipe['ingredients']):
            raise ValueError(f"Ingredient count mismatch: expected {len(full_recipe['ingredients'])}, got {len(translated_ingredients)}")

        ingredients_updated = 0
        for i, ingredient in enumerate(full_recipe['ingredients']):
            translated_name = translated_ingredients[i]
            if not translated_name:
                raise ValueError(f"Ingredient {i} translation is empty for locale {target_locale}")

            existing_ing_trans = ingredient['name_translations'] or {}
            existing_ing_trans[target_bcp47] = translated_name

            # Update recipe_ingredients
            cur.execute("""
                UPDATE recipe_ingredients
                SET name_translations = %s
                WHERE id = %s
            """, (json.dumps(existing_ing_trans), ingredient['id']))

            if cur.rowcount > 0:
                ingredients_updated += 1
            else:
                raise ValueError(f"Ingredient {ingredient['id']} not found in database")

            # Propagate to autocomplete_items (match by exact name + type)
            autocomplete_type = map_ingredient_to_autocomplete_type(ingredient.get('type'))
            if autocomplete_type and ingredient.get('name'):
                # Match ingredient by original name (case-insensitive) and type
                cur.execute("""
                    UPDATE autocomplete_items
                    SET name = name || %s
                    WHERE type::text = %s
                      AND LOWER(name ->> %s) = LOWER(%s)
                """, (
                    json.dumps({target_bcp47: translated_name}),
                    autocomplete_type,
                    source_bcp47,
                    ingredient['name']
                ))
                if cur.rowcount > 0:
                    logger.info(f"Propagated ingredient translation to AutocompleteItem: "
                                f"'{ingredient['name']}' -> '{translated_name}' ({target_bcp47})")

        logger.info(f"Updated {ingredients_updated}/{len(full_recipe['ingredients'])} ingredients for recipe {recipe_id}")


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
        elif entity_type == 'FOOD_MASTER':
            # Merge new translations into existing JSONB name and description
            cur.execute("""
                UPDATE foods_master
                SET name = name || %s,
                    description = COALESCE(description, '{}'::jsonb) || %s
                WHERE id = %s
            """, (
                json.dumps(translations.get('name', {})),
                json.dumps(translations.get('description', {})),
                entity_id
            ))
        elif entity_type == 'AUTOCOMPLETE_ITEM':
            # Merge new translations into existing JSONB name
            cur.execute("""
                UPDATE autocomplete_items
                SET name = name || %s
                WHERE id = %s
            """, (json.dumps(translations.get('name', {})), entity_id))
        elif entity_type == 'USER':
            cur.execute("""
                UPDATE users
                SET bio_translations = %s
                WHERE id = %s
            """, (json.dumps(translations.get('bio', {})), entity_id))
        elif entity_type == 'COMMENT':
            cur.execute("""
                UPDATE comments
                SET content_translations = %s
                WHERE id = %s
            """, (json.dumps(translations.get('content', {})), entity_id))


class ModerationFailure(Exception):
    """Exception raised when content fails moderation check."""
    def __init__(self, reason: str):
        self.reason = reason
        super().__init__(f"Content moderation failed: {reason}")


def hide_comment(conn, comment_id: int, reason: str):
    """Hide a comment that failed content moderation."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE comments
            SET is_hidden = TRUE, hidden_reason = %s
            WHERE id = %s
        """, (reason[:500], comment_id))
    logger.info(f"Comment {comment_id} hidden due to moderation failure: {reason[:100]}")


def process_full_recipe_event(conn, translator: GeminiTranslator, event: dict,
                               entity_id: int, source_locale: str,
                               pending_locales: list, completed_locales: list,
                               target_locales: list) -> bool:
    """
    Process RECIPE_FULL entity type - translates entire recipe with context.
    This provides better quality translations by giving Gemini the full context
    of title, description, food_name, all steps, and all ingredients in a single API call.
    Also propagates translations to FoodMaster and AutocompleteItem for free.

    IMPORTANT: Content and images are validated BEFORE translation.
    If validation fails, the translation is skipped and marked as failed.
    """
    # Fetch full recipe with FoodMaster, steps, and ingredients (with types)
    full_recipe = fetch_full_recipe(conn, entity_id, source_locale)
    if not full_recipe:
        logger.warning(f"Recipe not found: {entity_id}")
        return False

    recipe = full_recipe['recipe']
    food_master = full_recipe.get('food_master', {})
    steps = full_recipe['steps']
    ingredients = full_recipe['ingredients']

    logger.info(f"Translating full recipe {entity_id}: '{recipe['title']}' "
                f"(food: '{food_master.get('name', 'N/A')}', "
                f"{len(steps)} steps, {len(ingredients)} ingredients)")

    # Debug logging for locale verification
    logger.info(f"Recipe {entity_id} source locale: {source_locale}, "
                f"cookingStyle from DB: {recipe.get('cooking_style', 'N/A')}")

    # Build content for batch translation (includes food_name for FoodMaster propagation)
    content_to_translate = {
        'title': recipe['title'],
        'description': recipe['description'] or '',
        'food_name': food_master.get('name', ''),
        'steps': [s['description'] for s in steps],
        'ingredients': [i['name'] for i in ingredients]
    }

    # =============================================================================
    # CONTENT MODERATION: Validate text content and images BEFORE translation
    # =============================================================================
    logger.info(f"Validating recipe {entity_id} content before translation...")

    # 1. Validate text content
    text_result = translator.moderate_recipe_content(
        title=content_to_translate['title'],
        description=content_to_translate['description'],
        steps=content_to_translate['steps'],
        ingredients=content_to_translate['ingredients'],
        food_name=content_to_translate['food_name']
    )
    if not text_result:
        logger.warning(f"Recipe {entity_id} text content failed moderation: {text_result.reason}")
        raise ModerationFailure(f"Text content inappropriate: {text_result.reason}")

    # 2. Validate images
    image_urls = fetch_recipe_image_urls(conn, entity_id, limit=3)
    for image_url in image_urls:
        image_result = translator.moderate_image(image_url)
        if not image_result:
            logger.warning(f"Recipe {entity_id} image failed moderation ({image_url}): {image_result.reason}")
            raise ModerationFailure(f"Image inappropriate: {image_result.reason}")

    logger.info(f"Recipe {entity_id} passed content moderation (text + {len(image_urls)} images)")
    # =============================================================================

    new_completed = list(completed_locales)
    failed_locales = []

    logger.info(f"Recipe {entity_id}: Starting translation for {len(pending_locales)} locales: {pending_locales}")
    logger.info(f"Recipe {entity_id}: Initial completed_locales: {completed_locales}")

    for target_locale in pending_locales:
        logger.info(f"Recipe {entity_id}: Attempting translation to {target_locale}")
        try:
            # Use batch translation for full recipe context
            translated = translator.translate_recipe_batch(
                content=content_to_translate,
                source_locale=source_locale,
                target_locale=target_locale
            )
            logger.info(f"Recipe {entity_id}: translate_recipe_batch succeeded for {target_locale}")

            # Validate translation completeness
            if not translated.get('title') or not translated.get('steps') or not translated.get('ingredients'):
                raise ValueError(f"Incomplete translation: missing title, steps, or ingredients")

            expected_steps = len(content_to_translate.get('steps', []))
            expected_ingredients = len(content_to_translate.get('ingredients', []))
            actual_steps = len(translated.get('steps', []))
            actual_ingredients = len(translated.get('ingredients', []))

            if actual_steps != expected_steps:
                raise ValueError(f"Translation step count mismatch: expected {expected_steps}, got {actual_steps}")
            if actual_ingredients != expected_ingredients:
                raise ValueError(f"Translation ingredient count mismatch: expected {expected_ingredients}, got {actual_ingredients}")

            # Save all translations (recipe, steps, ingredients)
            # + propagate to FoodMaster and AutocompleteItem
            logger.info(f"Recipe {entity_id}: Calling save_full_recipe_translations for {target_locale}")
            save_full_recipe_translations(
                conn, entity_id, full_recipe, translated, target_locale
            )
            logger.info(f"Recipe {entity_id}: save_full_recipe_translations succeeded for {target_locale}")

            new_completed.append(target_locale)
            logger.info(f"Recipe {entity_id}: Added {target_locale} to new_completed. Current count: {len(new_completed)}")

        except Exception as e:
            failed_locales.append(target_locale)
            logger.error(f"Recipe {entity_id}: FAILED to translate to {target_locale}: {e}", exc_info=True)
            # Continue with other locales

    # Update completed locales
    logger.info(f"Recipe {entity_id}: Final new_completed ({len(new_completed)} locales): {new_completed}")
    logger.info(f"Recipe {entity_id}: Failed locales ({len(failed_locales)}): {failed_locales}")
    update_completed_locales(conn, event['id'], new_completed)

    # Log summary of translation results
    if failed_locales:
        logger.warning(f"Recipe {entity_id} translation summary: "
                      f"Completed {len(new_completed)}/{len(target_locales)} languages. "
                      f"Failed: {', '.join(failed_locales)}")
    else:
        logger.info(f"Recipe {entity_id} successfully translated to all {len(new_completed)} languages")

    # Return True if all locales are done
    return set(new_completed) >= set(target_locales)


def process_event(conn, translator: GeminiTranslator, event: dict) -> bool:
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

    # Special handling for RECIPE_FULL - translates entire recipe with context
    if entity_type == 'RECIPE_FULL':
        return process_full_recipe_event(
            conn, translator, event, entity_id, source_locale,
            pending_locales, completed_locales, target_locales
        )

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
    elif entity_type == 'FOOD_MASTER':
        # FoodMaster stores translations directly in name/description JSONB
        name_json = entity['name'] or {}
        description_json = entity['description'] or {}

        # Convert source_locale to BCP47 format to find source content
        source_bcp47 = LOCALE_MAP.get(source_locale, f"{source_locale}-{source_locale.upper()}")

        # Extract source name from JSONB
        source_name = name_json.get(source_bcp47) or name_json.get(source_locale)
        if not source_name and name_json:
            # Fallback: use first available name
            source_name = next(iter(name_json.values()))

        source_description = description_json.get(source_bcp47) or description_json.get(source_locale) or ''

        content_to_translate = {
            'name': source_name or '',
            'description': source_description
        }
        existing_translations = {
            'name': {},
            'description': {}
        }
    elif entity_type == 'AUTOCOMPLETE_ITEM':
        # AutocompleteItem stores translations directly in name JSONB
        name_json = entity['name'] or {}

        # Convert source_locale to BCP47 format to find source content
        source_bcp47 = LOCALE_MAP.get(source_locale, f"{source_locale}-{source_locale.upper()}")

        source_name = name_json.get(source_bcp47) or name_json.get(source_locale)
        if not source_name and name_json:
            # Fallback: use first available name
            source_name = next(iter(name_json.values()))

        if not source_name:
            logger.warning(f"No source name found for autocomplete item {entity_id} in locale {source_locale}")
            return False

        content_to_translate = {'name': source_name}
        existing_translations = {'name': {}}
    elif entity_type == 'USER':
        content_to_translate = {'bio': entity['bio'] or ''}
        existing_translations = {'bio': entity['bio_translations'] or {}}
    elif entity_type == 'COMMENT':
        content_to_translate = {'content': entity['content'] or ''}
        existing_translations = {'content': entity['content_translations'] or {}}

    # =============================================================================
    # CONTENT MODERATION: Validate content and images BEFORE translation
    # Applies to LOG_POST and COMMENT
    # =============================================================================
    if entity_type == 'LOG_POST':
        logger.info(f"Validating log post {entity_id} content before translation...")

        # 1. Validate text content
        text_result = translator.moderate_text_content(
            title=content_to_translate.get('title'),
            content=content_to_translate.get('content'),
            context="cooking log post"
        )
        if not text_result:
            logger.warning(f"Log post {entity_id} text content failed moderation: {text_result.reason}")
            raise ModerationFailure(f"Text content inappropriate: {text_result.reason}")

        # 2. Validate images
        image_urls = fetch_log_post_image_urls(conn, entity_id, limit=3)
        for image_url in image_urls:
            image_result = translator.moderate_image(image_url)
            if not image_result:
                logger.warning(f"Log post {entity_id} image failed moderation ({image_url}): {image_result.reason}")
                raise ModerationFailure(f"Image inappropriate: {image_result.reason}")

        logger.info(f"Log post {entity_id} passed content moderation (text + {len(image_urls)} images)")

    elif entity_type == 'COMMENT':
        logger.info(f"Validating comment {entity_id} content before translation...")

        # Validate text content
        text_result = translator.moderate_text_content(
            title=None,
            content=content_to_translate.get('content'),
            context="user comment on cooking log post"
        )
        if not text_result:
            logger.warning(f"Comment {entity_id} failed moderation: {text_result.reason}")
            # Hide the comment instead of raising an exception
            hide_comment(conn, entity_id, text_result.reason)
            raise ModerationFailure(f"Comment hidden due to inappropriate content: {text_result.reason}")

        logger.info(f"Comment {entity_id} passed content moderation")
    # =============================================================================

    # Translate to each pending locale
    new_completed = list(completed_locales)

    for target_locale in pending_locales:
        try:
            # Determine appropriate context for translation
            if entity_type == 'RECIPE_STEP':
                context = "cooking recipe step"
            elif entity_type in ('FOOD_MASTER', 'AUTOCOMPLETE_ITEM'):
                context = "food ingredient name for a cooking recipe app"
            elif entity_type == 'USER':
                context = "user bio/profile description for a cooking recipe app"
            elif entity_type == 'COMMENT':
                context = "user comment on a cooking log post"
            else:
                context = "cooking recipe content"

            translated = translator.translate_content(
                content=content_to_translate,
                source_locale=source_locale,
                target_locale=target_locale,
                context=context
            )

            # Merge translations - always use BCP47 locale keys for consistency
            translation_key = to_bcp47(target_locale)

            for field, value in translated.items():
                if field not in existing_translations:
                    existing_translations[field] = {}
                existing_translations[field][translation_key] = value

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

        translator = get_gemini_client()

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
                        SELECT id, entity_type, entity_id, source_locale, target_locales, completed_locales, status
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
            logger.info(f"Batch processing: found {len(events)} pending events")

            if events:
                # Log summary of what we're about to process
                event_summary = []
                for e in events:
                    event_summary.append(f"{e['entity_type']}:{e['entity_id']}")
                logger.info(f"Processing events: {', '.join(event_summary)}")

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
