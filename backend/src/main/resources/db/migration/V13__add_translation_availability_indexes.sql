-- Migration: V13__add_translation_availability_indexes.sql
-- Purpose: Add indexes to optimize translation availability filtering
-- This supports the filter: source locale matches OR translation exists

-- Index for extracting language code from recipes.cooking_style (source locale)
-- SUBSTRING(cooking_style FROM 1 FOR 2) extracts "ko" from "ko-KR"
CREATE INDEX IF NOT EXISTS idx_recipes_cooking_style_lang
    ON recipes ((SUBSTRING(cooking_style FROM 1 FOR 2)))
    WHERE deleted_at IS NULL AND is_private = false;

-- Index for extracting language code from log_posts.locale (source locale)
-- SUBSTRING(locale FROM 1 FOR 2) extracts "ko" from "ko-KR"
CREATE INDEX IF NOT EXISTS idx_log_posts_locale_lang
    ON log_posts ((SUBSTRING(locale FROM 1 FOR 2)))
    WHERE deleted_at IS NULL AND is_private = false;

-- GIN index for JSONB key existence checks on recipes.title_translations
-- Supports: title_translations ? 'ko' (check if translation exists for a language)
CREATE INDEX IF NOT EXISTS idx_recipes_title_trans_gin
    ON recipes USING GIN (title_translations)
    WHERE deleted_at IS NULL AND is_private = false;

-- GIN index for JSONB key existence checks on log_posts.title_translations
-- Supports: title_translations ? 'ko' (check if translation exists for a language)
CREATE INDEX IF NOT EXISTS idx_log_posts_title_trans_gin
    ON log_posts USING GIN (title_translations)
    WHERE deleted_at IS NULL AND is_private = false;
