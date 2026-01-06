-- V6__add_change_tracking.sql
-- Phase 7-2: Add change tracking fields for recipe variations
-- Enables automatic change detection with soft delete tracking

-- Add structured diff for visualization (stores what changed from parent)
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS change_diff JSONB DEFAULT '{}';

-- Add optional user's reason for changes (max 200 chars enforced at app level)
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS change_reason TEXT;

-- Add auto-detected categories (JSONB array of strings)
-- Categories: INGREDIENT, TECHNIQUE, AMOUNT, SEASONING
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS change_categories JSONB DEFAULT '[]';

-- Add constraint for change_reason length
ALTER TABLE recipes ADD CONSTRAINT check_change_reason_length
CHECK (change_reason IS NULL OR LENGTH(change_reason) <= 200);

-- GIN index for category-based queries (future: filter by change category)
CREATE INDEX IF NOT EXISTS idx_recipes_change_categories ON recipes USING GIN (change_categories);

-- Comment documenting the change_diff structure
COMMENT ON COLUMN recipes.change_diff IS 'JSONB structure: {
  "ingredients": {
    "removed": ["청양고추 3개"],
    "added": ["파프리카 1개"],
    "modified": [{"from": "닭 500g", "to": "닭 600g"}]
  },
  "steps": {
    "removed": ["2. 청양고추를 썬다"],
    "added": ["2. 파프리카를 썬다"],
    "modified": []
  }
}';

COMMENT ON COLUMN recipes.change_reason IS 'User-provided reason for the changes, max 200 chars';

COMMENT ON COLUMN recipes.change_categories IS 'Auto-detected categories: ["INGREDIENT", "TECHNIQUE", "AMOUNT", "SEASONING"]';
