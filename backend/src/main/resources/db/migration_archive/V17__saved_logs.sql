-- Saved logs table (bookmarking log posts)
CREATE TABLE IF NOT EXISTS saved_logs (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_post_id BIGINT NOT NULL REFERENCES log_posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, log_post_id)
);

-- Index for fetching user's saved logs (chronological)
CREATE INDEX IF NOT EXISTS idx_saved_logs_user ON saved_logs(user_id, created_at DESC);

-- Index for counting how many times a log has been saved
CREATE INDEX IF NOT EXISTS idx_saved_logs_log ON saved_logs(log_post_id);

-- Add saved_count column to log_posts table
ALTER TABLE log_posts ADD COLUMN IF NOT EXISTS saved_count INTEGER NOT NULL DEFAULT 0;
