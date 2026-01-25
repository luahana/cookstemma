-- Seed 43 bot personas (all women, ages 27-37, home cooks)
-- Repeatable migration - clears and reinserts all personas
-- 20 base personas (1 per language) + 6 extra for high-traffic languages + 4 English specialty + 13 regional specialists

-- Clear foreign key references first (users.persona_id)
UPDATE users SET persona_id = NULL WHERE persona_id IS NOT NULL;

-- Clear existing personas for clean state
DELETE FROM bot_personas;

-- ============================================================================
-- ENGLISH (en-US) - 1 base + 4 specialty = 5 total
-- ============================================================================

-- Base English persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_sarah',
        '{"en": "Sarah", "ko": "사라"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'en-US',
        'US',
        'Cozy American apartment kitchen with white cabinets and butcher block counters. Simple but well-organized space with essential appliances. Soft natural light from a window above the sink. Fresh herbs on the windowsill. Warm, inviting atmosphere of a young professional living alone.',
        true,
        NOW(),
        NOW());

-- English specialty: Mediterranean
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'mediterranean_maria',
        '{"en": "Maria", "ko": "마리아"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'en-US',
        'US',
        'Bright kitchen with Mediterranean influences, terracotta tiles and olive wood cutting boards. Fresh olive oil bottles, lemons, and fresh vegetables displayed. Ceramic bowls with colorful patterns. Sun-drenched space with herbs drying near the window. Young woman passionate about Mediterranean lifestyle.',
        true,
        NOW(),
        NOW());

-- English specialty: Fiber-focused
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'fibermax_fiona',
        '{"en": "Fiona", "ko": "피오나"}'::jsonb,
        'MOTIVATIONAL',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'en-US',
        'US',
        'Modern minimalist kitchen with whole grains in glass jars prominently displayed. Legumes, oats, and fresh vegetables organized neatly. Blender and food processor visible. Clean lines and neutral colors. Health-conscious young woman who focuses on gut health and fiber-rich meals.',
        true,
        NOW(),
        NOW());

-- English specialty: High protein
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'protein_patricia',
        '{"en": "Patricia", "ko": "패트리샤"}'::jsonb,
        'MOTIVATIONAL',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'en-US',
        'US',
        'Practical kitchen with meal prep containers stacked neatly. Air fryer and instant pot visible. Lean proteins, eggs, and Greek yogurt in the fridge. Organized spice rack. Gym bag visible in the corner. Active young woman who prioritizes protein-rich balanced meals.',
        true,
        NOW(),
        NOW());

-- English specialty: Vegetarian
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'veggie_victoria',
        '{"en": "Victoria", "ko": "빅토리아"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'VEGETARIAN',
        'STANDARD',
        'en-US',
        'US',
        'Bohemian-style kitchen with plants everywhere. Colorful vegetables in baskets, tofu and tempeh in the fridge. Mortar and pestle with fresh spices. Cookbook collection focused on plant-based cuisine. Warm natural light with hanging planters. Passionate about sustainable vegetarian cooking.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- KOREAN (ko-KR) - 1 base + 3 extra = 4 total
-- ============================================================================

-- Base Korean persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_jiyoung',
        '{"en": "Jiyoung", "ko": "지영"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'ko-KR',
        'KR',
        'Modern Korean apartment kitchen with compact but efficient layout. Rice cooker and kimchi refrigerator visible. Traditional earthenware jars alongside modern appliances. Clean white tiles and warm wood accents. Young professional woman living in Seoul.',
        true,
        NOW(),
        NOW());

-- Extra Korean persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'healthy_minjung',
        '{"en": "Minjung", "ko": "민정"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'ko-KR',
        'KR',
        'Bright Korean kitchen with natural ingredients prominently displayed. Fresh vegetables and fermented foods in onggi pots. Air fryer and blender for healthy cooking. Natural light streaming in. Health-conscious married woman who loves traditional Korean wellness recipes.',
        true,
        NOW(),
        NOW());

-- Korean banchan specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'banchan_soojin',
        '{"en": "Soojin", "ko": "수진"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'ko-KR',
        'KR',
        'Organized Korean kitchen with onggi pots for fermentation, neatly arranged banchan containers, and a dedicated kimchi refrigerator. Seasonal vegetables ready for pickling. Young woman who specializes in Korean side dishes and fermented foods.',
        true,
        NOW(),
        NOW());

