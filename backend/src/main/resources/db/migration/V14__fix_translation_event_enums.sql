-- Convert translation_events columns from native enum types to VARCHAR
-- This allows Hibernate @Enumerated(EnumType.STRING) to work properly

-- Step 1: Drop the partial index that references status enum values
DROP INDEX IF EXISTS idx_translation_events_pending;

-- Step 2: Add temporary VARCHAR columns
ALTER TABLE translation_events ADD COLUMN status_temp VARCHAR(20);
ALTER TABLE translation_events ADD COLUMN entity_type_temp VARCHAR(30);

-- Step 3: Copy data (values are already uppercase in the enum)
UPDATE translation_events SET status_temp = status::text;
UPDATE translation_events SET entity_type_temp = entity_type::text;

-- Step 4: Drop old columns
ALTER TABLE translation_events DROP COLUMN status;
ALTER TABLE translation_events DROP COLUMN entity_type;

-- Step 5: Rename temp columns
ALTER TABLE translation_events RENAME COLUMN status_temp TO status;
ALTER TABLE translation_events RENAME COLUMN entity_type_temp TO entity_type;

-- Step 6: Add NOT NULL constraints
ALTER TABLE translation_events ALTER COLUMN status SET NOT NULL;
ALTER TABLE translation_events ALTER COLUMN status SET DEFAULT 'PENDING';
ALTER TABLE translation_events ALTER COLUMN entity_type SET NOT NULL;

-- Step 7: Recreate indexes with VARCHAR columns
CREATE INDEX idx_translation_events_pending ON translation_events(status, created_at)
    WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX idx_translation_events_entity ON translation_events(entity_type, entity_id);

-- Step 8: Drop the native enum types (no longer needed)
DROP TYPE IF EXISTS translation_status;
DROP TYPE IF EXISTS translatable_entity;
