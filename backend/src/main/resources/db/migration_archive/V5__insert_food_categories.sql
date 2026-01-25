-- 1. 대분류 삽입 (depth = 1, parent_id IS NULL)
INSERT INTO food_categories (id, code, name, depth, parent_id)
    OVERRIDING SYSTEM VALUE
VALUES
    (1, 'DISH', jsonb_build_object('ko-KR', '요리', 'en-US', 'Dish', 'ja-JP', '料理'), 1, NULL),
    (2, 'DESSERT', jsonb_build_object('ko-KR', '디저트', 'en-US', 'Dessert', 'ja-JP', 'デザート'), 1, NULL),
    (3, 'DRINK', jsonb_build_object('ko-KR', '음료', 'en-US', 'Drink', 'ja-JP', '飲み物'), 1, NULL),
    (4, 'ALCOHOL', jsonb_build_object('ko-KR', '주류', 'en-US', 'Alcohol', 'ja-JP', 'お酒'), 1, NULL),
    (5, 'SNACK', jsonb_build_object('ko-KR', '간식', 'en-US', 'Snack', 'ja-JP', 'おやつ'), 1, NULL),
    (6, 'SAUCE', jsonb_build_object('ko-KR', '소스', 'en-US', 'Sauce', 'ja-JP', 'ソース'), 1, NULL)
ON CONFLICT (id) DO NOTHING;

-- 2. 중분류 삽입 (depth = 2, parent_id 참조)
INSERT INTO food_categories (id, code, name, depth, parent_id)
    OVERRIDING SYSTEM VALUE
VALUES
-- 요리 하위 (Parent: 1)
(101, 'RICE', jsonb_build_object('ko-KR', '밥', 'en-US', 'Rice', 'ja-JP', 'ご飯'), 2, 1),
(102, 'NOODLE', jsonb_build_object('ko-KR', '면', 'en-US', 'Noodle', 'ja-JP', '麺'), 2, 1),
(103, 'MEAT', jsonb_build_object('ko-KR', '고기', 'en-US', 'Meat', 'ja-JP', '肉'), 2, 1),
(104, 'SEAFOOD', jsonb_build_object('ko-KR', '해산물', 'en-US', 'Seafood', 'ja-JP', '海鮮'), 2, 1),
(105, 'VEGETABLE', jsonb_build_object('ko-KR', '채소', 'en-US', 'Vegetable', 'ja-JP', '野菜'), 2, 1),
(106, 'SOUP', jsonb_build_object('ko-KR', '국물요리', 'en-US', 'Soup', 'ja-JP', 'スープ'), 2, 1),
(107, 'SANDWICH', jsonb_build_object('ko-KR', '샌드위치', 'en-US', 'Sandwich', 'ja-JP', 'サンドイッチ'), 2, 1), -- 신규
(107, 'SANDWICH', jsonb_build_object('ko-KR', '샌드위치', 'en-US', 'Sandwich', 'ja-JP', 'サンドイッチ'), 2, 1), -- 신규
(108, 'SALAD', jsonb_build_object('ko-KR', '샐러드', 'en-US', 'Salad', 'ja-JP', 'サラダ'), 2, 1),         -- 신규
(109, 'PIZZA', jsonb_build_object('ko-KR', '피자', 'en-US', 'Pizza', 'ja-JP', 'ピザ'), 2, 1),           -- 신규

-- 디저트 하위 (Parent: 2)
(201, 'BAKERY', jsonb_build_object('ko-KR', '베이커리', 'en-US', 'Bakery', 'ja-JP', 'ベーカリー'), 2, 2),
(202, 'FRUIT', jsonb_build_object('ko-KR', '과일', 'en-US', 'Fruit', 'ja-JP', '果物'), 2, 2),
(203, 'ICECREAM', jsonb_build_object('ko-KR', '아이스크림', 'en-US', 'Icecream', 'ja-JP', 'アイスクリーム'), 2, 2),
(204, 'RICECAKE', jsonb_build_object('ko-KR', '떡', 'en-US', 'Ricecake', 'ja-JP', '餅'), 2, 2),

