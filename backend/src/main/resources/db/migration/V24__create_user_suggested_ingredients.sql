-- User Suggested Ingredients table for capturing ingredient names not found in AutocompleteItem
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

-- Indexes for common queries
CREATE INDEX idx_suggested_ingredients_status ON user_suggested_ingredients(status);
CREATE INDEX idx_suggested_ingredients_type ON user_suggested_ingredients(ingredient_type);
CREATE INDEX idx_suggested_ingredients_name ON user_suggested_ingredients(suggested_name);
CREATE INDEX idx_suggested_ingredients_user ON user_suggested_ingredients(user_id);
