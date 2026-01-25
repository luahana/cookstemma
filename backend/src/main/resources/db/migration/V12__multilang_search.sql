-- V12: Multi-language search support
-- Adds helper function and indexes for searching JSONB translation fields

-- Helper function to extract all JSONB values as concatenated text
CREATE OR REPLACE FUNCTION jsonb_values_text(j jsonb) RETURNS text AS $$
    SELECT COALESCE(string_agg(value, ' '), '')
    FROM jsonb_each_text(j);
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- Trigram indexes for translation JSONB fields (recipes)
CREATE INDEX idx_recipes_title_trans_trgm
    ON recipes USING GIN (jsonb_values_text(title_translations) gin_trgm_ops);

CREATE INDEX idx_recipes_desc_trans_trgm
    ON recipes USING GIN (jsonb_values_text(description_translations) gin_trgm_ops);

-- Trigram indexes for recipe_ingredients translations
CREATE INDEX idx_ri_name_trans_trgm
    ON recipe_ingredients USING GIN (jsonb_values_text(name_translations) gin_trgm_ops);

-- Trigram indexes for recipe_steps (base + translations)
CREATE INDEX idx_rs_desc_trgm
    ON recipe_steps USING GIN (description gin_trgm_ops);

CREATE INDEX idx_rs_desc_trans_trgm
    ON recipe_steps USING GIN (jsonb_values_text(description_translations) gin_trgm_ops);

-- Trigram indexes for log_posts translations
CREATE INDEX idx_lp_title_trans_trgm
    ON log_posts USING GIN (jsonb_values_text(title_translations) gin_trgm_ops);

CREATE INDEX idx_lp_content_trans_trgm
    ON log_posts USING GIN (jsonb_values_text(content_translations) gin_trgm_ops);

-- Trigram index for foods_master multilingual name JSONB
CREATE INDEX idx_fm_name_trgm
    ON foods_master USING GIN (jsonb_values_text(name) gin_trgm_ops);
