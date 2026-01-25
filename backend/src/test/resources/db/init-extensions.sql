-- Enable pg_trgm extension for full-text search with trigram matching
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Helper function to extract all JSONB values as concatenated text (for multi-language search)
CREATE OR REPLACE FUNCTION jsonb_values_text(j jsonb) RETURNS text AS $$
    SELECT COALESCE(string_agg(value, ' '), '')
    FROM jsonb_each_text(j);
$$ LANGUAGE SQL IMMUTABLE STRICT;