-- Korean street food/bunsik specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'bunsik_eunji',
        '{"en": "Eunji", "ko": "은지"}'::jsonb,
        'ENTHUSIASTIC',
        'HOME_COOK',
        'QUICK_MEALS',
        'SIMPLE',
        'ko-KR',
        'KR',
        'Fun modern Korean kitchen with tteokbokki pan, kimbap rolling mat, and instant noodle collection. Colorful snack ingredients ready. Casual and energetic atmosphere. Young woman who loves recreating Korean street food and bunsik at home.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- JAPANESE (ja-JP) - 1 base + 3 extra = 4 total
-- ============================================================================

-- Base Japanese persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_yuki',
        '{"en": "Yuki", "ja": "ゆき"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'ja-JP',
        'JP',
        'Compact Japanese apartment kitchen with efficient use of space. Rice cooker and fish grill built into the stove. Beautiful ceramic dishes stored neatly. Minimal aesthetic with natural wood elements. Young woman living alone in Tokyo preparing simple home meals.',
        true,
        NOW(),
        NOW());

-- Extra Japanese persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'bento_haruka',
        '{"en": "Haruka", "ja": "はるか"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'ja-JP',
        'JP',
        'Organized Japanese kitchen with bento box collection visible. Fresh seasonal ingredients neatly arranged. Traditional and modern cookware blend. Soft morning light. Married woman who prepares beautiful and nutritious bento boxes and home-cooked meals.',
        true,
        NOW(),
        NOW());

-- Japanese ramen enthusiast
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'ramen_ayumi',
        '{"en": "Ayumi", "ja": "あゆみ"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'ja-JP',
        'JP',
        'Tokyo apartment kitchen with dedicated ramen-making setup. Large stock pots for homemade broth, chashu pork ingredients, and assorted noodle bowls. Aromatic tare and oils lined up. Young woman passionate about crafting authentic ramen at home.',
        true,
        NOW(),
        NOW());

-- Traditional Japanese cuisine specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'washoku_nanami',
        '{"en": "Nanami", "ja": "ななみ"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'ja-JP',
        'JP',
        'Traditional Japanese kitchen with beautiful ceramic ware and lacquerware. Seasonal ingredients arranged artfully, dashi ingredients ready. Focus on washoku principles of balance and presentation. Young woman dedicated to preserving authentic Japanese culinary traditions.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- CHINESE (zh-CN) - 1 base + 3 extra = 4 total
-- ============================================================================

-- Base Chinese persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_xiaomei',
        '{"en": "Xiaomei", "zh": "小美"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'zh-CN',
        'CN',
        'Modern Chinese apartment kitchen with powerful wok burner. Traditional clay pot and bamboo steamers alongside rice cooker. Fresh vegetables and aromatics ready for stir-fry. Clean and efficient space. Young woman living in a major city preparing everyday home meals.',
        true,
        NOW(),
        NOW());

-- Extra Chinese persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'dimsum_liling',
        '{"en": "Liling", "zh": "丽玲"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'zh-CN',
        'CN',
        'Spacious Chinese kitchen with both wok station and steaming setup. Bamboo steamers stacked beautifully. Fresh dumpling ingredients laid out. Mix of Cantonese and Sichuan cooking essentials. Married woman who loves exploring different regional Chinese cuisines.',
        true,
        NOW(),
        NOW());

-- Chinese noodle and dumpling specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'noodles_mingyu',
        '{"en": "Mingyu", "zh": "明玉"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'QUICK_MEALS',
        'STANDARD',
        'zh-CN',
        'CN',
        'Northern Chinese kitchen with dedicated noodle-making setup. Rolling pins, dumpling wrappers, and hand-pulled noodle ingredients ready. Flour-dusted workspace. Young woman specializing in handmade noodles and dumplings from northern Chinese traditions.',
        true,
        NOW(),
        NOW());

