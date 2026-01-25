-- V17: Add is_hidden and hidden_reason columns to comments for content moderation
-- Hidden comments are still visible to their author but hidden from others

-- Add is_hidden column for content moderation
ALTER TABLE comments ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT FALSE;

-- Add hidden_reason for audit trail
ALTER TABLE comments ADD COLUMN IF NOT EXISTS hidden_reason TEXT;

-- Index for filtering hidden comments (partial index for efficiency)
CREATE INDEX IF NOT EXISTS idx_comments_is_hidden ON comments(is_hidden) WHERE is_hidden = TRUE;

-- Add content_translations column if not exists (for comment translation support)
ALTER TABLE comments ADD COLUMN IF NOT EXISTS content_translations JSONB DEFAULT '{}';
