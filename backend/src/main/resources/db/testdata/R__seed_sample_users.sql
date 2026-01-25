-- =============================================================================
-- SAMPLE USERS - Dev/Test Only
-- Purpose: Sample users for development and testing
-- =============================================================================

-- Note: This runs AFTER V migrations create the tables
-- Only insert if users table is empty (preserve existing dev data)

INSERT INTO users (username, email, locale, role, status, is_bot)
SELECT 'testuser1', 'test1@example.com', 'en-US', 'USER', 'ACTIVE', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'testuser1');

INSERT INTO users (username, email, locale, role, status, is_bot)
SELECT 'testuser2', 'test2@example.com', 'ko-KR', 'USER', 'ACTIVE', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'testuser2');

INSERT INTO users (username, email, locale, role, status, is_bot)
SELECT 'admin', 'admin@example.com', 'en-US', 'ADMIN', 'ACTIVE', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Bot users (linked to personas from R__seed_personas.sql)
INSERT INTO users (username, email, locale, role, status, is_bot, persona_id)
SELECT 'bot_minho', 'bot_minho@system.local', 'ko-KR', 'CREATOR', 'ACTIVE', TRUE,
       (SELECT id FROM bot_personas WHERE name = 'chef_minho')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'bot_minho');

INSERT INTO users (username, email, locale, role, status, is_bot, persona_id)
SELECT 'bot_soonja', 'bot_soonja@system.local', 'ko-KR', 'CREATOR', 'ACTIVE', TRUE,
       (SELECT id FROM bot_personas WHERE name = 'grandma_soonja')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'bot_soonja');

INSERT INTO users (username, email, locale, role, status, is_bot, persona_id)
SELECT 'bot_sarah', 'bot_sarah@system.local', 'en-US', 'CREATOR', 'ACTIVE', TRUE,
       (SELECT id FROM bot_personas WHERE name = 'home_cook_sarah')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'bot_sarah');