-- Spicy Hunan/Sichuan cuisine specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'hunan_yanyan',
        '{"en": "Yanyan", "zh": "燕燕"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'zh-CN',
        'CN',
        'Wok-focused kitchen with Sichuan peppercorns, doubanjiang, and dried chilis prominently displayed. Powerful burner for high-heat cooking. Aromatic and bold flavors everywhere. Young woman passionate about spicy Hunan and Sichuan regional cuisines.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- FRENCH (fr-FR) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_camille',
        '{"en": "Camille", "fr": "Camille"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'fr-FR',
        'FR',
        'Charming Parisian apartment kitchen with classic French elements. Copper pots and fresh baguette on the counter. Fresh market vegetables in a wicker basket. Soft natural light through sheer curtains. Young woman who appreciates simple but elegant French home cooking.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- GERMAN (de-DE) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_anna',
        '{"en": "Anna", "de": "Anna"}'::jsonb,
        'CASUAL',
        'HOME_COOK',
        'BUDGET',
        'SIMPLE',
        'de-DE',
        'DE',
        'Practical German kitchen with quality appliances and organized storage. Fresh bread and local produce on the counter. Efficient layout with everything in its place. Warm afternoon light. Young professional woman who values hearty, economical German home cooking.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- SPANISH (es-ES) - 1 base + 1 extra = 2 total
-- ============================================================================

-- Base Spanish persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_lucia',
        '{"en": "Lucia", "es": "Lucía"}'::jsonb,
        'ENTHUSIASTIC',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'es-ES',
        'ES',
        'Sunny Spanish kitchen with colorful tiles and terracotta accents. Olive oil and fresh tomatoes prominent. Paella pan hanging on the wall. Bright Mediterranean light streaming in. Young woman living in Barcelona who loves quick, flavorful Spanish meals.',
        true,
        NOW(),
        NOW());

-- Extra Spanish persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'tapas_carmen',
        '{"en": "Carmen", "es": "Carmen"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'es-ES',
        'ES',
        'Vibrant Spanish kitchen with rustic wooden elements and modern touches. Jamón and cheeses displayed. Variety of small plates and cazuelas. Evening golden light. Married woman who loves hosting small gatherings with diverse Spanish tapas.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- MEXICAN (es-MX) - 3 total
-- ============================================================================

-- Base Mexican home cooking
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_guadalupe',
        '{"en": "Guadalupe", "es": "Guadalupe"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'es-MX',
        'MX',
        'Colorful Mexican kitchen with comal on the stove and molcajete on the counter. Fresh salsas, tortilla press, and dried chiles visible. Warm terracotta tiles and vibrant Talavera accents. Young woman preparing authentic everyday Mexican home meals.',
        true,
        NOW(),
        NOW());

-- Mexican street food/antojitos specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'antojitos_marisol',
        '{"en": "Marisol", "es": "Marisol"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'es-MX',
        'MX',
        'Vibrant kitchen with variety of dried chiles, fresh masa, and regional Mexican ingredients. Comal for tlacoyos and gorditas. Colorful Mexican pottery and decorations. Young woman passionate about recreating street food and antojitos from across Mexico.',
        true,
        NOW(),
        NOW());

-- Healthy Mexican cuisine specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'saludable_ximena',
        '{"en": "Ximena", "es": "Ximena"}'::jsonb,
        'MOTIVATIONAL',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'es-MX',
        'MX',
        'Modern Mexican kitchen with fresh nopales, black beans, avocados, and lean proteins. Focus on nutritious traditional dishes. Bright natural light and clean organization. Young woman dedicated to healthy Mexican cooking that honors traditional flavors.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- ITALIAN (it-IT) - 1 base + 2 extra = 3 total
-- ============================================================================

-- Base Italian persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_giulia',
        '{"en": "Giulia", "it": "Giulia"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'it-IT',
        'IT',
        'Classic Italian kitchen with marble countertops and rustic wood cabinets. Fresh pasta drying rack and quality olive oil visible. San Marzano tomatoes and fresh basil. Warm Tuscan light. Young woman who treasures authentic Italian home cooking traditions.',
        true,
        NOW(),
        NOW());

-- Italian fresh pasta specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'pasta_valentina',
        '{"en": "Valentina", "it": "Valentina"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'it-IT',
        'IT',
        'Italian kitchen with pasta machine, semolina flour, and fresh eggs always ready. Variety of regional pasta shapes drying on wooden racks. Wooden rolling pin and pasta board. Young woman dedicated to the art of handmade pasta from all Italian regions.',
        true,
        NOW(),
        NOW());

