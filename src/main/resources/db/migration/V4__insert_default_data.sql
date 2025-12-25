-- 1. Dimensions (대분류) 데이터 삽입
INSERT INTO context_dimensions (name)
VALUES
    ('when'),
    ('dietary')
    ON CONFLICT (name) DO NOTHING;

-- 2. Tags (태그) 데이터 삽입 ('when' 디멘션 하위)
INSERT INTO context_tags (dimension_id, tag_name, display_name, locale, display_order)
VALUES
    (
        (SELECT id FROM context_dimensions WHERE name = 'when'), -- 'when'의 ID를 자동으로 찾음
        'daily',
        '✨ 일상',
        'ko-KR',
        0
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'when'),
        'date',
        '🕯️ 데이트',
        'ko-KR',
        1
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'when'),
        'alone',
        '🏠 혼술/혼밥',
        'ko-KR',
        2
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'when'),
        'party',
        '🎉 홈파티',
        'ko-KR',
        3
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'when'),
        'camping',
        '⛰️ 캠핑',
        'ko-KR',
        4
    )
    ON CONFLICT (dimension_id, tag_name, locale) DO NOTHING;

INSERT INTO context_tags (dimension_id, tag_name, display_name, locale, display_order)
VALUES
    (
        (SELECT id FROM context_dimensions WHERE name = 'dietary'),
        'none',
        '일반식',
        'ko-KR',
        0
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'dietary'),
        'lchf',
        '🥑 저탄고지',
        'ko-KR',
        1
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'dietary'),
        'vegan',
        '🌿 비건',
        'ko-KR',
        2
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'dietary'),
        'diet',
        '🍎 다이어트',
        'ko-KR',
        3
    ),
    (
        (SELECT id FROM context_dimensions WHERE name = 'dietary'),
        'diabetes',
        '🚫 당뇨주의',
        'ko-KR',
        4
    )
    ON CONFLICT (dimension_id, tag_name, locale) DO NOTHING;