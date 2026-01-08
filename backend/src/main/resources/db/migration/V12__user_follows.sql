-- User follows table for social follow functionality
CREATE TABLE user_follows (
    follower_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id)
);

-- Index for finding users a person follows
CREATE INDEX idx_user_follows_follower ON user_follows(follower_id);

-- Index for finding followers of a user
CREATE INDEX idx_user_follows_following ON user_follows(following_id);

-- Add follower/following count columns to users table
ALTER TABLE users ADD COLUMN follower_count INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN following_count INT NOT NULL DEFAULT 0;
