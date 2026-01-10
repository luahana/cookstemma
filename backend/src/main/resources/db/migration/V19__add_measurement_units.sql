-- Add structured measurement fields to recipe_ingredients
ALTER TABLE recipe_ingredients
ADD COLUMN quantity DOUBLE PRECISION NULL,
ADD COLUMN unit VARCHAR(20) NULL;

-- Add measurement preference to users
ALTER TABLE users
ADD COLUMN measurement_preference VARCHAR(20) DEFAULT 'ORIGINAL';

-- Add index for filtering by unit (useful for future queries)
CREATE INDEX idx_recipe_ingredients_unit ON recipe_ingredients(unit) WHERE unit IS NOT NULL;

-- Comment for documentation
COMMENT ON COLUMN recipe_ingredients.quantity IS 'Numeric quantity for structured measurements (nullable for legacy)';
COMMENT ON COLUMN recipe_ingredients.unit IS 'Standardized unit enum (nullable for legacy)';
COMMENT ON COLUMN users.measurement_preference IS 'User preference for displaying measurements: METRIC, US, or ORIGINAL';
