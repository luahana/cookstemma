-- [101] 요리 - 밥 (Rice)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '비빔밥', 'en-US', 'Bibimbap', 'ja-JP', 'ビビンバ'),
                                                                                jsonb_build_object('ko-KR', '각종 나물과 고추장, 달걀 등을 밥과 비벼 먹는 한국 전통 요리', 'en-US', 'Traditional Korean rice mixed with vegetables, meat, and red chili paste.'),
                                                                                '비빔밥, 비빕밥, 비븸밥, bibimbap, 섞어밥, 골동반, v-bap'),
                                                                               (101, jsonb_build_object('ko-KR', '김밥', 'en-US', 'Gimbap', 'ja-JP', 'キンパ'),
                                                                                jsonb_build_object('ko-KR', '김 위에 밥과 다양한 속재료를 올리고 말아 한입 크기로 썬 음식', 'en-US', 'Rice and various ingredients rolled in dried seaweed.'),
                                                                                '김밥, 긴밥, 기맘, gimbap, kimbap, 삼각김밥, 꼬마김밥, 분식'),
                                                                               (101, jsonb_build_object('ko-KR', '볶음밥', 'en-US', 'Fried Rice', 'ja-JP', 'チャーハン'),
                                                                                jsonb_build_object('ko-KR', '밥을 채소, 고기 등과 함께 기름에 볶아낸 요리', 'en-US', 'Rice stir-fried with vegetables, meat, and eggs in a pan.'),
                                                                                '볶음밥, 보끔밥, fried rice, 중식볶음밥, 계란볶음밥, 김치볶음밥'),
                                                                               (101, jsonb_build_object('ko-KR', '초밥', 'en-US', 'Sushi', 'ja-JP', '寿司'),
                                                                                jsonb_build_object('ko-KR', '식초로 간을 한 밥 위에 신선한 생선이나 해산물을 올린 일본 요리', 'en-US', 'Vinegared rice topped with fresh raw fish or seafood.'),
                                                                                '초밥, 스시, sushi, 회밥, 생선초밥, 오마카세, 스시롤'),
                                                                               (101, jsonb_build_object('ko-KR', '리조또', 'en-US', 'Risotto', 'ja-JP', 'リゾット'),
                                                                                jsonb_build_object('ko-KR', '쌀을 육수와 함께 익혀 부드러운 식감을 내는 이탈리아식 쌀요리', 'en-US', 'Creamy Italian rice dish cooked with broth and various ingredients.'),
                                                                                '리조또, 리조토, risotto, 크림리조또, 이태리밥, 쌀죽'),
                                                                               (101, jsonb_build_object('ko-KR', '파에야', 'en-US', 'Paella', 'ja-JP', 'パエリア'),
                                                                                jsonb_build_object('ko-KR', '해산물과 고기, 사프란을 넣어 만든 스페인 전통 팬 요리', 'en-US', 'Spanish rice dish cooked in a large shallow pan with seafood and saffron.'),
                                                                                '파에야, 빠에야, paella, 스페인볶음밥, 해산물밥'),
                                                                               (101, jsonb_build_object('ko-KR', '포케', 'en-US', 'Poke Bowl', 'ja-JP', 'ポキ丼'),
                                                                                jsonb_build_object('ko-KR', '신선한 생선회와 채소를 소스에 버무려 밥 위에 올린 하와이식 덮밥', 'en-US', 'Hawaiian dish of diced raw fish served over rice with vegetables.'),
                                                                                '포케, poke, 하와이안덮밥, 회덮밥, 다이어트식단, 포케보울'),
                                                                               (101, jsonb_build_object('ko-KR', '나시고랭', 'en-US', 'Nasi Goreng', 'ja-JP', 'ナシゴレン'),
                                                                                jsonb_build_object('ko-KR', '특유의 향신료와 소스로 볶아낸 인도네시아식 볶음밥', 'en-US', 'Flavorful Indonesian fried rice cooked with spices and meat.'),
                                                                                '나시고랭, 나시고렝, nasi goreng, 동남아볶음밥, 인도네시아음식'),
                                                                               (101, jsonb_build_object('ko-KR', '오므라이스', 'en-US', 'Omurice', 'ja-JP', 'オムライス'),
                                                                                jsonb_build_object('ko-KR', '볶은 밥을 얇은 달걀지단으로 감싼 요리', 'en-US', 'Fried rice wrapped in a thin omelet, often served with sauce.'),
                                                                                '오므라이스, 오무라이스, omurice, 계란덮밥, 오믈렛라이스'),
                                                                               (101, jsonb_build_object('ko-KR', '국밥', 'en-US', 'Gukbap', 'ja-JP', 'クッパ'),
                                                                                jsonb_build_object('ko-KR', '진한 국물에 밥을 말아 먹는 한국의 대중적인 식사', 'en-US', 'Korean soup served with rice, typically beef, pork, or sprout broth.'),
                                                                                '국밥, 쿡파, gukbap, 순대국밥, 돼지국밥, 해장국, 탕반') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Noodle)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '파스타', 'en-US', 'Pasta', 'ja-JP', 'パスタ'),
                                                                                jsonb_build_object('ko-KR', '이탈리아의 대표적인 면 요리로 소스에 따라 종류가 다양함', 'en-US', 'Versatile Italian noodle dish served with various sauces.'),
                                                                                '파스타, 스파게티, pasta, spaghetti, 면요리, 이태리국수'),
                                                                               (102, jsonb_build_object('ko-KR', '라면', 'en-US', 'Ramen', 'ja-JP', 'ラーメン'),
                                                                                jsonb_build_object('ko-KR', '튀긴 면과 매콤한 국물이 특징인 한국의 대표 인스턴트 식품', 'en-US', 'Popular instant or fresh noodles in savory, spicy broth.'),
                                                                                '라면, 라묜, ramen, 인스턴트, 컵라면, 생라면, 신라면, 불닭'),
                                                                               (102, jsonb_build_object('ko-KR', '냉면', 'en-US', 'Naengmyeon', 'ja-JP', '冷麺'),
                                                                                jsonb_build_object('ko-KR', '시원한 육수나 매콤한 양념에 비벼 먹는 차가운 면 요리', 'en-US', 'Cold Korean buckwheat noodles served in chilled broth or spicy sauce.'),
                                                                                '냉면, 물냉, 비냉, naengmyeon, 평양냉면, 함흥냉면, 살얼음국수'),
                                                                               (102, jsonb_build_object('ko-KR', '우동', 'en-US', 'Udon', 'ja-JP', 'うどん'),
                                                                                jsonb_build_object('ko-KR', '두꺼운 면발과 맑은 가쓰오부시 육수가 특징인 일본식 면 요리', 'en-US', 'Thick Japanese wheat noodles served in a hot dashi broth.'),
                                                                                '우동, udon, 가락국수, 튀김우동, 일식국수'),
                                                                               (102, jsonb_build_object('ko-KR', '까르보나라', 'en-US', 'Carbonara', 'ja-JP', 'カルボナーラ'),
                                                                                jsonb_build_object('ko-KR', '베이컨, 달걀, 치즈를 베이스로 만든 고소한 크림 파스타', 'en-US', 'Classic Italian pasta with bacon, eggs, cheese, and cream.'),
                                                                                '까르보나라, 카르보나라, carbonara, 크림스파게티, 까르보'),
                                                                               (102, jsonb_build_object('ko-KR', '자장면', 'en-US', 'Jajangmyeon', 'ja-JP', 'ジャジャン麺'),
                                                                                jsonb_build_object('ko-KR', '춘장을 볶아 만든 검은색 소스에 면을 비벼 먹는 한국식 중화요리', 'en-US', 'Korean-Chinese noodles topped with a savory black bean sauce.'),
                                                                                '자장면, 짜장면, 짜장, jajangmyeon, jjajangmyeon, 중식, 블랙데이') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Meat)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '스테이크', 'en-US', 'Steak', 'ja-JP', 'ステーキ'),
                                                                                jsonb_build_object('ko-KR', '두꺼운 소고기를 그릴에 구워낸 고기 요리', 'en-US', 'Thick slice of beef grilled or pan-seared to preference.'),
                                                                                '스테이크, 스테끼, steak, 소고기구이, 등심, 안심, 티본'),
                                                                               (103, jsonb_build_object('ko-KR', '삼겹살', 'en-US', 'Grilled Pork Belly', 'ja-JP', 'サムギョプサル'),
                                                                                jsonb_build_object('ko-KR', '돼지의 삼겹 부위를 구워 채소와 쌈을 싸 먹는 한국 요리', 'en-US', 'Grilled slices of pork belly served with lettuce and ssamjang.'),
                                                                                '삼겹살, 겹살이, 오겹살, pork belly, bbq, 돼지고기구이, 회식메뉴'),
                                                                               (103, jsonb_build_object('ko-KR', '치킨', 'en-US', 'Fried Chicken', 'ja-JP', 'フライドチキン'),
                                                                                jsonb_build_object('ko-KR', '닭고기에 튀김옷을 입혀 바삭하게 튀겨낸 전 세계적인 인기 요리', 'en-US', 'Deep-fried chicken with a crispy crust, a global favorite.'),
                                                                                '치킨, 통닭, 프라이드치킨, 양념치킨, fried chicken, 치느님, 닭튀김'),
                                                                               (103, jsonb_build_object('ko-KR', '불고기', 'en-US', 'Bulgogi', 'ja-JP', 'プルコギ'),
                                                                                jsonb_build_object('ko-KR', '얇게 썬 소고기를 달콤한 간장 양념에 재워 구워낸 한국 요리', 'en-US', 'Thinly sliced beef marinated in sweet soy sauce and grilled.'),
                                                                                '불고기, 불고기덮밥, bulgogi, 간장불고기, 뚝배기불고기'),
                                                                               (103, jsonb_build_object('ko-KR', '햄버거', 'en-US', 'Hamburger', 'ja-JP', 'ハンバーガー'),
                                                                                jsonb_build_object('ko-KR', '빵 사이에 고기 패티와 각종 채소, 소스를 넣어 만든 음식', 'en-US', 'Sandwich with a ground meat patty, vegetables, and condiments in a bun.'),
                                                                                '햄버거, 버거, burger, 패스트푸드, 수제버거, 와퍼, 빅맥'),
                                                                               (103, jsonb_build_object('ko-KR', '돈카츠', 'en-US', 'Tonkatsu', 'ja-JP', 'とんかつ'),
                                                                                jsonb_build_object('ko-KR', '돼지고기에 빵가루를 입혀 바삭하게 튀겨낸 일본식 요리', 'en-US', 'Breaded and deep-fried pork cutlet, served with sauce and cabbage.'),
                                                                                '돈카츠, 돈까스, 돈가스, tonkatsu, 포크커틀릿, 일식돈까스') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Coffee)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (301, jsonb_build_object('ko-KR', '플랫화이트', 'en-US', 'Flat White', 'ja-JP', 'フラットホワイト'),
                                                                                jsonb_build_object('ko-KR', '에스프레소에 미세한 우유 거품을 섞어 부드럽고 진한 맛을 내는 커피', 'en-US', 'Espresso mixed with a thin layer of microfoam milk for a smooth taste.'),
                                                                                '플랫화이트, flat white, 호주커피, 라떼보다진한, 커피'),
                                                                               (301, jsonb_build_object('ko-KR', '에스프레소', 'en-US', 'Espresso', 'ja-JP', 'エスプレッソ'),
                                                                                jsonb_build_object('ko-KR', '높은 압력으로 빠르게 추출한 진한 커피의 원액', 'en-US', 'Concentrated coffee brewed by forcing hot water through fine grounds.'),
                                                                                '에스프레소, espresso, 커피원액, 샷, 커피바'),
                                                                               (301, jsonb_build_object('ko-KR', '카페라떼', 'en-US', 'Cafe Latte', 'ja-JP', 'カフェラテ'),
                                                                                jsonb_build_object('ko-KR', '에스프레소와 부드러운 우유를 섞어 만든 대중적인 커피', 'en-US', 'Espresso combined with steamed milk, topped with a touch of foam.'),
                                                                                '카페라떼, 라떼, latte, 우유커피, 카페라테, 아이스라떼') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 증류주 (Spirits)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (404, jsonb_build_object('ko-KR', '위스키', 'en-US', 'Whisky', 'ja-JP', 'ウイスキー'),
                                                                                jsonb_build_object('ko-KR', '곡물을 발효시켜 만든 술을 증류하여 오크통에서 숙성시킨 고급 주류', 'en-US', 'Distilled alcoholic drink made from fermented grain mash, aged in wood.'),
                                                                                '위스키, 위스끼, whisky, whiskey, 싱글몰트, 버번, 스카치, 온더락'),
                                                                               (404, jsonb_build_object('ko-KR', '소주', 'en-US', 'Soju', 'ja-JP', '焼酎'),
                                                                                jsonb_build_object('ko-KR', '한국에서 가장 대중적인 증류주로 깔끔하고 투명한 맛이 특징', 'en-US', 'Most popular clear, distilled Korean spirit with a clean taste.'),
                                                                                '소주, 쏘주, soju, 초록병, 참이슬, 처음처럼, 증류식소주, 소맥'),
                                                                               (404, jsonb_build_object('ko-KR', '하이볼', 'en-US', 'Highball', 'ja-JP', 'ハイボール'),
                                                                                jsonb_build_object('ko-KR', '위스키나 증류주에 탄산수와 레몬을 섞어 시원하게 마시는 칵테일', 'en-US', 'Mixed drink of spirits, usually whisky, and a larger amount of carbonated mixer.'),
                                                                                '하이볼, 하이보루, highball, 산토리하이볼, 위스키에이드, 짐빔하이볼') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 피자 (Pizza)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '페퍼로니피자', 'en-US', 'Pepperoni Pizza', 'ja-JP', 'ペパロニピザ'),
                                                                                jsonb_build_object('ko-KR', '짭짤한 페퍼로니 소시지가 듬뿍 올라간 가장 대중적인 피자', 'en-US', 'Classic pizza topped with tomato sauce, mozzarella, and sliced pepperoni.'),
                                                                                '페퍼로니피자, 페페로니, pepperoni pizza, 짭짤한피자, 피맥'),
                                                                               (109, jsonb_build_object('ko-KR', '마르게리따', 'en-US', 'Margherita', 'ja-JP', 'マルゲリータ'),
                                                                                jsonb_build_object('ko-KR', '토마토, 모짜렐라 치즈, 바질이 올라간 이탈리아 정통 나폴리 피자', 'en-US', 'Traditional Neapolitan pizza with tomatoes, mozzarella, and fresh basil.'),
                                                                                '마르게리따, 마르게리타, margherita, 치즈피자, 나폴리피자, 화덕피자') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [606] 소스 - 스프레드 (Spread)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (606, jsonb_build_object('ko-KR', '누텔라', 'en-US', 'Nutella', 'ja-JP', 'ヌテラ'),
                                                                                jsonb_build_object('ko-KR', '헤이즐넛과 초콜릿으로 만든 달콤하고 진한 스프레드', 'en-US', 'Sweet hazelnut chocolate spread, popular for bread and desserts.'),
                                                                                '누텔라, 악마의잼, nutella, 초코스프레드, 헤이즐넛초코'),
                                                                               (606, jsonb_build_object('ko-KR', '과카몰리', 'en-US', 'Guacamole', 'ja-JP', 'ワカモレ'),
                                                                                jsonb_build_object('ko-KR', '으깬 아보카도에 양파, 토마토, 라임을 넣어 만든 멕시코식 소스', 'en-US', 'Avocado-based dip with onion, tomato, lime, and cilantro.'),
                                                                                '과카몰리, 과카몰레, guacamole, 아보카도소스, 나쵸소스, 멕시칸딥') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Noodle) 추가분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '봉골레', 'en-US', 'Vongole', 'ja-JP', 'ボンゴレ'),
                                                                                jsonb_build_object('ko-KR', '모시조개나 바지락 등 조개를 넣어 만든 깔끔하고 담백한 오일 파스타', 'en-US', 'Classic Italian oil-based pasta cooked with fresh clams.'),
                                                                                '봉골레, 봉골레파스타, vongole, 조개파스타, 오일스파게티'),
                                                                               (102, jsonb_build_object('ko-KR', '팟타이', 'en-US', 'Pad Thai', 'ja-JP', 'パッタイ'),
                                                                                jsonb_build_object('ko-KR', '새콤달콤한 소스에 쌀면과 숙주, 땅콩가루를 넣어 볶은 태국 대표 요리', 'en-US', 'Stir-fried Thai rice noodles with eggs, tofu, tamarind pulp, and peanuts.'),
                                                                                '팟타이, 팟타이볶음면, pad thai, 태국국수, 동남아볶음면, 태국요리'),
                                                                               (102, jsonb_build_object('ko-KR', '쌀국수', 'en-US', 'Pho', 'ja-JP', 'フォー'),
                                                                                jsonb_build_object('ko-KR', '진한 고기 육수에 쌀면과 고기 고명, 고수를 곁들여 먹는 베트남 전통 면 요리', 'en-US', 'Vietnamese soup dish consisting of broth, rice noodles, herbs, and meat.'),
                                                                                '쌀국수, 베트남쌀국수, pho, 포, 퍼, 월남국수, 해장국수'),
                                                                               (102, jsonb_build_object('ko-KR', '라자냐', 'en-US', 'Lasagna', 'ja-JP', 'ラザニア'),
                                                                                jsonb_build_object('ko-KR', '넙적한 파스타 면과 라구 소스, 치즈를 층층이 쌓아 오븐에 구운 요리', 'en-US', 'Baked Italian dish consisting of layers of wide pasta, meat sauce, and cheese.'),
                                                                                '라자냐, 라쟈냐, lasagna, 오븐파스타, 이탈리아가정식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Meat) 추가분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '바비큐폭립', 'en-US', 'BBQ Pork Ribs', 'ja-JP', 'バーベキューリブ'),
                                                                                jsonb_build_object('ko-KR', '돼지 갈비에 달콤하고 짭짤한 바비큐 소스를 발라 구운 요리', 'en-US', 'Pork ribs slow-cooked and glazed with savory barbecue sauce.'),
                                                                                '바비큐폭립, 폭립, 등갈비, bbq ribs, 돼지갈비구이, 패밀리레스토랑'),
                                                                               (103, jsonb_build_object('ko-KR', '슈니첼', 'en-US', 'Schnitzel', 'ja-JP', 'シュニッツェル'),
                                                                                jsonb_build_object('ko-KR', '고기를 얇게 두드려 펴서 튀겨낸 독일 및 오스트리아식 고기 요리', 'en-US', 'Thinly pounded meat breaded and deep-fried, popular in Central Europe.'),
                                                                                '슈니첼, schnitzel, 유럽식돈까스, 독일돈까스'),
                                                                               (103, jsonb_build_object('ko-KR', '양갈비구이', 'en-US', 'Lamb Chops', 'ja-JP', 'ラムチョップ'),
                                                                                jsonb_build_object('ko-KR', '특유의 풍미가 있는 양의 갈비 부위를 그릴에 구워낸 요리', 'en-US', 'Grilled lamb ribs seasoned with herbs, often served with mint sauce.'),
                                                                                '양갈비구이, 양갈비, 양꼬치, lamb chops, 램스테이크, 숄더랙'),
                                                                               (103, jsonb_build_object('ko-KR', '타코', 'en-US', 'Taco', 'ja-JP', 'タコス'),
                                                                                jsonb_build_object('ko-KR', '또띠아에 고기, 채소, 소스를 싸서 먹는 멕시코의 대표적인 길거리 음식', 'en-US', 'Traditional Mexican dish consisting of a small corn or wheat tortilla with fillings.'),
                                                                                '타코, taco, 따꼬, 멕시칸푸드, 또띠아, 소프트타코, 하드타코') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [104] 요리 - 해산물 (Seafood)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (104, jsonb_build_object('ko-KR', '피쉬앤칩스', 'en-US', 'Fish and Chips', 'ja-JP', 'フィッシュ・アンド・チップス'),
                                                                                jsonb_build_object('ko-KR', '흰살생선 튀김과 감자튀김을 곁들여 먹는 영국식 요리', 'en-US', 'Classic British dish of battered fish served with fried potatoes.'),
                                                                                '피쉬앤칩스, 피시앤칩스, fish and chips, 생선튀김, 감튀'),
                                                                               (104, jsonb_build_object('ko-KR', '연어스테이크', 'en-US', 'Grilled Salmon', 'ja-JP', 'サーモンステーキ'),
                                                                                jsonb_build_object('ko-KR', '신선한 연어를 그릴이나 팬에 구워 부드러운 식감을 살린 요리', 'en-US', 'Salmon fillet seasoned and grilled to a tender perfection.'),
                                                                                '연어스테이크, 구운연어, salmon steak, 다이어트식단'),
                                                                               (104, jsonb_build_object('ko-KR', '감바스', 'en-US', 'Gambas al Ajillo', 'ja-JP', 'アヒージョ'),
                                                                                jsonb_build_object('ko-KR', '올리브유에 새우와 마늘을 넣어 끓인 스페인식 전채 요리', 'en-US', 'Spanish appetizer of shrimp sautéed in olive oil with garlic and chili.'),
                                                                                '감바스, 감바스알아히요, gambas, 새우요리, 와인안주, 스페인요리'),
                                                                               (104, jsonb_build_object('ko-KR', '랍스터롤', 'en-US', 'Lobster Roll', 'ja-JP', 'ロブスターロール'),
                                                                                jsonb_build_object('ko-KR', '버터에 버무린 랍스터 살을 샌드위치 빵 사이에 가득 채운 음식', 'en-US', 'Sandwich native to New England made of lobster meat served on a grilled roll.'),
                                                                                '랍스터롤, 랍스타롤, lobster roll, 바닷가재샌드위치, 고급샌드위치'),
                                                                               (104, jsonb_build_object('ko-KR', '세비체', 'en-US', 'Ceviche', 'ja-JP', 'セビーチェ'),
                                                                                jsonb_build_object('ko-KR', '해산물을 라임 즙과 채소에 버무려 차갑게 먹는 중남미식 회 요리', 'en-US', 'Latin American seafood dish made from fresh raw fish cured in citrus juices.'),
                                                                                '세비체, 세비체샐러드, ceviche, 중남미요리, 상큼한회') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Bakery) 추가분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '티라미수', 'en-US', 'Tiramisu', 'ja-JP', 'ティラミス'),
                                                                                jsonb_build_object('ko-KR', '마스카포네 치즈와 커피 향이 어우러진 이탈리아식 디저트', 'en-US', 'Coffee-flavored Italian dessert made of ladyfingers dipped in coffee and mascarpone.'),
                                                                                '티라미수, 티라미슈, tiramisu, 치즈케이크, 이태리케익'),
                                                                               (201, jsonb_build_object('ko-KR', '브라우니', 'en-US', 'Brownie', 'ja-JP', 'ブラウニー'),
                                                                                jsonb_build_object('ko-KR', '초콜릿을 가득 넣어 꾸덕하고 진한 맛이 특징인 사각형 케이크', 'en-US', 'Square or rectangular chocolate baked treat, known for its fudgy texture.'),
                                                                                '브라우니, 초코브라우니, brownie, 초코케이크, 꾸덕한디저트'),
                                                                               (201, jsonb_build_object('ko-KR', '베이글', 'en-US', 'Bagel', 'ja-JP', 'ベーグル'),
                                                                                jsonb_build_object('ko-KR', '가운데 구멍이 뚫린 쫄깃한 식감의 빵으로 크림치즈와 잘 어울림', 'en-US', 'Ring-shaped bread roll, boiled before baking for a chewy texture.'),
                                                                                '베이글, bagle, bagel, 런던베이글, 아침식사, 빵'),
                                                                               (201, jsonb_build_object('ko-KR', '팬케이크', 'en-US', 'Pancake', 'ja-JP', 'パンケーキ'),
                                                                                jsonb_build_object('ko-KR', '밀가루 반죽을 팬에 얇고 둥글게 구워 시럽과 곁들여 먹는 음식', 'en-US', 'Flat cake, often thin and round, prepared from a starch-based batter.'),
                                                                                '팬케이크, 팬케익, 핫케이크, pancake, 브런치, 시럽듬뿍'),
                                                                               (201, jsonb_build_object('ko-KR', '츄러스', 'en-US', 'Churros', 'ja-JP', 'チュロス'),
                                                                                jsonb_build_object('ko-KR', '밀가루 반죽을 튀겨 설탕과 시나몬 가루를 뿌린 스페인식 간식', 'en-US', 'Fried-dough pastry, predominantly choux, popular in Spain and Latin America.'),
                                                                                '츄러스, 추러스, churros, 놀이동산간식, 시나몬빵'),
                                                                               (201, jsonb_build_object('ko-KR', '스콘', 'en-US', 'Scone', 'ja-JP', 'スコーン'),
                                                                                jsonb_build_object('ko-KR', '영국식 퀵 브레드로 잼이나 클로티드 크림과 함께 먹는 담백한 빵', 'en-US', 'British baked good, lightly sweetened and served with jam or cream.'),
                                                                                '스콘, scone, 영국빵, 애프터눈티, 담백한디저트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Coffee) 추가분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (301, jsonb_build_object('ko-KR', '아인슈페너', 'en-US', 'Einspanner', 'ja-JP', 'アインシュペナー'),
                                                                                jsonb_build_object('ko-KR', '블랙커피 위에 차갑고 달콤한 휘핑크림을 얹은 비엔나식 커피', 'en-US', 'Vienna coffee made with espresso and topped with a large head of whipped cream.'),
                                                                                '아인슈페너, einspanner, 비엔나커피, 크림커피, 슈페너'),
                                                                               (301, jsonb_build_object('ko-KR', '카페라떼', 'en-US', 'Cafe Latte', 'ja-JP', 'カフェラテ'),
                                                                                jsonb_build_object('ko-KR', '에스프레소에 스팀 우유를 섞어 부드럽게 마시는 대중적인 커피', 'en-US', 'Classic coffee drink made with espresso and steamed milk.'),
                                                                                '카페라떼, 라떼, latte, 우유커피, 카페라테, 라떼아트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [402] 주류 - 와인 (Wine)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (402, jsonb_build_object('ko-KR', '카베르네소비뇽', 'en-US', 'Cabernet Sauvignon', 'ja-JP', 'カベルネ・ソーヴィニヨン'),
                                                                                jsonb_build_object('ko-KR', '전 세계적으로 가장 널리 재배되는 레드 와인용 포도 품종이자 와인', 'en-US', 'One of the world''s most widely recognized red wine grape varieties.'),
                                                                                '카베르네소비뇽, 카쇼, cabernet sauvignon, 레드와인, 드라이와인'),
                                                                               (402, jsonb_build_object('ko-KR', '샤르도네', 'en-US', 'Chardonnay', 'ja-JP', 'シャルドネ'),
                                                                                jsonb_build_object('ko-KR', '다양한 기후에서 잘 자라는 대표적인 화이트 와인용 포도 품종', 'en-US', 'Popular white wine grape variety known for its versatility.'),
                                                                                '샤르도네, 샤도네이, chardonnay, 화이트와인, 상큼한와인'),
                                                                               (402, jsonb_build_object('ko-KR', '샴페인', 'en-US', 'Champagne', 'ja-JP', 'シャンパン'),
                                                                                jsonb_build_object('ko-KR', '프랑스 샹파뉴 지역에서 생산되는 대표적인 스파클링 와인', 'en-US', 'Sparkling wine produced from grapes grown in the Champagne region of France.'),
                                                                                '샴페인, 샴팡, champagne, 스파클링와인, 축하주, 버블와인'),
                                                                               (402, jsonb_build_object('ko-KR', '상그리아', 'en-US', 'Sangria', 'ja-JP', 'サングリア'),
                                                                                jsonb_build_object('ko-KR', '와인에 과일과 설탕, 탄산수 등을 섞어 차갑게 마시는 스페인식 술', 'en-US', 'Traditional Spanish wine punch made with red wine and chopped fruit.'),
                                                                                '상그리아, 샹그리아, sangria, 과일와인, 식전주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 증류주 (Spirits) 추가분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (404, jsonb_build_object('ko-KR', '진토닉', 'en-US', 'Gin and Tonic', 'ja-JP', 'ジントニック'),
                                                                                jsonb_build_object('ko-KR', '진과 토닉워터를 섞고 레몬이나 라임을 곁들인 깔끔한 칵테일', 'en-US', 'Highball cocktail made with gin and tonic water, garnished with lime.'),
                                                                                '진토닉, g&t, gin and tonic, 칵테일, 깔끔한술'),
                                                                               (404, jsonb_build_object('ko-KR', '테킬라', 'en-US', 'Tequila', 'ja-JP', 'テキーラ'),
                                                                                jsonb_build_object('ko-KR', '멕시코 특산의 다육식물인 아가베를 증류하여 만든 독주', 'en-US', 'Distilled beverage made from the blue agave plant, primarily in Mexico.'),
                                                                                '테킬라, 데킬라, tequila, 아가베, 샷, 멕시코술'),
                                                                               (404, jsonb_build_object('ko-KR', '보드카', 'en-US', 'Vodka', 'ja-JP', 'ウォッカ'),
                                                                                jsonb_build_object('ko-KR', '곡물을 증류한 뒤 자작나무 활성탄으로 여과하여 맛이 투명하고 깨끗한 술', 'en-US', 'Clear distilled alcoholic beverage originating from Poland and Russia.'),
                                                                                '보드카, vodka, 무색무취, 칵테일베이스, 앱솔루트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [606] 소스 - 스프레드 (Spread) 추가분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (606, jsonb_build_object('ko-KR', '땅콩버터', 'en-US', 'Peanut Butter', 'ja-JP', 'ピーナッツバター'),
                                                                                jsonb_build_object('ko-KR', '볶은 땅콩을 갈아 만든 고소하고 꾸덕한 스프레드', 'en-US', 'Food paste or spread made from ground, dry-roasted peanuts.'),
                                                                                '땅콩버터, 피넛버터, peanut butter, 잼, 고소한소스'),
                                                                               (606, jsonb_build_object('ko-KR', '후무스', 'en-US', 'Hummus', 'ja-JP', 'フムス'),
                                                                                jsonb_build_object('ko-KR', '병아리콩을 삶아 올리브유, 타히니 소스와 섞은 중동식 스프레드', 'en-US', 'Middle Eastern dip made from cooked, mashed chickpeas blended with tahini.'),
                                                                                '후무스, 허무스, hummus, 병아리콩, 다이어트소스, 비건스프레드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [506] 간식 - 에너지바 (Protein Bar)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (506, jsonb_build_object('ko-KR', '단백질바', 'en-US', 'Protein Bar', 'ja-JP', 'プロテインバー'),
     jsonb_build_object('ko-KR', '단백질 함량이 높아 운동 전후나 간식으로 먹기 좋은 영양바', 'en-US', 'Nutrition bar that contains a high proportion of protein.'),
     '단백질바, 에너지바, 프로틴바, protein bar, 헬스간식, 식단관리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [605] 소스 - 드레싱 (Dressing)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (605, jsonb_build_object('ko-KR', '랜치드레싱', 'en-US', 'Ranch Dressing', 'ja-JP', 'ランチドレッシング'),
                                                                                jsonb_build_object('ko-KR', '버터밀크와 마요네즈, 허브를 넣어 만든 고소하고 상큼한 드레싱', 'en-US', 'Popular American salad dressing based on buttermilk and herbs.'),
                                                                                '랜치드레싱, 랜치소스, ranch dressing, 샐러드소스, 피자디핑소스'),
                                                                               (605, jsonb_build_object('ko-KR', '발사믹식초', 'en-US', 'Balsamic Vinegar', 'ja-JP', 'バルサミコ酢'),
                                                                                jsonb_build_object('ko-KR', '포도즙을 숙성시켜 만든 풍미가 깊고 새콤한 이탈리아 전통 식초', 'en-US', 'Dark, concentrated, and intensely flavored vinegar from Italy.'),
                                                                                '발사믹식초, 발사믹, balsamic vinegar, 샐러드식초, 포도식초') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [107] 요리 - 샌드위치 (Sandwich)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (107, jsonb_build_object('ko-KR', '클럽샌드위치', 'en-US', 'Club Sandwich', 'ja-JP', 'クラブハウスサンド'),
                                                                                jsonb_build_object('ko-KR', '닭고기, 베이컨, 양상추, 토마토를 넣어 3단으로 만든 클래식 샌드위치', 'en-US', 'Classic triple-decker sandwich with poultry, bacon, lettuce, and tomato.'),
                                                                                '클럽샌드위치, 클럽샌위치, club sandwich, 호밀빵샌드위치, 브런치메뉴'),
                                                                               (107, jsonb_build_object('ko-KR', '부리토', 'en-US', 'Burrito', 'ja-JP', 'ブリトー'),
                                                                                jsonb_build_object('ko-KR', '또띠아에 고기, 콩, 밥 등을 넣어 말아 만든 멕시코 전통 음식', 'en-US', 'Mexican dish consisting of a flour tortilla wrapped around various fillings.'),
                                                                                '부리토, 브리또, 부리또, burrito, 멕시칸롤, 간편식, 콩부리토'),
                                                                               (107, jsonb_build_object('ko-KR', '베이글샌드위치', 'en-US', 'Bagel Sandwich', 'ja-JP', 'ベーグルサンド'),
                                                                                jsonb_build_object('ko-KR', '쫄깃한 베이글 사이에 크림치즈나 연어, 햄 등을 넣어 만든 샌드위치', 'en-US', 'Sandwich made with a sliced bagel and various savory fillings.'),
                                                                                '베이글샌드위치, 베이글샌위치, bagel sandwich, 연어베이글, 크림치즈베이글') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Salad)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (108, jsonb_build_object('ko-KR', '코바샐러드', 'en-US', 'Cobb Salad', 'ja-JP', 'コブサラダ'),
                                                                                jsonb_build_object('ko-KR', '닭고기, 아보카도, 달걀 등을 가지런히 줄지어 담아낸 미국식 샐러드', 'en-US', 'American garden salad typically made with chopped greens, chicken, and avocado.'),
                                                                                '코바샐러드, 콥샐러드, cobb salad, 다이어트도시락, 건강식, 믹스샐러드'),
                                                                               (108, jsonb_build_object('ko-KR', '그리스샐러드', 'en-US', 'Greek Salad', 'ja-JP', 'ギリシャサラダ'),
                                                                                jsonb_build_object('ko-KR', '토마토, 오이, 페타 치즈에 올리브유를 곁들인 지중해식 샐러드', 'en-US', 'Fresh Mediterranean salad with tomatoes, cucumbers, feta cheese, and olives.'),
                                                                                '그리스샐러드, 그릭샐러드, greek salad, 페타치즈샐러드, 지중해식단') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [303] 음료 - 탄산음료 (Soda)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (303, jsonb_build_object('ko-KR', '콜라', 'en-US', 'Cola', 'ja-JP', 'コーラ'),
                                                                                jsonb_build_object('ko-KR', '전 세계적으로 가장 유명한 흑갈색의 청량 탄산음료', 'en-US', 'Sweet, carbonated soft drink flavored with vanilla, cinnamon, and citrus.'),
                                                                                '콜라, 콜라라, cola, coke, 코카콜라, 펩시, 제로콜라, 탄산음료'),
                                                                               (303, jsonb_build_object('ko-KR', '레몬에이드', 'en-US', 'Lemonade', 'ja-JP', 'レモネード'),
                                                                                jsonb_build_object('ko-KR', '레몬 과즙과 설탕, 탄산수를 섞어 만든 상큼한 음료', 'en-US', 'Refreshing sweetened beverage made from lemon juice and carbonated water.'),
                                                                                '레몬에이드, 레모네이드, lemonade, 레몬차, 상큼한음료, 에이드'),
                                                                               (303, jsonb_build_object('ko-KR', '진저에일', 'en-US', 'Ginger Ale', 'ja-JP', 'ジンジャーエール'),
                                                                                jsonb_build_object('ko-KR', '생강 향이 가미된 탄산음료로 칵테일 믹서로도 자주 쓰임', 'en-US', 'Carbonated soft drink flavored with ginger, often used as a mixer.'),
                                                                                '진저에일, 진저엘, ginger ale, 생강탄산, 분다버그, 칵테일재료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [307] 음료 - 대체유 (Vegan Milk)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (307, jsonb_build_object('ko-KR', '오트밀크', 'en-US', 'Oat Milk', 'ja-JP', 'オーツミルク'),
                                                                                jsonb_build_object('ko-KR', '귀리를 주원료로 만든 고소한 맛의 식물성 대체 우유', 'en-US', 'Plant milk derived from whole oat grains with a creamy texture.'),
                                                                                '오트밀크, 귀리우유, oat milk, 오트사이드, 비건우유, 대체유'),
                                                                               (307, jsonb_build_object('ko-KR', '아몬드밀크', 'en-US', 'Almond Milk', 'ja-JP', 'アーモンドミルク'),
                                                                                jsonb_build_object('ko-KR', '아몬드를 갈아 만든 저칼로리 식물성 음료', 'en-US', 'Plant milk with a watery texture and nutty flavor made from almonds.'),
                                                                                '아몬드밀크, 아몬드브리즈, almond milk, 다이어트우유, 견과류음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [401] 주류 - 맥주 (Beer)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (401, jsonb_build_object('ko-KR', '라거', 'en-US', 'Lager', 'ja-JP', 'ラガー'),
                                                                                jsonb_build_object('ko-KR', '저온에서 발효시켜 깔끔하고 청량한 맛이 특징인 맥주', 'en-US', 'Type of beer conditioned at low temperatures, known for its crisp taste.'),
                                                                                '라거, lager, 탄산맥주, 국산맥주, 시원한맥주, 테라, 카스'),
                                                                               (401, jsonb_build_object('ko-KR', '에일', 'en-US', 'Ale', 'ja-JP', 'エール'),
                                                                                jsonb_build_object('ko-KR', '상온에서 발효시켜 과일 향과 진한 풍미가 특징인 맥주', 'en-US', 'Beer brewed using a warm fermentation method, resulting in a fruity flavor.'),
                                                                                '에일, ale, 수제맥주, 크래프트비어, IPA, 쌉싸름한맥주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [403] 주류 - 전통주 (Traditional)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (403, jsonb_build_object('ko-KR', '막걸리', 'en-US', 'Makgeolli', 'ja-JP', 'マッコリ'),
     jsonb_build_object('ko-KR', '쌀이나 밀로 빚어 만든 한국 전통 탁주', 'en-US', 'Korean rice wine with a milky, off-white appearance and sweet-sour taste.'),
     '막걸리, 막걸리나, makgeolli, 전통주, 탁주, 농주, 파전친구') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [405] 주류 - 사이더 (Cider)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (405, jsonb_build_object('ko-KR', '애플사이더', 'en-US', 'Apple Cider', 'ja-JP', 'アップルサイダー'),
     jsonb_build_object('ko-KR', '사과를 발효시켜 만든 과실주로 달콤하고 톡 쏘는 맛이 특징', 'en-US', 'Alcoholic beverage made from the fermented juice of apples.'),
     '애플사이더, 사이더, cider, 사과주, 써머스비, 과일맥주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Snack)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (501, jsonb_build_object('ko-KR', '나초', 'en-US', 'Nachos', 'ja-JP', 'ナチョス'),
                                                                                jsonb_build_object('ko-KR', '옥수수 또띠아 조각을 튀겨 치즈나 소스를 곁들여 먹는 간식', 'en-US', 'Mexican regional dish consisting of fried corn tortilla chips with cheese.'),
                                                                                '나초, 나쵸, nachos, 치즈나초, 영화관간식, 맥주안주'),
                                                                               (501, jsonb_build_object('ko-KR', '팝콘', 'en-US', 'Popcorn', 'ja-JP', 'ポップコーン'),
                                                                                jsonb_build_object('ko-KR', '옥수수 알갱이를 열로 튀겨낸 가볍고 바삭한 간식', 'en-US', 'Snack made from corn kernels that puff up when heated.'),
                                                                                '팝콘, 파콘, popcorn, 카라멜팝콘, 어니언팝콘, 극장간식'),
                                                                               (501, jsonb_build_object('ko-KR', '프레첼', 'en-US', 'Pretzel', 'ja-JP', 'プレッツェル'),
                                                                                jsonb_build_object('ko-KR', '매듭 모양으로 구운 짭짤하고 딱딱한 식감의 독일식 과자', 'en-US', 'Type of baked pastry made from dough that is commonly shaped into a knot.'),
                                                                                '프레첼, 프레젤, pretzel, 짭짤한과자, 매듭과자, 맥주안주'),
                                                                               (501, jsonb_build_object('ko-KR', '포테이토칩', 'en-US', 'Potato Chips', 'ja-JP', 'ポテトチップス'),
                                                                                jsonb_build_object('ko-KR', '감자를 얇게 썰어 기름에 튀긴 바삭한 과자', 'en-US', 'Thin slices of potato that have been deep fried or baked until crunchy.'),
                                                                                '포테이토칩, 감자칩, 포카칩, 프링글스, potato chips, 짭짤한간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [505] 간식 - 시리얼 (Cereal)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (505, jsonb_build_object('ko-KR', '그래놀라', 'en-US', 'Granola', 'ja-JP', 'グラノーラ'),
                                                                                jsonb_build_object('ko-KR', '오트밀, 견과류, 꿀 등을 섞어 오븐에 구워낸 건강 시리얼', 'en-US', 'Breakfast food consisting of rolled oats, nuts, and honey baked until crisp.'),
                                                                                '그래놀라, 그라놀라, granola, 수제그래놀라, 요거트토핑, 다이어트시리얼'),
                                                                               (505, jsonb_build_object('ko-KR', '오트밀', 'en-US', 'Oatmeal', 'ja-JP', 'オートミール'),
                                                                                jsonb_build_object('ko-KR', '귀리를 볶거나 쪄서 압착한 것으로 우유나 물에 끓여 먹는 건강식', 'en-US', 'Meal made from ground, rolled, or steel-cut oats, often served hot.'),
                                                                                '오트밀, 오트, oatmeal, 귀리죽, 아침식사, 식단관리'),
                                                                               (505, jsonb_build_object('ko-KR', '콘플레이크', 'en-US', 'Cornflakes', 'ja-JP', 'コーンフレーク'),
                                                                                jsonb_build_object('ko-KR', '옥수수를 주원료로 만든 가장 대중적인 아침 식사용 시리얼', 'en-US', 'Breakfast cereal made by toasting flakes of corn.'),
                                                                                '콘플레이크, 콘푸로스트, 시리얼, cornflakes, 아침우유, 호랑이기운') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [601] 소스 - 오일 (Oil/Butter)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (601, jsonb_build_object('ko-KR', '올리브유', 'en-US', 'Olive Oil', 'ja-JP', 'オリーブオイル'),
                                                                                jsonb_build_object('ko-KR', '올리브 열매를 압착하여 만든 건강한 식물성 기름', 'en-US', 'Liquid fat obtained from olives, a traditional tree crop of the Mediterranean.'),
                                                                                '올리브유, 올리브오일, olive oil, 엑스트라버진, 압착유, 이태리요리필수'),
                                                                               (601, jsonb_build_object('ko-KR', '버터', 'en-US', 'Butter', 'ja-JP', 'バター'),
                                                                                jsonb_build_object('ko-KR', '우유에서 분리한 유지방을 응고시킨 고소한 맛의 식품', 'en-US', 'Dairy product made from the fat and protein components of churned cream.'),
                                                                                '버터, 가염버터, 무염버터, butter, 버터구이, 빵도둑, 요리치트키') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Seasoning/Sauce)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '케첩', 'en-US', 'Ketchup', 'ja-JP', 'ケチャップ'),
                                                                                jsonb_build_object('ko-KR', '잘 익은 토마토를 주원료로 만든 새콤달콤한 소스', 'en-US', 'Table condiment with a sweet and tangy flavor, made from tomatoes.'),
                                                                                '케첩, 케찹, ketchup, 토마토소스, 감튀소스, 하인즈'),
                                                                               (604, jsonb_build_object('ko-KR', '마요네즈', 'en-US', 'Mayonnaise', 'ja-JP', 'マヨネーズ'),
                                                                                jsonb_build_object('ko-KR', '식용유, 달걀노른자, 식초를 섞어 만든 고소하고 부드러운 소스', 'en-US', 'Thick, creamy dressing often used as a condiment, made from oil and egg yolks.'),
                                                                                '마요네즈, 마요, mayo, mayonnaise, 고소한소스, 살찌는맛'),
                                                                               (604, jsonb_build_object('ko-KR', '타바스코', 'en-US', 'Tabasco', 'ja-JP', 'タバスコ'),
                                                                                jsonb_build_object('ko-KR', '매운 고추를 발효시켜 만든 톡 쏘는 매운맛의 핫소스', 'en-US', 'Brand of hot sauce made from tabasco peppers, vinegar, and salt.'),
                                                                                '타바스코, 핫소스, tabasco, 피자소스, 매운소스'),
                                                                               (604, jsonb_build_object('ko-KR', '스리라차', 'en-US', 'Sriracha', 'ja-JP', 'シラチャーソース'),
                                                                                jsonb_build_object('ko-KR', '태국식 매운 소스로 칼로리가 낮아 다이어터들에게 인기 있는 소스', 'en-US', 'Type of hot sauce made from a paste of chili peppers, vinegar, and garlic.'),
                                                                                '스리라차, 쓰리라차, sriracha, 닭표소스, 다이어트소스, 0칼로리소스'),
                                                                               (604, jsonb_build_object('ko-KR', '트러플오일', 'en-US', 'Truffle Oil', 'ja-JP', 'トリュフオイル'),
                                                                                jsonb_build_object('ko-KR', '송이버섯의 향을 입힌 고급 오일로 소량으로도 깊은 풍미를 냄', 'en-US', 'Modern culinary ingredient used to impart the flavor and aroma of truffles.'),
                                                                                '트러플오일, 트러플, truffle oil, 송로버섯오일, 풍미작렬, 짜파게티꿀조합') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Noodle) - 누락분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '라면', 'en-US', 'Ramen', 'ja-JP', 'ラーメン'),
     jsonb_build_object('ko-KR', '꼬들꼬들한 면과 매콤하고 진한 국물이 특징인 한국의 대표 인스턴트 면 요리', 'en-US', 'Popular Korean instant noodles known for their spicy broth and chewy texture.'),
     '라면, 라묜, ramen, 인스턴트라면, 컵라면, 봉지라면, 해장라면, 신라면, 불닭') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Bakery) - 누락분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '크로와상', 'en-US', 'Croissant', 'ja-JP', 'クロワッサン'),
                                                                                jsonb_build_object('ko-KR', '버터를 듬뿍 넣어 결을 살린 겹겹의 바삭하고 고소한 프랑스식 빵', 'en-US', 'Buttery, flaky, crescent-shaped French pastry made of layered dough.'),
                                                                                '크로와상, 크로아상, croissant, 패스츄리, 버터빵, 아침빵, 크로플'),
                                                                               (201, jsonb_build_object('ko-KR', '치즈케이크', 'en-US', 'Cheesecake', 'ja-JP', 'チーズケーキ'),
                                                                                jsonb_build_object('ko-KR', '크림치즈를 주원료로 하여 입안에서 부드럽게 녹는 진한 풍미의 케이크', 'en-US', 'Rich and creamy dessert cake made with a mixture of soft fresh cheese.'),
                                                                                '치즈케이크, 치즈케익, cheesecake, 뉴욕치즈케이크, 필라델피아, 꾸덕한케이크'),
                                                                               (201, jsonb_build_object('ko-KR', '마카롱', 'en-US', 'Macaron', 'ja-JP', 'マカロン'),
                                                                                jsonb_build_object('ko-KR', '머랭을 이용해 만든 바삭한 꼬끄와 달콤한 필링이 조화를 이루는 프랑스식 고급 디저트', 'en-US', 'Sweet meringue-based confection made with egg white, icing sugar, and almond meal.'),
                                                                                '마카롱, 마카롱롱, macaron, 뚱카롱, 달달구리, 디저트선물, 꼬끄') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [303] 음료 - 탄산음료 (Soda) - 누락분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (303, jsonb_build_object('ko-KR', '루트비어', 'en-US', 'Root Beer', 'ja-JP', 'ルートビア'),
     jsonb_build_object('ko-KR', '북미 지역에서 인기 있는 독특한 허브와 사사프라스 향이 가미된 탄산음료', 'en-US', 'Sweet North American beverage traditionally made using the root bark of the sassafras tree.'),
     '루트비어, root beer, 물파스맛음료, 탄산음료, A&W, 독특한음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Seasoning) - 누락분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '발사믹글레이즈', 'en-US', 'Balsamic Glaze', 'ja-JP', 'バルサミコグレーズ'),
                                                                                jsonb_build_object('ko-KR', '발사믹 식초를 졸여 만든 걸쭉하고 달콤한 소스로 샐러드나 피자에 활용됨', 'en-US', 'Thickened balsamic vinegar with a sweet and tangy flavor, used for drizzling.'),
                                                                                '발사믹글레이즈, 발사믹소스, balsamic glaze, 샐러드드레싱, 포도농축액, 데코소스'),
                                                                               (604, jsonb_build_object('ko-KR', '굴소스', 'en-US', 'Oyster Sauce', 'ja-JP', 'オイスターソース'),
                                                                                jsonb_build_object('ko-KR', '굴 추출물을 베이스로 만든 진한 갈색의 소스로 볶음 요리에 감칠맛을 더함', 'en-US', 'Rich, dark brown sauce made from oyster extracts, used in stir-fries.'),
                                                                                '굴소스, 굴소스요리, oyster sauce, 중식소스, 감칠맛치트키, 이금기, 볶음소스'),
                                                                               (604, jsonb_build_object('ko-KR', '허니머스터드', 'en-US', 'Honey Mustard', 'ja-JP', 'ハニーマスタード'),
                                                                                jsonb_build_object('ko-KR', '겨자에 꿀을 섞어 매콤함과 달콤함이 어우러진 대중적인 소스', 'en-US', 'Blended sauce of mustard and honey, perfect for dipping chicken and snacks.'),
                                                                                '허니머스터드, 머스타드소스, honey mustard, 치킨소스, 달콤한소스, 딥핑소스') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;


