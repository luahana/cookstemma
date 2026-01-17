-- =============================================================================
-- UTILITY TABLES: Analytics, Idempotency, Autocomplete
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