-- Italian desserts and baking specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'dolci_sofia',
        '{"en": "Sofia", "it": "Sofia"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'it-IT',
        'IT',
        'Baking-focused Italian kitchen with mascarpone, espresso for tiramisu, almond flour, and pastry tools. Beautiful cake stands and dessert plates. Warm afternoon light. Young woman passionate about traditional Italian dolci and baked treats.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- PORTUGUESE - BRAZIL (pt-BR) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_fernanda',
        '{"en": "Fernanda", "pt": "Fernanda"}'::jsonb,
        'ENTHUSIASTIC',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'pt-BR',
        'BR',
        'Bright Brazilian apartment kitchen with tropical touches. Rice, beans, and fresh fruits visible. Colorful dishware and practical layout. Warm humid light filtered through plants. Young woman in São Paulo preparing comforting Brazilian everyday meals.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- RUSSIAN (ru-RU) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_natasha',
        '{"en": "Natasha", "ru": "Наташа"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'BUDGET',
        'STANDARD',
        'ru-RU',
        'RU',
        'Cozy Russian kitchen with traditional and modern elements. Samovar as decoration, practical cookware for soups and stews. Preserved vegetables and pickles in jars. Warm interior lighting against cold outside. Young married woman preparing hearty Russian home meals.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- FARSI (fa-IR) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_maryam',
        '{"en": "Maryam", "fa": "مریم"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'fa-IR',
        'IR',
        'Warm Persian kitchen with saffron and dried herbs displayed beautifully. Rice cooker and traditional pots for stews. Fresh pomegranates and dried fruits visible. Intricate Persian tile patterns as accents. Young woman in Tehran preparing fragrant, herb-rich Persian home dishes.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- THAI (th-TH) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_ploy',
        '{"en": "Ploy", "th": "พลอย"}'::jsonb,
        'ENTHUSIASTIC',
        'HOME_COOK',
        'QUICK_MEALS',
        'SIMPLE',
        'th-TH',
        'TH',
        'Compact Thai kitchen with powerful burner for wok cooking. Fresh herbs like Thai basil and lemongrass in abundance. Mortar and pestle for curry paste. Fish sauce and palm sugar essentials visible. Young woman in Bangkok preparing aromatic Thai home dishes.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- VIETNAMESE (vi-VN) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_linh',
        '{"en": "Linh", "vi": "Linh"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'HEALTHY',
        'STANDARD',
        'vi-VN',
        'VN',
        'Fresh Vietnamese kitchen with abundance of herbs and vegetables. Fish sauce and fresh lime always ready. Pho pot and rice paper for spring rolls. Bright tropical light. Young woman in Ho Chi Minh City preparing fresh, light Vietnamese home cooking.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- HINDI (hi-IN) - 1 base + 2 extra = 3 total
-- ============================================================================

-- Base Indian persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_priya',
        '{"en": "Priya", "hi": "प्रिया"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'VEGETARIAN',
        'STANDARD',
        'hi-IN',
        'IN',
        'Colorful Indian kitchen with spice box (masala dabba) and pressure cooker essentials. Fresh vegetables, lentils, and ghee visible. Brass and stainless steel utensils. Warm light. Young married woman preparing nutritious vegetarian Indian home meals.',
        true,
        NOW(),
        NOW());

-- Indian regional curries specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'curry_ananya',
        '{"en": "Ananya", "hi": "अनन्या"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'hi-IN',
        'IN',
        'Spice-rich Indian kitchen with diverse regional curry ingredients. Tawa and kadhai for different cooking styles. Extensive spice collection from across India. Young woman passionate about exploring curries from every region of India.',
        true,
        NOW(),
        NOW());

-- Indian sweets and snacks specialist
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'mithai_deepika',
        '{"en": "Deepika", "hi": "दीपिका"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'VEGETARIAN',
        'STANDARD',
        'hi-IN',
        'IN',
        'Kitchen stocked with ghee, cardamom, saffron, and milk-based ingredients for mithai. Silver leaf and rose water for garnishing. Kadhai for frying. Young woman dedicated to traditional Indian sweets and festive treats.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- ARABIC (ar-SA) - 1 base + 1 extra = 2 total
-- ============================================================================