-- [108] 요리 - 샐러드 (Salad) - 최종 누락분
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (108, jsonb_build_object('ko-KR', '시저샐러드', 'en-US', 'Caesar Salad', 'ja-JP', 'シーザーサラダ'),
     jsonb_build_object('ko-KR', '로메인 상추와 크루통, 파마산 치즈에 시저 드레싱을 곁들인 전 세계적으로 사랑받는 샐러드', 'en-US', 'Popular green salad of romaine lettuce and croutons dressed with lemon juice, olive oil, and parmesan.'),
     '시저샐러드, 시저샐러드, caesar salad, 로메인샐러드, 닭가슴살샐러드, 식전샐러드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Vegetable) - 최종 누락분 (건강식/다이어트용)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (105, jsonb_build_object('ko-KR', '포케', 'en-US', 'Poke', 'ja-JP', 'ポキ'),
     jsonb_build_object('ko-KR', '신선한 생선과 다양한 채소를 소스에 버무려 먹는 영양 가득한 하와이식 건강식', 'en-US', 'Healthy Hawaiian dish featuring diced raw fish mixed with fresh vegetables and flavorful sauces.'),
     '포케, poke, 다이어트포케, 야채포케, 샐러드보울, 비건포케, 건강식단') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Soup/Stew)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '김치찌개', 'en-US', 'Kimchi Jjigae', 'ja-JP', 'キムチチゲ'),
                                                                                jsonb_build_object('ko-KR', '잘 익은 김치와 돼지고기를 넣어 끓인 한국의 대표적인 찌개', 'en-US', 'Iconic Korean stew made with fermented kimchi and pork.'),
                                                                                '김치찌개, 김찌, kimchi stew, soul food, 한국음식, 매콤한찌개'),
                                                                               (106, jsonb_build_object('ko-KR', '된장찌개', 'en-US', 'Doenjang Jjigae', 'ja-JP', '味噌チゲ'),
                                                                                jsonb_build_object('ko-KR', '된장을 풀어 두부, 채소와 함께 끓인 구수하고 담백한 찌개', 'en-US', 'Hearty Korean stew made with soybean paste and vegetables.'),
                                                                                '된장찌개, 됀장찌개, soybean paste stew, 집밥, 구수한맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Korean Stews)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '김치찌개', 'en-US', 'Kimchi Jjigae', 'ja-JP', 'キムチチゲ'),
                                                                                jsonb_build_object('ko-KR', '잘 익은 김치와 돼지고기를 넣어 끓인 한국인의 부동의 1위 찌개', 'en-US', 'Classic Korean stew made with aged kimchi, pork, and tofu.'),
                                                                                '김치찌개, 김찌, 킴치찌개, kimchi stew, soul food, 한국음식, 매콤한찌개, 참치김치찌개, 돼지김치찌개'),
                                                                               (106, jsonb_build_object('ko-KR', '된장찌개', 'en-US', 'Doenjang Jjigae', 'ja-JP', '味噌チゲ'),
                                                                                jsonb_build_object('ko-KR', '된장을 베이스로 두부와 채소를 넣어 끓인 구수한 한국 전통 찌개', 'en-US', 'Hearty Korean stew made with soybean paste, tofu, and vegetables.'),
                                                                                '된장찌개, 됀장찌개, soybean paste stew, jjigae, 집밥, 구수한맛, 고깃집된장찌개'),
                                                                               (106, jsonb_build_object('ko-KR', '부대찌개', 'en-US', 'Budae Jjigae', 'ja-JP', '部隊チゲ'),
                                                                                jsonb_build_object('ko-KR', '햄, 소시지, 라면 사리 등을 넣어 끓인 얼큰한 퓨전 찌개', 'en-US', 'Korean fusion stew with spicy broth, ham, sausage, and ramen noodles.'),
                                                                                '부대찌개, 부대찌게, army stew, 햄찌개, 소시지찌개, 모둠사리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Street Food & Comfort Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '떡볶이', 'en-US', 'Tteokbokki', 'ja-JP', 'トッポギ'),
                                                                                jsonb_build_object('ko-KR', '고추장 소스에 가래떡을 버무린 한국의 대표적인 길거리 음식', 'en-US', 'Spicy and sweet simmered rice cakes, a staple Korean street food.'),
                                                                                '떡볶이, 떡보끼, 떡볶기, tteokbokki, topokki, 분식, 매운음식, 로제떡볶이, 국물떡볶이'),
                                                                               (102, jsonb_build_object('ko-KR', '맥앤치즈', 'en-US', 'Mac and Cheese', 'ja-JP', 'マカロニ・アンド・チーズ'),
                                                                                jsonb_build_object('ko-KR', '마카로니와 진한 치즈 소스가 어우러진 서구권의 대표적인 컴포트 푸드', 'en-US', 'Rich and creamy macaroni pasta mixed with a thick cheese sauce.'),
                                                                                '맥앤치즈, 마카로니치즈, mac and cheese, macaroni, 치즈파스타, 미국가정식, 느끼한맛'),
                                                                               (102, jsonb_build_object('ko-KR', '잡채', 'en-US', 'Japchae', 'ja-JP', 'チャプチェ'),
                                                                                jsonb_build_object('ko-KR', '당면과 각종 채소, 고기를 간장 양념에 볶아낸 한국 전통 요리', 'en-US', 'Stir-fried glass noodles with vegetables, meat, and a soy-based sauce.'),
                                                                                '잡채, 당면요리, japchae, glass noodles, 잔치음식, 한정식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Meat Favorites)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '제육볶음', 'en-US', 'Spicy Pork', 'ja-JP', '豚肉炒め'),
     jsonb_build_object('ko-KR', '돼지고기를 고추장 양념에 매콤하게 볶아낸 한국의 대중적인 반찬', 'en-US', 'Thinly sliced pork stir-fried in a spicy gochujang-based sauce.'),
     '제육볶음, 제육, spicy pork, stir-fried pork, 고추장불고기, 기사식당메뉴, 밥도둑') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [107] 요리 - 샌드위치 (Brunch Items)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (107, jsonb_build_object('ko-KR', '아보카도 토스트', 'en-US', 'Avocado Toast', 'ja-JP', 'アボカドトースト'),
                                                                                jsonb_build_object('ko-KR', '잘 익은 아보카도를 으깨어 빵 위에 올린 건강하고 트렌디한 브런치', 'en-US', 'Toasted bread topped with mashed avocado, seasoning, and often eggs.'),
                                                                                '아보카도토스트, 아보토, avocado toast, 브런치, 다이어트식단, 건강식, 오오티디푸드'),
                                                                               (107, jsonb_build_object('ko-KR', '반미', 'en-US', 'Banh Mi', 'ja-JP', 'バインミー'),
                                                                                jsonb_build_object('ko-KR', '바게트 빵에 고기, 채소, 고수 등을 넣어 만든 베트남식 샌드위치', 'en-US', 'Vietnamese sandwich consisting of a baguette filled with savory ingredients.'),
                                                                                '반미, 바인미, banh mi, 베트남샌드위치, 고수샌드위치, 바게트샌드위치') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Global Classics)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '에그 베네딕트', 'en-US', 'Eggs Benedict', 'ja-JP', 'エッグベネディクト'),
                                                                                jsonb_build_object('ko-KR', '잉글리시 머핀 위에 수란과 홀랜다이즈 소스를 올린 고급 브런치 요리', 'en-US', 'Traditional American brunch dish with poached eggs and hollandaise sauce.'),
                                                                                '에그베네딕트, 에그베네딕드, eggs benedict, 수란, 브런치맛집, 호텔조식'),
                                                                               (109, jsonb_build_object('ko-KR', '치킨 커리', 'en-US', 'Chicken Curry', 'ja-JP', 'チキンカレー'),
                                                                                jsonb_build_object('ko-KR', '다양한 향신료와 코코넛 밀크가 어우러진 진한 풍미의 카레 요리', 'en-US', 'Spicy and aromatic chicken dish cooked in a flavorful curry sauce.'),
                                                                                '치킨커리, 카레, curry, 치킨마살라, 버터치킨, 인도음식, 일본카레') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Bakery)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '와플', 'en-US', 'Waffle', 'ja-JP', 'ワッフル'),
                                                                                jsonb_build_object('ko-KR', '격자 무늬 팬에 구워낸 바삭한 빵으로 시럽이나 과일을 곁들임', 'en-US', 'Batter-based cake cooked in a patterned iron, served with toppings.'),
                                                                                '와플, 벨기에와플, waffle, 길거리와플, 크로플, 디저트'),
                                                                               (201, jsonb_build_object('ko-KR', '초콜릿 칩 쿠키', 'en-US', 'Chocolate Chip Cookies', 'ja-JP', 'チョコチップクッキー'),
                                                                                jsonb_build_object('ko-KR', '초콜릿 칩이 가득 박혀 바삭하고 달콤한 전 세계적인 인기 간식', 'en-US', 'Classic baked treats filled with melted chocolate chips.'),
                                                                                '초코쿠키, 초코칩쿠키, chocolate chip cookies, 달달구리, 간식, 홈베이킹') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Trendy Drinks)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (301, jsonb_build_object('ko-KR', '말차라떼', 'en-US', 'Matcha Latte', 'ja-JP', '抹茶ラテ'),
     jsonb_build_object('ko-KR', '진한 말차 가루와 우유가 조화를 이루는 쌉싸름하고 고소한 음료', 'en-US', 'Aromatic latte made with premium matcha green tea and steamed milk.'),
     '말차라떼, 녹차라떼, matcha latte, 그린티라떼, 일본차, 건강음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 아이스크림 (Frozen Desserts)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (203, jsonb_build_object('ko-KR', '팥빙수', 'en-US', 'Bingsu', 'ja-JP', 'かき氷'),
     jsonb_build_object('ko-KR', '얼음을 갈아 팥과 떡, 연유 등을 올려 먹는 한국의 여름 디저트', 'en-US', 'Korean shaved ice dessert with sweet toppings like red beans and fruit.'),
     '팥빙수, 빙수, bingsu, shaved ice, 설빙, 여름간식, 시원한디저트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Global Favorite)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '순두부찌개', 'en-US', 'Soft Tofu Stew', 'ja-JP', '純豆腐チゲ'),
     jsonb_build_object('ko-KR', '부드러운 순두부와 해산물, 양념장이 어우러진 얼큰한 찌개', 'en-US', 'Spicy Korean stew made with extra soft tofu, seafood, and vegetables.'),
     '순두부찌개, 순두부, soft tofu stew, soondubu, 맵부심, 해장찌개, k-stew') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Korean Classic & Party Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '보쌈', 'en-US', 'Bossam', 'ja-JP', 'ポッサム'),
     jsonb_build_object('ko-KR', '돼지고기를 수육으로 삶아 김치, 속재료와 함께 싸 먹는 요리', 'en-US', 'Boiled pork slices served with spicy radish salad and lettuce wraps.'),
     '보쌈, 수육, bossam, boiled pork, 야식추천, 고기파티, 김장김치') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [104] 요리 - 해산물 (Global Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (104, jsonb_build_object('ko-KR', '피쉬 타코', 'en-US', 'Fish Tacos', 'ja-JP', 'フィッシュタコス'),
     jsonb_build_object('ko-KR', '또띠아에 튀긴 생선과 신선한 살사, 소스를 곁들인 멕시코식 요리', 'en-US', 'Mexican dish with fried or grilled fish, cabbage slaw, and lime in a tortilla.'),
     '피쉬타코, 생선타코, fish tacos, 타코맛집, 멕시칸요리, 가벼운식사') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Health Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '콤부차', 'en-US', 'Kombucha', 'ja-JP', 'コンブチャ'),
     jsonb_build_object('ko-KR', '차를 발효시켜 만든 톡 쏘는 탄산과 새콤한 맛의 건강 음료', 'en-US', 'Fermented, lightly effervescent sweetened black or green tea drink.'),
     '콤부차, 콤부차추천, kombucha, 발효음료, 유산균음료, 다이어트차') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Korean Essential)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (301, jsonb_build_object('ko-KR', '아이스 아메리카노', 'en-US', 'Iced Americano', 'ja-JP', 'アイスアメーカノ'),
     jsonb_build_object('ko-KR', '에스프레소에 찬물과 얼음을 더한 한국인이 가장 선호하는 커피', 'en-US', 'Espresso shots topped with cold water and ice, a daily staple in Korea.'),
     '아이스아메리카노, 아아, 얼죽아, iced americano, 커피, 카페인충전') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Seasonal Korean Snacks)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (501, jsonb_build_object('ko-KR', '붕어빵', 'en-US', 'Bungeoppang', 'ja-JP', 'たい焼き'),
                                                                                jsonb_build_object('ko-KR', '붕어 모양 틀에 반죽과 팥소를 넣어 구운 한국의 대표 겨울 간식', 'en-US', 'Fish-shaped pastry stuffed with sweetened red bean paste, a winter favorite.'),
                                                                                '붕어빵, 잉어빵, 붕어빵맛집, bungeoppang, 팥붕, 슈붕, 겨울간식'),
                                                                               (501, jsonb_build_object('ko-KR', '호떡', 'en-US', 'Hotteok', 'ja-JP', 'ホットク'),
                                                                                jsonb_build_object('ko-KR', '쫄깃한 반죽 안에 설탕과 견과류 시럽을 넣어 구운 달콤한 간식', 'en-US', 'Popular Korean street food pancake filled with brown sugar and nuts.'),
                                                                                '호떡, 꿀호떡, 씨앗호떡, hotteok, k-dessert, 겨울길거리음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [107] 요리 - 샌드위치 (Western Breakfast)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (107, jsonb_build_object('ko-KR', '프렌치 토스트', 'en-US', 'French Toast', 'ja-JP', 'フレンチトースト'),
     jsonb_build_object('ko-KR', '달걀과 우유를 적신 식빵을 노릇하게 구워 시럽을 곁들인 요리', 'en-US', 'Sliced bread soaked in eggs and milk, then fried and served with syrup.'),
     '프렌치토스트, 프토, french toast, 브런치, 아침식사, 달콤한빵') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Trendy & Essential)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '마라탕', 'en-US', 'Malatang', 'ja-JP', '麻辣湯'),
                                                                                jsonb_build_object('ko-KR', '원하는 재료를 골라 매콤하고 얼큰한 마라 소스에 끓여내는 중식 요리', 'en-US', 'Spicy Chinese street food where you choose ingredients to be cooked in a numbing broth.'),
                                                                                '마라탕, 마라턍, malatang, maratang, 매운국수, 혈중마라농도, 꿔바로우친구, 마라'),
                                                                               (102, jsonb_build_object('ko-KR', '냉밀면', 'en-US', 'Milmyeon', 'ja-JP', 'ミルミョン'),
                                                                                jsonb_build_object('ko-KR', '부산의 대표 향토 음식으로 밀가루 면을 사용한 시원한 면 요리', 'en-US', 'Busan-style cold wheat noodles served in a savory, chilled broth.'),
                                                                                '냉밀면, 밀면, milmyeon, 부산음식, 살얼음국수, 여름별미') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (K-Soul Food & Global Comfort)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '삼계탕', 'en-US', 'Samgyetang', 'ja-JP', '参鶏湯'),
                                                                                jsonb_build_object('ko-KR', '어린 닭에 인삼, 마늘, 대추 등을 넣어 푹 고아낸 한국의 대표 보양식', 'en-US', 'Healthy Korean chicken soup with ginseng, garlic, and jujubes.'),
                                                                                '삼계탕, 삼개탕, samgyetang, ginseng chicken soup, 보양식, 복날, 몸보신, 닭요리'),
                                                                               (103, jsonb_build_object('ko-KR', '버팔로 윙', 'en-US', 'Buffalo Wings', 'ja-JP', 'バッファローウィング'),
                                                                                jsonb_build_object('ko-KR', '닭 날개를 튀겨 매콤하고 새콤한 소스에 버무린 미국식 안주 요리', 'en-US', 'Deep-fried chicken wings coated in a vinegar-based cayenne pepper hot sauce.'),
                                                                                '버팔로윙, 닭날개튀김, buffalo wings, 맥주안주, 윙봉, 매운닭튀김'),
                                                                               (103, jsonb_build_object('ko-KR', '족발', 'en-US', 'Jokbal', 'ja-JP', 'チョッパル'),
                                                                                jsonb_build_object('ko-KR', '돼지 발을 향신료를 넣은 간장 육수에 삶아내어 쫄깃한 식감을 살린 요리', 'en-US', 'Korean dish of pig''s trotters cooked with soy sauce and spices.'),
                                                                                '족발, 족빨, jokbal, pig trotters, 야식추천, 콜라겐, 장충동족발') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Fusion & Global Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '샥슈카', 'en-US', 'Shakshuka', 'ja-JP', 'シャクシュカ'),
                                                                                jsonb_build_object('ko-KR', '토마토 소스에 달걀을 넣어 익힌 중동식 요리로 에그인헬로도 불림', 'en-US', 'Middle Eastern dish of eggs poached in a sauce of tomatoes, chili peppers, and onions.'),
                                                                                '샥슈카, 에그인헬, shakshuka, egg in hell, 지옥에빠진달걀, 브런치메뉴, 토마토요리'),
                                                                               (109, jsonb_build_object('ko-KR', '퀘사디아', 'en-US', 'Quesadilla', 'ja-JP', 'ケサディーヤ'),
                                                                                jsonb_build_object('ko-KR', '또띠아 사이에 치즈와 고기, 채소 등을 넣어 구운 멕시코 요리', 'en-US', 'Mexican dish consisting of a tortilla filled with cheese and other savory ingredients.'),
                                                                                '퀘사디아, 케사디야, quesadilla, 멕시칸피자, 치즈또띠아, 간편식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Health & Diet)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (108, jsonb_build_object('ko-KR', '스무디볼', 'en-US', 'Smoothie Bowl', 'ja-JP', 'スムージーボウル'),
                                                                                jsonb_build_object('ko-KR', '걸쭉한 스무디 위에 과일, 견과류, 그래놀라 등을 토핑한 건강식', 'en-US', 'Thick smoothie topped with fruit, nuts, and seeds, served in a bowl.'),
                                                                                '스무디볼, 스무디보울, smoothie bowl, 아사이볼, 다이어트식단, 인스타감성, 건강식'),
                                                                               (108, jsonb_build_object('ko-KR', '카프레제', 'en-US', 'Caprese Salad', 'ja-JP', 'カプレーゼ'),
                                                                                jsonb_build_object('ko-KR', '토마토, 모짜렐라 치즈, 바질을 곁들인 신선하고 가벼운 이탈리아식 샐러드', 'en-US', 'Simple Italian salad made of sliced fresh mozzarella, tomatoes, and sweet basil.'),
                                                                                '카프레제, 카프레제샐러드, caprese, 토마토치즈샐러드, 와인안주, 이탈리아전채') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Professional & Modern)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (301, jsonb_build_object('ko-KR', '콜드브루', 'en-US', 'Cold Brew', 'ja-JP', 'コールドブリュー'),
     jsonb_build_object('ko-KR', '찬물로 오랜 시간 천천히 추출하여 쓴맛이 적고 풍미가 깊은 커피', 'en-US', 'Coffee brewed with cold water over a long period for a smooth flavor.'),
     '콜드브루, 콜드브루커피, cold brew, 더치커피, 쓴맛없는커피, 깔끔한커피') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Global Standard)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '차이 라떼', 'en-US', 'Chai Latte', 'ja-JP', 'チャイラテ'),
     jsonb_build_object('ko-KR', '인도식 홍차인 차이에 우유와 향신료를 더한 이국적인 맛의 음료', 'en-US', 'Tea beverage made by mixing spiced black tea with steamed milk.'),
     '차이라떼, 차이티, chai latte, 인도홍차, 밀크티, 스파이스티') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Korean Comfort)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (101, jsonb_build_object('ko-KR', '전복죽', 'en-US', 'Abalone Porridge', 'ja-JP', '鮑粥'),
     jsonb_build_object('ko-KR', '전복을 넣어 끓인 고소하고 영양가 높은 한국의 대표 보양죽', 'en-US', 'Nutritious Korean rice porridge made with fresh abalone.'),
     '전복죽, 전복죽맛집, abalone porridge, 보양식, 아침식사, 환자식, 고소한죽') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;



