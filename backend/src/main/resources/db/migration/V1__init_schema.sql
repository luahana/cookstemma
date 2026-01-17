-- =============================================================================
-- PAIRING PLANET - DATABASE INITIALIZATION
-- Purpose: Core infrastructure and ENUMs (functions are in R__functions.sql)
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Trigram search

-- =============================================================================
-- ENUM TYPES
-- =============================================================================

-- User account status
CREATE TYPE account_status AS ENUM ('ACTIVE', 'BANNED', 'DELETED');

-- User roles
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'CREATOR');

-- Gender options
CREATE TYPE gender_type AS ENUM ('MALE', 'FEMALE', 'OTHER');

-- Social providers
CREATE TYPE social_provider AS ENUM ('GOOGLE', 'NAVER', 'KAKAO', 'APPLE');

-- Image processing status
CREATE TYPE image_status AS ENUM ('PROCESSING', 'ACTIVE', 'DELETED');

-- Image types
CREATE TYPE image_type AS ENUM ('COVER', 'STEP', 'LOG', 'LOG_POST');

-- Image variant sizes
CREATE TYPE image_variant AS ENUM ('ORIGINAL', 'LARGE_1200', 'MEDIUM_800', 'THUMB_400', 'THUMB_200');

-- Cooking outcome
CREATE TYPE cooking_outcome AS ENUM ('SUCCESS', 'PARTIAL', 'FAILED');

-- Notification types
CREATE TYPE notification_type AS ENUM ('RECIPE_COOKED', 'RECIPE_VARIATION', 'NEW_FOLLOWER');

-- Report reasons
CREATE TYPE report_reason AS ENUM ('SPAM', 'HARASSMENT', 'INAPPROPRIATE_CONTENT', 'IMPERSONATION', 'OTHER');

-- Device types
CREATE TYPE device_type AS ENUM ('ANDROID', 'IOS', 'WEB');

-- Measurement units
CREATE TYPE measurement_unit AS ENUM (
    'G', 'KG', 'ML', 'L', 'TSP', 'TBSP', 'CUP',
    'PIECE', 'SLICE', 'BUNCH', 'PINCH', 'DASH'
);

-- Ingredient types
CREATE TYPE ingredient_type AS ENUM ('MAIN', 'SECONDARY', 'SEASONING', 'GARNISH');

-- Cooking time ranges
CREATE TYPE cooking_time_range AS ENUM (
    'UNDER_15_MIN', 'MIN_15_TO_30', 'MIN_30_TO_60', 'HOUR_1_TO_2', 'OVER_2_HOURS'
);

-- Bot personality tones
CREATE TYPE bot_tone AS ENUM (
    'professional', 'casual', 'warm', 'enthusiastic', 'educational', 'motivational'
);

-- Bot skill levels
CREATE TYPE bot_skill_level AS ENUM ('professional', 'intermediate', 'beginner', 'home_cook');

-- Bot vocabulary styles
CREATE TYPE bot_vocabulary_style AS ENUM ('technical', 'simple', 'conversational');

-- NOTE: Utility functions are in R__functions.sql (repeatable migration)