-- 음료 하위 (Parent: 3)
(301, 'COFFEE', jsonb_build_object('ko-KR', '커피', 'en-US', 'Coffee', 'ja-JP', 'コーヒー'), 2, 3),
(302, 'TEA', jsonb_build_object('ko-KR', '차', 'en-US', 'Tea', 'ja-JP', 'お茶'), 2, 3),
(303, 'SODA', jsonb_build_object('ko-KR', '탄산음료', 'en-US', 'Soda', 'ja-JP', '탄산음료'), 2, 3),
(304, 'JUICE', jsonb_build_object('ko-KR', '주스', 'en-US', 'Juice', 'ja-JP', 'ジュース'), 2, 3),
(305, 'DAIRY', jsonb_build_object('ko-KR', '유제품', 'en-US', 'Dairy', 'ja-JP', '乳製品'), 2, 3),
(306, 'SMOOTHIE', jsonb_build_object('ko-KR', '스무디', 'en-US', 'Smoothie', 'ja-JP', 'スムージー'), 2, 3), -- 신규
(307, 'VEGAN_MILK', jsonb_build_object('ko-KR', '대체유', 'en-US', 'Veganmilk', 'ja-JP', '代替乳'), 2, 3),   -- 신규

-- 주류 하위 (Parent: 4)
(401, 'BEER', jsonb_build_object('ko-KR', '맥주', 'en-US', 'Beer', 'ja-JP', 'ビール'), 2, 4),
(402, 'WINE', jsonb_build_object('ko-KR', '와인', 'en-US', 'Wine', 'ja-JP', 'ワイン'), 2, 4),
(403, 'TRADITIONAL', jsonb_build_object('ko-KR', '전통주', 'en-US', 'Traditional', 'ja-JP', '伝統酒'), 2, 4),
(404, 'SPIRITS', jsonb_build_object('ko-KR', '증류주', 'en-US', 'Spirits', 'ja-JP', '蒸留酒'), 2, 4),
(405, 'CIDER', jsonb_build_object('ko-KR', '사이더', 'en-US', 'Cider', 'ja-JP', 'サイダー'), 2, 4),          -- 신규

-- 간식 하위 (Parent: 5)
(501, 'SNACK_CRACKER', jsonb_build_object('ko-KR', '과자', 'en-US', 'Snack', 'ja-JP', 'スナック菓子'), 2, 5),
(502, 'CANDY', jsonb_build_object('ko-KR', '사탕젤리', 'en-US', 'Candy', 'ja-JP', 'キャン디'), 2, 5),
(503, 'NUTS', jsonb_build_object('ko-KR', '견과류', 'en-US', 'Nuts', 'ja-JP', 'ナッツ'), 2, 5),
(504, 'DRIED', jsonb_build_object('ko-KR', '마른안주', 'en-US', 'Dried', 'ja-JP', '干物'), 2, 5),
(505, 'CEREAL', jsonb_build_object('ko-KR', '시리얼', 'en-US', 'Cereal', 'ja-JP', 'シリアル'), 2, 5),        -- 신규
(506, 'PROTEIN_BAR', jsonb_build_object('ko-KR', '에너지바', 'en-US', 'Proteinbar', 'ja-JP', 'プロテインバー'), 2, 5), -- 신규

-- 소스 하위 (Parent: 6)
(601, 'OIL', jsonb_build_object('ko-KR', '오일', 'en-US', 'Oil', 'ja-JP', 'オイル'), 2, 6),
(602, 'PASTE', jsonb_build_object('ko-KR', '장류', 'en-US', 'Paste', 'ja-JP', '味噌'), 2, 6),
(603, 'SYRUP', jsonb_build_object('ko-KR', '시럽', 'en-US', 'Syrup', 'ja-JP', 'シロップ'), 2, 6),
(604, 'SEASONING', jsonb_build_object('ko-KR', '양념', 'en-US', 'Seasoning', 'ja-JP', '調味料'), 2, 6),
(605, 'DRESSING', jsonb_build_object('ko-KR', '드레싱', 'en-US', 'Dressing', 'ja-JP', 'ドレッシング'), 2, 6), -- 신규
(606, 'SPREAD', jsonb_build_object('ko-KR', '스프레드', 'en-US', 'Spread', 'ja-JP', 'スプレッド'), 2, 6)     -- 신규
ON CONFLICT (id) DO NOTHING;

-- 3. ID 시퀀스 동기화
SELECT setval(pg_get_serial_sequence('food_categories', 'id'), COALESCE(MAX(id), 1)) FROM food_categories;