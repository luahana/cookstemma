-- =============================================================================
-- FOODS MASTER - Dev/Test Only
-- Purpose: Sample foods for development and testing
-- =============================================================================

-- Only insert if foods_master table is empty (preserve existing dev data)
INSERT INTO foods_master (name, description, category_id, food_score)
SELECT
    '{"ko-KR": "김치찌개", "en-US": "Kimchi Stew"}'::jsonb,
    '{"ko-KR": "발효된 김치로 만든 얼큰한 찌개", "en-US": "A spicy stew made with fermented kimchi"}'::jsonb,
    (SELECT id FROM food_categories WHERE code = 'KOREAN'),
    95.0
WHERE NOT EXISTS (SELECT 1 FROM foods_master WHERE name->>'en-US' = 'Kimchi Stew');

INSERT INTO foods_master (name, description, category_id, food_score)
SELECT
    '{"ko-KR": "비빔밥", "en-US": "Bibimbap"}'::jsonb,
    '{"ko-KR": "다양한 나물과 고추장을 곁들인 밥", "en-US": "Rice with assorted vegetables and gochujang"}'::jsonb,
    (SELECT id FROM food_categories WHERE code = 'KOREAN'),
    92.0
WHERE NOT EXISTS (SELECT 1 FROM foods_master WHERE name->>'en-US' = 'Bibimbap');

INSERT INTO foods_master (name, description, category_id, food_score)
SELECT
    '{"ko-KR": "된장찌개", "en-US": "Doenjang Stew"}'::jsonb,
    '{"ko-KR": "된장으로 맛을 낸 구수한 찌개", "en-US": "A savory stew made with fermented soybean paste"}'::jsonb,
    (SELECT id FROM food_categories WHERE code = 'KOREAN'),
    90.0
WHERE NOT EXISTS (SELECT 1 FROM foods_master WHERE name->>'en-US' = 'Doenjang Stew');

INSERT INTO foods_master (name, description, category_id, food_score)
SELECT
    '{"ko-KR": "불고기", "en-US": "Bulgogi"}'::jsonb,
    '{"ko-KR": "달콤한 양념에 재운 소고기 구이", "en-US": "Marinated beef grilled to perfection"}'::jsonb,
    (SELECT id FROM food_categories WHERE code = 'KOREAN'),
    88.0
WHERE NOT EXISTS (SELECT 1 FROM foods_master WHERE name->>'en-US' = 'Bulgogi');

INSERT INTO foods_master (name, description, category_id, food_score)
SELECT
    '{"ko-KR": "파스타", "en-US": "Pasta"}'::jsonb,
    '{"ko-KR": "이탈리아 전통 면요리", "en-US": "Traditional Italian pasta dish"}'::jsonb,
    (SELECT id FROM food_categories WHERE code = 'WESTERN'),
    85.0
WHERE NOT EXISTS (SELECT 1 FROM foods_master WHERE name->>'en-US' = 'Pasta');
