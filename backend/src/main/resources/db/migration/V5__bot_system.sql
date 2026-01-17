-- =============================================================================
-- BOT SYSTEM: Personas and API Keys
-- =============================================================================

-- -----------------------------------------------------------------------------
-- BOT PERSONAS
-- Purpose: Bot personality profiles for content generation
-- -----------------------------------------------------------------------------
CREATE TABLE bot_personas (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- Identity
    name            VARCHAR(50) NOT NULL UNIQUE,
    display_name    JSONB NOT NULL DEFAULT '{}'::jsonb,  -- Localized

    -- Personality
    tone            bot_tone NOT NULL,
    skill_level     bot_skill_level NOT NULL,
    dietary_focus   VARCHAR(50),
    vocabulary_style bot_vocabulary_style NOT NULL,

    -- Locale settings
    locale          VARCHAR(10) NOT NULL,
    culinary_locale VARCHAR(10) NOT NULL,

    -- AI prompt
    kitchen_style_prompt TEXT NOT NULL,

    -- Status
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by_id   BIGINT REFERENCES users(id),

    CONSTRAINT chk_bot_personas_display_name CHECK (jsonb_typeof(display_name) = 'object')
);

COMMENT ON TABLE bot_personas IS 'Bot personality profiles for AI content generation';
COMMENT ON COLUMN bot_personas.tone IS 'Personality tone: professional, casual, warm, etc.';
COMMENT ON COLUMN bot_personas.kitchen_style_prompt IS 'Detailed prompt for AI image generation';

CREATE INDEX idx_bot_personas_name ON bot_personas(name);
CREATE INDEX idx_bot_personas_locale ON bot_personas(locale);
CREATE INDEX idx_bot_personas_active ON bot_personas(is_active) WHERE is_active = TRUE;

CREATE TRIGGER trg_bot_personas_updated_at
    BEFORE UPDATE ON bot_personas
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Add FK from users to bot_personas
ALTER TABLE users
    ADD CONSTRAINT fk_users_persona
    FOREIGN KEY (persona_id) REFERENCES bot_personas(id) ON DELETE SET NULL;

CREATE INDEX idx_users_persona ON users(persona_id) WHERE persona_id IS NOT NULL;
CREATE INDEX idx_users_bot_active ON users(is_bot, status) WHERE is_bot = TRUE;

-- -----------------------------------------------------------------------------
-- BOT API KEYS
-- Purpose: API authentication for bot accounts
-- -----------------------------------------------------------------------------
CREATE TABLE bot_api_keys (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    bot_user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Security (key_prefix for identification, hash for verification)
    key_prefix      VARCHAR(8) NOT NULL,
    key_hash        VARCHAR(64) NOT NULL UNIQUE,  -- SHA-256

    name            VARCHAR(100) NOT NULL,

    -- Status
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at    TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE bot_api_keys IS 'API keys for bot authentication (prefix + SHA256 hash)';
COMMENT ON COLUMN bot_api_keys.key_prefix IS 'First 8 chars for identification';
COMMENT ON COLUMN bot_api_keys.key_hash IS 'SHA-256 hash of full key';

CREATE INDEX idx_bot_api_keys_hash ON bot_api_keys(key_hash);
CREATE INDEX idx_bot_api_keys_bot_user ON bot_api_keys(bot_user_id);
CREATE INDEX idx_bot_api_keys_active ON bot_api_keys(is_active) WHERE is_active = TRUE;

CREATE TRIGGER trg_bot_api_keys_updated_at
    BEFORE UPDATE ON bot_api_keys
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
