-- Migration: V14__user_bio_translations.sql
-- Purpose: Add bio_translations JSONB column to users table for multi-language bio support

-- Add bio_translations column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio_translations JSONB DEFAULT '{}';

-- Add GIN index for JSONB operations on bio_translations
CREATE INDEX IF NOT EXISTS idx_users_bio_trans_gin
    ON users USING GIN (bio_translations jsonb_path_ops);

-- Add USER value to translatable_entity enum
DO $$ BEGIN
    ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'USER';
EXCEPTION WHEN duplicate_object THEN null;
END $$;
