-- View History table for tracking recently viewed recipes and logs
CREATE TABLE view_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(20) NOT NULL, -- 'RECIPE' or 'LOG_POST'
    entity_id BIGINT NOT NULL,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,

    -- Ensure unique view per user per entity (will update timestamp on re-view)
    CONSTRAINT uk_view_history_user_entity UNIQUE (user_id, entity_type, entity_id)
);

-- Index for efficient lookups by user
CREATE INDEX idx_view_history_user_viewed ON view_history (user_id, viewed_at DESC);

-- Index for efficient lookups by entity
CREATE INDEX idx_view_history_entity ON view_history (entity_type, entity_id);
