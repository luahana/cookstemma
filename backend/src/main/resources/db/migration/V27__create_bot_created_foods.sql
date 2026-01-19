-- Create bot_created_foods table to track which foods each bot persona has created recipes for
CREATE TABLE bot_created_foods (
    id              BIGSERIAL PRIMARY KEY,
    persona_name    VARCHAR(100) NOT NULL,
    food_name       VARCHAR(200) NOT NULL,
    recipe_public_id UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uk_bot_created_foods_persona_food UNIQUE (persona_name, food_name)
);

-- Index for efficient lookups by persona
CREATE INDEX idx_bot_created_foods_persona ON bot_created_foods(persona_name);
