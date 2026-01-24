-- V18: Convert search_keywords from TEXT to JSONB for multilingual keyword storage
-- This migration:
-- 1. Converts existing TEXT data to JSONB, wrapping in {"en": "..."} if not empty
-- 2. Creates GIN index for efficient JSONB search

-- Convert search_keywords from TEXT to JSONB
-- Using a simpler USING clause that PostgreSQL handles better
ALTER TABLE foods_master
ALTER COLUMN search_keywords TYPE jsonb
USING (
    CASE
        WHEN search_keywords IS NOT NULL AND TRIM(search_keywords) != ''
        THEN jsonb_build_object('en', search_keywords)
        ELSE '{}'::jsonb
    END
);

-- Add GIN index for efficient JSONB search operations
CREATE INDEX IF NOT EXISTS idx_foods_master_search_keywords ON foods_master USING GIN (search_keywords);

-- Add comment explaining the structure
COMMENT ON COLUMN foods_master.search_keywords IS 'JSONB map of locale -> comma-separated keywords. Example: {"en": "kimchi stew, korean food", "ko": "김치찌개, 한식"}';