-- [101] 요리 - 밥 (Keto & Vegan Alternatives)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '컬리플라워 라이스', 'en-US', 'Cauliflower Rice', 'ja-JP', 'カリフラワーライス'),
                                                                                jsonb_build_object('ko-KR', '컬리플라워를 잘게 다져 밥 대신 먹는 저탄수화물 식단용 리조또나 볶음밥 베이스', 'en-US', 'Finely chopped cauliflower used as a low-carb alternative to rice.'),
                                                                                '컬리플라워라이스, 컬리라이스, cauliflower rice, 저탄고지, 키토제닉, 다이어트식단, keto, lchf'),
                                                                               (101, jsonb_build_object('ko-KR', '퀴노아 샐러드 보울', 'en-US', 'Quinoa Bowl', 'ja-JP', 'キヌアボウル'),
                                                                                jsonb_build_object('ko-KR', '고단백 곡물인 퀴노아와 신선한 채소를 곁들인 영양 가득한 비건 식사', 'en-US', 'Nutritious bowl featuring high-protein quinoa, mixed vegetables, and plant-based toppings.'),
                                                                                '퀴노아보울, 퀴노아샐러드, quinoa, 수퍼푸드, 비건식단, vegan, 글루텐프리, gf') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Gluten-Free & Low-Carb)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '주키니 누들', 'en-US', 'Zucchini Noodles', 'ja-JP', 'ズッキーニヌードル'),
                                                                                jsonb_build_object('ko-KR', '애호박을 길게 뽑아 면 대신 사용하는 저칼로리 글루텐프리 요리', 'en-US', 'Zucchini cut into thin strands to replace traditional pasta noodles.'),
                                                                                '주키니누들, 쥬키니누들, zoodles, 주들스, 호박면, keto, 키토파스타, 글루텐프리, 저탄고지'),
                                                                               (102, jsonb_build_object('ko-KR', '곤약면', 'en-US', 'Konjac Noodles', 'ja-JP', 'こんにゃく麺'),
                                                                                jsonb_build_object('ko-KR', '칼로리가 거의 없는 곤약을 면 형태로 만든 다이어트용 면 요리', 'en-US', 'Zero-calorie noodles made from konjac yam, popular for weight loss.'),
                                                                                '곤약면, 곤약국수, 실곤약, konjac noodles, shirataki, 다이어트면, 0칼로리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Vegan & Middle Eastern)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (105, jsonb_build_object('ko-KR', '팔라펠', 'en-US', 'Falafel', 'ja-JP', 'ファラフェル'),
                                                                                jsonb_build_object('ko-KR', '병아리콩이나 잠두를 갈아 둥글게 튀겨낸 중동의 대표적인 비건 단백질 요리', 'en-US', 'Deep-fried balls made from ground chickpeas or fava beans, a vegan staple.'),
                                                                                '팔라펠, 팔라펄, falafel, 병아리콩튀김, 비건치킨, vegan, 중동요리, 채식단백질'),
                                                                               (105, jsonb_build_object('ko-KR', '라따뚜이', 'en-US', 'Ratatouille', 'ja-JP', 'ラタトゥイユ'),
                                                                                jsonb_build_object('ko-KR', '가지, 호박, 토마토 등 각종 채소를 듬뿍 넣어 끓인 프랑스식 채소 스튜', 'en-US', 'Traditional French stewed vegetable dish consisting of eggplant, zucchini, and peppers.'),
                                                                                '라따뚜이, 라타투이, ratatouille, 채소요리, 비건스튜, 프랑스가정식, vegan') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Plant-Based Alternatives)