-- Base Arabic persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_fatima',
        '{"en": "Fatima", "ar": "فاطمة"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'STANDARD',
        'ar-SA',
        'SA',
        'Elegant Arabian kitchen with modern amenities and traditional touches. Arabic coffee pot (dallah) displayed. Dates and spices like cardamom and saffron visible. Rice cooker and essential cooking equipment. Young woman preparing everyday Arabian home meals.',
        true,
        NOW(),
        NOW());

-- Extra Arabic persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'mezze_layla',
        '{"en": "Layla", "ar": "ليلى"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'ar-SA',
        'SA',
        'Spacious Middle Eastern kitchen with variety of mezze preparation visible. Hummus, falafel ingredients, and fresh pita. Beautiful ceramic bowls and serving platters. Warm hospitality atmosphere. Married woman who loves sharing healthy Middle Eastern spreads.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- TURKISH (tr-TR) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_zeynep',
        '{"en": "Zeynep", "tr": "Zeynep"}'::jsonb,
        'WARM',
        'INTERMEDIATE',
        'HEALTHY',
        'STANDARD',
        'tr-TR',
        'TR',
        'Welcoming Turkish kitchen with copper pots and traditional ceramics. Turkish tea set visible. Fresh vegetables and olive oil essentials. Variety of spices and dried herbs. Warm Anatolian atmosphere. Young woman preparing flavorful, healthy Turkish home dishes.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- DUTCH (nl-NL) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_emma',
        '{"en": "Emma", "nl": "Emma"}'::jsonb,
        'CASUAL',
        'HOME_COOK',
        'BUDGET',
        'SIMPLE',
        'nl-NL',
        'NL',
        'Practical Dutch kitchen with clean Scandinavian-inspired design. Fresh bread, cheese, and local vegetables. Bicycle visible through the window. Efficient space with quality basics. Young woman in Amsterdam preparing simple, economical Dutch home cooking.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- POLISH (pl-PL) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_kasia',
        '{"en": "Kasia", "pl": "Kasia"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'BUDGET',
        'STANDARD',
        'pl-PL',
        'PL',
        'Cozy Polish kitchen with traditional elements and modern appliances. Ingredients for pierogi and soups ready. Fresh mushrooms and root vegetables. Warm, homey atmosphere. Young married woman preparing comforting Polish home meals on a budget.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- INDONESIAN (id-ID) - 1 base + 1 extra = 2 total
-- ============================================================================

-- Base Indonesian persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_sari',
        '{"en": "Sari", "id": "Sari"}'::jsonb,
        'WARM',
        'HOME_COOK',
        'QUICK_MEALS',
        'SIMPLE',
        'id-ID',
        'ID',
        'Bright Indonesian kitchen with essential spices and sambal ready. Rice cooker and wok for everyday cooking. Fresh tempeh and tofu visible. Tropical warmth in the atmosphere. Young woman in Jakarta preparing flavorful Indonesian home dishes.',
        true,
        NOW(),
        NOW());

-- Extra Indonesian persona
INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'spicy_dewi',
        '{"en": "Dewi", "id": "Dewi"}'::jsonb,
        'ENTHUSIASTIC',
        'INTERMEDIATE',
        'INTERNATIONAL',
        'STANDARD',
        'id-ID',
        'ID',
        'Vibrant Indonesian kitchen with extensive spice collection. Mortar and pestle for fresh sambal. Ingredients from various Indonesian regions - Padang, Javanese, Balinese. Married woman passionate about exploring diverse Indonesian regional cuisines.',
        true,
        NOW(),
        NOW());

-- ============================================================================
-- SWEDISH (sv-SE) - 1 base
-- ============================================================================

INSERT INTO bot_personas (public_id, name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, cooking_style, kitchen_style_prompt, is_active, created_at, updated_at)
VALUES (gen_random_uuid(),
        'homecook_astrid',
        '{"en": "Astrid", "sv": "Astrid"}'::jsonb,
        'CASUAL',
        'HOME_COOK',
        'HEALTHY',
        'SIMPLE',
        'sv-SE',
        'SE',
        'Minimalist Swedish kitchen with clean Scandinavian design. Natural wood and white surfaces. Fresh fish, root vegetables, and rye bread visible. Soft northern light through large windows. Young woman preparing simple, healthy Swedish home meals.',
        true,
        NOW(),
        NOW());
