-- =============================================================================
-- SOCIAL TABLES: Follows, Blocks, Reports, Notifications
-- =============================================================================

-- -----------------------------------------------------------------------------
-- USER FOLLOWS
-- Purpose: Social follow relationships
-- -----------------------------------------------------------------------------
CREATE TABLE user_follows (
    follower_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    following_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT chk_user_follows_no_self CHECK (follower_id != following_id)
);

COMMENT ON TABLE user_follows IS 'Social follow relationships between users';

CREATE INDEX idx_user_follows_follower ON user_follows(follower_id, created_at DESC);
CREATE INDEX idx_user_follows_following ON user_follows(following_id, created_at DESC);

-- -----------------------------------------------------------------------------
-- USER BLOCKS
-- Purpose: User blocking for content filtering
-- -----------------------------------------------------------------------------
CREATE TABLE user_blocks (
    blocker_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (blocker_id, blocked_id),
    CONSTRAINT chk_user_blocks_no_self CHECK (blocker_id != blocked_id)
);

COMMENT ON TABLE user_blocks IS 'User blocking relationships';

CREATE INDEX idx_user_blocks_blocker ON user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked ON user_blocks(blocked_id);

-- -----------------------------------------------------------------------------
-- USER REPORTS
-- Purpose: User-submitted reports for moderation
-- -----------------------------------------------------------------------------
CREATE TABLE user_reports (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    reporter_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reported_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    reason          report_reason NOT NULL,
    description     TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_user_reports_no_self CHECK (reporter_id != reported_id)
);

COMMENT ON TABLE user_reports IS 'User-submitted reports for moderation review';

CREATE INDEX idx_user_reports_reported ON user_reports(reported_id);
CREATE INDEX idx_user_reports_created ON user_reports(created_at DESC);

-- -----------------------------------------------------------------------------
-- NOTIFICATIONS
-- Purpose: In-app notification inbox
-- -----------------------------------------------------------------------------
CREATE TABLE notifications (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- Recipients
    recipient_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_id       BIGINT REFERENCES users(id) ON DELETE SET NULL,

    -- Content
    type            notification_type NOT NULL,
    title           VARCHAR(255) NOT NULL,
    body            VARCHAR(500) NOT NULL,

    -- Context references
    recipe_id       BIGINT REFERENCES recipes(id) ON DELETE CASCADE,
    log_post_id     BIGINT REFERENCES log_posts(id) ON DELETE CASCADE,

    -- Additional data
    data            JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Read status
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE notifications IS 'In-app notification inbox';
COMMENT ON COLUMN notifications.data IS 'Additional JSON payload for rich notifications';

CREATE INDEX idx_notifications_recipient_unread ON notifications(recipient_id, created_at DESC)
    WHERE is_read = FALSE;
CREATE INDEX idx_notifications_recipient_all ON notifications(recipient_id, created_at DESC);
CREATE INDEX idx_notifications_sender ON notifications(sender_id) WHERE sender_id IS NOT NULL;

CREATE TRIGGER trg_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- USER FCM TOKENS
-- Purpose: Firebase Cloud Messaging tokens for push notifications
-- -----------------------------------------------------------------------------
CREATE TABLE user_fcm_tokens (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    fcm_token       VARCHAR(512) NOT NULL,
    device_type     device_type NOT NULL,
    device_id       VARCHAR(255),

    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at    TIMESTAMPTZ,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_user_fcm_token UNIQUE (user_id, fcm_token)
);

COMMENT ON TABLE user_fcm_tokens IS 'Push notification device tokens';

CREATE INDEX idx_user_fcm_tokens_user ON user_fcm_tokens(user_id) WHERE is_active = TRUE;
CREATE INDEX idx_user_fcm_tokens_token ON user_fcm_tokens(fcm_token);

CREATE TRIGGER trg_user_fcm_tokens_updated_at
    BEFORE UPDATE ON user_fcm_tokens
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