-- 카테고리는 103(고기)이지만 식물성 고기를 찾는 유저들을 위해 배치
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '두부 스테이크', 'en-US', 'Tofu Steak', 'ja-JP', '豆腐ステーキ'),
                                                                                jsonb_build_object('ko-KR', '단단한 두부를 구워 고기 스테이크 같은 식감을 낸 비건 요리', 'en-US', 'Pan-seared firm tofu slices seasoned and served like a traditional steak.'),
                                                                                '두부스테이크, tofu steak, 두부구이, 비건단백질, 채식스테이크, vegan, 저칼로리'),
                                                                               (103, jsonb_build_object('ko-KR', '템페 구이', 'en-US', 'Grilled Tempeh', 'ja-JP', 'テンペ焼き'),
                                                                                jsonb_build_object('ko-KR', '콩을 발효시켜 만든 인도네시아식 단백질 식품인 템페를 구운 요리', 'en-US', 'Slices of fermented soybean cake, grilled for a nutty flavor and firm texture.'),
                                                                                '템페구이, 템페, tempeh, 발효콩, 비건고기, vegan, 고단백식단') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Keto & Health)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '사골 곰탕', 'en-US', 'Bone Broth', 'ja-JP', 'サゴルコムタン'),
     jsonb_build_object('ko-KR', '소뼈를 오랜 시간 고아낸 진한 국물로 키토 식단의 필수 요소', 'en-US', 'Nutrient-rich broth made by simmering animal bones for an extended period.'),
     '사골곰탕, 사골국, bone broth, 본브로스, 키토국물, keto, 저탄고지, 보양식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Keto Favorite)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (301, jsonb_build_object('ko-KR', '방탄커피', 'en-US', 'Bulletproof Coffee', 'ja-JP', 'バターコーヒー'),
     jsonb_build_object('ko-KR', '에스프레소에 무염 버터와 MCT 오일을 섞어 마시는 고지방 커피', 'en-US', 'Coffee blended with unsalted butter and MCT oil, a staple of keto diets.'),
     '방탄커피, 버터커피, bulletproof coffee, keto coffee, 키토커피, mct오일, 저탄고지') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Nut-Free & Healthy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (501, jsonb_build_object('ko-KR', '병아리콩 스낵', 'en-US', 'Roasted Chickpeas', 'ja-JP', 'ひよこ豆のスナック'),
     jsonb_build_object('ko-KR', '병아리콩을 오븐에 구워 바삭하게 만든 너트프리 건강 간식', 'en-US', 'Crunchy, seasoned chickpeas roasted until golden, a nut-free snack alternative.'),
     '병아리콩스낵, 구운병아리콩, roasted chickpeas, 너트프리, nutfree, 건강간식, 비건과자') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [606] 소스 - 스프레드 (Nut-Free Alternatives)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (606, jsonb_build_object('ko-KR', '해바라기씨 버터', 'en-US', 'Sunflower Seed Butter', 'ja-JP', 'ひまわりの種のバター'),
     jsonb_build_object('ko-KR', '땅콩 알레르기가 있는 사람들을 위한 해바라기씨 베이스의 스프레드', 'en-US', 'Creamy spread made from roasted sunflower seeds, a safe peanut butter alternative.'),
     '해바라기씨버터, 썬버터, sunbutter, nutfree, 너트프리, 알러지프리, 땅콩버터대체') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 아이스크림/기타 (Dairy-Free)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (203, jsonb_build_object('ko-KR', '치아씨드 푸딩', 'en-US', 'Chia Seed Pudding', 'ja-JP', 'チアシードプリン'),
     jsonb_build_object('ko-KR', '치아씨드를 식물성 우유에 불려 만든 유제품 없는 건강 디저트', 'en-US', 'Healthy, dairy-free pudding made by soaking chia seeds in plant milk.'),
     '치아씨드푸딩, 치아푸딩, chia pudding, 다이어트푸딩, dairyfree, 데일리프리, 비건디저트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Healthy Grains & Keto)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '현미밥', 'en-US', 'Brown Rice', 'ja-JP', '玄米ご飯'),
                                                                                jsonb_build_object('ko-KR', '도정하지 않아 식이섬유가 풍부하고 혈당 조절에 도움을 주는 건강한 밥', 'en-US', 'Unpolished rice rich in fiber and nutrients, ideal for blood sugar control.'),
                                                                                '현미밥, 현미, brown rice, 잡곡밥, 건강식단, 다이어트밥, 복합탄수화물'),
                                                                               (101, jsonb_build_object('ko-KR', '보리밥', 'en-US', 'Barley Rice', 'ja-JP', '麦ご飯'),
                                                                                jsonb_build_object('ko-KR', '톡톡 터지는 식감이 특징이며 비타민과 섬유질이 풍부한 보리를 섞은 밥', 'en-US', 'Rice mixed with barley, known for its chewy texture and high fiber content.'),
                                                                                '보리밥, 꽁보리밥, barley rice, 식이섬유, 소화잘되는밥, 웰빙푸드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Gluten-Free & Vegan)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '메밀면', 'en-US', 'Buckwheat Noodles', 'ja-JP', 'そば'),
     jsonb_build_object('ko-KR', '밀가루 대신 메밀을 주원료로 하여 글루텐 함량이 적고 구수한 맛이 나는 면', 'en-US', 'Noodles made from buckwheat flour, a gluten-friendly and earthy alternative.'),
     '메밀면, 모밀, 소바, buckwheat noodles, soba, 글루텐프리, gf, 다이어트면, 구수한면') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Plant-Based Protein)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '비건 패티', 'en-US', 'Plant-based Patty', 'ja-JP', '植物性パティ'),
                                                                                jsonb_build_object('ko-KR', '콩이나 버섯 등 식물성 재료로 고기의 맛과 식감을 구현한 대체육 패티', 'en-US', 'Meat-free patty made from soy or pea protein, designed to mimic beef.'),
                                                                                '비건패티, 대체육, 콩고기, plant based patty, beyond meat, impossible burger, 비건버거, vegan'),
                                                                               (103, jsonb_build_object('ko-KR', '밀고기', 'en-US', 'Seitan', 'ja-JP', 'セイタン'),
                                                                                jsonb_build_object('ko-KR', '밀의 글루텐을 추출하여 만든 쫄깃한 식감의 고단백 식물성 대체육', 'en-US', 'Wheat gluten-based meat substitute with a savory, chewy texture.'),
                                                                                '밀고기, 세이탄, seitan, 비건고기, 밀고기스테이크, vegan, 고단백채식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Vegetarian & Health)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '렌틸콩 수프', 'en-US', 'Lentil Soup', 'ja-JP', 'レンズ豆のスープ'),
     jsonb_build_object('ko-KR', '단백질이 풍부한 렌틸콩을 듬뿍 넣어 끓인 든든하고 담백한 비건 수프', 'en-US', 'Hearty and protein-rich soup made with lentils, vegetables, and herbs.'),
     '렌틸콩수프, 렌틸수프, lentil soup, 비건수프, vegan, 슈퍼푸드, 다이어트수프, 단백질수프') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [107] 요리 - 샌드위치 (Low-Carb / Keto)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (107, jsonb_build_object('ko-KR', '상추 랩', 'en-US', 'Lettuce Wraps', 'ja-JP', 'レタスラップ'),
     jsonb_build_object('ko-KR', '빵이나 또띠아 대신 신선한 상추 잎으로 속재료를 감싼 저탄수화물 메뉴', 'en-US', 'Low-carb alternative using fresh lettuce leaves instead of bread or tortillas.'),
     '상추랩, 레터스랩, lettuce wraps, 노브레드, 저탄고지, keto, 키토제닉, 다이어트샌드위치, 글루텐프리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Dairy-Free / Anti-Inflammatory)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '강황 라떼', 'en-US', 'Golden Milk', 'ja-JP', 'ゴールデンミルク'),
     jsonb_build_object('ko-KR', '강황과 식물성 우유를 섞어 만든 항염 효과가 뛰어난 건강 음료', 'en-US', 'Anti-inflammatory drink made with turmeric, spices, and plant-based milk.'),
     '강황라떼, 골든밀크, golden milk, turmeric latte, 데일리프리, dairyfree, 면역력강화, 비건라떼') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Keto & Nut-Free)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (501, jsonb_build_object('ko-KR', '돼지껍데기 튀김', 'en-US', 'Pork Rinds', 'ja-JP', '豚皮チップス'),
                                                                                jsonb_build_object('ko-KR', '탄수화물은 거의 없고 지방과 단백질로 이루어진 바삭한 키토제닉 간식', 'en-US', 'Crispy snack made from deep-fried pork skin, perfect for zero-carb diets.'),
                                                                                '돼지껍데기튀김, 돼껍튀김, 치차론, pork rinds, chicharron, 키토간식, keto, 저탄고지, 고지방간식'),
                                                                               (501, jsonb_build_object('ko-KR', '김부각', 'en-US', 'Seaweed Crackers', 'ja-JP', 'のり天'),
                                                                                jsonb_build_object('ko-KR', '김에 찹쌀풀을 발려 튀겨낸 바삭하고 고소한 한국 전통 채식 간식', 'en-US', 'Traditional Korean snack made of deep-fried seaweed coated with rice paste.'),
                                                                                '김부각, 부각, seaweed crackers, k-snack, 비건과자, vegan, 바삭한간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Vegan / Dairy-Free)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (604, jsonb_build_object('ko-KR', '영양 효모', 'en-US', 'Nutritional Yeast', 'ja-JP', 'ニュートリショナルイースト'),
     jsonb_build_object('ko-KR', '비건 식단에서 치즈와 같은 고소한 풍미를 내기 위해 사용하는 필수 식재료', 'en-US', 'Deactivated yeast used in vegan cooking to provide a cheesy, nutty flavor.'),
     '영양효모, 뉴트리셔널이스트, nutritional yeast, 비건치즈가루, 비타민보충, vegan, 데일리프리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Halal & Middle Eastern)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '양고기 케밥', 'en-US', 'Lamb Kebab', 'ja-JP', 'ラムケバブ'),
                                                                                jsonb_build_object('ko-KR', '향신료로 양념한 양고기를 꼬치에 끼워 구운 할랄 인증 가능 지중해 요리', 'en-US', 'Spiced lamb grilled on skewers, a staple Halal-friendly Mediterranean dish.'),
                                                                                '양고기케밥, 케밥, kebab, lamb, halal, 할랄푸드, 지중해요리, 꼬치구이'),
                                                                               (103, jsonb_build_object('ko-KR', '치킨 너겟', 'en-US', 'Chicken Nuggets', 'ja-JP', 'チキンナゲット'),
                                                                                jsonb_build_object('ko-KR', '닭고기를 갈아 바삭하게 튀겨낸 아이들이 가장 좋아하는 대표적인 키즈 메뉴', 'en-US', 'Bite-sized pieces of breaded and fried chicken, a favorite for children.'),
                                                                                '치킨너겟, 너겟, nuggets, kids menu, 어린이메뉴, 키즈식단, 핑거푸드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Asian Street Food & Kosher Friendly)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '딤섬', 'en-US', 'Dim Sum', 'ja-JP', '点心'),
                                                                                jsonb_build_object('ko-KR', '차와 함께 즐기는 중국식 만두와 전채 요리로 종류가 매우 다양한 요리', 'en-US', 'Variety of small Chinese dishes, typically steamed or fried dumplings served with tea.'),
                                                                                '딤섬, 하가우, 샤오롱바오, dimsum, yumcha, 얌차, 중국요리, 만두'),
                                                                               (109, jsonb_build_object('ko-KR', '마초 볼 수프', 'en-US', 'Matzo Ball Soup', 'ja-JP', 'マッツァ・ボール・スープ'),
                                                                                jsonb_build_object('ko-KR', '유대인들이 축제 때 즐겨 먹는 무교병 가루로 만든 완자가 들어간 따뜻한 국물 요리', 'en-US', 'Traditional Jewish soup with dumplings made from matzo meal, a Kosher classic.'),
                                                                                '마초볼수프, 유대인음식, kosher, 코셔푸드, matzo ball soup, 명절요리, 따뜻한수프') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (European Tapas & Gluten-Free Alternative)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (501, jsonb_build_object('ko-KR', '파타타스 브라바스', 'en-US', 'Patatas Bravas', 'ja-JP', 'パタタス・ブラバス'),
                                                                                jsonb_build_object('ko-KR', '튀긴 감자에 매콤한 소스를 곁들인 스페인의 대표적인 타파스 메뉴', 'en-US', 'Spanish dish of irregular-sized fried potatoes served with a spicy warm sauce.'),
                                                                                '파타타스브라바스, 타파스, tapas, 스페인안주, 감자요리, 술안주'),
                                                                               (501, jsonb_build_object('ko-KR', '고구마 튀김', 'en-US', 'Sweet Potato Fries', 'ja-JP', 'さつまいもフライ'),
                                                                                jsonb_build_object('ko-KR', '감자튀김의 건강한 대안으로 글루텐프리 식단에서 자주 찾는 바삭하고 달콤한 간식', 'en-US', 'Sweet and crunchy alternative to potato fries, popular in gluten-free diets.'),
                                                                                '고구마튀김, 고구마프라이, sweet potato fries, gf, 글루텐프리, 다이어트간식, 에어프라이어메뉴') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Global Superfood)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (108, jsonb_build_object('ko-KR', '아사이볼', 'en-US', 'Acai Bowl', 'ja-JP', 'アサイーボウル'),
     jsonb_build_object('ko-KR', '슈퍼푸드인 아사이베리 스무디에 신선한 과일과 견과류를 올린 건강식', 'en-US', 'Healthy breakfast bowl made of frozen and mashed acai palm fruit topped with fruit.'),
     '아사이볼, 아사이보울, acai bowl, 슈퍼푸드, 비건브런치, vegan, 건강한아침') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Global Sauce)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (604, jsonb_build_object('ko-KR', '치미추리 소스', 'en-US', 'Chimichurri', 'ja-JP', 'チミチュリ'),
     jsonb_build_object('ko-KR', '파슬리와 마늘을 베이스로 한 아르헨티나식 소스로 고기 요리와 잘 어울림', 'en-US', 'Argentine uncooked sauce used for grilled meat, made of parsley and garlic.'),
     '치미추리, chimichurri, 스테이크소스, 남미소스, 허브소스, 남미요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Korean & Japanese Casual)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '유부초밥', 'en-US', 'Inari Sushi', 'ja-JP', 'いなり寿司'),
                                                                                jsonb_build_object('ko-KR', '달콤 짭짤하게 조린 유부 속에 밥을 채워 넣은 간편하고 대중적인 초밥', 'en-US', 'Fried tofu pouches stuffed with seasoned sushi rice, a sweet and savory favorite.'),
                                                                                '유부초밥, 유부, inari, 이나리, 대왕유부초밥, 소풍도시락, 초밥'),
                                                                               (101, jsonb_build_object('ko-KR', '회덮밥', 'en-US', 'Hwedupbap', 'ja-JP', '刺身丼'),
                                                                                jsonb_build_object('ko-KR', '신선한 생선회와 각종 채소를 초고추장에 비벼 먹는 한국식 덮밥', 'en-US', 'Korean rice bowl topped with fresh raw fish, vegetables, and spicy chili sauce.'),
                                                                                '회덮밥, 해물덮밥, hwedupbap, raw fish bowl, 초장비빔밥, 일식덮밥') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Trendy Italian & Thai)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '뇨끼', 'en-US', 'Gnocchi', 'ja-JP', 'ニョッキ'),
                                                                                jsonb_build_object('ko-KR', '감자와 밀가루를 반죽해 만든 이탈리아식 수제비로 쫀득하고 고소한 맛이 특징', 'en-US', 'Soft Italian dumplings made from potatoes and flour, served with various sauces.'),
                                                                                '뇨끼, 뇨끼맛집, gnocchi, 감자뇨끼, 이태리수제비, 꾸덕한소스'),
                                                                               (102, jsonb_build_object('ko-KR', '팟씨유', 'en-US', 'Pad See Ew', 'ja-JP', 'パッシー유'),
                                                                                jsonb_build_object('ko-KR', '넓은 쌀면을 간장 소스에 고기, 채소와 함께 볶아낸 달콤 짭짤한 태국 요리', 'en-US', 'Stir-fried wide rice noodles with soy sauce, Chinese broccoli, and meat.'),
                                                                                '팟씨유, 팟시유, pad see ew, 태국볶음면, 간장쌀국수, 동남아음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Korean Dessert Trends)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '크로플', 'en-US', 'Croffle', 'ja-JP', 'クロッフル'),
                                                                                jsonb_build_object('ko-KR', '크로와상 생지를 와플 팬에 구워 바삭함과 고소함을 극대화한 디저트', 'en-US', 'Hybrid of a croissant and a waffle, crispy on the outside and buttery inside.'),
                                                                                '크로플, croffle, 크로와상와플, 홈카페, 디저트맛집, 겉바속촉'),
                                                                               (201, jsonb_build_object('ko-KR', '소금빵', 'en-US', 'Salt Bread', 'ja-JP', '塩パン'),
                                                                                jsonb_build_object('ko-KR', '버터 풍미가 가득한 빵 위에 소금을 뿌려 짭짤하고 고소한 맛을 낸 인기 빵', 'en-US', 'Soft, buttery bread roll topped with a sprinkle of sea salt.'),
                                                                                '소금빵, 시오빵, salt bread, 버터롤, 단짠디저트, 베이커리추천') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 유제품 (Health & Diet Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (203, jsonb_build_object('ko-KR', '그릭 요거트', 'en-US', 'Greek Yogurt', 'ja-JP', 'ギリシャヨーグルト'),
     jsonb_build_object('ko-KR', '유청을 제거해 꾸덕한 식감과 높은 단백질 함량을 자랑하는 건강 요거트', 'en-US', 'Thick, strained yogurt with a creamy texture and high protein content.'),
     '그릭요거트, 꾸덕요거트, greek yogurt, 다이어트식단, 요거트볼, 아침식사, 건강간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [502] 간식 - 사탕/젤리 (Current Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (502, jsonb_build_object('ko-KR', '탕후루', 'en-US', 'Tanghulu', 'ja-JP', 'タンフル'),
     jsonb_build_object('ko-KR', '신선한 과일에 설탕 시럽을 입혀 굳힌 바삭하고 달콤한 간식', 'en-US', 'Traditional Chinese candied fruit snack with a crunchy sugar coating.'),
     '탕후루, 탕후루맛집, tanghulu, 과일사탕, 간식, 달달구리, MZ간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Spicy Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (109, jsonb_build_object('ko-KR', '마라샹궈', 'en-US', 'Mala Xiang Guo', 'ja-JP', '麻辣香鍋'),
     jsonb_build_object('ko-KR', '원하는 재료를 매콤한 마라 소스에 볶아낸 중식 볶음 요리', 'en-US', 'Spicy and numbing stir-fry dish made with various meats and vegetables.'),
     '마라샹궈, 샹궈, malaxiangguo, 마라볶음, 술안주, 중식요리, 매운음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Keto & Gluten-Free)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '두부면', 'en-US', 'Tofu Noodles', 'ja-JP', '豆腐麺'),
                                                                                jsonb_build_object('ko-KR', '단백질이 풍부한 두부를 면 형태로 가공하여 밀가루 대신 사용하는 건강 면', 'en-US', 'High-protein noodles made from tofu, a popular low-carb substitute for flour pasta.'),
                                                                                '두부면, 포두부, tofu noodles, 비건파스타, vegan, keto, 저탄고지, 글루텐프리, gf'),
                                                                               (102, jsonb_build_object('ko-KR', '천사채', 'en-US', 'Kelp Noodles', 'ja-JP', 'ケルプヌードル'),
                                                                                jsonb_build_object('ko-KR', '해조류 추출물로 만든 투명한 면으로 칼로리가 낮아 다이어트 및 키토 식단에 인기', 'en-US', 'Translucent noodles made from kelp extract, very low in calories and keto-friendly.'),
                                                                                '천사채, 해초면, kelp noodles, 키토면, keto, 다이어트국수, 곤약대체') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 피자/기타 (Low-Carb & GF)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (109, jsonb_build_object('ko-KR', '컬리플라워 피자', 'en-US', 'Cauliflower Pizza', 'ja-JP', 'カリフラワーピザ'),
     jsonb_build_object('ko-KR', '밀가루 대신 컬리플라워로 도우를 만들어 탄수화물을 획기적으로 줄인 건강 피자', 'en-US', 'Pizza with a crust made from cauliflower, perfect for gluten-free and keto diets.'),
     '컬리플라워피자, cauliflower pizza, 키토피자, keto, 글루텐프리피자, gf, 저탄수화물') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [107] 요리 - 샌드위치 (Keto & Nut-Free)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (107, jsonb_build_object('ko-KR', '클라우드 브레드', 'en-US', 'Cloud Bread', 'ja-JP', 'クラウドブレッド'),
     jsonb_build_object('ko-KR', '밀가루 없이 달걀과 치즈로 만든 구름처럼 폭신한 저탄수화물 빵', 'en-US', 'Fluffy, grain-free bread made from eggs and cream cheese, a keto staple.'),
     '클라우드브레드, 구름빵, cloud bread, 노밀가루빵, 키토빵, keto, 글루텐프리, gf') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Vegan & High-Protein)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (101, jsonb_build_object('ko-KR', '병아리콩 샐러드', 'en-US', 'Chickpea Salad', 'ja-JP', 'ひよこ豆のサラダ'),
     jsonb_build_object('ko-KR', '삶은 병아리콩을 메인으로 채소와 드레싱을 곁들인 든든한 식사대용 비건 메뉴', 'en-US', 'Filling vegan salad featuring boiled chickpeas as the main protein source.'),
     '병아리콩샐러드, 병아리콩, chickpea salad, hummus bowl, 비건식단, vegan, 고단백채식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [307] 음료 - 대체유 (Dairy-Free & Nut-Free)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (307, jsonb_build_object('ko-KR', '코코넛 밀크', 'en-US', 'Coconut Milk', 'ja-JP', 'ココナッツミルク'),
     jsonb_build_object('ko-KR', '코코넛 과육에서 추출한 진하고 부드러운 식물성 밀크로 유제품 대체제로 사용', 'en-US', 'Creamy plant-based milk extracted from coconuts, a popular dairy-free option.'),
     '코코넛밀크, coconut milk, 데일리프리, dairyfree, 비건우유, 키토음료, keto') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Vegan & GF)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '비건 브라우니', 'en-US', 'Vegan Brownie', 'ja-JP', 'ヴィーガンブラウニー'),
     jsonb_build_object('ko-KR', '달걀과 버터 대신 식물성 재료를 사용하여 만든 진하고 달콤한 건강 디저트', 'en-US', 'Fudgy brownie made without eggs or dairy, using plant-based alternatives.'),
     '비건브라우니, vegan brownie, 채식디저트, 건강빵, 노에그, 노버터, vegan') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [606] 소스 - 스프레드 (Keto & Vegan)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (606, jsonb_build_object('ko-KR', '아몬드 버터', 'en-US', 'Almond Butter', 'ja-JP', 'アーモンドバター'),
     jsonb_build_object('ko-KR', '볶은 아몬드를 그대로 갈아 만든 고소하고 건강한 지방이 풍부한 스프레드', 'en-US', 'Creamy spread made from roasted almonds, a high-fat favorite for keto diets.'),
     '아몬드버터, almond butter, 키토소스, keto, 저탄고지, 건강한지방, 땅콩버터대체') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Vegan & Modern Healthy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (105, jsonb_build_object('ko-KR', '콜리플라워 윙', 'en-US', 'Cauliflower Wings', 'ja-JP', 'カリフラワーウィング'),
                                                                                jsonb_build_object('ko-KR', '치킨 대신 컬리플라워를 튀겨 버팔로 소스에 버무린 인기 비건 안주 요리', 'en-US', 'Fried cauliflower florets tossed in spicy buffalo sauce, a popular vegan alternative to chicken wings.'),
                                                                                '콜리플라워윙, 비건치킨, cauliflower wings, vegan, 채식안주, 가짜치킨, 버팔로컬리플라워'),
                                                                               (105, jsonb_build_object('ko-KR', '그릴드 아스파라거스', 'en-US', 'Grilled Asparagus', 'ja-JP', 'アスパラガスのグリル'),
                                                                                jsonb_build_object('ko-KR', '아스파라거스를 올리브유와 소금으로 간해 그릴에 구워낸 저탄수화물 채소 요리', 'en-US', 'Fresh asparagus spears seasoned and grilled, a perfect low-carb side dish.'),
                                                                                '아스파라거스구이, 구운아스파라거스, grilled asparagus, keto, 키토제닉, 다이어트가니쉬, 스테이크친구') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Comfort Food & Soul Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '클램 차우더', 'en-US', 'Clam Chowder', 'ja-JP', 'クラムチャウダー'),
                                                                                jsonb_build_object('ko-KR', '조개와 감자, 크림을 넣어 끓인 고소하고 걸쭉한 북미식 수프', 'en-US', 'Rich and creamy American soup made with clams, potatoes, and onions.'),
                                                                                '클램차우더, 조개수프, clam chowder, 크림수프, 해산물수프, 따뜻한음식'),
                                                                               (106, jsonb_build_object('ko-KR', '순대국', 'en-US', 'Sundae-guk', 'ja-JP', 'スンデク'),
                                                                                jsonb_build_object('ko-KR', '진한 돼지 사골 육수에 순대와 머릿고기를 넣어 끓인 한국의 대표 보양 국밥', 'en-US', 'Hearty Korean soup made with blood sausage and pork offal in a rich broth.'),
                                                                                '순대국, 순대국밥, sundaeguk, 해장국, 아침식사, 소울푸드, 든든한한끼') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Regional & Dietary Variation)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '비빔국수', 'en-US', 'Bibim-guksu', 'ja-JP', 'ビビン麺'),
                                                                                jsonb_build_object('ko-KR', '매콤달콤한 고추장 양념에 소면과 채소를 비벼 먹는 차가운 면 요리', 'en-US', 'Cold Korean noodles mixed with a sweet and spicy chili pepper sauce.'),
                                                                                '비빔국수, 비빔면, bibimguksu, 매운면, 여름별미, 비빔국수맛집'),
                                                                               (102, jsonb_build_object('ko-KR', '두부면 파스타', 'en-US', 'Tofu Pasta', 'ja-JP', '豆腐パスタ'),
                                                                                jsonb_build_object('ko-KR', '밀가루 면 대신 두부면을 사용하여 단백질 함량을 높인 건강한 파스타', 'en-US', 'Pasta dish using tofu noodles instead of wheat, ideal for high-protein and gluten-free diets.'),
                                                                                '두부면파스타, 두부파스타, tofu pasta, 비건파스타, vegan, keto, 글루텐프리, gf, 다이어트식단') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Keto & Protein Snack)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (501, jsonb_build_object('ko-KR', '육포', 'en-US', 'Beef Jerky', 'ja-JP', 'ビーフジャーキー'),
                                                                                jsonb_build_object('ko-KR', '소고기를 얇게 썰어 말린 고단백 간식으로 키토제닉 식단에 적합한 안주', 'en-US', 'Lean meat trimmed of fat, cut into strips, and dried, a high-protein keto snack.'),
                                                                                '육포, 비프저키, beef jerky, 고단백간식, 술안주, 편의점간식, keto, 저탄고지'),
                                                                               (501, jsonb_build_object('ko-KR', '케일 칩', 'en-US', 'Kale Chips', 'ja-JP', 'ケールチップス'),
                                                                                jsonb_build_object('ko-KR', '케일에 올리브유와 소금을 발라 구워낸 바삭하고 가벼운 비건 스낵', 'en-US', 'Crispy, seasoned kale leaves baked until crunchy, a healthy vegan snack.'),
                                                                                '케일칩, 야채칩, kale chips, 비건과자, vegan, 다이어트스낵, 글루텐프리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [505] 간식 - 시리얼 (Modern Healthy Breakfast)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (505, jsonb_build_object('ko-KR', '오버나이트 오트밀', 'en-US', 'Overnight Oats', 'ja-JP', 'オーバーナイトオーツ'),
     jsonb_build_object('ko-KR', '귀리를 우유나 요거트에 밤새 불려 과일과 함께 먹는 간편하고 건강한 아침 식사', 'en-US', 'Oats soaked in milk or yogurt overnight, typically topped with fruit and seeds.'),
     '오버나이트오트밀, 오오트, overnight oats, 아침식사, 비건아침, 다이어트식단, 건강식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Vegan & Mediterranean)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (105, jsonb_build_object('ko-KR', '바바 가누쉬', 'en-US', 'Baba Ganoush', 'ja-JP', 'ババガヌーシュ'),
                                                                                jsonb_build_object('ko-KR', '구운 가지를 으깨어 타히니, 올리브유와 섞어 만든 중동식 비건 딥 소스', 'en-US', 'Roasted eggplant dip mixed with tahini, olive oil, and garlic, a vegan favorite.'),
                                                                                '바바가누쉬, 가지딥, baba ganoush, 비건소스, vegan, keto, 지중해식단, 저탄수화물'),
                                                                               (105, jsonb_build_object('ko-KR', '에다마메', 'en-US', 'Edamame', 'ja-JP', '枝豆'),
                                                                                jsonb_build_object('ko-KR', '덜 익은 상태의 콩을 쪄서 만든 고단백 식물성 간식으로 키토제닉 식단에 적합', 'en-US', 'Young soybeans in the pod, steamed and seasoned with salt, high in protein and keto-friendly.'),
                                                                                '에다마메, 풋콩, 자숙면, edamame, 고단백간식, vegan, keto, 다이어트간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Korean Soul Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '감자탕', 'en-US', 'Gamjatang', 'ja-JP', 'カムジャタン'),
     jsonb_build_object('ko-KR', '돼지 등뼈와 감자, 우거지를 넣어 얼큰하게 끓인 한국의 보양 국물 요리', 'en-US', 'Spicy Korean pork bone soup with potatoes, dried radish greens, and aromatic perilla seeds.'),
     '감자탕, 해장국, 뼈다귀해장국, gamjatang, pork bone soup, 소울푸드, 단백질식단, 든든한한끼') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Keto Specialist)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '차플', 'en-US', 'Chaffle', 'ja-JP', 'チャッフル'),
                                                                                jsonb_build_object('ko-KR', '치즈와 달걀로 만든 밀가루 없는 와플로 키토제닉 식단의 대표적인 빵 대체제', 'en-US', 'Waffle made from cheese and eggs instead of flour, a staple for keto-based diets.'),
                                                                                '차플, 치즈와플, chaffle, keto bread, 키토빵, 저탄고지, lchf, 글루텐프리, gf'),
                                                                               (109, jsonb_build_object('ko-KR', '사시미', 'en-US', 'Sashimi', 'ja-JP', '刺身'),
                                                                                jsonb_build_object('ko-KR', '신선한 생선을 얇게 썰어 소스에 찍어 먹는 요리로 탄수화물이 거의 없는 순수 단백질 식단', 'en-US', 'Thinly sliced fresh raw seafood served with soy sauce, a perfect zero-carb protein source.'),
                                                                                '사시미, 회, 생선회, sashimi, 생선회맛집, 고단백식단, keto, 다이어트식단') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 유제품/대체 (Dairy-Free Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (203, jsonb_build_object('ko-KR', '코코넛 요거트', 'en-US', 'Coconut Yogurt', 'ja-JP', 'ココナッツヨーグルト'),
     jsonb_build_object('ko-KR', '코코넛 밀크를 발효시켜 만든 유제품 없는 비건 요거트', 'en-US', 'Creamy, dairy-free yogurt made from fermented coconut milk, a vegan and keto favorite.'),
     '코코넛요거트, 비건요거트, coconut yogurt, dairyfree, 데일리프리, vegan, keto, 건강디저트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [506] 간식 - 에너지바 (Keto Fat Bomb)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (506, jsonb_build_object('ko-KR', '팻 밤', 'en-US', 'Fat Bomb', 'ja-JP', 'ファットボム'),
     jsonb_build_object('ko-KR', '코코넛 오일, 버터, 견과류로 만든 고지방 저탄수화물 에너지 간식', 'en-US', 'High-fat, low-carb snacks made with healthy fats to sustain energy in keto diets.'),
     '팻밤, 팻봄, fat bomb, 키토간식, 저탄고지에너지바, keto, 고지방다이어트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Korean Classic & GF Option)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '잡채', 'en-US', 'Japchae', 'ja-JP', 'チャプチェ'),
                                                                                jsonb_build_object('ko-KR', '고구마 전분으로 만든 당면과 각종 채소, 고기를 볶아낸 한국의 잔치 요리', 'en-US', 'Stir-fried glass noodles made from sweet potato starch with vegetables and meat.'),
                                                                                '잡채, 잡채밥, japchae, glass noodles, 잔치음식, k-food, 글루텐프리, gf'),
                                                                               (102, jsonb_build_object('ko-KR', '쌀국수(분짜)', 'en-US', 'Bun Cha', 'ja-JP', 'ブンチャー'),
                                                                                jsonb_build_object('ko-KR', '숯불 돼지고기와 쌀국수를 새콤달콤한 소스에 적셔 먹는 베트남의 대표 요리', 'en-US', 'Vietnamese dish of grilled pork and rice noodles served with a dipping sauce.'),
                                                                                '분짜, buncha, 베트남쌀국수, 찍먹국수, 동남아요리, 쌀국수') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Probiotic & Health)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '미소된장국', 'en-US', 'Miso Soup', 'ja-JP', '味噌汁'),
                                                                                jsonb_build_object('ko-KR', '미소를 풀어 두부, 미역과 함께 끓인 담백하고 건강한 일본식 국물 요리', 'en-US', 'Traditional Japanese soup consisting of a dashi stock mixed with softened miso paste.'),
                                                                                '미소된장국, 미소국, miso soup, 미소시루, 일식국물, 발효음식, probiotic, 속편한음식'),
                                                                               (106, jsonb_build_object('ko-KR', '가스파초', 'en-US', 'Gazpacho', 'ja-JP', 'ガスパチョ'),
                                                                                jsonb_build_object('ko-KR', '신선한 채소를 갈아 차갑게 먹는 스페인 안달루시아 지방의 전통 수프', 'en-US', 'Cold Spanish soup made of raw, blended vegetables, perfect for summer.'),
                                                                                '가스파초, 가스파쵸, gazpacho, 냉수프, 비건수프, vegan, 스페인요리, 건강수프') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Keto & Global Favorites)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '오믈렛', 'en-US', 'Omelette', 'ja-JP', 'オムレツ'),
                                                                                jsonb_build_object('ko-KR', '달걀을 풀어 다양한 속재료를 넣고 익힌 부드러운 단백질 요리', 'en-US', 'Dish made from beaten eggs fried with butter or oil in a frying pan.'),
                                                                                '오믈렛, 오물렛, omelette, 계란요리, 고단백, keto, 저탄고지, 브런치, 수플레오믈렛'),
                                                                               (109, jsonb_build_object('ko-KR', '해물파전', 'en-US', 'Seafood Pancake', 'ja-JP', '海鮮チヂミ'),
                                                                                jsonb_build_object('ko-KR', '쪽파와 각종 해산물을 듬뿍 넣어 노릇하게 구워낸 한국의 대표 전 요리', 'en-US', 'Savory Korean pancake made with scallions and a variety of seafood.'),
                                                                                '해물파전, 파전, seafood pancake, pajeon, 부침개, 막걸리안주, k-pizza') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Global Sauce & Vegan Base)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '바질 페스토', 'en-US', 'Basil Pesto', 'ja-JP', 'バジルペースト'),
                                                                                jsonb_build_object('ko-KR', '바질, 잣, 파마산 치즈, 올리브유를 갈아 만든 이탈리아의 향긋한 소스', 'en-US', 'Italian sauce consisting of crushed garlic, pine nuts, basil, and cheese.'),
                                                                                '바질페스토, pesto, 페스토, 파스타소스, 이태리양념, 허브소스, 샌드위치소스'),
                                                                               (604, jsonb_build_object('ko-KR', '타히니 소스', 'en-US', 'Tahini', 'ja-JP', 'タヒニ'),
                                                                                jsonb_build_object('ko-KR', '참깨를 갈아 만든 고소한 중동식 소스로 비건 요리에 널리 쓰임', 'en-US', 'Middle Eastern condiment made from toasted ground hulled sesame.'),
                                                                                '타히니, 타히니소스, tahini, 참깨소스, 비건소스, vegan, 후무스재료, 중동양념') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Global Pastry)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '바클라바', 'en-US', 'Baklava', 'ja-JP', 'バクラヴァ'),
     jsonb_build_object('ko-KR', '얇은 반죽 층 사이에 견과류와 꿀을 넣어 만든 달콤하고 바삭한 중동식 디저트', 'en-US', 'Sweet dessert pastry made of layers of filo filled with chopped nuts and syrup.'),
     '바클라바, 박클라바, baklava, 터키디저트, 꿀디저트, 달달구리, 페이스트리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Zero-Carb & Ancient Grains)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '곤약밥', 'en-US', 'Konjac Rice', 'ja-JP', 'こんにゃくご飯'),
                                                                                jsonb_build_object('ko-KR', '칼로리가 거의 없는 곤약을 쌀 모양으로 가공하여 만든 극한의 다이어트 식단용 밥', 'en-US', 'Rice-shaped konjac pearls, an extremely low-calorie and zero-carb alternative to white rice.'),
                                                                                '곤약밥, 곤약쌀, konjac rice, shirataki rice, 키토제닉, keto, 다이어트밥, 0칼로리식단'),
                                                                               (101, jsonb_build_object('ko-KR', '귀리밥', 'en-US', 'Oat Rice', 'ja-JP', 'オート麦ご飯'),
                                                                                jsonb_build_object('ko-KR', '식이섬유가 풍부한 귀리를 섞어 지은 밥으로 혈당 조절과 포만감 유지에 탁월함', 'en-US', 'Steamed rice mixed with whole oats, known for high fiber and steady energy release.'),
                                                                                '귀리밥, 오트라이스, oat rice, 슈퍼푸드, 혈당조절, 건강식단, 복합탄수화물') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Gluten-Free Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '글루텐프리 파스타', 'en-US', 'Gluten-Free Pasta', 'ja-JP', 'グルテンフリーパスタ'),
                                                                                jsonb_build_object('ko-KR', '밀가루 대신 옥수수나 쌀가루로 만든 면으로 글루텐 불내증이 있는 유저를 위한 파스타', 'en-US', 'Pasta made from corn, rice, or quinoa flour, specially designed for gluten-sensitive diets.'),
                                                                                '글루텐프리파스타, gf pasta, glutenfree, 노밀가루면, 옥수수면, 쌀파스타'),
                                                                               (102, jsonb_build_object('ko-KR', '해초국수', 'en-US', 'Seaweed Noodles', 'ja-JP', '海藻麺'),
                                                                                jsonb_build_object('ko-KR', '해조류 성분으로 만든 투명하고 쫄깃한 면으로 저칼로리 비건 식단의 핵심 재료', 'en-US', 'Translucent, mineral-rich noodles made from seaweed extracts, popular in vegan and low-cal diets.'),
                                                                                '해초국수, 바다국수, seaweed noodles, 비건국수, vegan, 다이어트국수, 살안찌는면') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [307] 음료 - 대체유 (Dairy-Free Essentials)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (307, jsonb_build_object('ko-KR', '두유', 'en-US', 'Soy Milk', 'ja-JP', '豆乳'),
                                                                                jsonb_build_object('ko-KR', '대두를 갈아 만든 전통적인 식물성 우유로 단백질이 풍부한 유제품 대체제', 'en-US', 'Traditional plant milk made from soybeans, a versatile high-protein dairy alternative.'),
                                                                                '두유, 소이밀크, soy milk, 비건우유, vegan, 데일리프리, dairyfree, 베지밀, 단백질음료'),
                                                                               (307, jsonb_build_object('ko-KR', '캐슈밀크', 'en-US', 'Cashew Milk', 'ja-JP', 'カシューミルク'),
                                                                                jsonb_build_object('ko-KR', '캐슈너트를 갈아 만든 크리미한 식감의 견과류 밀크로 요리와 커피에 잘 어울림', 'en-US', 'Creamy nut milk made from soaked cashews, favored for its rich texture in lattes and cooking.'),
                                                                                '캐슈밀크, 캐슈넛우유, cashew milk, 견과류음료, 비건라떼재료, dairyfree, 데일리프리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Keto & Clean Eating)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '나한과 감미료', 'en-US', 'Monk Fruit Sweetener', 'ja-JP', '羅漢果甘味料'),
                                                                                jsonb_build_object('ko-KR', '칼로리와 혈당 지수가 0인 천연 감미료로 키토제닉 베이킹과 요리에 필수적임', 'en-US', 'Natural zero-calorie sweetener derived from monk fruit, ideal for keto and diabetic diets.'),
                                                                                '나한과, 몽크프루트, monk fruit, 키토설탕, 0칼로리당, keto, 대체당, 스테비아친구'),
                                                                               (604, jsonb_build_object('ko-KR', '액상 아미노스', 'en-US', 'Liquid Aminos', 'ja-JP', 'リ퀴드アミノ'),
                                                                                jsonb_build_object('ko-KR', '간장 대신 사용하는 글루텐프리 비건 조미료로 필수 아미노산을 함유함', 'en-US', 'Gluten-free, non-GMO soy sauce alternative rich in essential amino acids.'),
                                                                                '액상아미노스, 리퀴드아미노스, liquid aminos, 비건간장, 글루텐프리간장, gf, 저염간장') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Plant-Based Hearty Meals)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '렌틸 버거', 'en-US', 'Lentil Burger', 'ja-JP', 'レンズ豆バーガー'),
     jsonb_build_object('ko-KR', '고기 대신 렌틸콩을 으깨어 만든 고단백 비건 패티가 들어간 햄버거', 'en-US', 'Hearty burger featuring a protein-packed patty made from mashed lentils and spices.'),
     '렌틸버거, 렌틸콩패티, lentil burger, 비건버거, vegan, 채식버거, 건강한버거') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Cafe Culture & Dessert Coffee)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (301, jsonb_build_object('ko-KR', '아포가토', 'en-US', 'Affogato', 'ja-JP', 'アフォガート'),
                                                                                jsonb_build_object('ko-KR', '진한 에스프레소를 달콤한 바닐라 아이스크림 위에 부어 먹는 이탈리아식 디저트 커피', 'en-US', 'Italian coffee-based dessert made by pouring a shot of hot espresso over vanilla ice cream.'),
                                                                                '아포가토, 아포가또, affogato, 에스프레소아이스크림, 커피디저트, 달콤쌉싸름'),
                                                                               (301, jsonb_build_object('ko-KR', '더티 커피', 'en-US', 'Dirty Coffee', 'ja-JP', 'ダー티コーヒー'),
                                                                                jsonb_build_object('ko-KR', '컵 주변으로 에스프레소나 초콜릿이 흘러넘치는 듯한 시각적 효과가 특징인 트렌디한 커피', 'en-US', 'Visual-focused coffee with overflowing espresso, cream, and chocolate powder.'),
                                                                                '더티커피, dirty coffee, 인스타감성커피, 크림커피, 비주얼커피') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Aromatic & Herbal Teas)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (302, jsonb_build_object('ko-KR', '얼그레이', 'en-US', 'Earl Grey', 'ja-JP', 'アールグレイ'),
                                                                                jsonb_build_object('ko-KR', '베르가모트 향을 입힌 홍차로 우아하고 향긋한 풍미가 특징인 대표적인 가향차', 'en-US', 'Classic black tea blend flavored with oil from the rind of bergamot orange.'),
                                                                                '얼그레이, earl grey, 홍차, 베르가못, 티타임, 애프터눈티, 향긋한차'),
                                                                               (302, jsonb_build_object('ko-KR', '루이보스', 'en-US', 'Rooibos', 'ja-JP', 'ルイボス'),
                                                                                jsonb_build_object('ko-KR', '카페인이 없어 임산부나 아이들도 마시기 좋은 남아프리카산 허브차', 'en-US', 'Caffeine-free herbal tea from South Africa with a naturally sweet and earthy flavor.'),
                                                                                '루이보스, rooibos, 루이보스티, 무카페인, 허브차, 건강차, 레드티') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [306] 음료 - 스무디 (Healthy & Functional)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (306, jsonb_build_object('ko-KR', '그린 스무디', 'en-US', 'Green Smoothie', 'ja-JP', 'グリーンスムージー'),
     jsonb_build_object('ko-KR', '케일, 시금치 등 녹색 채소와 과일을 함께 갈아 만든 영양 가득한 해독 음료', 'en-US', 'Blended drink made with green leafy vegetables and fruits, packed with nutrients.'),
     '그린스무디, 해독주스, 디톡스, green smoothie, 비건음료, vegan, 다이어트주스, 클렌즈') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [401] 주류 - 맥주 (Craft Beer Varieties)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (401, jsonb_build_object('ko-KR', 'IPA', 'en-US', 'India Pale Ale', 'ja-JP', 'インディア・ペールエール'),
                                                                                jsonb_build_object('ko-KR', '홉의 향과 쓴맛이 강렬하며 과일 향과 꽃 향기가 특징인 수제 맥주의 대명사', 'en-US', 'Hoppy beer style within the broader category of pale ale, known for bitter and floral notes.'),
                                                                                'IPA, 아이피에이, 인디아페일에일, 수제맥주, 홉향, 쌉싸름한맥주, 크래프트비어'),
                                                                               (401, jsonb_build_object('ko-KR', '스타우트', 'en-US', 'Stout', 'ja-JP', 'スタウト'),
                                                                                jsonb_build_object('ko-KR', '볶은 보리를 사용하여 검은 빛깔과 커피, 초콜릿 향이 나는 진한 흑맥주', 'en-US', 'Dark, top-fermented beer with a number of variations including dry stout and oatmeal stout.'),
                                                                                '스타우트, stout, 흑맥주, 기네스, 커피향맥주, 진한맥주, 밤에마시는술') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [402] 주류 - 와인 (Trendy Wines)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (402, jsonb_build_object('ko-KR', '로제 와인', 'en-US', 'Rosé Wine', 'ja-JP', 'ロゼワイン'),
                                                                                jsonb_build_object('ko-KR', '포도 껍질을 짧게 침출시켜 매력적인 분홍빛을 띠는 상큼한 와인', 'en-US', 'Type of wine that incorporates some of the color from grape skins, but not enough to be red.'),
                                                                                '로제와인, 로제, rose wine, 핑크와인, 파티와인, 가벼운와인, 식전주'),
                                                                               (402, jsonb_build_object('ko-KR', '내추럴 와인', 'en-US', 'Natural Wine', 'ja-JP', 'ナチュラルワイン'),
                                                                                jsonb_build_object('ko-KR', '첨가물 없이 전통적인 방식으로 생산하여 개성 있는 풍미를 가진 친환경 와인', 'en-US', 'Wine made with minimal chemical and technological intervention in growing and making.'),
                                                                                '내추럴와인, 내츄럴와인, natural wine, 유기농와인, 오렌지와인, 컨벤셔널와인반대') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 칵테일 (Classic Cocktails)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (404, jsonb_build_object('ko-KR', '모히토', 'en-US', 'Mojito', 'ja-JP', 'モヒート'),
                                                                                jsonb_build_object('ko-KR', '화이트 럼에 민트, 라임, 설탕을 넣어 시원하게 즐기는 상쾌한 칵테일', 'en-US', 'Traditional Cuban highball consisting of white rum, sugar, lime juice, and mint.'),
                                                                                '모히토, 모히또, mojito, 칵테일, 상쾌한술, 민트술, 몰디브한잔'),
                                                                               (404, jsonb_build_object('ko-KR', '마가리타', 'en-US', 'Margarita', 'ja-JP', 'マルガリータ'),
                                                                                jsonb_build_object('ko-KR', '테킬라 베이스에 라임 즙과 소금을 곁들여 마시는 멕시코풍 칵테일', 'en-US', 'Cocktail consisting of tequila, orange liqueur, and lime juice often served with salt on the rim.'),
                                                                                '마가리타, 마가리따, margarita, 테킬라칵테일, 소금테두리, 혼술추천') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Gourmet Pastry)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '까눌레', 'en-US', 'Canelé', 'ja-JP', 'カヌレ'),
                                                                                jsonb_build_object('ko-KR', '겉은 검게 구워져 바삭하고 속은 촉촉한 커스터드 맛이 나는 프랑스 보르도 전통 과자', 'en-US', 'Small French pastry with a soft and tender custard center and a dark, thick caramelized crust.'),
                                                                                '까눌레, 카눌레, canele, 구움과자, 보르도디저트, 겉바속촉, 베이커리추천'),
                                                                               (201, jsonb_build_object('ko-KR', '휘낭시에', 'en-US', 'Financier', 'ja-JP', 'フィナンシェ'),
                                                                                jsonb_build_object('ko-KR', '버터를 태워 풍미를 살린 금괴 모양의 쫀득한 프랑스식 구움과자', 'en-US', 'Small French almond cake, flavored with beurre noisette, baked in a small mold.'),
                                                                                '휘낭시에, 피낭시에, financier, 금괴빵, 구움과자, 고소한디저트, 커피단짝'),
                                                                               (201, jsonb_build_object('ko-KR', '당근 케이크', 'en-US', 'Carrot Cake', 'ja-JP', 'キャロットケーキ'),
                                                                                jsonb_build_object('ko-KR', '당근과 견과류를 듬뿍 넣고 크림치즈 프로스팅을 얹은 담백하고 진한 케이크', 'en-US', 'Sweet cake with mashed carrots and often topped with cream cheese frosting.'),
                                                                                '당근케이크, 당케, carrot cake, 건강한케이크, 크림치즈케익, 홈베이킹추천') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [204] 디저트 - 전통/쌀떡 (Trendy Traditional Korean)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (204, jsonb_build_object('ko-KR', '약과', 'en-US', 'Yakgwa', 'ja-JP', '薬菓'),
                                                                                jsonb_build_object('ko-KR', '밀가루에 꿀과 참기름을 넣어 튀긴 후 조청에 집청한 한국 전통 과자', 'en-US', 'Traditional Korean deep-fried dessert made with wheat flour, honey, and ginger.'),
                                                                                '약과, 약과쿠키, yakgwa, 할매니얼, 전통디저트, 달콤한간식, 집청, k-dessert'),
                                                                               (204, jsonb_build_object('ko-KR', '인절미', 'en-US', 'Injeolmi', 'ja-JP', 'インジョルミ'),
                                                                                jsonb_build_object('ko-KR', '쫄깃한 떡에 고소한 볶은 콩가루를 듬뿍 묻힌 한국의 대표 떡', 'en-US', 'Type of Korean rice cake made by steaming and pounding glutinous rice flour, coated with bean powder.'),
                                                                                '인절미, 인절미떡, injeolmi, 콩고물떡, 고소한디저트, 쫄깃한식감') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Essential Side & Probiotics)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (105, jsonb_build_object('ko-KR', '김치', 'en-US', 'Kimchi', 'ja-JP', 'キムチ'),
     jsonb_build_object('ko-KR', '배추를 소금에 절여 고춧가루, 마늘 등으로 버무려 발효시킨 한국의 대표 반찬', 'en-US', 'Traditional Korean fermented side dish made with cabbage and various seasonings.'),
     '김치, 배추김치, kimchi, k-food, 발효음식, 유산균, 반찬, probotics, side dish, banchan') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Japanese Street Food & Global Favorite)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '타코야끼', 'en-US', 'Takoyaki', 'ja-JP', 'たこ焼き'),
                                                                                jsonb_build_object('ko-KR', '밀가루 반죽 안에 문어를 넣어 둥글게 구워낸 일본의 대표적인 길거리 음식', 'en-US', 'Ball-shaped Japanese snack made of a wheat flour-based batter and filled with minced octopus.'),
                                                                                '타코야끼, 다코야끼, takoyaki, 문어빵, 일식간식, 타코야키, street food, 겉바속촉'),
                                                                               (109, jsonb_build_object('ko-KR', '콘치즈', 'en-US', 'Korean Corn Cheese', 'ja-JP', 'コーンチーズ'),
                                                                                jsonb_build_object('ko-KR', '옥수수와 모짜렐라 치즈를 마요네즈와 함께 구워낸 한국식 퓨전 안주 요리', 'en-US', 'Creamy and cheesy Korean side dish made with sweet corn, mayonnaise, and mozzarella.'),
                                                                                '콘치즈, corn cheese, 횟집콘치즈, 안주, 마요옥수수, k-food, 단짠') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Vegan & Mediterranean Middle East)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (108, jsonb_build_object('ko-KR', '타불레', 'en-US', 'Tabbouleh', 'ja-JP', 'タブレ'),
     jsonb_build_object('ko-KR', '파슬리, 민트, 토마토, 불굴(곡물)을 잘게 썰어 레몬즙과 올리브유에 버무린 비건 샐러드', 'en-US', 'Levantine vegetarian salad made mostly of finely chopped parsley, tomatoes, and mint.'),
     '타불레, 따불레, tabbouleh, 파슬리샐러드, 비건식단, vegan, 중동요리, 건강식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기/대체 (Vegetarian Protein)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '할루미 구이', 'en-US', 'Grilled Halloumi', 'ja-JP', 'ハルーミ焼き'),
     jsonb_build_object('ko-KR', '구워도 녹지 않는 독특한 식감의 할루미 치즈를 구워 고기 대신 즐기는 요리', 'en-US', 'Slices of halloumi cheese grilled until golden, a popular vegetarian meat substitute.'),
     '할루미구이, 할루미치즈, halloumi, 구워먹는치즈, 베지테리언스테이크, 고기대체, vegetarian') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 증류주/칵테일 (High Trend in Korea)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (404, jsonb_build_object('ko-KR', '얼그레이 하이볼', 'en-US', 'Earl Grey Highball', 'ja-JP', 'アールグレイハイボール'),
     jsonb_build_object('ko-KR', '위스키와 탄산수에 달콤하고 향긋한 얼그레이 시럽을 더한 트렌디한 칵테일', 'en-US', 'Trendy highball cocktail mixed with whisky, soda water, and aromatic Earl Grey syrup.'),
     '얼그레이하이볼, 얼하이, earl grey highball, 위스키, 트렌디한술, 박나래하이볼, 술안주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Keto & GF Luxury)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '컬리플라워 뇨끼', 'en-US', 'Cauliflower Gnocchi', 'ja-JP', 'カリフラワーニョッキ'),
     jsonb_build_object('ko-KR', '밀가루 대신 컬리플라워를 주원료로 만든 저탄수화물 글루텐프리 뇨끼', 'en-US', 'Low-carb and gluten-free alternative to traditional gnocchi made primarily from cauliflower.'),
     '컬리플라워뇨끼, 컬리뇨끼, cauliflower gnocchi, keto, 키토제닉, 글루텐프리, gf, 저탄고지') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [307] 음료 - 대체유 (Rising Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (307, jsonb_build_object('ko-KR', '피스타치오 밀크', 'en-US', 'Pistachio Milk', 'ja-JP', 'ピスタチオミルク'),
     jsonb_build_object('ko-KR', '피스타치오 견과류의 풍미와 영양을 그대로 담은 고소한 식물성 대체 우유', 'en-US', 'Nutty and creamy plant-based milk made from ground pistachios, a rising dairy-free trend.'),
     '피스타치오밀크, 피스타치오우유, pistachio milk, 비건우유, vegan, 데일리프리, dairyfree, 견과류음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Global Classic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '크레이프', 'en-US', 'Crepe', 'ja-JP', 'クレープ'),
     jsonb_build_object('ko-KR', '얇게 구운 반죽에 과일이나 시럽, 생크림 등을 얹어 돌돌 말아 먹는 프랑스식 디저트', 'en-US', 'Very thin pancake, usually made from wheat flour and served with sweet or savory fillings.'),
     '크레이프, 크레페, crepe, 프랑스디저트, 길거리간식, 달콤한빵') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Korean Street/Soul Snack)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (501, jsonb_build_object('ko-KR', '김말이', 'en-US', 'Fried Seaweed Rolls', 'ja-JP', 'キムマリ'),
     jsonb_build_object('ko-KR', '당면으로 채운 김을 튀김옷을 입혀 바삭하게 튀겨낸 한국의 대표 분식', 'en-US', 'Seaweed rolls stuffed with glass noodles and deep-fried until crispy.'),
     '김말이, 김마리, fried seaweed rolls, k-snack, 분식, 떡볶이친구, 튀김') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Essential Kimchi Varieties & Vegan Side)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (105, jsonb_build_object('ko-KR', '깍두기', 'en-US', 'Kkakdugi', 'ja-JP', 'カクテキ'),
                                                                                jsonb_build_object('ko-KR', '무를 네모나게 썰어 소금에 절인 후 양념에 버무린 아삭한 식감의 김치', 'en-US', 'Diced radish kimchi seasoned with chili powder, garlic, and ginger, known for its crunchy texture.'),
                                                                                '깍두기, 무김치, kkakdugi, radish kimchi, 국밥친구, 아삭아삭, k-food, 반찬'),
                                                                               (105, jsonb_build_object('ko-KR', '파김치', 'en-US', 'Pa-kimchi', 'ja-JP', 'ネギキムチ'),
                                                                                jsonb_build_object('ko-KR', '쪽파를 멸치액젓과 고춧가루 양념으로 버무린 알싸하고 감칠맛 나는 김치', 'en-US', 'Spicy green onion kimchi seasoned with fermented fish sauce, known for its sharp flavor.'),
                                                                                '파김치, 쪽파김치, pa-kimchi, green onion kimchi, 짜파게티꿀조합, k-food, 알싸한맛, 밥도둑'),
                                                                               (105, jsonb_build_object('ko-KR', '미역줄기무침', 'en-US', 'Seaweed Salad', 'ja-JP', '茎わかめの和え物'),
                                                                                jsonb_build_object('ko-KR', '미역줄기를 소금기를 빼고 기름에 볶아 만든 오독오독한 식감의 건강 반찬', 'en-US', 'Stir-fried seaweed stems seasoned with garlic and sesame oil, a high-fiber vegan side dish.'),
                                                                                '미역줄기무침, 미역샐러드, seaweed salad, chuka wakame, 비건식단, vegan, 일식샐러드, gf, 오독오독') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Cultural & Festive Soup)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '떡국', 'en-US', 'Tteok-guk', 'ja-JP', 'トック'),
                                                                                jsonb_build_object('ko-KR', '가래떡을 얇게 썰어 사골 육수에 끓인 한국의 신년 대표 음식', 'en-US', 'Traditional Korean soup made with sliced rice cakes in a rich beef broth, eaten on New Year.'),
                                                                                '떡국, 떡국맛집, tteokguk, rice cake soup, 설날음식, 새해음식, 나이한살, k-food, 명절요리'),
                                                                               (106, jsonb_build_object('ko-KR', '계란찜', 'en-US', 'Steamed Egg', 'ja-JP', 'ケランチム'),
                                                                                jsonb_build_object('ko-KR', '달걀을 풀어 육수와 함께 뚝배기에 부드럽게 쪄낸 한국식 달걀 요리', 'en-US', 'Fluffy Korean steamed egg custard served in a hot earthenware pot.'),
                                                                                '계란찜, 달걀찜, gyeran-jjim, steamed egg, 폭탄계란찜, 매운음식짝꿍, 단백질반찬') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Festive & High-Protein)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '갈비찜', 'en-US', 'Galbi-jjim', 'ja-JP', 'カルビチム'),
     jsonb_build_object('ko-KR', '소갈비나 돼지갈비를 간장 양념에 각종 채소와 함께 달콤하게 쪄낸 명절 요리', 'en-US', 'Braised short ribs cooked with root vegetables in a sweet and savory soy-based sauce.'),
     '갈비찜, 소갈비찜, 돼지갈비찜, galbi-jjim, braised short ribs, 명절음식, 잔치음식, k-food, 단짠') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Street Food & Trendy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '순대', 'en-US', 'Sundae', 'ja-JP', 'スンデ'),
                                                                                jsonb_build_object('ko-KR', '돼지 창자에 당면과 선지, 채소를 채워 넣어 찐 한국의 대표 분식', 'en-US', 'Korean blood sausage made by steaming cow or pig''s intestines stuffed with various ingredients.'),
                                                                                '순대, 피순대, 찰순대, sundae, blood sausage, 분식, 간허파, 떡튀순, 길거리음식'),
                                                                               (109, jsonb_build_object('ko-KR', '계란말이', 'en-US', 'Gyeran-mari', 'ja-JP', '卵焼き'),
                                                                                jsonb_build_object('ko-KR', '달걀을 얇게 펴서 여러 번 말아 만든 대중적인 도시락 반찬이자 술안주', 'en-US', 'Korean-style rolled omelet often filled with finely chopped vegetables.'),
                                                                                '계란말이, 달걀말이, gyeran-mari, rolled omelet, 반찬, 도시락반찬, 술안주, 집밥') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Gourmet & Healthy Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (108, jsonb_build_object('ko-KR', '부라타 샐러드', 'en-US', 'Burrata Salad', 'ja-JP', 'ブッラータサラダ'),
                                                                                jsonb_build_object('ko-KR', '부드러운 크림이 들어있는 부라타 치즈와 신선한 채소, 과일을 곁들인 샐러드', 'en-US', 'Fresh salad featuring creamy burrata cheese, tomatoes, and balsamic glaze.'),
                                                                                '부라타샐러드, 부라타치즈, burrata salad, 치즈샐러드, 인스타감성, 브런치, 고급디저트, 와인안주'),
                                                                               (105, jsonb_build_object('ko-KR', '컬리플라워 스테이크', 'en-US', 'Cauliflower Steak', 'ja-JP', 'カリフラワーステーキ'),
                                                                                jsonb_build_object('ko-KR', '컬리플라워를 통째로 구워 고기 스테이크처럼 즐기는 저탄수화물 비건 메인 요리', 'en-US', 'Thick slices of cauliflower roasted or grilled, served as a vegan and keto main dish.'),
                                                                                '컬리플라워스테이크, cauliflower steak, 비건스테이크, vegan, keto, 저탄고지, 다이어트메인, 글루텐프리, gf') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Traditional Ritual)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '전통 말차', 'en-US', 'Matcha', 'ja-JP', '抹茶'),
     jsonb_build_object('ko-KR', '찻잎을 곱게 갈아 물에 풀어 마시는 진한 풍미의 고단백 항산화 차', 'en-US', 'Finely ground powder of specially grown and processed green tea leaves.'),
     '말차, 가루녹차, matcha, 일본차, 다도, 건강차, superfood, 항산화, 그린티') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (National Snacks & Anju)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (501, jsonb_build_object('ko-KR', '새우깡', 'en-US', 'Shrimp Crackers', 'ja-JP', 'かっぱえびせん'),
                                                                                jsonb_build_object('ko-KR', '실제 새우를 갈아 넣어 고소하고 짭짤한 맛이 특징인 한국의 국민 과자', 'en-US', 'Korea''s representative shrimp-flavored snack, loved for its savory and salty taste.'),
                                                                                '새우깡, 새우과자, shrimp crackers, 국민과자, 손이가요, 맥주안주, k-snack'),
                                                                               (501, jsonb_build_object('ko-KR', '초코파이', 'en-US', 'Choco Pie', 'ja-JP', 'チョコパイ'),
                                                                                jsonb_build_object('ko-KR', '폭신한 비스킷 사이에 마시멜로를 넣고 초콜릿을 입힌 한국의 대표 간식', 'en-US', 'Famous Korean snack consisting of two small round layers of cake with marshmallow filling and a chocolate covering.'),
                                                                                '초코파이, 초코파이정, chocopie, 국민간식, 마시멜로, k-dessert, 군대간식'),
                                                                               (501, jsonb_build_object('ko-KR', '쥐포', 'en-US', 'Dried Filefish', 'ja-JP', 'カワハギの干物'),
                                                                                jsonb_build_object('ko-KR', '쥐치 살을 말려 구워낸 짭짤하고 쫄깃한 한국의 대표적인 마른 안주', 'en-US', 'Sweet and salty dried filefish fillet, a popular chewy snack often paired with beer.'),
                                                                                '쥐포, 쥐포구이, dried filefish, 마른안주, 맥주도둑, 캠핑간식, 쫄깃한맛'),
                                                                               (501, jsonb_build_object('ko-KR', '빼빼로', 'en-US', 'Pepero', 'ja-JP', 'ペペロ'),
                                                                                jsonb_build_object('ko-KR', '가늘고 긴 과자에 초콜릿을 입힌 스틱형 과자', 'en-US', 'Thin cookie stick dipped in chocolate, famous for its celebratory day in Korea.'),
                                                                                '빼빼로, 포키, pepero, pocky, 스틱과자, 빼빼로데이, 초코스틱') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [303] 음료 - 탄산/기능성 (Trends & Energy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (303, jsonb_build_object('ko-KR', '에너지 드링크', 'en-US', 'Energy Drink', 'ja-JP', 'エナジードリンク'),
                                                                                jsonb_build_object('ko-KR', '고카페인과 타우린이 함유되어 피로 회복과 집중력 향상을 돕는 음료', 'en-US', 'High-caffeine beverage designed to provide a physical and mental boost.'),
                                                                                '에너지드링크, 레드불, 몬스터, 핫식스, energy drink, 카페인수혈, 밤샘공부, 수험생음료'),
                                                                               (303, jsonb_build_object('ko-KR', '스포츠 음료', 'en-US', 'Sports Drink', 'ja-JP', 'スポーツ飲料'),
                                                                                jsonb_build_object('ko-KR', '운동 후 체내에 수분과 전해질을 빠르게 보충해 주는 이온 음료', 'en-US', 'Beverage designed to help athletes replace water, electrolytes, and energy after training.'),
                                                                                '스포츠음료, 이온음료, 포카리스웨트, 게토레이, sports drink, 수분보충, 탈수예방, 오운완'),
                                                                               (303, jsonb_build_object('ko-KR', '제로 탄산음료', 'en-US', 'Zero Sugar Soda', 'ja-JP', 'ゼロ炭酸飲料'),
                                                                                jsonb_build_object('ko-KR', '설탕 대신 대체 감미료를 사용하여 칼로리를 낮춘 탄산음료', 'en-US', 'Carbonated soft drink that uses artificial sweeteners instead of sugar.'),
                                                                                '제로콜라, 제로사이다, zero sugar, 다이어트콜라, 펩시제로, 헬시플레저, 0칼로리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [304] 음료 - 유제품 (Iconic K-Milk)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (304, jsonb_build_object('ko-KR', '바나나맛 우유', 'en-US', 'Banana Flavored Milk', 'ja-JP', 'バナナ味牛乳'),
     jsonb_build_object('ko-KR', '단지 모양 용기로 유명한 한국의 대표적인 가공유', 'en-US', 'Iconic Korean banana-flavored milk known for its unique jar-shaped bottle.'),
     '바나나맛우유, 바나나우유, 단지우유, 뚱바, banana milk, k-drink, 목욕후필수, 편의점꿀템') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Specialty & Boba)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '버블티', 'en-US', 'Bubble Tea', 'ja-JP', 'タピオカティー'),
     jsonb_build_object('ko-KR', '밀크티에 쫄깃한 타피오카 펄을 넣어 마시는 대만식 음료', 'en-US', 'Tea-based drink from Taiwan mixed with milk and chewy tapioca pearls.'),
     '버블티, 밀크티, bubble tea, boba, 보바, 타피오카펄, 공차, 타로버블티, 쫀득쫀득') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [401] 주류 - 맥주 (Modern Trends)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (401, jsonb_build_object('ko-KR', '무알코올 맥주', 'en-US', 'Non-alcoholic Beer', 'ja-JP', 'ノンアルコールビール'),
     jsonb_build_object('ko-KR', '맥주의 맛과 향은 살리되 알코올 함량을 0%에 가깝게 낮춘 음료', 'en-US', 'Beer with little or no alcohol content, designed to taste like real beer.'),
     '무알콜맥주, 논알콜맥주, non-alcoholic beer, 임산부맥주, 술기분만, 혼술, 다이어트맥주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 아이스크림 (K-Ice Cream Icons)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (203, jsonb_build_object('ko-KR', '메로나', 'en-US', 'Melona', 'ja-JP', 'メローナ'),
                                                                                jsonb_build_object('ko-KR', '부드럽고 쫀득한 식감의 한국 대표 멜론 맛 아이스크림 바', 'en-US', 'Popular Korean melon-flavored ice pop known for its creamy and chewy texture.'),
                                                                                '메로나, 멜론아이스크림, melona, 올때메로나, k-icecream, 달콤한간식'),
                                                                               (203, jsonb_build_object('ko-KR', '소프트 서브', 'en-US', 'Soft Serve', 'ja-JP', 'ソフトクリーム'),
                                                                                jsonb_build_object('ko-KR', '공기 함량이 높아 질감이 매우 부드러운 우유 맛 아이스크림', 'en-US', 'Type of ice cream that is softer and less dense than regular ice creams.'),
                                                                                '소프트아이스크림, 소프트서브, soft serve, 우유아이스크림, 상하목장, 디저트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [403] 주류 - 전통주/소주 (Korean Soul Liquor)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (403, jsonb_build_object('ko-KR', '소주', 'en-US', 'Soju', 'ja-JP', '焼酎'),
                                                                                jsonb_build_object('ko-KR', '한국을 대표하는 증류주로 깔끔한 맛이 특징이며 다양한 음식과 잘 어울리는 술', 'en-US', 'Korea''s most popular distilled spirit, known for its clear taste and versatility with food.'),
                                                                                '소주, 참이슬, 처음처럼, 진로, soju, 초록병, 삼겹살짝꿍, 회식 필수, 소맥, 혼술'),
                                                                               (403, jsonb_build_object('ko-KR', '과일 소주', 'en-US', 'Fruit Soju', 'ja-JP', 'フルーツ焼酎'),
                                                                                jsonb_build_object('ko-KR', '소주에 과일 향과 단맛을 더해 가볍고 상큼하게 즐길 수 있는 저도수 주류', 'en-US', 'Flavored soju with fruit extracts, offering a sweet and refreshing taste with lower alcohol content.'),
                                                                                '과일소주, 자몽에이슬, 청포도에이슬, 순하리, fruit soju, 달달한술, 술찌추천, 파티주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 피자/버거 (Global Standard)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '마르게리따 피자', 'en-US', 'Margherita Pizza', 'ja-JP', 'マルゲリータ'),
                                                                                jsonb_build_object('ko-KR', '토마토, 모짜렐라 치즈, 바질만을 사용한 가장 기본적이고 담백한 이탈리아 피자', 'en-US', 'Classic Italian pizza topped with tomatoes, fresh mozzarella, and basil leaves.'),
                                                                                '마르게리따, 마르게리타, margherita, 치즈피자, 화덕피자, 나폴리피자, 담백한맛'),
                                                                               (109, jsonb_build_object('ko-KR', '페퍼로니 피자', 'en-US', 'Pepperoni Pizza', 'ja-JP', 'ペパロニピザ'),
                                                                                jsonb_build_object('ko-KR', '짭짤한 페퍼로니 햄이 가득 올라가 미국에서 가장 인기 있는 대표적인 피자', 'en-US', 'The most popular pizza in the US, topped with spicy and salty pepperoni slices.'),
                                                                                '페퍼로니피자, 페페로니피자, pepperoni, 미제피자, 짭짤한맛, 맥주안주'),
                                                                               (109, jsonb_build_object('ko-KR', '치즈버거', 'en-US', 'Cheeseburger', 'ja-JP', 'チーズバーガー'),
                                                                                jsonb_build_object('ko-KR', '육즙 가득한 패티와 녹아내린 치즈가 완벽한 조화를 이루는 클래식 버거', 'en-US', 'Classic beef burger topped with melted cheese, lettuce, tomato, and pickles.'),
                                                                                '치즈버거, 수제버거, cheeseburger, 쿼터파운더, 육즙가득, 버거맛집, 패스트푸드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Global Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '오코노미야끼', 'en-US', 'Okonomiyaki', 'ja-JP', 'お好み焼き'),
     jsonb_build_object('ko-KR', '양배추와 다양한 해산물, 고기를 반죽해 구운 뒤 소스를 얹은 일본식 부침개', 'en-US', 'Savory Japanese pancake made with shredded cabbage and various toppings.'),
     '오코노미야끼, 오코노미야키, okonomiyaki, 일식부침개, 가쓰오부시, 맥주안주, 철판요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Trendy Cafe Items)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (301, jsonb_build_object('ko-KR', '플랫 화이트', 'en-US', 'Flat White', 'ja-JP', 'フラットホワイト'),
     jsonb_build_object('ko-KR', '카페라떼보다 우유 양이 적어 에스프레소의 진한 풍미를 느낄 수 있는 부드러운 커피', 'en-US', 'Coffee drink consisting of espresso with a thin layer of microfoam, originating from Oceania.'),
     '플랫화이트, flatwhite, 진한라떼, 호주커피, 카페투어, 라떼아트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Herbal & Aesthetic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '히비스커스 차', 'en-US', 'Hibiscus Tea', 'ja-JP', 'ハイビスカスティー'),
     jsonb_build_object('ko-KR', '붉은 빛깔과 새콤한 맛이 특징이며 다이어트와 미용에 좋은 카페인 없는 차', 'en-US', 'Vibrant red herbal tea with a tart flavor, rich in vitamin C and caffeine-free.'),
     '히비스커스, 히비스커스티, hibiscus, 빨간차, 다이어트차, 무카페인, 상큼한차') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Refined Pastry)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '마들렌', 'en-US', 'Madeleine', 'ja-JP', 'マドレーヌ'),
     jsonb_build_object('ko-KR', '조개 모양의 폭신하고 고소한 프랑스식 구움과자', 'en-US', 'Small French sponge cake with a distinctive shell-like shape.'),
     '마들렌, 구움과자, madeleine, 홈베이킹, 프랑스디저트, 커피단짝, 달콤한빵') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (K-Daily Side Dish)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (105, jsonb_build_object('ko-KR', '조미김', 'en-US', 'Seasoned Seaweed', 'ja-JP', '韓国のり'),
     jsonb_build_object('ko-KR', '들기름이나 참기름을 발라 구워 짭짤하고 고소한 한국의 대표 밑반찬', 'en-US', 'Toasted seaweed seasoned with sesame oil and salt, a staple side dish in Korea.'),
     '조미김, 도시락김, gim, seasoned seaweed, 한국김, 밥도둑, 맥주안주, k-food') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Specialty Ingredients)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (105, jsonb_build_object('ko-KR', '아보카도', 'en-US', 'Avocado', 'ja-JP', 'アボカド'),
                                                                                jsonb_build_object('ko-KR', '숲의 버터라고 불리는 부드럽고 고소한 과일로 샐러드와 토스트에 필수적인 식재료', 'en-US', 'Creamy green fruit known as nature''s butter, a staple for salads and toasts.'),
                                                                                '아보카도, 아보카도슬라이스, avocado, 숲의버터, 건강식재료, 샌드위치재료'),
                                                                               (105, jsonb_build_object('ko-KR', '올리브', 'en-US', 'Olives', 'ja-JP', 'オリーブ'),
                                                                                jsonb_build_object('ko-KR', '특유의 풍미와 짭조름한 맛이 특징인 지중해 식재료로 피자나 파스타에 활용됨', 'en-US', 'Small oval fruit of the olive tree, used for oil or eaten as a savory snack/topping.'),
                                                                                '올리브, 블랙올리브, 그린올리브, olives, 지중해식단, 피자토핑, 파스타재료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Cheese Varieties)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '모짜렐라 치즈', 'en-US', 'Mozzarella', 'ja-JP', 'モッツァレラ'),
                                                                                jsonb_build_object('ko-KR', '가열하면 길게 늘어나는 특징이 있어 피자와 파스타에 가장 많이 쓰이는 치즈', 'en-US', 'Mild, white semi-soft Italian cheese, famous for its stretchiness on pizzas.'),
                                                                                '모짜렐라, 모짜렐라치즈, mozzarella, 피자치즈, 스트링치즈, 치즈추가'),
                                                                               (109, jsonb_build_object('ko-KR', '체다 치즈', 'en-US', 'Cheddar', 'ja-JP', 'チェダーチーズ'),
                                                                                jsonb_build_object('ko-KR', '진한 노란색과 고소한 풍미가 특징이며 햄버거와 샌드위치에 자주 쓰이는 치즈', 'en-US', 'Relatively hard, off-white to sharp-tasting natural cheese, popular in burgers.'),
                                                                                '체다치즈, 체다, cheddar, 노란치즈, 슬라이스치즈, 버거치즈'),
                                                                               (109, jsonb_build_object('ko-KR', '파마산 치즈', 'en-US', 'Parmesan', 'ja-JP', 'パルメザンチーズ'),
                                                                                jsonb_build_object('ko-KR', '단단한 질감의 치즈를 가루 내어 요리의 풍미를 더할 때 뿌려 먹는 치즈', 'en-US', 'Hard, granular Italian cheese often grated over pasta and salads.'),
                                                                                '파마산, 파마산가루, 파마산치즈, parmesan, 가루치즈, 풍미작렬'),
                                                                               (109, jsonb_build_object('ko-KR', '리코타 치즈', 'en-US', 'Ricotta', 'ja-JP', 'リコッタチーズ'),
                                                                                jsonb_build_object('ko-KR', '입자가 고우면서도 부드럽고 담백한 맛이 특징인 샐러드용 치즈', 'en-US', 'Italian whey cheese with a mild, slightly sweet flavor and creamy texture.'),
                                                                                '리코타치즈, 리코타, ricotta, 샐러드치즈, 부드러운치즈, 브런치재료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Detailed Delivery Chicken)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '후라이드 치킨', 'en-US', 'Fried Chicken', 'ja-JP', 'フライドチキン'),
                                                                                jsonb_build_object('ko-KR', '바삭한 튀김옷과 촉촉한 속살의 조화가 일품인 가장 기본적인 배달 치킨', 'en-US', 'Classic deep-fried chicken with a crispy outer coating and juicy meat.'),
                                                                                '후라이드, 후라이드치킨, fried chicken, 옛날통닭, 바삭바삭, 치맥, 배달인기'),
                                                                               (103, jsonb_build_object('ko-KR', '양념 치킨', 'en-US', 'Seasoned Chicken', 'ja-JP', 'ヤンニョムチキン'),
                                                                                jsonb_build_object('ko-KR', '바삭하게 튀긴 치킨을 매콤달콤한 고추장 소스에 버무린 한국의 대표 치킨', 'en-US', 'Fried chicken coated in a sweet and spicy gochujang-based glaze.'),
                                                                                '양념치킨, 양념통닭, seasoned chicken, k-chicken, 맵단, 배달음식, 반반치킨'),
                                                                               (103, jsonb_build_object('ko-KR', '간장 치킨', 'en-US', 'Soy Sauce Chicken', 'ja-JP', '醤油チキン'),
                                                                                jsonb_build_object('ko-KR', '짭조름하고 달콤한 간장 소스를 입혀 남녀노소 즐기기 좋은 치킨', 'en-US', 'Fried chicken glazed with a savory and sweet soy-based sauce.'),
                                                                                '간장치킨, 소이치킨, soy sauce chicken, 짭짤한맛, 교촌치킨스타일, 단짠치킨') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Detailed Delivery Pizza)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '하와이안 피자', 'en-US', 'Hawaiian Pizza', 'ja-JP', 'ハワイアンピザ'),
                                                                                jsonb_build_object('ko-KR', '햄과 달콤한 파인애플이 토핑되어 호불호가 갈리지만 매니아층이 두터운 피자', 'en-US', 'Pizza topped with ham and pineapple, known for its sweet and savory mix.'),
                                                                                '하와이안피자, 파인애플피자, hawaiian pizza, 호불호음식, 단짠피자, 열대과일피자'),
                                                                               (109, jsonb_build_object('ko-KR', '고구마 피자', 'en-US', 'Sweet Potato Pizza', 'ja-JP', 'サツマイモピザ'),
                                                                                jsonb_build_object('ko-KR', '달콤한 고구마 무스가 듬뿍 올라가 한국에서 특히 인기 있는 부드러운 피자', 'en-US', 'Popular Korean-style pizza topped with sweet potato mousse.'),
                                                                                '고구마피자, 고구마무스, sweet potato pizza, k-pizza, 달콤한피자, 아이들간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Delivery Chinese Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '짜장면', 'en-US', 'Jajangmyeon', 'ja-JP', 'ジャジャン麺'),
                                                                                jsonb_build_object('ko-KR', '춘장을 볶아 만든 검은 소스에 면을 비벼 먹는 한국식 중화요리의 대명사', 'en-US', 'Popular Korean-Chinese noodle dish topped with a thick black bean sauce.'),
                                                                                '짜장면, 자장면, jajangmyeon, 블랙데이, 이삿날음식, 중식배달, 짜장면맛집'),
                                                                               (102, jsonb_build_object('ko-KR', '짬뽕', 'en-US', 'Jjamppong', 'ja-JP', 'チャンポン'),
                                                                                jsonb_build_object('ko-KR', '해산물과 채소가 가득 들어간 얼큰하고 시원한 국물의 한국식 중화 면 요리', 'en-US', 'Spicy Korean-Chinese seafood noodle soup with a rich, smoky broth.'),
                                                                                '짬뽕, 짬뽕국물, jjamppong, 얼큰한음식, 해장메뉴, 불맛, 중식배달') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Convenience & Quick Meal)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '삼각김밥', 'en-US', 'Triangle Gimbap', 'ja-JP', '三角おにぎり'),
                                                                                jsonb_build_object('ko-KR', '간편하게 즐길 수 있는 삼각형 모양의 주먹밥으로 다양한 속재료가 특징', 'en-US', 'Triangle-shaped rice ball wrapped in seaweed, a popular quick snack in Korea.'),
                                                                                '삼각김밥, 삼김, triangle gimbap, 편의점음식, 참치마요, 전주비빔, 간편식'),
                                                                               (101, jsonb_build_object('ko-KR', '컵밥', 'en-US', 'Cup Rice', 'ja-JP', 'カップご飯'),
                                                                                jsonb_build_object('ko-KR', '컵 모양 용기에 밥과 토핑을 담아 간편하게 비벼 먹는 한 끼 식사', 'en-US', 'Convenient rice bowl served in a cup with various toppings and sauces.'),
                                                                                '컵밥, 노량진컵밥, cup rice, 간편도시락, 편의점꿀템, 혼밥메뉴') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (K-Street Food Sensation)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '한국식 핫도그', 'en-US', 'Korean Corn Dog', 'ja-JP', '韓国式ホットドッグ'),
                                                                                jsonb_build_object('ko-KR', '반죽을 입혀 튀긴 소시지나 치즈에 설탕과 소스를 곁들인 길거리 간식', 'en-US', 'Deep-fried sausage or cheese on a stick coated in batter and sugar.'),
                                                                                '핫도그, 감자핫도그, corn dog, k-hotdog, 명랑핫도그, 설탕뿌린핫도그, 길거리음식'),
                                                                               (109, jsonb_build_object('ko-KR', '소떡소떡', 'en-US', 'Sotteok Sotteok', 'ja-JP', 'ソトクソトク'),
                                                                                jsonb_build_object('ko-KR', '소시지와 가래떡을 번갈아 끼워 구운 뒤 매콤달콤한 소스를 바른 간식', 'en-US', 'Popular street food skewer with alternating rice cakes and sausages.'),
                                                                                '소떡소떡, 소떡, sotteok, 휴게소음식, 이영자맛집, 떡꼬치, 맵단간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Global & Traditional Condiments)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '고추장', 'en-US', 'Gochujang', 'ja-JP', 'コチュジャン'),
                                                                                jsonb_build_object('ko-KR', '고추와 찹쌀 등을 발효시켜 만든 한국 전통의 매콤달콤한 장류', 'en-US', 'Traditional Korean red chili paste made from fermented soybeans and chili.'),
                                                                                '고추장, 꼬추장, gochujang, k-sauce, 매운양념, 비빔밥소스, 발효식품'),
                                                                               (604, jsonb_build_object('ko-KR', '굴소스', 'en-US', 'Oyster Sauce', 'ja-JP', 'オイスターソース'),
                                                                                jsonb_build_object('ko-KR', '굴 추출물을 베이스로 만든 감칠맛이 뛰어난 중식 소스', 'en-US', 'Rich and savory sauce made from oyster extracts, essential for stir-fries.'),
                                                                                '굴소스, oyster sauce, 이금기, 중식양념, 볶음요리치트키, 감칠맛'),
                                                                               (604, jsonb_build_object('ko-KR', '발사믹 식초', 'en-US', 'Balsamic Vinegar', 'ja-JP', 'バルサミコ酢'),
                                                                                jsonb_build_object('ko-KR', '포도즙을 숙성시켜 만든 깊은 풍미와 산미가 특징인 이탈리아 전통 식초', 'en-US', 'Dark, concentrated, and intensely flavored vinegar made from grapes.'),
                                                                                '발사믹, 발사믹식초, balsamic, 샐러드소스, 올리브유짝꿍, 고급식재료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 칵테일 (Modern Highball Culture)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (404, jsonb_build_object('ko-KR', '하이볼', 'en-US', 'Highball', 'ja-JP', 'ハイボール'),
     jsonb_build_object('ko-KR', '위스키에 탄산수나 토닉워터를 섞어 레몬을 곁들인 청량한 칵테일', 'en-US', 'Refreshing cocktail made with whisky and carbonated water or ginger ale.'),
     '하이볼, 산토리하이볼, highball, 위스키소다, 레몬하이볼, 이자카야술, 술안주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Global Treats)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '도넛', 'en-US', 'Donuts', 'ja-JP', 'ドーナツ'),
                                                                                jsonb_build_object('ko-KR', '기름에 튀긴 링 모양의 빵에 설탕이나 다양한 필링을 채운 디저트', 'en-US', 'Sweet fried dough rings or balls with various glazes and fillings.'),
                                                                                '도넛, 도너츠, donuts, 노티드, 던킨, 달콤한디저트, 빵순이, 간식'),
                                                                               (201, jsonb_build_object('ko-KR', '바게트', 'en-US', 'Baguette', 'ja-JP', 'バゲット'),
                                                                                jsonb_build_object('ko-KR', '겉은 바삭하고 속은 쫄깃한 긴 막대 모양의 프랑스 대표 빵', 'en-US', 'Long, thin loaf of French bread known for its crisp crust and airy inside.'),
                                                                                '바게트, 프랑스빵, baguette, 마늘바게트재료, 식사빵, 겉바속촉') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Charcuterie & Wine Pairing)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (501, jsonb_build_object('ko-KR', '살라미', 'en-US', 'Salami', 'ja-JP', 'サラミ'),
     jsonb_build_object('ko-KR', '양념한 돼지고기를 건조시켜 만든 이탈리아식 소시지로 와인 안주로 인기', 'en-US', 'Cured sausage consisting of fermented and air-dried meat.'),
     '살라미, salami, 샤퀴테리, 와인안주, 짭조름한맛, 샌드위치햄') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;


