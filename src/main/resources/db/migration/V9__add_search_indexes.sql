-- Full-text search indexes using pg_trgm (trigram similarity)
-- pg_trgm extension is already enabled in V1__init.sql

-- Recipe search indexes
CREATE INDEX IF NOT EXISTS idx_recipe_title_trgm ON recipes USING GIN (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_recipe_description_trgm ON recipes USING GIN (description gin_trgm_ops);

-- Recipe ingredients search index
CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_name_trgm ON recipe_ingredients USING GIN (name gin_trgm_ops);

-- LogPost search indexes
CREATE INDEX IF NOT EXISTS idx_log_post_title_trgm ON log_posts USING GIN (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_log_post_content_trgm ON log_posts USING GIN (content gin_trgm_ops);
