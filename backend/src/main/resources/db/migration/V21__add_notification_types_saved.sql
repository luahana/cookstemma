-- Add RECIPE_SAVED and LOG_SAVED notification types
-- These are required for the save button feature to work properly
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'RECIPE_SAVED';
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'LOG_SAVED';
