-- V14: Add soft delete columns to users table

ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE NULL;
ALTER TABLE users ADD COLUMN delete_scheduled_at TIMESTAMP WITH TIME ZONE NULL;

COMMENT ON COLUMN users.deleted_at IS 'Timestamp when user account was soft deleted';
COMMENT ON COLUMN users.delete_scheduled_at IS 'Timestamp when user account is scheduled for permanent deletion';
