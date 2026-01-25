-- Save/Bookmark System for Recipes
-- Create saved_recipes table
CREATE TABLE IF NOT EXISTS saved_recipes (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, recipe_id)
);

-- Index for user's saved recipes lookup (ordered by most recent)
CREATE INDEX IF NOT EXISTS idx_saved_recipes_user ON saved_recipes(user_id, created_at DESC);

-- Index for recipe's save count lookup
CREATE INDEX IF NOT EXISTS idx_saved_recipes_recipe ON saved_recipes(recipe_id);
