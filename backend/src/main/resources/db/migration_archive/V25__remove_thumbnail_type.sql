-- Migration to remove THUMBNAIL from image_type enum
-- THUMBNAIL is being replaced by COVER for recipe cover images

-- Step 1: Update any existing THUMBNAIL images to COVER
UPDATE images SET type = 'COVER' WHERE type = 'THUMBNAIL';

-- Step 2: Recreate enum without THUMBNAIL
-- PostgreSQL doesn't support removing enum values directly, so we recreate

-- Create new enum type without THUMBNAIL
CREATE TYPE image_type_new AS ENUM ('STEP', 'LOG', 'LOG_POST', 'COVER');

-- Alter images table to use the new type
ALTER TABLE images ALTER COLUMN type TYPE image_type_new USING type::text::image_type_new;

-- Drop old type and rename new type
DROP TYPE image_type;
ALTER TYPE image_type_new RENAME TO image_type;
