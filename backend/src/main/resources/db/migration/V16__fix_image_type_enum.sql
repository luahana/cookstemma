-- Add LOG_POST to image_type enum (Java uses LOG_POST, database had LOG)
ALTER TYPE image_type ADD VALUE IF NOT EXISTS 'LOG_POST';
