-- Add view_count to recipes table
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;

-- Add view_count to log_posts table
ALTER TABLE log_posts ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;

-- Add indexes for sorting performance
CREATE INDEX IF NOT EXISTS idx_recipes_view_count ON recipes(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_saved_count ON recipes(saved_count DESC);
CREATE INDEX IF NOT EXISTS idx_log_posts_view_count ON log_posts(view_count DESC);
CREATE INDEX IF NOT EXISTS idx_log_posts_saved_count ON log_posts(saved_count DESC);
