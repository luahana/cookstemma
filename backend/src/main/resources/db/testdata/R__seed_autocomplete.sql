-- =============================================================================
-- AUTOCOMPLETE ITEMS - Repeatable Migration (Dev Only)
-- Purpose: Pre-indexed items for search autocomplete
-- =============================================================================

-- Clear and repopulate (idempotent)
TRUNCATE autocomplete_items CASCADE;

-- Reset sequence
ALTER SEQUENCE autocomplete_items_id_seq RESTART WITH 1;

-- Dish types
INSERT INTO autocomplete_items (type, name, score) VALUES
('DISH', '{"ko-KR": "김치찌개", "en-US": "Kimchi Stew"}'::jsonb, 95),
('DISH', '{"ko-KR": "된장찌개", "en-US": "Doenjang Stew"}'::jsonb, 90),
('DISH', '{"ko-KR": "비빔밥", "en-US": "Bibimbap"}'::jsonb, 92),
('DISH', '{"ko-KR": "불고기", "en-US": "Bulgogi"}'::jsonb, 88),
('DISH', '{"ko-KR": "파스타", "en-US": "Pasta"}'::jsonb, 85),
('DISH', '{"ko-KR": "라면", "en-US": "Ramen"}'::jsonb, 94),
('DISH', '{"ko-KR": "삼겹살", "en-US": "Samgyeopsal"}'::jsonb, 91),
('DISH', '{"ko-KR": "치킨", "en-US": "Fried Chicken"}'::jsonb, 93);

-- Main ingredients
INSERT INTO autocomplete_items (type, name, score) VALUES
('MAIN_INGREDIENT', '{"ko-KR": "돼지고기", "en-US": "Pork"}'::jsonb, 90),
('MAIN_INGREDIENT', '{"ko-KR": "소고기", "en-US": "Beef"}'::jsonb, 88),
('MAIN_INGREDIENT', '{"ko-KR": "닭고기", "en-US": "Chicken"}'::jsonb, 92),
('MAIN_INGREDIENT', '{"ko-KR": "두부", "en-US": "Tofu"}'::jsonb, 85),
('MAIN_INGREDIENT', '{"ko-KR": "연어", "en-US": "Salmon"}'::jsonb, 80),
('MAIN_INGREDIENT', '{"ko-KR": "새우", "en-US": "Shrimp"}'::jsonb, 78),
('MAIN_INGREDIENT', '{"ko-KR": "계란", "en-US": "Egg"}'::jsonb, 95);

-- Seasonings
INSERT INTO autocomplete_items (type, name, score) VALUES
('SEASONING', '{"ko-KR": "고추장", "en-US": "Gochujang"}'::jsonb, 90),
('SEASONING', '{"ko-KR": "된장", "en-US": "Doenjang"}'::jsonb, 88),
('SEASONING', '{"ko-KR": "간장", "en-US": "Soy Sauce"}'::jsonb, 95),
('SEASONING', '{"ko-KR": "참기름", "en-US": "Sesame Oil"}'::jsonb, 85),
('SEASONING', '{"ko-KR": "고춧가루", "en-US": "Red Pepper Flakes"}'::jsonb, 87),
('SEASONING', '{"ko-KR": "마늘", "en-US": "Garlic"}'::jsonb, 92);
