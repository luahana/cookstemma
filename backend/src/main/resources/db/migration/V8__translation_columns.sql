-- =============================================================================
-- TRANSLATION COLUMNS: Add JSONB columns for multilingual content
-- =============================================================================
-- Supports 12 languages: ko, en, ja, zh, fr, es, it, de, ru, pt, el, ar
-- Structure: {"en": "English text", "ja": "日本語テキスト", ...}
-- =============================================================================

-- -----------------------------------------------------------------------------
-- RECIPES: title and description translations
-- -----------------------------------------------------------------------------
ALTER TABLE recipes ADD COLUMN title_translations JSONB DEFAULT '{}';
ALTER TABLE recipes ADD COLUMN description_translations JSONB DEFAULT '{}';

COMMENT ON COLUMN recipes.title_translations IS 'Translated titles: {"en": "...", "ja": "...", ...}';
COMMENT ON COLUMN recipes.description_translations IS 'Translated descriptions: {"en": "...", "ja": "...", ...}';

-- GIN indexes for efficient JSONB queries (e.g., searching by language)
CREATE INDEX idx_recipes_title_trans ON recipes USING GIN(title_translations jsonb_path_ops);
CREATE INDEX idx_recipes_desc_trans ON recipes USING GIN(description_translations jsonb_path_ops);

-- -----------------------------------------------------------------------------
-- RECIPE STEPS: description translations
-- -----------------------------------------------------------------------------
ALTER TABLE recipe_steps ADD COLUMN description_translations JSONB DEFAULT '{}';

COMMENT ON COLUMN recipe_steps.description_translations IS 'Translated step descriptions: {"en": "...", "ja": "...", ...}';

-- -----------------------------------------------------------------------------
-- RECIPE INGREDIENTS: name translations
-- -----------------------------------------------------------------------------
ALTER TABLE recipe_ingredients ADD COLUMN name_translations JSONB DEFAULT '{}';

COMMENT ON COLUMN recipe_ingredients.name_translations IS 'Translated ingredient names: {"en": "...", "ja": "...", ...}';

-- -----------------------------------------------------------------------------
-- LOG POSTS: title and content translations
-- -----------------------------------------------------------------------------
ALTER TABLE log_posts ADD COLUMN title_translations JSONB DEFAULT '{}';
ALTER TABLE log_posts ADD COLUMN content_translations JSONB DEFAULT '{}';

COMMENT ON COLUMN log_posts.title_translations IS 'Translated titles: {"en": "...", "ja": "...", ...}';
COMMENT ON COLUMN log_posts.content_translations IS 'Translated content: {"en": "...", "ja": "...", ...}';

-- GIN indexes for log posts
CREATE INDEX idx_log_posts_title_trans ON log_posts USING GIN(title_translations jsonb_path_ops);
CREATE INDEX idx_log_posts_content_trans ON log_posts USING GIN(content_translations jsonb_path_ops);

-- -----------------------------------------------------------------------------
-- TRANSLATION EVENTS: Track pending/completed translations
-- -----------------------------------------------------------------------------
CREATE TYPE translation_status AS ENUM ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED');
CREATE TYPE translatable_entity AS ENUM ('RECIPE', 'RECIPE_STEP', 'RECIPE_INGREDIENT', 'LOG_POST');

CREATE TABLE translation_events (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- What to translate
    entity_type     translatable_entity NOT NULL,
    entity_id       BIGINT NOT NULL,
    source_locale   VARCHAR(5) NOT NULL,  -- Original language (e.g., 'ko', 'en')

    -- Status tracking
    status          translation_status NOT NULL DEFAULT 'PENDING',
    target_locales  JSONB NOT NULL,  -- Array of target languages: ["en", "ja", "zh"]
    completed_locales JSONB DEFAULT '[]',  -- Array of completed translations

    -- Error handling
    retry_count     INTEGER NOT NULL DEFAULT 0,
    last_error      TEXT,

    -- Timestamps
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ
);

COMMENT ON TABLE translation_events IS 'Tracks async translation requests for user content';
COMMENT ON COLUMN translation_events.target_locales IS 'Languages to translate to: ["en", "ja", "zh", ...]';
COMMENT ON COLUMN translation_events.completed_locales IS 'Successfully translated languages';

-- Indexes for queue processing
CREATE INDEX idx_translation_events_pending ON translation_events(status, created_at)
    WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX idx_translation_events_entity ON translation_events(entity_type, entity_id);
