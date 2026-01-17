-- =============================================================================
-- WEBP VARIANTS: Add WebP image variants for better compression
-- =============================================================================

-- Add new WebP variants to the image_variant enum
ALTER TYPE image_variant ADD VALUE IF NOT EXISTS 'LARGE_1200_WEBP';
ALTER TYPE image_variant ADD VALUE IF NOT EXISTS 'MEDIUM_800_WEBP';
ALTER TYPE image_variant ADD VALUE IF NOT EXISTS 'THUMB_400_WEBP';
ALTER TYPE image_variant ADD VALUE IF NOT EXISTS 'THUMB_200_WEBP';
