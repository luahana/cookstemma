-- Bot Personas table
-- Stores bot personality profiles that define how bots create content
CREATE TABLE bot_personas (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name JSONB NOT NULL,
    tone VARCHAR(30) NOT NULL,
    skill_level VARCHAR(20) NOT NULL,
    dietary_focus VARCHAR(50),
    vocabulary_style VARCHAR(30) NOT NULL,
    locale VARCHAR(10) NOT NULL,
    culinary_locale VARCHAR(10) NOT NULL,
    kitchen_style_prompt TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bot API Keys table
-- Stores API keys for bot authentication (Stripe-style prefix + hash pattern)
CREATE TABLE bot_api_keys (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    key_prefix VARCHAR(8) NOT NULL,
    key_hash VARCHAR(64) NOT NULL UNIQUE,
    bot_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    last_used_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add persona reference to users (optional - bots are linked to their persona)
ALTER TABLE users ADD COLUMN persona_id BIGINT REFERENCES bot_personas(id);

-- Indexes for efficient queries
CREATE INDEX idx_bot_personas_name ON bot_personas(name);
CREATE INDEX idx_bot_personas_locale ON bot_personas(locale);
CREATE INDEX idx_bot_personas_is_active ON bot_personas(is_active) WHERE is_active = TRUE;

CREATE INDEX idx_bot_api_keys_hash ON bot_api_keys(key_hash);
CREATE INDEX idx_bot_api_keys_bot_user_id ON bot_api_keys(bot_user_id);
CREATE INDEX idx_bot_api_keys_is_active ON bot_api_keys(is_active) WHERE is_active = TRUE;

CREATE INDEX idx_users_persona_id ON users(persona_id) WHERE persona_id IS NOT NULL;
CREATE INDEX idx_users_is_bot ON users(is_bot) WHERE is_bot = TRUE;

-- Comment on tables
COMMENT ON TABLE bot_personas IS 'Bot personality profiles defining content generation style';
COMMENT ON TABLE bot_api_keys IS 'API keys for bot authentication (prefix + SHA256 hash)';
COMMENT ON COLUMN bot_personas.display_name IS 'JSON with locale keys: {"en": "Chef Park", "ko": "박수진 셰프"}';
COMMENT ON COLUMN bot_personas.tone IS 'e.g., professional, casual, enthusiastic, educational';
COMMENT ON COLUMN bot_personas.skill_level IS 'e.g., professional, intermediate, beginner, home_cook';
COMMENT ON COLUMN bot_personas.dietary_focus IS 'Optional specialty: vegetarian, healthy, budget, etc.';
COMMENT ON COLUMN bot_personas.vocabulary_style IS 'e.g., technical, simple, conversational';
COMMENT ON COLUMN bot_personas.kitchen_style_prompt IS 'Detailed prompt for image generation describing kitchen aesthetic';
COMMENT ON COLUMN bot_api_keys.key_prefix IS 'First 8 chars of key for identification (e.g., pp_bot_x)';
COMMENT ON COLUMN bot_api_keys.key_hash IS 'SHA-256 hash of the full API key';
