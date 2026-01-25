-- Add soft delete fields to images table
ALTER TABLE images ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE images ADD COLUMN IF NOT EXISTS delete_scheduled_at TIMESTAMP;

-- Index for efficiently finding images scheduled for deletion
CREATE INDEX IF NOT EXISTS idx_images_delete_scheduled
    ON images(delete_scheduled_at)
    WHERE deleted_at IS NOT NULL;

-- Index for efficiently finding non-deleted images by uploader
CREATE INDEX IF NOT EXISTS idx_images_uploader_not_deleted
    ON images(uploader_id)
    WHERE deleted_at IS NULL;
