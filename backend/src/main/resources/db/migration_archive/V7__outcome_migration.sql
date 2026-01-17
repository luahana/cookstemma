-- V7: Migrate rating to outcome for log posts
-- Phase 7-1: UX Spec Alignment - Emoji Outcome

-- Add outcome column
ALTER TABLE recipe_logs
ADD COLUMN outcome VARCHAR(20);

-- Migrate existing ratings to outcomes
UPDATE recipe_logs SET outcome = CASE
    WHEN rating >= 4 THEN 'SUCCESS'
    WHEN rating = 3 THEN 'PARTIAL'
    WHEN rating <= 2 THEN 'FAILED'
    ELSE 'PARTIAL'
END;

-- Make outcome NOT NULL after migration
ALTER TABLE recipe_logs
ALTER COLUMN outcome SET NOT NULL;

-- Add CHECK constraint
ALTER TABLE recipe_logs
ADD CONSTRAINT chk_outcome
CHECK (outcome IN ('SUCCESS', 'PARTIAL', 'FAILED'));

-- Drop old rating column
ALTER TABLE recipe_logs DROP COLUMN rating;
