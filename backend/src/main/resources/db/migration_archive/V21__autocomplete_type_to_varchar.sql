-- Convert autocomplete_items.type from PostgreSQL enum to VARCHAR for better portability
-- This matches the pattern used by other entities in the codebase

-- Step 1: Add temporary column
ALTER TABLE autocomplete_items ADD COLUMN type_new VARCHAR(30);

-- Step 2: Copy data with explicit cast
UPDATE autocomplete_items SET type_new = type::text;

-- Step 3: Drop old column
ALTER TABLE autocomplete_items DROP COLUMN type;

-- Step 4: Rename new column
ALTER TABLE autocomplete_items RENAME COLUMN type_new TO type;

-- Step 5: Add NOT NULL constraint
ALTER TABLE autocomplete_items ALTER COLUMN type SET NOT NULL;

-- Step 6: Recreate index (old index was dropped with column)
CREATE INDEX IF NOT EXISTS idx_autocomplete_type ON autocomplete_items(type);

-- Step 7: Drop the enum type (no longer needed)
DROP TYPE IF EXISTS autocomplete_type;
