-- Add VARCHAR limits to TEXT fields that were previously unlimited
-- Setting to 500 characters for user-facing content fields

-- Users table
ALTER TABLE users ALTER COLUMN youtube_url TYPE VARCHAR(500);

-- Recipes table
ALTER TABLE recipes ALTER COLUMN description TYPE VARCHAR(500);

-- Recipe steps table
ALTER TABLE recipe_steps ALTER COLUMN description TYPE VARCHAR(500);

-- Log posts table
ALTER TABLE log_posts ALTER COLUMN title TYPE VARCHAR(500);
ALTER TABLE log_posts ALTER COLUMN content TYPE VARCHAR(500);

-- Comments table
ALTER TABLE comments ALTER COLUMN body TYPE VARCHAR(500);

-- Notifications table
ALTER TABLE notifications ALTER COLUMN description TYPE VARCHAR(500);
