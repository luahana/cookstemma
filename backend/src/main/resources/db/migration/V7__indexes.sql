-- =============================================================================
-- ADDITIONAL PERFORMANCE INDEXES
-- Purpose: Composite and specialized indexes for common query patterns
-- =============================================================================

-- Discovery feeds
CREATE INDEX IF NOT EXISTS idx_recipes_feed
    ON recipes(created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

CREATE INDEX IF NOT EXISTS idx_log_posts_feed
    ON log_posts(created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

-- User profile queries
CREATE INDEX IF NOT EXISTS idx_recipes_by_user_public
    ON recipes(creator_id, created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

CREATE INDEX IF NOT EXISTS idx_log_posts_by_user_public
    ON log_posts(creator_id, created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

-- Recipe variations
CREATE INDEX IF NOT EXISTS idx_recipes_variations
    ON recipes(root_recipe_id, created_at DESC)
    WHERE root_recipe_id IS NOT NULL AND deleted_at IS NULL;
