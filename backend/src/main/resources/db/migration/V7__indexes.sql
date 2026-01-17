-- =============================================================================
-- ADDITIONAL PERFORMANCE INDEXES
-- Purpose: Composite and specialized indexes for common query patterns
-- =============================================================================

-- Discovery feeds
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recipes_feed
    ON recipes(created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_log_posts_feed
    ON log_posts(created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

-- User profile queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recipes_by_user_public
    ON recipes(creator_id, created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_log_posts_by_user_public
    ON log_posts(creator_id, created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;

-- Recipe variations
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recipes_variations
    ON recipes(root_recipe_id, created_at DESC)
    WHERE root_recipe_id IS NOT NULL AND deleted_at IS NULL;

COMMENT ON INDEX idx_recipes_feed IS 'Optimized for public recipe discovery feed';
COMMENT ON INDEX idx_log_posts_feed IS 'Optimized for public log post feed';