-- [101] 요리 - 밥 (Korean Rice Thief & Healthy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '간장게장', 'en-US', 'Soy Marinated Crab', 'ja-JP', 'カンジャンケジャン'),
                                                                                jsonb_build_object('ko-KR', '신선한 꽃게를 한약재를 넣은 간장에 숙성시킨 한국의 대표적인 밥도둑 요리', 'en-US', 'Raw crabs marinated in a soy sauce-based brine, famous as a "rice thief" in Korea.'),
                                                                                '간장게장, 양념게장, 게장, ganjang gejang, soy marinated crab, 밥도둑, 해산물요리, 밥비빔'),
                                                                               (101, jsonb_build_object('ko-KR', '쌈밥', 'en-US', 'Ssam-bap', 'ja-JP', 'サンパプ'),
                                                                                jsonb_build_object('ko-KR', '다양한 쌈 채소에 밥과 강된장, 고기 등을 싸서 먹는 신선하고 건강한 한국식 식사', 'en-US', 'Fresh leafy vegetable wraps served with rice and savory dipping sauces.'),
                                                                                '쌈밥, 쌈밥정식, ssambap, 유기농식단, 건강식, vegan, 웰빙푸드, 쌈채소') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Stamina & Health)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '장어구이', 'en-US', 'Grilled Eel', 'ja-JP', 'うなぎの蒲焼'),
     jsonb_build_object('ko-KR', '특유의 고소한 맛과 풍부한 영양으로 기력 회복에 좋은 최고의 보양 요리', 'en-US', 'Grilled eel seasoned with savory or spicy sauce, known for its high nutritional value.'),
     '장어구이, 민물장어, 바다장어, grilled eel, unagi, jangeo, 보양식, 기력회복, 스테미너') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (K-Healthy Jelly)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (105, jsonb_build_object('ko-KR', '도토리묵', 'en-US', 'Acorn Jelly', 'ja-JP', 'どんぐりムク'),
     jsonb_build_object('ko-KR', '도토리 가루를 쑤어 만든 탱글탱글한 식감의 저칼로리 건강 채소 요리', 'en-US', 'Jelly made from acorn starch, a popular low-calorie and vegan-friendly side dish.'),
     '도토리묵, 묵무침, acorn jelly, dotorimuk, 다이어트음식, vegan, 건강반찬, 저칼로리간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [306] 음료 - 스무디/기능성 (Fitness & Protein)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (306, jsonb_build_object('ko-KR', '단백질 쉐이크', 'en-US', 'Protein Shake', 'ja-JP', 'プロテインシェイク'),
     jsonb_build_object('ko-KR', '운동 전후 근육 합성을 돕기 위해 마시는 고단백 기능성 음료', 'en-US', 'Beverage made with protein powder, milk, or water, essential for muscle recovery.'),
     '단백질쉐이크, 프로틴쉐이크, protein shake, 오운완, 헬스음료, 근성장, 식단관리, 고단백') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [601] 소스 - 오일 (Luxury Ingredients)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (601, jsonb_build_object('ko-KR', '트러플 오일', 'en-US', 'Truffle Oil', 'ja-JP', 'トリュフオイル'),
     jsonb_build_object('ko-KR', '세계 3대 진미인 송로버섯의 향을 담아 요리의 품격을 높여주는 고급 오일', 'en-US', 'High-quality oil infused with the aroma of truffles, used to enhance gourmet dishes.'),
     '트러플오일, 송로버섯, truffle oil, 풍미작렬, 고급식재료, 요리치트키, 트러플파스타') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 칵테일 (Professional Mixology)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (404, jsonb_build_object('ko-KR', '에스프레소 마티니', 'en-US', 'Espresso Martini', 'ja-JP', 'エスプレッソマティーニ'),
     jsonb_build_object('ko-KR', '에스프레소와 보드카를 섞어 만든 세련되고 각성 효과가 있는 클래식 칵테일', 'en-US', 'Cold, coffee-flavored cocktail made with vodka, espresso, and coffee liqueur.'),
     '에스프레소마티니, espressomartini, 커피술, 칵테일바, 혼술, 세련된술') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Global Trendy Sweet)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '수플레 팬케이크', 'en-US', 'Souffle Pancake', 'ja-JP', 'スフレパンケーキ'),
     jsonb_build_object('ko-KR', '머랭을 이용해 구름처럼 폭신하고 부드러운 식감이 특징인 디저트', 'en-US', 'Extra fluffy, airy, and jiggly Japanese-style pancakes made with egg whites.'),
     '수플레팬케이크, 수플레, souffle pancake, 푹신한빵, 디저트맛집, 인스타감성') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (K-Street/Pub Classic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '어묵탕', 'en-US', 'Fish Cake Soup', 'ja-JP', 'おでん'),
                                                                                jsonb_build_object('ko-KR', '다양한 모양의 어묵을 멸치 육수에 끓여낸 시원하고 담백한 국물 요리', 'en-US', 'Light and savory soup with assorted fish cakes, a classic Korean street and pub snack.'),
                                                                                '어묵탕, 오뎅탕, eomuktang, fish cake soup, 소주안주, 길거리음식, 겨울국물, 포장마차'),
                                                                               (106, jsonb_build_object('ko-KR', '마라전골', 'en-US', 'Mala Hot Pot', 'ja-JP', '麻辣火鍋'),
                                                                                jsonb_build_object('ko-KR', '화끈한 마라 육수에 고기와 채소를 듬뿍 넣어 끓여 먹는 사천식 전골 요리', 'en-US', 'Spicy Sichuan-style hot pot with various meats and vegetables in a numbing broth.'),
                                                                                '마라전골, 훠궈, hotpot, mala, 마라탕친구, 술안주, 얼큰한음식, 중식전골') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (K-Night Snack/Anju)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '닭발', 'en-US', 'Chicken Feet', 'ja-JP', '鶏足'),
     jsonb_build_object('ko-KR', '매콤한 양념에 버무려 구워낸 콜라겐 가득한 한국의 대표적인 야식 메뉴', 'en-US', 'Spicy marinated chicken feet, a popular chewy and spicy late-night snack in Korea.'),
     '닭발, 무뼈닭발, 국물닭발, dakbal, chicken feet, 매운음식, 야식, 콜라겐, 소주안주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Gourmet Brunch & Asian Roll)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '키슈', 'en-US', 'Quiche', 'ja-JP', 'キッシュ'),
                                                                                jsonb_build_object('ko-KR', '달걀, 생크림, 베이컨, 채소 등을 넣어 구운 프랑스식 식사용 타르트', 'en-US', 'Savory French tart consisting of pastry crust filled with savory custard and cheese.'),
                                                                                '키슈, 키쉬, quiche, 프랑스요리, 브런치메뉴, 달걀타르트, 고급조식'),
                                                                               (109, jsonb_build_object('ko-KR', '스프링 롤', 'en-US', 'Spring Rolls', 'ja-JP', '春巻き'),
                                                                                jsonb_build_object('ko-KR', '채소나 고기를 얇은 피에 말아 튀기거나 신선하게 먹는 아시아식 전채 요리', 'en-US', 'Variety of filled, rolled appetizers found in East Asian and Southeast Asian cuisine.'),
                                                                                '스프링롤, 짜조, 춘권, spring rolls, 베트남요리, 중식만두, 튀김간식, 에피타이저') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [403] 주류 - 전통주/사케 (Asian Spirits)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (403, jsonb_build_object('ko-KR', '사케', 'en-US', 'Sake', 'ja-JP', '日本酒'),
     jsonb_build_object('ko-KR', '쌀을 발효시켜 만든 일본의 전통 증류주로 깔끔하고 깊은 풍미가 특징', 'en-US', 'Traditional Japanese rice wine, known for its clean and complex flavor profiles.'),
     '사케, 정종, 니혼슈, sake, 일본술, 이자카야, 도쿠리, 따뜻한술, 차가운술') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차 (Japanese Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '호지차', 'en-US', 'Hojicha', 'ja-JP', 'ほうじ茶'),
     jsonb_build_object('ko-KR', '녹차 잎을 볶아서 만들어 떫은맛이 적고 구수한 풍미가 일품인 차', 'en-US', 'Japanese green tea that is roasted in a porcelain pot over charcoal, offering a nutty flavor.'),
     '호지차, 호지티, hojicha, 볶은녹차, 구수한차, 저카페인, 티타임') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 아이스크림 (Italian Premium)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (203, jsonb_build_object('ko-KR', '젤라또', 'en-US', 'Gelato', 'ja-JP', 'ジェラート'),
     jsonb_build_object('ko-KR', '일반 아이스크림보다 공기 함량이 적어 쫀득하고 진한 맛이 특징인 이탈리아식 빙과', 'en-US', 'Italian frozen dessert known for its dense texture and intense flavors.'),
     '젤라또, 젤라토, gelato, 이탈리아아이스크림, 쫀득한아이스크림, 수제디저트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Global Specialty - Thailand)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '똠양꿍', 'en-US', 'Tom Yum Goong', 'ja-JP', 'トムヤムクン'),
     jsonb_build_object('ko-KR', '새우와 향신료를 넣어 끓인 태국의 대표적인 매콤새콤한 수프', 'en-US', 'Classic Thai spicy and sour soup with shrimp, lemongrass, and galangal.'),
     '똠양꿍, 똠양궁, tomyumgoong, 태국요리, 세계3대수프, 매콤새콤, 고수요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (SE Asia & Thailand)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '나시고랭', 'en-US', 'Nasi Goreng', 'ja-JP', 'ナシゴレン'),
                                                                                jsonb_build_object('ko-KR', '달콤 짭짤한 소스에 채소와 고기를 함께 볶은 인도네시아식 볶음밥', 'en-US', 'Indonesian-style fried rice with a sweet and savory sauce, topped with an egg.'),
                                                                                '나시고랭, 나시고렝, nasigoreng, 인도네시아음식, 동남아볶음밥, 세계에서가장맛있는음식'),
                                                                               (101, jsonb_build_object('ko-KR', '가파오 라이스', 'en-US', 'Gapao Rice', 'ja-JP', 'ガパオライス'),
                                                                                jsonb_build_object('ko-KR', '다진 돼지고기와 바질을 볶아 밥 위에 얹어 먹는 태국의 인기 덮밥', 'en-US', 'Thai basil stir-fry with minced meat, served over rice with a fried egg.'),
                                                                                '가파오라이스, 카우팟가파오, gapaorice, 태국덮밥, 바질볶음밥, 태국음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Mexico, India, S.America Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '엔칠라다', 'en-US', 'Enchilada', 'ja-JP', 'エンチラーダ'),
                                                                                jsonb_build_object('ko-KR', '또띠아에 속재료를 채워 말고 소스를 뿌려 오븐에 구운 멕시코 요리', 'en-US', 'Corn tortilla rolled around a filling and covered with a savory sauce.'),
                                                                                '엔칠라다, 엔칠라따, enchilada, 멕시코요리, 멕시칸푸드, 또띠아오븐구이'),
                                                                               (109, jsonb_build_object('ko-KR', '난', 'en-US', 'Naan', 'ja-JP', 'ナン'),
                                                                                jsonb_build_object('ko-KR', '탄두르 화덕에 구워낸 인도의 전통 빵으로 커리와 함께 즐기는 음식', 'en-US', 'Leavened, oven-baked flatbread, a staple in Indian cuisine usually eaten with curry.'),
                                                                                '난, 인도난, 갈릭난, 허니난, naan, 인도음식, 커리짝꿍, 화덕빵'),
                                                                               (109, jsonb_build_object('ko-KR', '엠파나다', 'en-US', 'Empanada', 'ja-JP', 'エンパナーダ'),
                                                                                jsonb_build_object('ko-KR', '고기, 치즈, 채소 등으로 속을 채워 구운 남미의 전통 파이', 'en-US', 'Baked or fried turnover consisting of pastry and filling, common in Latin America.'),
                                                                                '엠파나다, 엠파나따, empanada, 남미간식, 스페인파이, 미트파이') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Gourmet Toppings & Cheese)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '브리 치즈', 'en-US', 'Brie Cheese', 'ja-JP', 'ブリーチーズ'),
                                                                                jsonb_build_object('ko-KR', '흰 곰팡이가 핀 껍질과 부드러운 속살이 특징인 프랑스산 연성 치즈', 'en-US', 'Soft-ripened French cheese named after Brie, the region from which it originated.'),
                                                                                '브리치즈, brie, 와인치즈, 프랑스치즈, 구운브리치즈, 치즈플래터'),
                                                                               (109, jsonb_build_object('ko-KR', '고르곤졸라 치즈', 'en-US', 'Gorgonzola', 'ja-JP', 'ゴルゴンゾーラ'),
                                                                                jsonb_build_object('ko-KR', '푸른 곰팡이가 핀 이탈리아의 대표적인 블루 치즈로 톡 쏘는 맛이 특징', 'en-US', 'Veined Italian blue cheese, made from unskimmed cow''s milk, known for its sharp flavor.'),
                                                                                '고르곤졸라, 고르곤졸라치즈, gorgonzola, 블루치즈, 꿀찍어먹는치즈, 꼬릿한치즈'),
                                                                               (103, jsonb_build_object('ko-KR', '프로슈토', 'en-US', 'Prosciutto', 'ja-JP', 'プロシュート'),
                                                                                jsonb_build_object('ko-KR', '돼지 뒷다리를 소금에 절여 건조시킨 이탈리아의 생햄', 'en-US', 'Italian dry-cured ham that is usually thinly sliced and served uncooked.'),
                                                                                '프로슈토, 프레슈토, prosciutto, 하몽친구, 생햄, 와인안주, 멜론프로슈토'),
                                                                               (109, jsonb_build_object('ko-KR', '송로버섯', 'en-US', 'Truffle', 'ja-JP', 'トリュフ'),
                                                                                jsonb_build_object('ko-KR', '세계 3대 진미 중 하나로 독특하고 깊은 풍미를 가진 값비싼 버섯', 'en-US', 'Edible fungus highly prized as a delicacy for its strong, earthy aroma.'),
                                                                                '트러플, 송로버섯, truffle, 블랙트러플, 화이트트러플, 고급식재료, 요리치트키') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (CVS New & Best Ramen)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '불닭볶음면', 'en-US', 'Buldak Ramen', 'ja-JP', 'ブルダック炒め麺'),
                                                                                jsonb_build_object('ko-KR', '강렬한 매운맛으로 전 세계적인 챌린지 열풍을 일으킨 한국의 볶음면', 'en-US', 'Globally famous spicy Korean stir-fried noodles known for their extreme heat.'),
                                                                                '불닭볶음면, 불닭, buldak, spicyramen, k-ramen, 까르보불닭, 매운라면, 편의점라면'),
                                                                               (102, jsonb_build_object('ko-KR', '신라면', 'en-US', 'Shin Ramyun', 'ja-JP', '辛ラーメン'),
                                                                                jsonb_build_object('ko-KR', '한국을 대표하는 매콤하고 얼큰한 맛의 국민 라면', 'en-US', 'Iconic Korean spicy instant noodle soup, loved for its bold and savory broth.'),
                                                                                '신라면, 신라면컵, shinramyun, 국민라면, 얼큰한라면, k-food, 편의점라면'),
                                                                               (102, jsonb_build_object('ko-KR', '육개장 사발면', 'en-US', 'Yukgaejang Cup', 'ja-JP', 'ユッケジャンサバル麺'),
                                                                                jsonb_build_object('ko-KR', '얇은 면발과 익숙한 육개장 맛으로 오랫동안 사랑받은 컵라면', 'en-US', 'Legendary Korean cup noodle featuring thin noodles and a savory beef soup base.'),
                                                                                '육개장, 육개장사발면, yukgaejang, 컵라면, 얇은면, 추억의맛, 캠핑라면') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Korean Soul Food & Global Visual)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '참치김밥', 'en-US', 'Tuna Gimbap', 'ja-JP', 'ツナキンパ'),
                                                                                jsonb_build_object('ko-KR', '고소한 마요네즈에 버무린 참치를 가득 넣은 한국의 가장 대중적인 프리미엄 김밥', 'en-US', 'Korea''s most popular premium gimbap filled with savory tuna and mayonnaise.'),
                                                                                '참치김밥, 참마김밥, tunagimbap, 소풍도시락, 분식맛집, 참치마요, k-roll'),
                                                                               (101, jsonb_build_object('ko-KR', '지라시 스시', 'en-US', 'Chirashi Sushi', 'ja-JP', 'ちらし寿司'),
                                                                                jsonb_build_object('ko-KR', '초밥용 밥 위에 신선한 생선회와 채소, 달걀지단을 흩뿌리듯 얹어낸 화려한 일본식 덮밥', 'en-US', 'Colorful Japanese bowl of sushi rice topped with scattered raw fish and garnishes.'),
                                                                                '지라시스시, 치라시스시, chirashi, 일식덮밥, 꽃초밥, 홈파티메뉴') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Global Spicy & Exotic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '락사', 'en-US', 'Laksa', 'ja-JP', 'ラクサ'),
     jsonb_build_object('ko-KR', '코코넛 밀크와 매콤한 커리 베이스의 국물에 해산물을 곁들인 동남아식 면 요리', 'en-US', 'Spicy noodle soup popular in Southeast Asia, consisting of rice noodles with chicken, prawn or fish.'),
     '락사, laksa, 싱가포르음식, 말레이시아음식, 코코넛쌀국수, 동남아요리, 이색음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소/반찬 (K-Traditional & Healthy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (105, jsonb_build_object('ko-KR', '무생채', 'en-US', 'Radish Salad', 'ja-JP', '무생채'),
     jsonb_build_object('ko-KR', '무를 채 썰어 고춧가루와 식초로 새콤달콤하게 버무린 아삭한 한국식 반찬', 'en-US', 'Crispy and tangy Korean radish salad seasoned with chili flakes and vinegar.'),
     '무생채, 무채무침, k-side dish, 비빔밥재료, 아삭한반찬, 소화잘되는음식, vegan') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Luxury Spices & Flavor Boosters)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '와사비', 'en-US', 'Wasabi', 'ja-JP', 'わさび'),
                                                                                jsonb_build_object('ko-KR', '코끝이 찡한 매운맛이 특징이며 생선회나 고기의 풍미를 살려주는 일본식 향신료', 'en-US', 'Pungent green paste made from grated wasabi root, essential for sushi and grilled meats.'),
                                                                                '와사비, 고추냉이, wasabi, 일식양념, 고기짝꿍, 알싸한맛, 생와사비'),
                                                                               (604, jsonb_build_object('ko-KR', '사프란', 'en-US', 'Saffron', 'ja-JP', 'サフラン'),
                                                                                jsonb_build_object('ko-KR', '독특한 향과 노란 빛깔을 내는 세계에서 가장 값비싼 향신료로 파에야 등에 사용됨', 'en-US', 'The world''s most expensive spice, derived from crocus flowers, used for flavor and color.'),
                                                                                '사프란, 샤프란, saffron, 고급향신료, 파에야재료, 리조또재료, 노란꽃가루'),
                                                                               (604, jsonb_build_object('ko-KR', '고춧가루', 'en-US', 'Chili Flakes', 'ja-JP', '粉唐辛子'),
                                                                                jsonb_build_object('ko-KR', '잘 말린 고추를 갈아 만든 한국 요리의 매운맛을 책임지는 필수 양념', 'en-US', 'Essential Korean seasoning made from dried red chilies, the base for kimchi and stews.'),
                                                                                '고춧가루, 고추가루, gochugaru, chili flakes, k-spice, 매운양념, 요리필수템') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Healthy Toppings)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (109, jsonb_build_object('ko-KR', '카카오 닙스', 'en-US', 'Cacao Nibs', 'ja-JP', 'カカオニブ'),
     jsonb_build_object('ko-KR', '카카오빈을 부수어 만든 쌉싸름한 맛의 수퍼푸드로 요거트나 스무디 토핑으로 인기', 'en-US', 'Crushed cacao beans with a bitter, chocolatey flavor, rich in antioxidants.'),
     '카카오닙스, cacaonibs, 다이어트토핑, 항산화푸드, 초코릿원료, 수퍼푸드, 요거트재료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Refined Pastry)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '다쿠아즈', 'en-US', 'Dacquoise', 'ja-JP', 'ダックワーズ'),
     jsonb_build_object('ko-KR', '겉은 바삭하고 속은 폭신한 머랭 반죽 사이에 크림을 채운 프랑스식 디저트', 'en-US', 'Dessert cake made with layers of almond and hazelnut meringue and whipped cream.'),
     '다쿠아즈, 다쿠아즈맛집, dacquoise, 머랭디저트, 겉바속촉, 고급구움과자, 프랑스과자') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [303] 음료 - 탄산/주류 대체 (Trendy Non-Alcoholic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (303, jsonb_build_object('ko-KR', '무알코올 하이볼', 'en-US', 'Non-alcoholic Highball', 'ja-JP', 'ノンアルハイボール'),
     jsonb_build_object('ko-KR', '위스키의 향은 살리되 알코올은 제거하여 부담 없이 분위기를 즐길 수 있는 음료', 'en-US', 'A mocktail version of the highball, offering the aroma of spirits without the alcohol.'),
     '무알콜하이볼, 논알콜하이볼, non-alcoholic, 헬시플레저, 임산부음료, 기분만내기, 제로하이볼') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Global Iconic Dishes)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '빠에야', 'en-US', 'Paella', 'ja-JP', 'パエリア'),
                                                                                jsonb_build_object('ko-KR', '해산물, 고기, 채소를 쌀과 함께 황금빛 사프란으로 익혀낸 스페인의 전통 쌀요리', 'en-US', 'Traditional Spanish rice dish flavored with saffron and cooked with seafood or meat.'),
                                                                                '빠에야, 파에야, paella, 스페인요리, 사프란밥, 해산물쌀요리, 유럽음식'),
                                                                               (109, jsonb_build_object('ko-KR', '푸틴', 'en-US', 'Poutine', 'ja-JP', 'プティン'),
                                                                                jsonb_build_object('ko-KR', '감자튀김 위에 치즈 커드와 진한 그레이비 소스를 얹은 캐나다의 대표적인 컴포트 푸드', 'en-US', 'Canadian dish consisting of french fries topped with cheese curds and brown gravy.'),
                                                                                '푸틴, poutine, 캐나다음식, 감자튀김요리, 치즈커드, 그레이비소스, 살찌는맛'),
                                                                               (109, jsonb_build_object('ko-KR', '반세오', 'en-US', 'Banh Xeo', 'ja-JP', 'バインセオ'),
                                                                                jsonb_build_object('ko-KR', '쌀가루 반죽에 해산물과 채소를 넣어 반달 모양으로 부쳐낸 베트남식 부침개', 'en-US', 'Crispy, stuffed Vietnamese rice pancake filled with shrimp, pork, and bean sprouts.'),
                                                                                '반세오, 바인세오, banhxeo, 베트남부침개, 베트남요리, 동남아음식, 겉바속촉') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Casual Japanese & Essential Fried Rice)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (101, jsonb_build_object('ko-KR', '가츠동', 'en-US', 'Katsudon', 'ja-JP', 'カツ丼'),
                                                                                jsonb_build_object('ko-KR', '갓 튀긴 돈카츠를 달콤 짭짤한 소스와 달걀로 졸여 밥 위에 얹은 일본식 덮밥', 'en-US', 'Popular Japanese bowl of rice topped with a deep-fried pork cutlet, egg, and condiments.'),
                                                                                '가츠동, 돈가스덮밥, katsudon, 일식덮밥, 한그릇요리, 돈카츠덮밥, 혼밥메뉴'),
                                                                               (101, jsonb_build_object('ko-KR', '계란 볶음밥', 'en-US', 'Egg Fried Rice', 'ja-JP', '卵炒飯'),
                                                                                jsonb_build_object('ko-KR', '달걀과 밥을 고슬고슬하게 볶아내어 담백하고 고소한 맛을 낸 가장 기본적인 볶음밥', 'en-US', 'Simple and savory stir-fried rice with scrambled eggs, a universal comfort food.'),
                                                                                '계란볶음밥, 달걀볶음밥, eggfriedrice, 간단요리, 자취요리, 아이들식단, 고슬고슬') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [601] 소스 - 오일/유제품 (Healthy Fats & Dairy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (601, jsonb_build_object('ko-KR', '기 버터', 'en-US', 'Ghee Butter', 'ja-JP', 'ギーバター'),
                                                                                jsonb_build_object('ko-KR', '무염 버터를 끓여 수분과 유당을 제거한 순수 지방으로 키토 식단과 인도 요리에 필수적임', 'en-US', 'Clarified butter originating from ancient India, high in healthy fats and keto-friendly.'),
                                                                                '기버터, ghee, 키토버터, keto, 저탄고지, 방탄커피재료, 무유당버터, 건강한지방'),
                                                                               (604, jsonb_build_object('ko-KR', '메이플 시럽', 'en-US', 'Maple Syrup', 'ja-JP', '메이플시럽'),
                                                                                jsonb_build_object('ko-KR', '단풍나무 수액을 졸여 만든 천연 감미료로 팬케이크나 요거트에 곁들여 먹는 시럽', 'en-US', 'Natural sweetener made from the sap of maple trees, a classic topping for breakfast.'),
                                                                                '메이플시럽, maplesyrup, 천연시럽, 팬케이크시럽, 캐나다특산품, 비건설탕대체, vegan') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [501] 간식 - 과자 (Delivery & Pub Side)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (501, jsonb_build_object('ko-KR', '칠리 치즈 프라이', 'en-US', 'Chili Cheese Fries', 'ja-JP', 'チリチーズフライ'),
     jsonb_build_object('ko-KR', '바삭한 감자튀김 위에 매콤한 칠리 소스와 녹은 치즈를 가득 얹은 요리', 'en-US', 'Crispy french fries topped with spicy chili con carne and melted cheese.'),
     '칠리치즈프라이, 칠리프라이, chilicheesefries, 맥주안주, 미국식간식, 칼로리폭탄, 배달사이드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Gourmet French Dessert)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '몽블랑', 'en-US', 'Mont Blanc', 'ja-JP', 'モンブラン'),
     jsonb_build_object('ko-KR', '밤 페이스트를 국수 모양으로 짜 올려 산 모양을 만든 우아하고 달콤한 디저트', 'en-US', 'Classic dessert of sweetened chestnut purée topped with whipped cream, shaped like a mountain.'),
     '몽블랑, 몽블랑케이크, montblanc, 밤디저트, 고급베이커리, 가을디저트, 프랑스케이크') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Flavor Extract)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (604, jsonb_build_object('ko-KR', '유자청', 'en-US', 'Yuzu Marmalade', 'ja-JP', '柚子茶'),
     jsonb_build_object('ko-KR', '향긋한 유자를 설탕에 재워 만든 청으로 차나 드레싱, 요리 소스로 다양하게 활용됨', 'en-US', 'Fragrant citron preserve used for tea, dressings, and various gourmet sauces.'),
     '유자청, 유자차, yuzu, 유자드레싱, 상큼한소스, 비타민보충, k-tea') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Winter & Global Classic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '프렌치 어니언 수프', 'en-US', 'French Onion Soup', 'ja-JP', 'オニオングラタンスープ'),
                                                                                jsonb_build_object('ko-KR', '볶은 양파의 단맛과 진한 육수, 녹은 치즈가 어우러진 프랑스식 해장 수프', 'en-US', 'Classic French soup made of caramelized onions and beef stock, topped with melted cheese.'),
                                                                                '어니언수프, 양파스프, frenchonionsoup, 프랑스요리, 겨울음식, 해장수프, 치즈듬뿍'),
                                                                               (106, jsonb_build_object('ko-KR', '굴국밥', 'en-US', 'Oyster Rice Soup', 'ja-JP', 'カキ雑炊'),
                                                                                jsonb_build_object('ko-KR', '바다의 우유라 불리는 신선한 굴을 넣어 끓인 시원하고 영양 가득한 겨울 보양 국밥', 'en-US', 'Korean rice soup made with fresh oysters and vegetables, a seasonal winter specialty.'),
                                                                                '굴국밥, 굴요리, oystersoup, 제철음식, 겨울보양식, 시원한국물, 바다의우유') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Festive & Brunch)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '모둠전', 'en-US', 'Assorted Jeon', 'ja-JP', 'チヂミ盛り合わせ'),
                                                                                jsonb_build_object('ko-KR', '고기, 채소, 생선 등 다양한 재료에 밀가루와 달걀물을 입혀 부쳐낸 한국의 명절 요리', 'en-US', 'Variety of Korean pan-fried delicacies made with meat, seafood, and vegetables.'),
                                                                                '모둠전, 모듬전, jeon, 명절음식, 추석음식, 설날음식, 막걸리안주, 비오는날음식'),
                                                                               (109, jsonb_build_object('ko-KR', '크로크무슈', 'en-US', 'Croque Monsieur', 'ja-JP', 'クロックムッシュ'),
                                                                                jsonb_build_object('ko-KR', '빵 사이에 햄과 치즈를 넣고 베샤멜 소스를 얹어 구워낸 프랑스식 샌드위치', 'en-US', 'Hot sandwich made with ham and cheese, topped with creamy béchamel sauce.'),
                                                                                '크로크무슈, 크로크마담, croquemonsieur, 프랑스샌드위치, 브런치메뉴, 치즈토스트') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [101] 요리 - 밥 (Italian Gourmet)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (101, jsonb_build_object('ko-KR', '버섯 리조또', 'en-US', 'Mushroom Risotto', 'ja-JP', 'きのこリゾット'),
     jsonb_build_object('ko-KR', '다양한 버섯의 풍미와 크림의 고소함이 쌀알에 녹아든 이탈리아식 쌀 요리', 'en-US', 'Creamy Italian rice dish cooked with broth and a variety of sautéed mushrooms.'),
     '버섯리조또, 크림리조또, risotto, 이탈리아음식, 풍미작렬, 트러플리조또, 고급식사') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Artisan & Holiday)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '사워도우', 'en-US', 'Sourdough', 'ja-JP', 'サワードウ'),
                                                                                jsonb_build_object('ko-KR', '천연 발효종을 사용해 특유의 산미와 쫄깃한 식감을 가진 건강한 식사 빵', 'en-US', 'Naturally leavened bread made with fermented flour and water, known for its tangy flavor.'),
                                                                                '사워도우, 천연발효빵, sourdough, 건강빵, 비건빵, vegan, 담백한빵, 식사빵'),
                                                                               (201, jsonb_build_object('ko-KR', '슈톨렌', 'en-US', 'Stollen', 'ja-JP', 'シュトーレン'),
                                                                                jsonb_build_object('ko-KR', '말린 과일과 견과류를 넣고 설탕 가루를 입힌 독일의 전통 크리스마스 케이크', 'en-US', 'Traditional German fruit bread eaten during the Christmas season.'),
                                                                                '슈톨렌, stollen, 크리스마스케이크, 독일디저트, 연말파티, 겨울간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [402] 주류 - 와인 (Seasonal Warmth)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (402, jsonb_build_object('ko-KR', '뱅쇼', 'en-US', 'Vin Chaud', 'ja-JP', 'ヴァン・ショー'),
     jsonb_build_object('ko-KR', '와인에 과일과 시나몬을 넣어 따뜻하게 끓여낸 겨울철 대표 음료', 'en-US', 'Warm mulled wine flavored with spices and fruit, popular during winter.'),
     '뱅쇼, 뱅쇼만들기, vinchaud, mulledwine, 글뤼바인, 겨울와인, 감기예방, 파티음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Global Roast)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '베이징 덕', 'en-US', 'Peking Duck', 'ja-JP', '北京ダック'),
     jsonb_build_object('ko-KR', '바삭하게 구운 오리 껍질의 식감이 일품인 중국 북경의 대표 요리', 'en-US', 'Famous Chinese dish featuring crispy roasted duck skin and tender meat.'),
     '베이징덕, 북경오리, pekingduck, 중식요리, 고급요리, 가족외식, 오리구이') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Global Comfort Soup)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (106, jsonb_build_object('ko-KR', '베트남 쌀국수', 'en-US', 'Pho', 'ja-JP', 'フォー'),
                                                                                jsonb_build_object('ko-KR', '진한 소고기 육수에 쌀면과 신선한 허브를 곁들여 먹는 베트남의 국민 요리', 'en-US', 'Vietnamese noodle soup consisting of broth, rice noodles, herbs, and meat.'),
                                                                                '쌀국수, 포, pho, 베트남요리, 해장음식, 고수요리, 담백한국물, 동남아음식'),
                                                                               (106, jsonb_build_object('ko-KR', '육개장', 'en-US', 'Yukgaejang', 'ja-JP', 'ユッケジャン'),
                                                                                jsonb_build_object('ko-KR', '소고기와 고사리, 숙주 등을 넣고 얼큰하게 끓여낸 한국의 대표적인 매운 국물 요리', 'en-US', 'Spicy Korean beef soup with scallions, bean sprouts, and gosari.'),
                                                                                '육개장, 육계장, yukgaejang, 얼큰한맛, 이열치열, 보양식, k-food, 해장국') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소 (Vegan Essentials & Seasonal Street Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (105, jsonb_build_object('ko-KR', '후무스', 'en-US', 'Hummus', 'ja-JP', 'フムス'),
                                                                                jsonb_build_object('ko-KR', '삶은 병아리콩을 으깨어 타히니, 올리브유와 섞어 만든 중동의 건강한 비건 딥 소스', 'en-US', 'Middle Eastern dip made from cooked, mashed chickpeas blended with tahini and lemon juice.'),
                                                                                '후무스, 허머스, hummus, 병아리콩, 비건식단, vegan, 중동요리, 건강식재료, 다이어트딥'),
                                                                               (105, jsonb_build_object('ko-KR', '붕어빵', 'en-US', 'Bungeoppang', 'ja-JP', 'たい焼き'),
                                                                                jsonb_build_object('ko-KR', '붕어 모양 틀에 반죽과 팥소를 넣어 구운 한국의 대표적인 겨울철 길거리 간식', 'en-US', 'Fish-shaped pastry stuffed with sweetened red bean paste, a beloved winter snack in Korea.'),
                                                                                '붕어빵, 잉어빵, 팥붕, 슈붕, bungeoppang, 가슴속3천원, 겨울간식, k-snack, 길거리음식'),
                                                                               (105, jsonb_build_object('ko-KR', '라따뚜이', 'en-US', 'Ratatouille', 'ja-JP', 'ラタトゥイユ'),
                                                                                jsonb_build_object('ko-KR', '가지, 호박, 토마토 등 각종 채소를 허브와 함께 뭉근하게 익힌 프랑스 프로방스풍 요리', 'en-US', 'Traditional French Provençal stewed vegetable dish, originating in Nice.'),
                                                                                '라따뚜이, 라따뚜이요리, ratatouille, 프랑스요리, 비건요리, vegan, 채소찜, 건강식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Latin & Professional Toppings)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '세비체', 'en-US', 'Ceviche', 'ja-JP', 'セビーチェ'),
                                                                                jsonb_build_object('ko-KR', '신선한 해산물을 레몬이나 라임 즙에 재워 차갑게 먹는 남미의 대표적인 에피타이저', 'en-US', 'South American seafood dish made from fresh raw fish cured in fresh citrus juices.'),
                                                                                '세비체, 세비체샐러드, ceviche, 남미요리, 페루음식, 해산물샐러드, 상큼한맛'),
                                                                               (103, jsonb_build_object('ko-KR', '초리조', 'en-US', 'Chorizo', 'ja-JP', 'チョリソー'),
                                                                                jsonb_build_object('ko-KR', '피멘톤 향신료를 넣어 매콤하고 붉은 빛깔이 특징인 스페인식 건조 소시지', 'en-US', 'Spicy Spanish pork sausage seasoned with smoked paprika.'),
                                                                                '초리조, 초리소, chorizo, 스페인소시지, 매콤한햄, 타파스재료, 와인안주'),
                                                                               (105, jsonb_build_object('ko-KR', '고수', 'en-US', 'Cilantro', 'ja-JP', 'パクチー'),
                                                                                jsonb_build_object('ko-KR', '특유의 강한 향으로 호불호가 갈리지만 전 세계 요리에서 널리 쓰이는 향신 채소', 'en-US', 'Also known as coriander, an essential herb for Mexican, Asian, and Middle Eastern cuisines.'),
                                                                                '고수, 고수추가, cilantro, coriander, 샹차이, 팍치, 향신료, 동남아요리필수') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리/간식 (Global Sweet & Crunchy)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '츄러스', 'en-US', 'Churros', 'ja-JP', 'チュロス'),
     jsonb_build_object('ko-KR', '반죽을 별 모양으로 짜내어 튀긴 후 시나몬 설탕을 뿌려 먹는 스페인 전통 간식', 'en-US', 'Fried-dough pastry, predominantly Spanish and Portuguese, often coated in cinnamon sugar.'),
     '츄러스, 추로스, churros, 스페인간식, 시나몬설탕, 놀이공원간식, 디저트맛집, 달콤한맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [303] 음료 - 에이드/탄산 (CVS & Cafe Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (303, jsonb_build_object('ko-KR', '청포도 에이드', 'en-US', 'Green Grape Ade', 'ja-JP', 'マスカットエ이드'),
     jsonb_build_object('ko-KR', '상큼한 청포도 베이스에 탄산수를 섞어 청량감을 극대화한 시원한 음료', 'en-US', 'Refreshing carbonated drink made with green grape base and sparkling water.'),
     '청포도에이드, 머스캣에이드, greengrapeade, 시원한음료, 카페음료, 상큼한맛, 청량감') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (High-end Seafood & Flex)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '우니', 'en-US', 'Sea Urchin', 'ja-JP', 'ウニ'),
                                                                                jsonb_build_object('ko-KR', '바다의 풍미가 응축된 크리미하고 고소한 맛의 고급 식재료로 초밥이나 파스타에 활용됨', 'en-US', 'Creamy and briny sea urchin gonads, a highly prized gourmet delicacy.'),
                                                                                '우니, 성게알, seaurchin, 오마카세, 고급식재료, 감태싸먹는우유, 바다의맛, flex'),
                                                                               (109, jsonb_build_object('ko-KR', '캐비아', 'en-US', 'Caviar', 'ja-JP', 'キャビア'),
                                                                                jsonb_build_object('ko-KR', '철갑상어의 알을 소금에 절인 것으로 세계 3대 진미 중 하나인 최고급 식재료', 'en-US', 'Salt-cured roe of sturgeon, one of the world''s most expensive and prestigious delicacies.'),
                                                                                '캐비아, 캐비어, caviar, 세계3대진미, 파인다이닝, 플렉스, 고품격식사') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Trendy K-Delivery)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '로제 떡볶이', 'en-US', 'Rose Tteokbokki', 'ja-JP', 'ロゼトッポギ'),
                                                                                jsonb_build_object('ko-KR', '고추장 소스에 크림을 섞어 부드럽고 매콤한 맛을 낸 MZ세대 인기 배달 음식', 'en-US', 'Trendy Korean rice cakes in a creamy and spicy gochujang-based rose sauce.'),
                                                                                '로제떡볶이, 로제떡볶이추천, rosetteokbokki, 맵단부드러움, 배달음식, 배떡, 신전로제, k-food'),
                                                                               (109, jsonb_build_object('ko-KR', '감바스 알 아히요', 'en-US', 'Gambas al Ajillo', 'ja-JP', 'ガンバス・アル・アヒージョ'),
                                                                                jsonb_build_object('ko-KR', '올리브유에 마늘과 새우를 넣어 익힌 스페인식 안주로 빵과 함께 먹는 요리', 'en-US', 'Spanish dish of shrimp sautéed in olive oil with garlic and chili peppers.'),
                                                                                '감바스, 감바스알아히요, gambasalajillo, 새우요리, 와인안주, 맥주안주, 홈파티요리, 스페인요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Global Popular Noodles)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '돈코츠 라멘', 'en-US', 'Tonkotsu Ramen', 'ja-JP', '豚骨ラーメン'),
                                                                                jsonb_build_object('ko-KR', '돼지 뼈를 장시간 우려내어 국물이 진하고 구수한 일본의 대표적인 라멘', 'en-US', 'Japanese noodle soup with a rich, creamy broth made from boiled pork bones.'),
                                                                                '돈코츠라멘, 돈코츠, tonkotsuramen, 일본라멘, 진한국물, 일식맛집, 해장라면'),
                                                                               (102, jsonb_build_object('ko-KR', '팟타이', 'en-US', 'Pad Thai', 'ja-JP', 'パッタイ'),
                                                                                jsonb_build_object('ko-KR', '새우, 두부, 숙주 등을 넣고 새콤달콤한 소스에 볶아낸 태국의 대표 쌀국수 요리', 'en-US', 'Stir-fried rice noodle dish commonly served as street food in Thailand.'),
                                                                                '팟타이, 팟타이맛집, padthai, 태국볶음면, 동남아요리, 새콤달콤면, 세계의맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [303] 음료 - 기능성/탄산 (Healthy Fermented & Soda)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (303, jsonb_build_object('ko-KR', '콤부차', 'en-US', 'Kombucha', 'ja-JP', 'コンブチャ'),
                                                                                jsonb_build_object('ko-KR', '홍차나 녹차를 우린 물에 유익균을 넣어 발효시킨 새콤달콤한 탄산 건강 음료', 'en-US', 'Fermented, lightly effervescent sweetened black or green tea drink.'),
                                                                                '콤부차, kombucha, 발효음료, 디톡스음료, 유산균음료, 헬시플레저, 다이어트음료, 탄산대체'),
                                                                               (303, jsonb_build_object('ko-KR', '밀키스', 'en-US', 'Milkis', 'ja-JP', 'ミルキス'),
                                                                                jsonb_build_object('ko-KR', '우유의 부드러움과 탄산의 청량감이 어우러진 한국의 대표적인 유성 탄산음료', 'en-US', 'Popular Korean soft drink that combines carbonation with a milky flavor.'),
                                                                                '밀키스, milkis, 우유탄산, 부드러운탄산, k-drink, 추억의음료, 외국인인기음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [203] 디저트 - 빙과 (Summer Premium)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (203, jsonb_build_object('ko-KR', '망고 빙수', 'en-US', 'Mango Bingsu', 'ja-JP', 'マンゴーかき氷'),
     jsonb_build_object('ko-KR', '부드러운 눈꽃 우유 얼음 위에 신선한 망고를 듬뿍 올린 여름철 프리미엄 디저트', 'en-US', 'Premium Korean shaved ice dessert topped with fresh ripe mango slices.'),
     '망고빙수, 망빙, mangobingsu, 호텔빙수, 여름디저트, 눈꽃빙수, 달콤한간식, flex') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Essential Condiments)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (604, jsonb_build_object('ko-KR', '스리라차 소스', 'en-US', 'Sriracha', 'ja-JP', 'シラチャー・ソース'),
     jsonb_build_object('ko-KR', '태국식 매운 소스로 칼로리가 낮아 다이어트 식단에 자주 활용되는 만능 소스', 'en-US', 'Type of chili sauce or hot sauce made from a paste of chili peppers and vinegar.'),
     '스리라차, 스리라차소스, sriracha, 다이어트소스, 0칼로리소스, 매운소스, 닭표소스') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Healthy & Diet Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (108, jsonb_build_object('ko-KR', '포케', 'en-US', 'Poke Bowl', 'ja-JP', 'ポケボウル'),
                                                                                jsonb_build_object('ko-KR', '신선한 날생선과 채소, 곡물을 한 그릇에 담아 소스에 비벼 먹는 하와이식 건강식', 'en-US', 'Hawaiian dish of diced raw fish served over rice or greens with toppings.'),
                                                                                '포케, poke, 연어포케, 참치포케, 하와이안샐러드, 다이어트식단, 건강식, 오운완'),
                                                                               (108, jsonb_build_object('ko-KR', '코울슬로', 'en-US', 'Coleslaw', 'ja-JP', 'コールスロー'),
                                                                                jsonb_build_object('ko-KR', '잘게 썬 양배추에 마요네즈 드레싱을 버무린 상큼하고 아삭한 샐러드', 'en-US', 'Finely shredded raw cabbage with a salad dressing, commonly mayonnaise.'),
                                                                                '코울슬로, 양배추샐러드, coleslaw, 치킨친구, 버거사이드, 아삭한맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [107] 요리 - 샌드위치 (Global Street Sandwich)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (107, jsonb_build_object('ko-KR', '반미', 'en-US', 'Banh Mi', 'ja-JP', 'バインミー'),
                                                                                jsonb_build_object('ko-KR', '쌀 바게트 안에 고기, 절임 채소, 고수 등을 넣어 만든 베트남식 샌드위치', 'en-US', 'Vietnamese sandwich made with a baguette, savory fillings, and pickled vegetables.'),
                                                                                '반미, banhmi, 베트남샌드위치, 고수샌드위치, 쌀바게트, 동남아음식, 길거리음식'),
                                                                               (107, jsonb_build_object('ko-KR', '타코', 'en-US', 'Tacos', 'ja-JP', 'タコス'),
                                                                                jsonb_build_object('ko-KR', '또띠아에 고기, 채소, 살사 소스를 얹어 먹는 멕시코의 대표적인 국민 요리', 'en-US', 'Traditional Mexican dish consisting of a small hand-sized corn or wheat tortilla topped with a filling.'),
                                                                                '타코, taco, 멕시칸푸드, 혼술안주, 간단한식사, 비프타코, 치킨타코') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (2024-2025 Mega Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '두바이 초콜릿', 'en-US', 'Dubai Chocolate', 'ja-JP', 'ドバイチョコレート'),
                                                                                jsonb_build_object('ko-KR', '피스타치오 스프레드와 볶은 카다이프 면을 넣어 바삭한 식감을 극대화한 트렌디 초콜릿', 'en-US', 'Viral chocolate bar filled with pistachio cream and crunchy kunafa/kadayif strands.'),
                                                                                '두바이초콜릿, dubaichocolate, 피스타치오초콜릿, 카다이프, SNS화제, 디저트오픈런, 편의점두바이'),
                                                                               (201, jsonb_build_object('ko-KR', '베이글', 'en-US', 'Bagel', 'ja-JP', 'ベーグル'),
                                                                                jsonb_build_object('ko-KR', '달걀, 우유, 버터 없이 구워 쫄깃하고 담백한 도넛 모양의 빵', 'en-US', 'Ring-shaped bread roll, boiled before baking, resulting in a dense, chewy interior.'),
                                                                                '베이글, 런던베이글, bagel, 크림치즈베이글, 식사빵, 빵지순례, 쫄깃한빵') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [301] 음료 - 커피 (Cafe Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (301, jsonb_build_object('ko-KR', '아인슈페너', 'en-US', 'Einspänner', 'ja-JP', 'アインシュペナー'),
     jsonb_build_object('ko-KR', '진한 아메리카노 위에 차갑고 부드러운 휘핑크림을 듬뿍 얹은 오스트리아식 커피', 'en-US', 'Classic Viennese coffee drink made by topping a double shot of espresso with whipped cream.'),
     '아인슈페너, 비엔나커피, einspanner, 크림커피, 인생커피, 단쓴단쓴, 카페투어') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기/대체 (Vegan Protein Deep Cuts)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '템페', 'en-US', 'Tempeh', 'ja-JP', 'テンペ'),
                                                                                jsonb_build_object('ko-KR', '콩을 발효시켜 만든 인도네시아의 고단백 식재료로 쫀득한 식감이 특징인 비건 고기', 'en-US', 'Traditional Indonesian soy product made from fermented soybeans, a popular vegan protein.'),
                                                                                '템페, tempeh, 비건단백질, vegan, 발효콩, 다이어트식단, 고기대체, 인도네시아음식'),
                                                                               (103, jsonb_build_object('ko-KR', '세이탄', 'en-US', 'Seitan', 'ja-JP', 'セイタン'),
                                                                                jsonb_build_object('ko-KR', '밀가루의 글루텐 성분을 추출해 만든 고기 대용식으로 육질과 유사한 식감을 가짐', 'en-US', 'Wheat gluten used as a meat substitute, known for its remarkably meat-like texture.'),
                                                                                '세이탄, seitan, 밀고기, 비건고기, vegan, 고단백비건, 고기대체제') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [606] 소스 - 스프레드/양념 (Korean Essential Condiment)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (606, jsonb_build_object('ko-KR', '쌈장', 'en-US', 'Ssamjang', 'ja-JP', 'サムジャン'),
                                                                                jsonb_build_object('ko-KR', '된장과 고추장을 베이스로 각종 양념을 섞어 만든 한국 고기 요리의 필수 소스', 'en-US', 'Thick, spicy paste used with food wrapped in a leaf in Korean cuisine.'),
                                                                                '쌈장, ssamjang, 고기소스, 찍어먹는장, k-sauce, 고기친구, 삼겹살양념'),
                                                                               (604, jsonb_build_object('ko-KR', '멸치액젓', 'en-US', 'Fish Sauce', 'ja-JP', '魚醤'),
                                                                                jsonb_build_object('ko-KR', '멸치를 소금에 절여 발효시킨 한국의 전통 조미료로 깊은 감칠맛을 냄', 'en-US', 'Amber-colored liquid condiment made from fermented anchovies and salt.'),
                                                                                '멸치액젓, 피쉬소스, fishsauce, 김치양념, 요리감칠맛, 국물비법, k-flavor') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (K-Regional Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '돼지국밥', 'en-US', 'Pork Rice Soup', 'ja-JP', 'テジクッパ'),
     jsonb_build_object('ko-KR', '돼지 뼈를 진하게 우린 육수에 수육과 밥을 말아 먹는 부산의 대표 향토 음식', 'en-US', 'Busan''s iconic pork soup served with sliced pork and rice in a rich, milky broth.'),
     '돼지국밥, 정각국밥, pork ricesoup, 부산맛집, 부산음식, 해장국, 든든한한끼, 소울푸드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Global Specialty - Dim Sum & Mexican)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '소롱포', 'en-US', 'Xiaolongbao', 'ja-JP', '小籠包'),
                                                                                jsonb_build_object('ko-KR', '얇은 만두피 속에 진한 육즙이 가득 차 있는 상하이식 딤섬 요리', 'en-US', 'Chinese soup dumplings from Shanghai, filled with savory broth and meat.'),
                                                                                '소롱포, 샤오롱바오, xiaolongbao, 딤섬, 육즙만두, 중식요리, 홍콩딤섬'),
                                                                               (109, jsonb_build_object('ko-KR', '브리또', 'en-US', 'Burrito', 'ja-JP', 'ブリトー'),
                                                                                jsonb_build_object('ko-KR', '또띠아에 고기, 콩, 밥, 치즈 등을 넣어 큼직하게 말아낸 멕시코식 식사 요리', 'en-US', 'Large flour tortilla rolled around a filling of meat, beans, rice, and cheese.'),
                                                                                '브리또, 부리또, burrito, 멕시코요리, 든든한간식, 멕시칸푸드, 한끼식사') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Mediterranean & Gourmet Cheese)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '페타 치즈', 'en-US', 'Feta Cheese', 'ja-JP', 'フェタチーズ'),
                                                                                jsonb_build_object('ko-KR', '양이나 염소의 젖으로 만든 그리스의 대표적인 치즈로 짭조름하고 부서지는 질감이 특징', 'en-US', 'Crumbly Greek cheese made from sheep''s or goat''s milk, a staple of Mediterranean diets.'),
                                                                                '페타치즈, feta, 그리스치즈, 샐러드치즈, 지중해식단, 짭조름한치즈, keto'),
                                                                               (109, jsonb_build_object('ko-KR', '마스카포네', 'en-US', 'Mascarpone', 'ja-JP', 'マスカルポーネ'),
                                                                                jsonb_build_object('ko-KR', '입자가 매우 고우며 크림처럼 부드럽고 달콤한 풍미를 가진 이탈리아산 크림치즈', 'en-US', 'Italian cream cheese known for its exceptionally smooth texture and sweet, milky flavor.'),
                                                                                '마스카포네, 마스카포네치즈, mascarpone, 티라미수재료, 디저트치즈, 크림치즈, 고급식재료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [403] 주류 - 전통주 (K-Traditional Rice Wine)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (403, jsonb_build_object('ko-KR', '막걸리', 'en-US', 'Makgeolli', 'ja-JP', 'マッコリ'),
     jsonb_build_object('ko-KR', '쌀을 발효시켜 만든 한국의 전통 탁주로 부드럽고 톡 쏘는 탄산감이 특징인 술', 'en-US', 'Traditional Korean rice wine with a milky appearance and a sweet, tangy flavor.'),
     '막걸리, 탁주, makgeolli, 전통주, 파전친구, 비오는날주인공, k-alcohol, 혼술') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [307] 음료 - 대체유 (Trendy Plant-based Milk)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (307, jsonb_build_object('ko-KR', '오트 밀크', 'en-US', 'Oat Milk', 'ja-JP', 'オーツミルク'),
     jsonb_build_object('ko-KR', '귀리를 갈아 만든 식물성 우유로 고소한 맛이 특징이며 라떼와 잘 어울리는 대체유', 'en-US', 'Creamy plant-based milk made from oats, a popular dairy-free choice for coffee.'),
     '오트밀크, 귀리우유, oatmilk, 비건라떼, vegan, 데일리프리, dairyfree, 오트사이드') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Modern Bakery Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '프레첼', 'en-US', 'Pretzel', 'ja-JP', 'プレッツェル'),
     jsonb_build_object('ko-KR', '매듭 모양으로 구워낸 쫄깃하고 짭짤한 빵으로 최근 카페에서 매우 인기 있는 메뉴', 'en-US', 'Baked pastry shaped into a knot, known for its salty crust and chewy texture.'),
     '프레첼, 프렛즐, pretzel, 빵지순례, 짭짤한빵, 간식맛집, 독일빵') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차/전통음료 (K-Traditional Dessert Drink)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '식혜', 'en-US', 'Sikhye', 'ja-JP', 'シッケ'),
     jsonb_build_object('ko-KR', '엿기름을 우린 물에 밥을 넣어 삭힌 한국의 전통 달콤한 쌀 음료', 'en-US', 'Traditional Korean sweet rice beverage, often served as a dessert.'),
     '식혜, 단술, 감주, sikhye, 전통간식, 명절음식, 찜질방필수템, k-drink') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Summer Essentials)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '물냉면', 'en-US', 'Mul-Naengmyeon', 'ja-JP', '水冷麺'),
     jsonb_build_object('ko-KR', '살얼음이 낀 시원한 육수에 메밀면을 말아 먹는 한국의 대표적인 여름 면 요리', 'en-US', 'Cold buckwheat noodles served in a chilled, refreshing broth, a summer staple.'),
     '물냉면, 냉면, naengmyeon, 시원한음식, 여름별미, 평양냉면, 함흥냉면, 고기먹고후식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (K-Gourmet Specialty)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '육회', 'en-US', 'Beef Tartare', 'ja-JP', 'ユッケ'),
     jsonb_build_object('ko-KR', '신선한 소고기를 얇게 썰어 배, 달걀노른자와 함께 고소하게 양념한 요리', 'en-US', 'Korean-style beef tartare seasoned with sesame oil and served with pear.'),
     '육회, yukhoe, 소고기요리, 고단백, 술안주, 광장시장육회, 신선한맛, flex') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Mediterranean & Middle East Favorite)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '에그인헬', 'en-US', 'Shakshuka', 'ja-JP', 'シャクシュカ'),
                                                                                jsonb_build_object('ko-KR', '매콤한 토마토 소스에 달걀을 넣어 익힌 지중해식 브런치 메뉴 (삭슈카)', 'en-US', 'Dish of eggs poached in a sauce of tomatoes, chili peppers, and onions.'),
                                                                                '에그인헬, 삭슈카, shakshuka, 브런치맛집, 홈파티요리, 토마토계란요리, 지중해식단'),
                                                                               (109, jsonb_build_object('ko-KR', '팔라펠', 'en-US', 'Falafel', 'ja-JP', 'ファラフェル'),
                                                                                jsonb_build_object('ko-KR', '병아리콩을 갈아 향신료와 함께 튀겨낸 중동의 대표적인 비건 단백질 요리', 'en-US', 'Deep-fried ball or patty made from ground chickpeas, a Middle Eastern vegan staple.'),
                                                                                '팔라펠, falafel, 비건고기, vegan, 중동음식, 건강식단, 병아리콩요리, 고단백비건'),
                                                                               (109, jsonb_build_object('ko-KR', '라자냐', 'en-US', 'Lasagna', 'ja-JP', 'ラザニア'),
                                                                                jsonb_build_object('ko-KR', '넓적한 파스타 면 사이에 라구 소스와 치즈를 겹겹이 쌓아 구워낸 이탈리아 요리', 'en-US', 'Italian dish made of stacked layers of thin flat pasta alternating with fillings.'),
                                                                                '라자냐, lasagna, 라구파스타, 치즈듬뿍, 이탈리안가정식, 오븐요리, 꾸덕한맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Tea Time Classic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '스콘', 'en-US', 'Scone', 'ja-JP', 'スコーン'),
     jsonb_build_object('ko-KR', '영국에서 유래한 구움과자로 겉은 바삭하고 속은 포슬포슬한 식감이 특징', 'en-US', 'British baked good, usually made of wheat or oatmeal with baking powder.'),
     '스콘, scone, 카페디저트, 애프터눈티, 클로티드크림, 겉바속촉, 빵지순례') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [204] 디저트 - 전통/길거리 (K-Winter Warmth)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (204, jsonb_build_object('ko-KR', '호떡', 'en-US', 'Hotteok', 'ja-JP', 'ホットク'),
     jsonb_build_object('ko-KR', '반죽 안에 꿀, 설탕, 견과류를 넣어 노릇하게 구워낸 한국의 대표 길거리 간식', 'en-US', 'Popular Korean street snack consisting of a pancake filled with brown sugar and cinnamon.'),
     '호떡, 꿀호떡, hotteok, 겨울길거리음식, 달콤한간식, 꿀맛, k-dessert') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [108] 요리 - 샐러드 (Superfood Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (108, jsonb_build_object('ko-KR', '치아씨드 푸딩', 'en-US', 'Chia Seed Pudding', 'ja-JP', 'チアシードプリン'),
     jsonb_build_object('ko-KR', '치아씨드를 우유나 요거트에 불려 만든 식이섬유가 풍부한 건강 디저트', 'en-US', 'Healthy breakfast or dessert made by soaking chia seeds in liquid until gel-like.'),
     '치아씨드푸딩, chiaseed, 수퍼푸드, 다이어트식단, vegan, 식이섬유, 아침대용') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [404] 주류 - 칵테일/파티 (Global Party Drink)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (404, jsonb_build_object('ko-KR', '상그리아', 'en-US', 'Sangria', 'ja-JP', 'サングリア'),
     jsonb_build_object('ko-KR', '와인에 신선한 과일과 탄산수를 넣어 시원하게 즐기는 스페인식 파티 음료', 'en-US', 'Spanish alcoholic beverage made of red wine and chopped fruit, often with spirits.'),
     '상그리아, 샹그리아, sangria, 파티술, 여름와인, 달콤한술, 스페인칵테일') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (The Complete Naengmyeon Lineup)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (102, jsonb_build_object('ko-KR', '비빔냉면', 'en-US', 'Bibim-Naengmyeon', 'ja-JP', 'ビビン冷麺'),
                                                                                jsonb_build_object('ko-KR', '매콤달콤한 양념장에 면을 비벼 먹는 한국의 대표적인 비빔 면 요리', 'en-US', 'Cold buckwheat noodles mixed with a spicy, sweet, and tangy red chili sauce.'),
                                                                                '비빔냉면, 비냉, bibimnaengmyeon, 매운냉면, 함흥냉면스타일, 고기싸먹는냉면, 맵단'),
                                                                               (102, jsonb_build_object('ko-KR', '평양냉면', 'en-US', 'Pyongyang-Naengmyeon', 'ja-JP', '平壌冷麺'),
                                                                                jsonb_build_object('ko-KR', '메밀 함량이 높은 면과 슴슴하고 깊은 육수 맛이 특징인 평양식 전통 냉면', 'en-US', 'North Korean-style cold noodles known for subtle, clean beef broth and high buckwheat content.'),
                                                                                '평양냉면, 평냉, pyongyangnaengmyeon, 슴슴한맛, 평냉맛집, 완냉, 메밀면, 정통냉면'),
                                                                               (102, jsonb_build_object('ko-KR', '칼국수', 'en-US', 'Kalguksu', 'ja-JP', 'カルグクス'),
                                                                                jsonb_build_object('ko-KR', '밀가루 반죽을 칼로 썰어 만든 면을 진한 육수에 끓여낸 한국식 면 요리', 'en-US', 'Traditional Korean noodle soup made with hand-cut wheat flour noodles.'),
                                                                                '칼국수, 손칼국수, kalguksu, 바지락칼국수, 닭칼국수, 비오는날음식, 뜨끈한국물'),
                                                                               (102, jsonb_build_object('ko-KR', '함흥냉면', 'en-US', 'Hamhung-Naengmyeon', 'ja-JP', '咸興冷麺'),
                                                                                jsonb_build_object('ko-KR', '고구마 전분을 사용하여 쫄깃함이 강한 면에 매운 양념이나 회무침을 곁들인 냉면', 'en-US', 'Chewy potato starch noodles served with spicy sauce or raw fish topping.'),
                                                                                '함흥냉면, 회냉면, hamhungnaengmyeon, 쫄깃한냉면, 오장동냉면, 매운냉면') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (The Lunch King & Soul Stew)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '제육볶음', 'en-US', 'Jeyuk-Bokkeum', 'ja-JP', '豚肉炒め'),
                                                                                jsonb_build_object('ko-KR', '돼지고기를 매콤한 고추장 양념에 볶아낸 한국의 가장 대중적인 점심 메뉴', 'en-US', 'Spicy stir-fried pork marinated in gochujang, the most popular lunch menu in Korea.'),
                                                                                '제육볶음, 제육, jeyukbokkeum, 돼지불고기, 밥도둑, 점심메뉴1위, 쌈밥짝꿍, 기사식당메뉴'),
                                                                               (106, jsonb_build_object('ko-KR', '부대찌개', 'en-US', 'Budae-Jjigae', 'ja-JP', '部隊チゲ'),
                                                                                jsonb_build_object('ko-KR', '햄, 소시지, 김치 등을 넣고 얼큰하게 끓여낸 한국의 퓨전 국물 요리', 'en-US', 'Spicy Korean fusion stew made with ham, sausages, kimchi, and ramyeon noodles.'),
                                                                                '부대찌개, 부대찌개맛집, budaejjigae, armystew, 햄찌개, 라면사리필수, 얼큰한음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Global Dips & Exotic Classics)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '과카몰리', 'en-US', 'Guacamole', 'ja-JP', 'ワカモレ'),
                                                                                jsonb_build_object('ko-KR', '으깬 아보카도에 양파, 토마토, 라임 즙을 섞어 만든 멕시코식 딥 소스', 'en-US', 'Mexican avocado-based dip mixed with onions, tomatoes, and lime juice.'),
                                                                                '과카몰리, 과카몰레, guacamole, 아보카도요리, 나초칩소스, 멕시칸푸드, 비건딥, vegan'),
                                                                               (109, jsonb_build_object('ko-KR', '굴라쉬', 'en-US', 'Goulash', 'ja-JP', 'グヤーシュ'),
                                                                                jsonb_build_object('ko-KR', '소고기와 채소에 파프리카 가루를 넣어 매콤하게 끓인 헝가리식 전통 스튜', 'en-US', 'Hungarian stew of meat and vegetables, seasoned with paprika and other spices.'),
                                                                                '굴라쉬, 굴라시, goulash, 동유럽요리, 헝가리스튜, 매콤한수프, 따뜻한요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [302] 음료 - 차/전통음료 (Traditional Korean Refresher)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (302, jsonb_build_object('ko-KR', '수정과', 'en-US', 'Sujeonggwa', 'ja-JP', 'スジョングァ'),
     jsonb_build_object('ko-KR', '생강과 계피를 달인 물에 설탕이나 꿀을 넣고 차갑게 식혀 곶감을 띄워 마시는 음료', 'en-US', 'Traditional Korean cinnamon-ginger punch garnished with dried persimmons.'),
     '수정과, sujeonggwa, 계피차, 명절음식, 식후음료, 소화돕는차, k-drink, 전통음료') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (The Base of Korean Flavor)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (604, jsonb_build_object('ko-KR', '간장', 'en-US', 'Soy Sauce', 'ja-JP', '醤油'),
     jsonb_build_object('ko-KR', '콩을 발효시켜 만든 한국 요리의 가장 기본적인 조미료', 'en-US', 'Traditional liquid condiment made from fermented soybeans, salt, and water.'),
     '간장, 진간장, 국간장, soysauce, 요리필수템, 감칠맛, k-sauce') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (K-Night Delivery Kings)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '족발', 'en-US', 'Jokbal', 'ja-JP', 'チョッパル'),
                                                                                jsonb_build_object('ko-KR', '돼지 발을 향신료가 든 육수에 삶아내어 썰어낸 쫄깃하고 담백한 야식 메뉴', 'en-US', 'Pig''s trotters cooked with soy sauce and spices, loved for its chewy texture.'),
                                                                                '족발, 불족발, 냉채족발, jokbal, 야식추천, 콜라겐, 술안주, 배달맛집'),
                                                                               (103, jsonb_build_object('ko-KR', '보쌈', 'en-US', 'Bossam', 'ja-JP', 'ポッサム'),
                                                                                jsonb_build_object('ko-KR', '돼지고기를 삶아 기름기를 빼고 김치나 무속과 함께 싸 먹는 건강한 고기 요리', 'en-US', 'Boiled pork slices served with spicy radish salad and wrap vegetables.'),
                                                                                '보쌈, 수육, bossam, 쌈밥, 고기요리, 김장김치짝꿍, 야식, 배달음식'),
                                                                               (103, jsonb_build_object('ko-KR', '곱창 구이', 'en-US', 'Grilled Tripe', 'ja-JP', 'コプチャン焼き'),
                                                                                jsonb_build_object('ko-KR', '소나 돼지의 곱창을 그릴에 구워 고소한 풍미와 쫄깃한 식감을 즐기는 요리', 'en-US', 'Grilled beef or pork tripe, a popular high-protein snack often paired with alcohol.'),
                                                                                '곱창, 대창, 막창, 소곱창, 돼지곱창, gopchang, 곱창맛집, 술안주, 고소한맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Chinese-Korean Favorites)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '꿔바로우', 'en-US', 'Guobaorou', 'ja-JP', 'クバロウ'),
                                                                                jsonb_build_object('ko-KR', '돼지고기를 얇게 펴서 찹쌀 반죽으로 튀겨낸 새콤달콤한 동북아식 탕수육', 'en-US', 'Double-fried pork slices in a sweet and sour sauce, known for its extra crispy texture.'),
                                                                                '꿔바로우, 꿔바로우맛집, guobaorou, 찹쌀탕수육, 겉바속촉, 마라탕친구, 중식요리'),
                                                                               (103, jsonb_build_object('ko-KR', '마파두부', 'en-US', 'Mapo Tofu', 'ja-JP', '麻婆豆腐'),
                                                                                jsonb_build_object('ko-KR', '두부와 다진 고기를 매콤한 두반장 소스에 볶아낸 사천 지방의 대표 요리', 'en-US', 'Popular Sichuan dish consisting of tofu set in a spicy, oily, and bright red sauce.'),
                                                                                '마파두부, 마파두부덮밥, mapotofu, 사천요리, 중식밥요리, 매콤한두부, 혼밥메뉴') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Gourmet Ingredients & Global Classics)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '하몽', 'en-US', 'Jamon', 'ja-JP', 'ハモン'),
                                                                                jsonb_build_object('ko-KR', '스페인산 돼지 뒷다리를 소금에 절여 장기간 건조시킨 최고급 생햄', 'en-US', 'Traditional Spanish dry-cured ham, highly prized for its deep and complex flavor.'),
                                                                                '하몽, jamon, 이베리코, 생햄, 와인안주, 멜론하몽, 스페인식재료, 샤퀴테리'),
                                                                               (109, jsonb_build_object('ko-KR', '카망베르 치즈', 'en-US', 'Camembert', 'ja-JP', 'カマンベール'),
                                                                                jsonb_build_object('ko-KR', '흰 곰팡이가 핀 껍질 속에 부드럽고 진한 크림이 들어있는 프랑스 대표 치즈', 'en-US', 'Moist, soft, creamy, surface-ripened cow''s milk cheese from France.'),
                                                                                '카망베르, 카망베르치즈, camembert, 프랑스치즈, 구운치즈, 와인짝꿍, 부드러운치즈'),
                                                                               (103, jsonb_build_object('ko-KR', '탄두리 치킨', 'en-US', 'Tandoori Chicken', 'ja-JP', 'タンドリーチキン'),
                                                                                jsonb_build_object('ko-KR', '향신료와 요거트에 재운 닭고기를 화덕(탄두르)에서 구워낸 인도의 대표 요리', 'en-US', 'Indian dish consisting of roasted chicken prepared with yogurt and spices in a tandoor.'),
                                                                                '탄두리치킨, tandoori, 인도요리, 화덕치킨, 향신료요리, 다이어트치킨, 고단백') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [502] 간식 - 사탕/젤리 (Low-Calorie Trend)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (502, jsonb_build_object('ko-KR', '곤약 젤리', 'en-US', 'Konjac Jelly', 'ja-JP', 'こんにゃくゼリー'),
     jsonb_build_object('ko-KR', '칼로리가 매우 낮고 포만감을 주는 곤약으로 만든 다이어트용 건강 젤리', 'en-US', 'Low-calorie jelly snack made from konjac, popular for weight management.'),
     '곤약젤리, konjacjelly, 다이어트간식, 0칼로리간식, 헬시플레저, 일본간식, 곤약간식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Global Seafood Classic)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (109, jsonb_build_object('ko-KR', '피쉬 앤 칩스', 'en-US', 'Fish and Chips', 'ja-JP', 'フィッシュ・アンド・チップス'),
     jsonb_build_object('ko-KR', '흰살생선 튀김과 감자튀김을 곁들여 먹는 영국의 대표적인 컴포트 푸드', 'en-US', 'Hot dish consisting of fried fish in batter served with main-course-sized chips.'),
     '피쉬앤칩스, fishandchips, 영국요리, 생선튀김, 맥주안주, 펍안주, 바삭한요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Camping Visual Kings)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (103, jsonb_build_object('ko-KR', '토마호크 스테이크', 'en-US', 'Tomahawk Steak', 'ja-JP', 'トマホークステーキ'),
                                                                                jsonb_build_object('ko-KR', '길다란 갈비뼈를 따라 등심 부위가 붙어 있는 거대한 스테이크로 캠핑의 꽃이라 불리는 요리', 'en-US', 'Large ribeye beef steak with a long bone, a popular visual highlight for camping BBQ.'),
                                                                                '토마호크, 토마호크스테이크, tomahawk, 캠핑고기, 바베큐, BBQ, 돈마호크, 고기파티, 캠핑감성'),
                                                                               (103, jsonb_build_object('ko-KR', '양갈비 구이', 'en-US', 'Grilled Lamb Chops', 'ja-JP', 'ラムチョップ'),
                                                                                jsonb_build_object('ko-KR', '특유의 고소한 풍미와 부드러운 육질을 가진 양갈비를 그릴에 구워낸 캠핑 인기 메뉴', 'en-US', 'Tender lamb chops seasoned and grilled over an open flame, a trendy camping favorite.'),
                                                                                '양갈비, 숄더랙, 프렌치랙, lambchops, 양고기구이, 캠핑바베큐, 쯔란, 고기요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리/간식 (Camping Sweet Finish)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (201, jsonb_build_object('ko-KR', '마시멜로 구이', 'en-US', 'Grilled Marshmallows', 'ja-JP', '焼きマシュマロ'),
     jsonb_build_object('ko-KR', '불에 구워 겉은 바삭하고 속은 녹아내리는 달콤한 간식으로 스모어를 만들 때 필수적임', 'en-US', 'Sweet marshmallows roasted over a campfire until golden brown and gooey.'),
     '마시멜로구이, 마시멜로우, 스모어, smores, 캠핑간식, 불멍, 디저트, 달콤한맛') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Camping Special Side)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (109, jsonb_build_object('ko-KR', '모둠 꼬치구이', 'en-US', 'Assorted Skewers', 'ja-JP', '串焼き盛り合わせ'),
     jsonb_build_object('ko-KR', '고기, 대파, 버섯 등을 번갈아 끼워 구워 먹는 재미가 있는 캠핑 단골 메뉴', 'en-US', 'Skewers of meat and vegetables grilled over charcoal, a fun and easy camping snack.'),
     '꼬치구이, 캠핑꼬치, 야키토리, skewers, 모둠꼬치, 캠핑음식, 바베큐안주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [604] 소스 - 양념 (Global Exotic Sauces)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (604, jsonb_build_object('ko-KR', '스리라차 소스', 'en-US', 'Sriracha Sauce', 'ja-JP', 'シラチャー・ソース'),
                                                                                jsonb_build_object('ko-KR', '태국식 매운 소스로 칼로리가 낮아 다이어트 식단과 베트남 요리에 널리 쓰이는 만능 소스', 'en-US', 'Spicy Thai chili sauce, popular for low-calorie diets and Southeast Asian dishes.'),
                                                                                '스리라차, sriracha, 다이어트소스, 닭표소스, 0칼로리소스, 매운소스, 샌드위치소스'),
                                                                               (604, jsonb_build_object('ko-KR', '트러플 마요네즈', 'en-US', 'Truffle Mayo', 'ja-JP', 'トリュフマ요네즈'),
                                                                                jsonb_build_object('ko-KR', '고소한 마요네즈에 송로버섯의 깊은 풍미를 더해 튀김이나 샌드위치의 맛을 높여주는 소스', 'en-US', 'Creamy mayonnaise infused with rich truffle aroma, perfect for dipping fries or spreading.'),
                                                                                '트러플마요, 트러플마요네즈, trufflemayo, 고급소스, 풍미작렬, 디핑소스, 감자튀김소스'),
                                                                               (604, jsonb_build_object('ko-KR', '살사 소스', 'en-US', 'Salsa Sauce', 'ja-JP', 'サルサソース'),
                                                                                jsonb_build_object('ko-KR', '토마토, 양파, 할라피뇨를 다져 만든 멕시코식 매콤하고 상큼한 소스', 'en-US', 'Zesty Mexican sauce made with chopped tomatoes, onions, and chili peppers.'),
                                                                                '살사소스, 살사, salsa, 멕시칸소스, 나초소스, 타코양념, 상큼한매운맛'),
                                                                               (604, jsonb_build_object('ko-KR', '랜치 드레싱', 'en-US', 'Ranch Dressing', 'ja-JP', 'ランチドレッシング'),
                                                                                jsonb_build_object('ko-KR', '마요네즈와 버터밀크, 허브를 섞어 만든 크리미하고 고소한 미국 대표 소스', 'en-US', 'Popular American dressing made with buttermilk, herbs, and garlic, great for salads and wings.'),
                                                                                '랜치드레싱, 랜치소스, ranch, 샐러드소스, 피자디핑소스, 고소한소스, 미국맛'),
                                                                               (604, jsonb_build_object('ko-KR', '발사믹 글레이즈', 'en-US', 'Balsamic Glaze', 'ja-JP', 'バルサミコグレーズ'),
                                                                                jsonb_build_object('ko-KR', '발사믹 식초를 졸여 농축시킨 진하고 달콤한 소스로 카프레제 등에 뿌려 먹음', 'en-US', 'Reduced balsamic vinegar with a thick, syrupy consistency and sweet-tart flavor.'),
                                                                                '발사믹글레이즈, 발사믹소스, balsamicglaze, 샐러드드레싱, 스테이크소스, 데코레이션소스'),
                                                                               (604, jsonb_build_object('ko-KR', '라오간마 고추기름', 'en-US', 'Chili Oil (Lao Gan Ma)', 'ja-JP', '老干媽'),
                                                                                jsonb_build_object('ko-KR', '볶은 고추와 다양한 재료가 들어간 중국의 대표적인 감칠맛 강한 고추기름', 'en-US', 'Savory and spicy Chinese chili oil, famous for its deep umami flavor and versatility.'),
                                                                                '라오간마, 고추기름, chilioil, 중식양념, 마법의소스, 감칠맛, 볶음요리치트키') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Bar Snacks Part 2 - Soul Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '먹태', 'en-US', 'Dried Pollack', 'ja-JP', 'モクテ'),
                                                                                jsonb_build_object('ko-KR', '바삭하게 말린 명태를 살짝 구워 간장 마요네즈 소스에 찍어 먹는 가벼운 맥주 안주', 'en-US', 'Crispy dried pollack roasted and served with a savory soy-mayo dipping sauce.'),
                                                                                '먹태, 먹태구이, meoktae, 맥주안주, 노가리친구, 바삭한맛, 가벼운안주, 마요네즈간장'),
                                                                               (103, jsonb_build_object('ko-KR', '오돌뼈', 'en-US', 'Spicy Pork Cartilage', 'ja-JP', 'オドルピョ'),
                                                                                jsonb_build_object('ko-KR', '오독오독 씹히는 돼지 연골 부위를 매콤한 양념에 볶아낸 중독성 있는 야식 메뉴', 'en-US', 'Crunchy pork cartilage stir-fried in a spicy seasoning, a popular late-night drinking snack.'),
                                                                                '오돌뼈, 오독뼈, odolppyeo, 주먹밥친구, 매운안주, 포차안주, 야식, 씹는맛'),
                                                                               (109, jsonb_build_object('ko-KR', '골뱅이무침', 'en-US', 'Sea Snail Salad', 'ja-JP', 'つぶ貝の和え物'),
                                                                                jsonb_build_object('ko-KR', '쫄깃한 골뱅이와 신선한 채소를 새콤달콤한 양념에 무쳐 소면과 곁들이는 안주', 'en-US', 'Chewy sea snails and fresh vegetables mixed in a spicy and tangy sauce, served with noodles.'),
                                                                                '골뱅이무침, 골뱅이소면, golbaengimuchim, 새콤달콤안주, 맥주짝꿍, 을지로골뱅이, 소면사리'),
                                                                               (109, jsonb_build_object('ko-KR', '두부김치', 'en-US', 'Tofu with Stir-fried Kimchi', 'ja-JP', '豆腐キムチ'),
                                                                                jsonb_build_object('ko-KR', '따끈한 두부와 매콤하게 볶은 김치를 곁들여 먹는 한국의 대표적인 막걸리 안주', 'en-US', 'Warm tofu served with savory stir-fried kimchi and pork, a classic pairing for Makgeolli.'),
                                                                                '두부김치, dubukimchi, 막걸리안주, 전통안주, 건강한안주, 볶음김치, 집안주') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [201] 디저트 - 베이커리 (Regional Bakery Pilgrimage)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (201, jsonb_build_object('ko-KR', '튀김소보로', 'en-US', 'Fried Soboro', 'ja-JP', '揚げそぼろパン'),
                                                                                jsonb_build_object('ko-KR', '바삭한 소보로 빵 속에 달콤한 팥소가 들어있는 대전 성심당의 명물 빵', 'en-US', 'Famous fried streusel bread filled with sweet red bean paste from Daejeon''s Sungsimdang.'),
                                                                                '튀김소보로, 튀소, sungsimdang, 대전명물, 빵지순례, 성심당, 팥소보로, 줄서서먹는빵'),
                                                                               (201, jsonb_build_object('ko-KR', '근대골목 단팥빵', 'en-US', 'Modern Alley Red Bean Bread', 'ja-JP', '近代路地あんパン'),
                                                                                jsonb_build_object('ko-KR', '얇은 피 안에 단팥과 풍부한 크림이 가득 차 있는 대구의 대표적인 지역 빵', 'en-US', 'Famous Daegu bread filled with sweet red bean paste and rich fresh cream.'),
                                                                                '단팥빵, 크림단팥빵, daegu-bakery, 대구명물, 빵지순례, 근대골목, 추억의맛'),
                                                                               (201, jsonb_build_object('ko-KR', '통영 꿀빵', 'en-US', 'Tongyeong Honey Bread', 'ja-JP', '統営蜜パン'),
                                                                                jsonb_build_object('ko-KR', '튀긴 도넛 반죽에 달콤한 조청을 입히고 깨를 뿌린 통영의 대표 간식', 'en-US', 'Fried dough balls coated in sweet syrup and sesame seeds, a specialty of Tongyeong.'),
                                                                                '꿀빵, 통영꿀빵, k-dessert, 통영기념품, 달콤한빵, 꿀맛, 전국유명빵집') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Parent-Friendly & Baby Food)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
                                                                               (109, jsonb_build_object('ko-KR', '이유식', 'en-US', 'Baby Food', 'ja-JP', '離乳食'),
                                                                                jsonb_build_object('ko-KR', '영유아를 위해 자극적이지 않고 영양가 높게 조리한 단계별(초기/중기/후기) 식단', 'en-US', 'Nutritious, mild-flavored food prepared in stages for infants and toddlers.'),
                                                                                '이유식, 아기밥, babyfood, 육아소통, 초기이유식, 중기이유식, 후기이유식, 정성식단, 맘스타그램'),
                                                                               (105, jsonb_build_object('ko-KR', '멸치볶음', 'en-US', 'Stir-fried Anchovies', 'ja-JP', '煮干しの炒め物'),
                                                                                jsonb_build_object('ko-KR', '잔멸치를 간장이나 조청에 볶아 만든 칼슘이 풍부한 아이들 필수 밑반찬', 'en-US', 'Small anchovies stir-fried in soy sauce or syrup, a calcium-rich side dish for kids.'),
                                                                                '멸치볶음, 잔멸치볶음, myeolchibokkeum, 밑반찬, 도시락반찬, 아이들식단, 칼슘왕, 뼈건강'),
                                                                               (105, jsonb_build_object('ko-KR', '메추리알 장조림', 'en-US', 'Soy-braised Quail Eggs', 'ja-JP', ' 우ずらの卵の醤油煮'),
                                                                                jsonb_build_object('ko-KR', '메추리알을 간장에 짭조름하게 졸여 만든 아이들이 가장 좋아하는 인기 반찬', 'en-US', 'Quail eggs braised in a savory soy-based sauce, a favorite side dish for children.'),
                                                                                '메추리알장조림, 장조림, jjangjorim, 아이들반찬, 밑반찬, 밥도둑, 짭짤한맛, 도시락메뉴') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [105] 요리 - 채소/반찬 (The King of Korean Side Dishes)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (105, jsonb_build_object('ko-KR', '김', 'en-US', 'Gim', 'ja-JP', '海苔'),
     jsonb_build_object('ko-KR', '바삭하게 구워 소금과 들기름으로 맛을 낸 한국인의 필수 밑반찬이자 바다의 채소', 'en-US', 'Toasted seaweed seasoned with salt and oil, a must-have Korean side dish known as "sea vegetable".'),
     '김, 조미김, 김구이, gim, seaweed, seaweed paper, 밥도둑, k-food, 도시락김, 마른김')
    ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [102] 요리 - 면 (Global Pasta Classics)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (102, jsonb_build_object('ko-KR', '알리오 올리오', 'en-US', 'Aglio e Olio', 'ja-JP', 'アーリオ・オーリオ', 'zh-CN', '蒜香橄榄油意面', 'it-IT', 'Aglio e Olio', 'de-DE', 'Aglio e Olio', 'fr-FR', 'Aglio e Olio', 'es-ES', 'Aglio e Olio', 'pt-BR', 'Aglio e Olio', 'ru-RU', 'Алио э олио', 'el-GR', 'Αλιο Ολιο'),
     jsonb_build_object('ko-KR', '마늘과 올리브오일, 페페론치노로 간단하게 만드는 이탈리아 나폴리 지방의 대표적인 파스타', 'en-US', 'Classic Italian pasta from Naples made with garlic, olive oil, and red pepper flakes.'),
     '알리오올리오, 아리오올리오, aglioelio, 마늘파스타, 오일파스타, 이탈리아파스타, 간단한파스타, 페페론치노') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [103] 요리 - 고기 (Chinese Braised Meat)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (103, jsonb_build_object('ko-KR', '홍샤오러우', 'en-US', 'Red Braised Pork Belly', 'ja-JP', '紅焼肉', 'zh-CN', '红烧肉', 'it-IT', 'Maiale brasato rosso', 'de-DE', 'Rotgeschmorter Schweinebauch', 'fr-FR', 'Porc braisé rouge', 'es-ES', 'Cerdo estofado rojo', 'pt-BR', 'Barriga de porco braseada', 'ru-RU', 'Хуншаожоу', 'el-GR', 'Κόκκινο μπρεζέ χοιρινό'),
     jsonb_build_object('ko-KR', '간장과 설탕, 향신료를 넣어 달콤하고 진하게 조린 중국의 대표적인 돼지고기 요리', 'en-US', 'Classic Chinese dish of pork belly braised in soy sauce, sugar, and spices until tender and caramelized.'),
     '홍샤오러우, 红烧肉, hongshaorou, 중국고기요리, 삼겹살조림, 동파육, 중식요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Japanese Home Cooking)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '니쿠자가', 'en-US', 'Nikujaga', 'ja-JP', '肉じゃが', 'zh-CN', '日式土豆炖肉', 'it-IT', 'Nikujaga', 'de-DE', 'Nikujaga', 'fr-FR', 'Nikujaga', 'es-ES', 'Nikujaga', 'pt-BR', 'Nikujaga', 'ru-RU', 'Никудзяга', 'el-GR', 'Νικουτζάγκα'),
     jsonb_build_object('ko-KR', '감자와 소고기(또는 돼지고기)를 달콤한 간장 국물에 조린 일본의 대표적인 가정식', 'en-US', 'Traditional Japanese comfort food of meat and potatoes simmered in a sweet soy-based broth.'),
     '니쿠자가, 肉じゃが, nikujaga, 일본가정식, 감자조림, 고기감자, 일식요리, 오후쿠로노아지') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (French Classic Stew)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '뵈프 부르기뇽', 'en-US', 'Boeuf Bourguignon', 'ja-JP', 'ブッフ・ブルギニョン', 'zh-CN', '勃艮第红酒炖牛肉', 'it-IT', 'Bourguignon di manzo', 'de-DE', 'Boeuf Bourguignon', 'fr-FR', 'Bœuf bourguignon', 'es-ES', 'Ternera a la borgoñona', 'pt-BR', 'Boeuf Bourguignon', 'ru-RU', 'Бёф бургиньон', 'el-GR', 'Μπεφ μπουργκινιόν'),
     jsonb_build_object('ko-KR', '레드와인과 버섯, 양파를 넣어 오랜 시간 푹 끓인 프랑스 부르고뉴 지방의 전통 소고기 스튜', 'en-US', 'Classic French beef stew braised in red wine with mushrooms, onions, and bacon from the Burgundy region.'),
     '뵈프부르기뇽, 부르기뇽, boeufbourguignon, 프랑스요리, 와인스튜, 소고기스튜, 프렌치홈쿡') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Russian Classic Soup)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '보르시', 'en-US', 'Borscht', 'ja-JP', 'ボルシチ', 'zh-CN', '罗宋汤', 'it-IT', 'Borscht', 'de-DE', 'Borschtsch', 'fr-FR', 'Bortsch', 'es-ES', 'Borsch', 'pt-BR', 'Borscht', 'ru-RU', 'Борщ', 'el-GR', 'Μπορς'),
     jsonb_build_object('ko-KR', '비트 뿌리와 양배추, 고기를 넣어 끓여 사워크림을 곁들이는 동유럽의 대표적인 수프', 'en-US', 'Traditional Eastern European beet soup served with sour cream, a staple of Russian and Ukrainian cuisine.'),
     '보르시, 보르쉬, borscht, 러시아수프, 비트수프, 사워크림수프, 동유럽요리') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [106] 요리 - 국물요리 (Brazilian National Dish)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (106, jsonb_build_object('ko-KR', '페이조아다', 'en-US', 'Feijoada', 'ja-JP', 'フェイジョアーダ', 'zh-CN', '巴西黑豆炖肉', 'it-IT', 'Feijoada', 'de-DE', 'Feijoada', 'fr-FR', 'Feijoada', 'es-ES', 'Feijoada', 'pt-BR', 'Feijoada', 'ru-RU', 'Фейжоада', 'el-GR', 'Φεϊζοάδα'),
     jsonb_build_object('ko-KR', '검은콩과 돼지고기, 소시지를 넣어 푹 끓인 브라질의 대표적인 국민 요리', 'en-US', 'Brazil''s national dish of black beans stewed with pork, sausage, and beef, served with rice and orange slices.'),
     '페이조아다, feijoada, 브라질요리, 검은콩스튜, 남미요리, 브라질국민음식') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;

