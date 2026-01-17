-- V11: Push notifications infrastructure
-- FCM tokens (multi-device support) and notification inbox

-- User FCM Tokens table (supports multiple devices per user)
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token VARCHAR(512) NOT NULL,
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('ANDROID', 'IOS', 'WEB')),
    device_id VARCHAR(255),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_user_fcm_token UNIQUE (user_id, fcm_token)
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user ON user_fcm_tokens(user_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON user_fcm_tokens(fcm_token);

-- Notifications table (in-app notification inbox)
CREATE TABLE IF NOT EXISTS notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    recipient_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_id BIGINT REFERENCES users(id) ON DELETE SET NULL,

    type VARCHAR(50) NOT NULL CHECK (type IN ('RECIPE_COOKED', 'RECIPE_VARIATION')),

    -- Reference IDs for navigation
    recipe_id BIGINT REFERENCES recipes(id) ON DELETE CASCADE,
    log_post_id BIGINT REFERENCES log_posts(id) ON DELETE CASCADE,

    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,

    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,

    -- For additional data payload
    data JSONB DEFAULT '{}',

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread ON notifications(recipient_id, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_all ON notifications(recipient_id, created_at DESC);
