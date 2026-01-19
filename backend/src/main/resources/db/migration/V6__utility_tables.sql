-- =============================================================================
-- UTILITY TABLES: Analytics, Idempotency, Autocomplete, History, Translations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ANALYTICS EVENTS
-- Purpose: Event tracking for analytics
-- -----------------------------------------------------------------------------
CREATE TABLE analytics_events (
    id              BIGSERIAL PRIMARY KEY,

    event_id        UUID NOT NULL UNIQUE,  -- Idempotency
    event_type      VARCHAR(100) NOT NULL,

    -- References (UUIDs for flexibility)
    user_id         UUID,
    recipe_id       UUID,
    log_id          UUID,

    -- Timestamps
    timestamp       TIMESTAMPTZ NOT NULL,  -- Device time
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),  -- Server time

    -- Flexible properties
    properties      JSONB NOT NULL DEFAULT '{}'::jsonb
);

COMMENT ON TABLE analytics_events IS 'Event tracking for analytics';
COMMENT ON COLUMN analytics_events.timestamp IS 'Client-side event timestamp';
COMMENT ON COLUMN analytics_events.created_at IS 'Server-side receive timestamp';

CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_timestamp ON analytics_events(timestamp);
CREATE INDEX idx_analytics_events_user ON analytics_events(user_id) WHERE user_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- IDEMPOTENCY KEYS
-- Purpose: Prevent duplicate API operations
-- -----------------------------------------------------------------------------
CREATE TABLE idempotency_keys (
    id              BIGSERIAL PRIMARY KEY,

    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    request_path    VARCHAR(255) NOT NULL,
    request_hash    VARCHAR(64) NOT NULL,  -- SHA-256

    response_status INTEGER,
    response_body   TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL
);

COMMENT ON TABLE idempotency_keys IS 'Prevents duplicate API operations (24h TTL)';

CREATE INDEX idx_idempotency_keys_key ON idempotency_keys(idempotency_key);
CREATE INDEX idx_idempotency_keys_expires ON idempotency_keys(expires_at);
CREATE INDEX idx_idempotency_keys_user ON idempotency_keys(user_id);

-- -----------------------------------------------------------------------------
-- AUTOCOMPLETE ITEMS
-- Purpose: Pre-indexed items for search autocomplete
-- -----------------------------------------------------------------------------
CREATE TABLE autocomplete_items (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    type            VARCHAR(30) NOT NULL,  -- DISH, MAIN_INGREDIENT, etc.
    name            JSONB NOT NULL DEFAULT '{}'::jsonb,
    score           DOUBLE PRECISION NOT NULL DEFAULT 50.0,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_autocomplete_items_name CHECK (jsonb_typeof(name) = 'object')
);

COMMENT ON TABLE autocomplete_items IS 'Pre-indexed items for search autocomplete';

CREATE INDEX idx_autocomplete_items_type ON autocomplete_items(type);
CREATE INDEX idx_autocomplete_items_name_gin ON autocomplete_items USING GIN(name);
CREATE INDEX idx_autocomplete_items_score ON autocomplete_items(score DESC);

CREATE TRIGGER trg_autocomplete_items_updated_at
    BEFORE UPDATE ON autocomplete_items
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- VIEW HISTORY
-- Purpose: Track recently viewed recipes and logs
-- -----------------------------------------------------------------------------
CREATE TABLE view_history (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type     VARCHAR(20) NOT NULL,  -- 'RECIPE' or 'LOG_POST'
    entity_id       BIGINT NOT NULL,
    viewed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Ensure unique view per user per entity (will update timestamp on re-view)
    CONSTRAINT uk_view_history_user_entity UNIQUE (user_id, entity_type, entity_id)
);

COMMENT ON TABLE view_history IS 'Tracks recently viewed content for each user';

CREATE INDEX idx_view_history_user_viewed ON view_history(user_id, viewed_at DESC);
CREATE INDEX idx_view_history_entity ON view_history(entity_type, entity_id);

-- -----------------------------------------------------------------------------
-- SEARCH HISTORY
-- Purpose: Track user search queries
-- -----------------------------------------------------------------------------
CREATE TABLE search_history (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    query           VARCHAR(500) NOT NULL,
    searched_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE search_history IS 'User search query history';

CREATE INDEX idx_search_history_user_searched ON search_history(user_id, searched_at DESC);

-- -----------------------------------------------------------------------------
-- TRANSLATION EVENTS
-- Purpose: Track pending/completed translations
-- Note: Uses VARCHAR instead of ENUM for Hibernate compatibility
-- -----------------------------------------------------------------------------
CREATE TABLE translation_events (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- What to translate (VARCHAR for Hibernate compatibility)
    entity_type     VARCHAR(30) NOT NULL,  -- RECIPE, RECIPE_STEP, RECIPE_INGREDIENT, LOG_POST
    entity_id       BIGINT NOT NULL,
    source_locale   VARCHAR(5) NOT NULL,   -- Original language (e.g., 'ko', 'en')

    -- Status tracking (VARCHAR for Hibernate compatibility)
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, PROCESSING, COMPLETED, FAILED
    target_locales  JSONB NOT NULL,       -- Array of target languages: ["en", "ja", "zh"]
    completed_locales JSONB DEFAULT '[]', -- Array of completed translations

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

CREATE INDEX idx_translation_events_pending ON translation_events(status, created_at)
    WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX idx_translation_events_entity ON translation_events(entity_type, entity_id);

-- -----------------------------------------------------------------------------
-- USER SUGGESTED INGREDIENTS
-- Purpose: Capture ingredient names not found in AutocompleteItem
-- -----------------------------------------------------------------------------
CREATE TABLE user_suggested_ingredients (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    suggested_name  VARCHAR(255) NOT NULL,
    ingredient_type VARCHAR(20) NOT NULL,
    locale_code     VARCHAR(10) NOT NULL DEFAULT 'en-US',
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    user_id                 BIGINT REFERENCES users(id) ON DELETE SET NULL,
    autocomplete_item_id    BIGINT REFERENCES autocomplete_items(id) ON DELETE SET NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_suggested_ingredient_type CHECK (ingredient_type IN ('MAIN', 'SECONDARY', 'SEASONING')),
    CONSTRAINT chk_suggested_ingredient_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

COMMENT ON TABLE user_suggested_ingredients IS 'User submissions for new ingredient items';

CREATE INDEX idx_suggested_ingredients_status ON user_suggested_ingredients(status);
CREATE INDEX idx_suggested_ingredients_type ON user_suggested_ingredients(ingredient_type);
CREATE INDEX idx_suggested_ingredients_name ON user_suggested_ingredients(suggested_name);
CREATE INDEX idx_suggested_ingredients_user ON user_suggested_ingredients(user_id);

CREATE TRIGGER trg_user_suggested_ingredients_updated_at
    BEFORE UPDATE ON user_suggested_ingredients
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
