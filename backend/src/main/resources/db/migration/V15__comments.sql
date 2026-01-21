-- =============================================================================
-- COMMENTS SYSTEM: Comments on cooking logs with single-level replies
-- =============================================================================

-- Add new notification types for comments
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'COMMENT_ON_LOG';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'COMMENT_REPLY';

-- -----------------------------------------------------------------------------
-- COMMENTS
-- Purpose: Comments on cooking logs with single-level reply support
-- -----------------------------------------------------------------------------
CREATE TABLE comments (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- References
    log_post_id     BIGINT NOT NULL REFERENCES log_posts(id) ON DELETE CASCADE,
    creator_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id       BIGINT REFERENCES comments(id) ON DELETE CASCADE,  -- NULL for top-level comments

    -- Content
    content         TEXT NOT NULL,
    content_translations JSONB DEFAULT '{}',

    -- Counters
    reply_count     INTEGER NOT NULL DEFAULT 0,
    like_count      INTEGER NOT NULL DEFAULT 0,

    -- Edit tracking
    edited_at       TIMESTAMPTZ,

    -- Soft delete
    deleted_at      TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT chk_comments_content_length CHECK (LENGTH(content) <= 1000),
    CONSTRAINT chk_comments_reply_count CHECK (reply_count >= 0),
    CONSTRAINT chk_comments_like_count CHECK (like_count >= 0)
);

COMMENT ON TABLE comments IS 'Comments on cooking logs with single-level reply support';
COMMENT ON COLUMN comments.parent_id IS 'Parent comment ID for replies (NULL for top-level comments)';
COMMENT ON COLUMN comments.content_translations IS 'Translated content: {"en": "...", "ja": "...", ...}';
COMMENT ON COLUMN comments.deleted_at IS 'Soft delete timestamp - NULL means active';

-- Indexes
CREATE INDEX idx_comments_log_post ON comments(log_post_id, created_at DESC)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_comments_parent ON comments(parent_id, created_at ASC)
    WHERE parent_id IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_comments_creator ON comments(creator_id, created_at DESC);
CREATE INDEX idx_comments_top_level ON comments(log_post_id, created_at DESC)
    WHERE parent_id IS NULL AND deleted_at IS NULL;

CREATE TRIGGER trg_comments_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- COMMENT LIKES
-- Purpose: User likes on comments
-- -----------------------------------------------------------------------------
CREATE TABLE comment_likes (
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment_id      BIGINT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, comment_id)
);

COMMENT ON TABLE comment_likes IS 'User likes on comments';

CREATE INDEX idx_comment_likes_comment ON comment_likes(comment_id);
