-- V13: Add idempotency_keys table for preventing duplicate writes on network retries

CREATE TABLE idempotency_keys (
    id BIGSERIAL PRIMARY KEY,
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    user_id BIGINT NOT NULL,
    request_path VARCHAR(255) NOT NULL,
    request_hash VARCHAR(64) NOT NULL,
    response_status INT,
    response_body TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_idempotency_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Index for fast lookup by idempotency key
CREATE INDEX idx_idempotency_key ON idempotency_keys(idempotency_key);

-- Index for cleanup scheduler to find expired keys
CREATE INDEX idx_idempotency_expires_at ON idempotency_keys(expires_at);

-- Index for user-scoped lookups
CREATE INDEX idx_idempotency_user_id ON idempotency_keys(user_id);

COMMENT ON TABLE idempotency_keys IS 'Stores idempotency keys to prevent duplicate writes on network retries';
COMMENT ON COLUMN idempotency_keys.idempotency_key IS 'Client-generated UUID v4 for request deduplication';
COMMENT ON COLUMN idempotency_keys.request_hash IS 'SHA-256 hash of request body for verification';
COMMENT ON COLUMN idempotency_keys.expires_at IS 'Keys expire 24 hours after creation';
