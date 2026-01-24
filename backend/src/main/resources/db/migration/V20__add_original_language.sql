-- Add original_language column to recipes
ALTER TABLE recipes ADD COLUMN original_language VARCHAR(15);

-- Add original_language column to log_posts
ALTER TABLE log_posts ADD COLUMN original_language VARCHAR(15);

-- Backfill: Set original_language from cooking_style for existing recipes
UPDATE recipes SET original_language = cooking_style WHERE original_language IS NULL;

-- Backfill: Set original_language from locale for existing log_posts
UPDATE log_posts SET original_language = locale WHERE original_language IS NULL;
