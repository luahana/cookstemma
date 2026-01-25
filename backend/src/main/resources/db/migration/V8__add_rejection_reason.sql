-- V8: Add rejection_reason column to suggestion tables for AI verifier

-- Add rejection_reason column to user_suggested_foods
ALTER TABLE user_suggested_foods
ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR(500);

-- Add rejection_reason column to user_suggested_ingredients
ALTER TABLE user_suggested_ingredients
ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR(500);

-- Add comments for documentation
COMMENT ON COLUMN user_suggested_foods.rejection_reason IS 'English rejection reason from AI verifier';
COMMENT ON COLUMN user_suggested_ingredients.rejection_reason IS 'English rejection reason from AI verifier';