-- [109] 요리 - 기타 (Greek Classic Casserole)
INSERT INTO foods_master (category_id, name, description, search_keywords) VALUES
    (109, jsonb_build_object('ko-KR', '무사카', 'en-US', 'Moussaka', 'ja-JP', 'ムサカ', 'zh-CN', '穆萨卡', 'it-IT', 'Moussaka', 'de-DE', 'Moussaka', 'fr-FR', 'Moussaka', 'es-ES', 'Musaca', 'pt-BR', 'Moussaka', 'ru-RU', 'Мусака', 'el-GR', 'Μουσακάς'),
     jsonb_build_object('ko-KR', '가지, 감자, 다진 고기를 겹겹이 쌓고 베샤멜 소스를 얹어 구운 그리스의 대표적인 오븐 요리', 'en-US', 'Traditional Greek casserole of layered eggplant, potato, and spiced meat topped with creamy béchamel sauce.'),
     '무사카, moussaka, 그리스요리, 가지요리, 지중해요리, 오븐요리, 베샤멜') ON CONFLICT ((name ->> 'ko-KR')) DO NOTHING;







SELECT setval(pg_get_serial_sequence('foods_master', 'id'), COALESCE(MAX(id), 1)) FROM foods_master;


INSERT INTO users (username, locale, role, is_bot, status) VALUES
    ('빵지순례자', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('홈카페수민', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('소금빵이조아', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('오늘의무드', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('달콤한기록', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('브런치타임', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('망고무드', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('베이글러버', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('소소한식탁', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('아보카도러버', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('카페투어리스트', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('민트초코공주', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('휘낭시에덕후', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('올리브오일', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('바닐라라떼', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('햇살정원', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('식탁위의우주', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('오늘의빵', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('감성요정', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('라떼는말이야', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('마카롱달인', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('비건라이프', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('샐러드공주', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('요거트볼', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('블루베리즘', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('코지홈', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('화이트린넨', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('우드앤키친', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('심플리쿡', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('나만의식탁', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('향기로운오후', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('봄날의식사', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('별헤는밤', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('초록빛식탁', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('페어링마스터', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('냠냠박사', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('맛집지도', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('먹방요정', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('숲속의주방', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('새벽공기', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('레시피연구소', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('미니멀키친', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('든든한한끼', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('치즈케이크', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('와인한잔', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('주말브런치', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('꼬마요리사', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('부엌데기', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('소소한요리', 'ko-KR', 'USER', TRUE, 'ACTIVE'),
    ('우유식빵언니', 'ko-KR', 'USER', TRUE, 'ACTIVE')
    ON CONFLICT (username) DO NOTHING;