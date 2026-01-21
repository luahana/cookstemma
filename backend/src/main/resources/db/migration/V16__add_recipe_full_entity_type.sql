-- Add RECIPE_FULL entity type for context-aware recipe translation
-- This allows translating entire recipes (title, description, steps, ingredients) in a single API call

-- Add RECIPE_FULL to translatable_entity enum
DO $$ BEGIN
    ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'RECIPE_FULL';
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Migrate existing pending RECIPE events to RECIPE_FULL
-- This will cause them to be re-translated with full context
UPDATE translation_events
SET entity_type = 'RECIPE_FULL'
WHERE entity_type = 'RECIPE'
  AND status IN ('PENDING', 'FAILED');

-- Delete orphaned step/ingredient events that are still pending
-- These will now be handled as part of RECIPE_FULL
DELETE FROM translation_events
WHERE entity_type IN ('RECIPE_STEP', 'RECIPE_INGREDIENT')
  AND status IN ('PENDING', 'FAILED');
