-- =============================================================================
-- V9: Recipe Image Many-to-Many Relationship
-- =============================================================================
-- Purpose: Enable sharing of cover images across recipe variants
-- Problem: When creating variant recipes, cover images were being MOVED from
--          the parent recipe to the variant instead of being shared.
-- Solution: Create a join table (recipe_image_map) that allows the same image
--           to be linked to multiple recipes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CREATE JOIN TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE recipe_image_map (
    recipe_id       BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    image_id        BIGINT NOT NULL REFERENCES images(id) ON DELETE CASCADE,
    display_order   INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (recipe_id, image_id)
);

COMMENT ON TABLE recipe_image_map IS 'Join table for recipe-image many-to-many relationship. Enables image sharing across recipe variants.';
COMMENT ON COLUMN recipe_image_map.display_order IS 'Recipe-specific display order for the image';

-- Performance indexes
CREATE INDEX idx_recipe_image_map_image ON recipe_image_map(image_id);
CREATE INDEX idx_recipe_image_map_order ON recipe_image_map(recipe_id, display_order);

-- -----------------------------------------------------------------------------
-- MIGRATE EXISTING DATA
-- -----------------------------------------------------------------------------
-- Copy existing cover image relationships to the join table.
-- Only migrate COVER images (step images continue to use direct FK).
-- Note: Keep the original recipe_id on images for constraint satisfaction.

INSERT INTO recipe_image_map (recipe_id, image_id, display_order)
SELECT recipe_id, id, display_order
FROM images
WHERE recipe_id IS NOT NULL
  AND type = 'COVER'
  AND deleted_at IS NULL;

-- Log migration stats
DO $$
DECLARE
    migrated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO migrated_count FROM recipe_image_map;
    RAISE NOTICE 'Migrated % cover image relationships to recipe_image_map', migrated_count;
END $$;
