-- Fix rating column type from SMALLINT to INTEGER to match JPA entity
ALTER TABLE recipe_logs ALTER COLUMN rating TYPE INTEGER;
