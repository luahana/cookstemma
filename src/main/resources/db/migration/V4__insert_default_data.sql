-- 1. Dimensions (대분류) 데이터 삽입
INSERT INTO context_dimensions (name)
VALUES
    ('when'),
    ('dietary')
    ON CONFLICT (name) DO NOTHING;

-- 2. Tags (태그) 데이터 삽입 ('when' 디멘션 하위)
INSERT INTO context_tags (dimension_id, tag_name, display_name, locale, display_order)
VALUES
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'none', '✨ 일상', 'ko-KR', 0),
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'alone', '🏠 혼밥', 'ko-KR', 1),
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'date', '🕯️ 데이트', 'ko-KR', 2),
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'cost_effective', '💡 갓성비', 'ko-KR', 3),
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'gathering', '👥 모임', 'ko-KR', 4),
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'night_snack', '🌙 야식', 'ko-KR', 5),
    ((SELECT id FROM context_dimensions WHERE name = 'when'), 'sick', '🤒 아플 때', 'ko-KR', 6)
    ON CONFLICT (dimension_id, tag_name, locale) DO NOTHING;

-- 3. Tags (태그) 데이터 삽입 ('dietary' 디멘션 하위)
-- 순서: 일반식, 저탄고지, 고단저지, 저당식, 클린식, 채식, 비건
INSERT INTO context_tags (dimension_id, tag_name, display_name, locale, display_order)
VALUES
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'none', '일반식', 'ko-KR', 0),
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'lchf', '🥑 저탄고지', 'ko-KR', 1),
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'hplf', '🥩 고단저지', 'ko-KR', 2),
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'low_sugar', '🚫 저당식', 'ko-KR', 3),
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'clean', '🥗 클린식', 'ko-KR', 4),
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'vegetarian', '🥦 채식', 'ko-KR', 5),
    ((SELECT id FROM context_dimensions WHERE name = 'dietary'), 'vegan', '🌿 비건', 'ko-KR', 6)
    ON CONFLICT (dimension_id, tag_name, locale) DO NOTHING;