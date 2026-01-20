-- V10: Add image variant support for multi-platform optimization

-- Create enum type for image variants
DO $$ BEGIN
    CREATE TYPE image_variant_type AS ENUM ('ORIGINAL', 'LARGE_1200', 'MEDIUM_800', 'THUMB_400', 'THUMB_200');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add variant-related columns to images table
ALTER TABLE images ADD COLUMN IF NOT EXISTS variant_type image_variant_type;
ALTER TABLE images ADD COLUMN IF NOT EXISTS original_image_id BIGINT REFERENCES images(id) ON DELETE CASCADE;
ALTER TABLE images ADD COLUMN IF NOT EXISTS width INTEGER;
ALTER TABLE images ADD COLUMN IF NOT EXISTS height INTEGER;
ALTER TABLE images ADD COLUMN IF NOT EXISTS file_size BIGINT;
ALTER TABLE images ADD COLUMN IF NOT EXISTS format VARCHAR(10);

-- Index for efficient variant lookups
CREATE INDEX IF NOT EXISTS idx_images_original ON images(original_image_id) WHERE original_image_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_images_variant_type ON images(original_image_id, variant_type) WHERE original_image_id IS NOT NULL;

-- Set existing images as ORIGINAL variant (backfill)
UPDATE images SET variant_type = 'ORIGINAL' WHERE variant_type IS NULL AND original_image_id IS NULL;
