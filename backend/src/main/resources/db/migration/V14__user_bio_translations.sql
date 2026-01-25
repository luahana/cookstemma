-- Migration: V14__user_bio_translations.sql
-- Purpose: Add bio_translations JSONB column to users table for multi-language bio support

-- Add bio_translations column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio_translations JSONB DEFAULT '{}';

-- Add GIN index for JSONB operations on bio_translations
CREATE INDEX IF NOT EXISTS idx_users_bio_trans_gin
    ON users USING GIN (bio_translations jsonb_path_ops);

-- Create translatable_entity enum type if it doesn't exist, then add USER value
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'translatable_entity') THEN
        CREATE TYPE translatable_entity AS ENUM ('RECIPE', 'LOG_POST', 'FOOD');
    END IF;
END $$;

DO $$ BEGIN
    ALTER TYPE translatable_entity ADD VALUE IF NOT EXISTS 'USER';
EXCEPTION WHEN duplicate_object THEN null;
END $$;
