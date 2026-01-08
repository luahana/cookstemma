-- V15: Add deleted_at column to users table for soft delete

ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE NULL;

COMMENT ON COLUMN users.deleted_at IS 'Timestamp when user account was soft deleted';
