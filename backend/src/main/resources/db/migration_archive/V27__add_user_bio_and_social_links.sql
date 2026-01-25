-- Add bio and social media fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR(150);
ALTER TABLE users ADD COLUMN IF NOT EXISTS youtube_url VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS instagram_handle VARCHAR(30);
