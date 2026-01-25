-- V19: Add change_reason_translations for variant recipe translations
-- This allows the change_reason field (explaining modifications from parent) to be translated

ALTER TABLE recipes
ADD COLUMN IF NOT EXISTS change_reason_translations JSONB DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN recipes.change_reason_translations IS 'JSONB map of locale -> translated change reason (e.g., {"ko": "...", "en": "..."})';
