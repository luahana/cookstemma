-- Convert outcome (SUCCESS/PARTIAL/FAILED) to rating (1-5 stars)

-- Add new rating column
ALTER TABLE recipe_logs ADD COLUMN rating SMALLINT;

-- Migrate existing data:
-- SUCCESS → 5 stars
-- PARTIAL → 3 stars
-- FAILED → 1 star
UPDATE recipe_logs SET rating = CASE
    WHEN outcome = 'SUCCESS' THEN 5
    WHEN outcome = 'PARTIAL' THEN 3
    WHEN outcome = 'FAILED' THEN 1
    ELSE 3
END;

-- Add constraints
ALTER TABLE recipe_logs
    ALTER COLUMN rating SET NOT NULL,
    ADD CONSTRAINT chk_recipe_logs_rating CHECK (rating >= 1 AND rating <= 5);

-- Drop old column
ALTER TABLE recipe_logs DROP COLUMN outcome;

-- Add index for rating queries
CREATE INDEX idx_recipe_logs_rating ON recipe_logs(rating);
