-- Fix log_posts column types to TEXT
-- The columns should be TEXT but may have been created as VARCHAR(255) by Hibernate

ALTER TABLE log_posts ALTER COLUMN title TYPE TEXT;
ALTER TABLE log_posts ALTER COLUMN content TYPE TEXT;
