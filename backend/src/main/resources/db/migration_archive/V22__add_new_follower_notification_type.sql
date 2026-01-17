-- V22: Add NEW_FOLLOWER to notification types
-- The notifications table has a check constraint that only allows specific types.
-- This migration adds NEW_FOLLOWER to the allowed types.

-- Drop the existing constraint
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Add new constraint with NEW_FOLLOWER included
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
    CHECK (type IN ('RECIPE_COOKED', 'RECIPE_VARIATION', 'NEW_FOLLOWER'));
