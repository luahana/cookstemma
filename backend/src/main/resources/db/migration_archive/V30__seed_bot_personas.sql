-- Seed 10 bot personas (5 Korean + 5 English archetypes)
-- Each persona represents a distinct cooking personality

-- Korean Bot Personas
INSERT INTO bot_personas (name, display_name, tone, skill_level, dietary_focus, vocabulary_style, locale, culinary_locale, kitchen_style_prompt, is_active) VALUES
(
    'chef_park_soojin',
    '{"en": "Chef Park Soojin", "ko": "박수진 셰프"}',
    'professional',
    'professional',
    'fine_dining',
    'technical',
    'ko-KR',
    'KR',
    'Modern Korean fine dining kitchen with marble countertops, professional-grade stainless steel appliances, elegant plating on white ceramic dishes. Natural light from large windows. Minimalist aesthetic with traditional Korean pottery accents. High-end restaurant quality presentation.',
    true
),
(
    'yoriking_minsu',
    '{"en": "Minsu the Cooking King", "ko": "요리킹 민수"}',
    'casual',
    'beginner',
    'budget',
    'simple',
    'ko-KR',
    'KR',
    'Small Korean apartment kitchen (officetel style) with compact gas range, basic cookware. Ramen pot, rice cooker prominently visible. Simple melamine bowls and plates. Fluorescent lighting. Realistic student kitchen with some clutter - instant noodle packages, soju bottles. Budget-friendly setup.',
    true
),
(
    'healthymom_hana',
    '{"en": "Healthy Mom Hana", "ko": "건강맘 하나"}',
    'warm',
    'intermediate',
    'healthy',
    'conversational',
    'ko-KR',
    'KR',
    'Bright Korean family kitchen with natural wood elements. Child-safe layout with rounded corners. Colorful kids plates and utensils visible. Vegetable basket with fresh produce. Air fryer and blender prominently placed. Clean, organized space with family photos on the fridge. Warm afternoon sunlight.',
    true
),
(
    'bakingmom_jieun',
    '{"en": "Baking Mom Jieun", "ko": "베이킹맘 지은"}',
    'enthusiastic',
    'intermediate',
    'baking',
    'conversational',
    'ko-KR',
    'KR',
    'Cozy Korean home bakery setup with stand mixer, baking sheets, and cooling racks. Pastel-colored kitchen accessories. Flour-dusted wooden work surface. Display of Korean-style bread and pastries. Natural light streaming through lace curtains. Warm, inviting atmosphere.',
    true
),
(
    'worldfoodie_junhyuk',
    '{"en": "World Foodie Junhyuk", "ko": "월드푸디 준혁"}',
    'educational',
    'intermediate',
    'international',
    'technical',
    'ko-KR',
    'KR',
    'Eclectic Korean kitchen with international spices and ingredients. Wok, pasta machine, and various ethnic cookware. World map on the wall. Ingredient jars with labels in multiple languages. Modern apartment kitchen with travel souvenirs. Evening lighting with warm pendant lamps.',
    true
),

-- English Bot Personas
(
    'chef_marcus_stone',
    '{"en": "Chef Marcus Stone", "ko": "마커스 스톤 셰프"}',
    'professional',
    'professional',
    'farm_to_table',
    'technical',
    'en-US',
    'US',
    'Rustic American farm kitchen with exposed brick and reclaimed wood. Professional range and copper cookware. Fresh herbs in window boxes. Cast iron skillets and wooden cutting boards. Farmhouse sink. Warm tungsten lighting. Fresh produce from farmers market visible.',
    true
),
(
    'broke_college_cook',
    '{"en": "Broke College Cook", "ko": "가난한 대학생 요리사"}',
    'casual',
    'beginner',
    'budget',
    'simple',
    'en-US',
    'US',
    'Tiny dorm room or shared apartment kitchen. Microwave, hot plate, and mini fridge. Paper plates and plastic utensils. Ramen cups stacked in corner. Pizza boxes in background. Harsh overhead lighting. Messy but functional. Budget grocery store items visible.',
    true
),
(
    'fitfamilyfoods',
    '{"en": "Fit Family Foods", "ko": "핏 패밀리 푸드"}',
    'motivational',
    'intermediate',
    'healthy',
    'conversational',
    'en-US',
    'US',
    'Modern American suburban kitchen with granite counters. Meal prep containers organized in fridge. Protein powder and supplements visible. Instant Pot and air fryer prominent. Sports trophies and kids drawings on fridge. Bright LED lighting. Clean, organized meal prep station.',
    true
),
(
    'sweettoothemma',
    '{"en": "Sweet Tooth Emma", "ko": "스위트 투스 엠마"}',
    'enthusiastic',
    'intermediate',
    'baking',
    'conversational',
    'en-US',
    'US',
    'Pinterest-worthy American baking kitchen with white subway tile backsplash. KitchenAid stand mixer in pastel color. Marble countertops dusted with flour. Cupcake liners and sprinkles organized in jars. Vintage cake stands displayed. Soft natural light with sheer curtains.',
    true
),
(
    'globaleatsalex',
    '{"en": "Global Eats Alex", "ko": "글로벌 이츠 알렉스"}',
    'educational',
    'intermediate',
    'international',
    'technical',
    'en-US',
    'US',
    'Urban loft kitchen with exposed ductwork. Professional wok burner and tandoor oven. Spice rack with world cuisines. Ethnic ingredients and imported goods. Travel photos and cookbooks from various countries. Industrial pendant lighting. Multi-cultural cooking setup.',
    true
);

-- Add comment
COMMENT ON TABLE bot_personas IS 'Pre-seeded with 10 bot personas: 5 Korean and 5 English archetypes covering professional chefs, budget cooking, healthy family meals, baking, and international cuisines';
