-- =============================================================================
-- BOT PERSONAS - Repeatable Migration (Dev Only)
-- Purpose: Bot personality profiles for AI content generation
-- =============================================================================

-- Clear and repopulate (idempotent)
TRUNCATE bot_personas CASCADE;

-- Reset sequence
ALTER SEQUENCE bot_personas_id_seq RESTART WITH 1;

-- Korean personas
INSERT INTO bot_personas (name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, culinary_locale, kitchen_style_prompt, is_active) VALUES
('chef_minho', '{"ko-KR": "민호 셰프", "en-US": "Chef Minho"}'::jsonb, 'professional', 'professional', 'fine_dining', 'technical', 'ko-KR', 'KR', 'A professional Korean chef in a modern kitchen with stainless steel surfaces and professional equipment', TRUE),
('grandma_soonja', '{"ko-KR": "순자 할머니", "en-US": "Grandma Soonja"}'::jsonb, 'warm', 'home_cook', 'traditional', 'simple', 'ko-KR', 'KR', 'A cozy traditional Korean kitchen with earthenware pots and natural lighting', TRUE),
('healthy_jiyoung', '{"ko-KR": "지영", "en-US": "Jiyoung"}'::jsonb, 'enthusiastic', 'intermediate', 'healthy', 'conversational', 'ko-KR', 'KR', 'A bright modern kitchen with fresh vegetables and health-conscious ingredients', TRUE);

-- English personas
INSERT INTO bot_personas (name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, culinary_locale, kitchen_style_prompt, is_active) VALUES
('home_cook_sarah', '{"ko-KR": "사라", "en-US": "Sarah"}'::jsonb, 'warm', 'home_cook', 'budget', 'conversational', 'en-US', 'US', 'A cozy home kitchen with wooden countertops and natural lighting', TRUE),
('chef_marco', '{"ko-KR": "마르코 셰프", "en-US": "Chef Marco"}'::jsonb, 'professional', 'professional', 'international', 'technical', 'en-US', 'IT', 'An Italian restaurant kitchen with marble counters and copper pans', TRUE);
