-- Seed bot users and their API keys
-- Repeatable migration - only inserts if user doesn't exist
-- API keys match those in bot_engine/.env
-- Note: V12__add_bot_role.sql must run first to add 'BOT' to user_role enum

-- Uses pgcrypto extension for SHA-256 hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- BOT USERS
-- ============================================================================

-- chef_park_soojin
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'chef_park_soojin',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'ko-KR',
       'KR',
       true,
       (SELECT id FROM bot_personas WHERE name = 'chef_park_soojin')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'chef_park_soojin')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'chef_park_soojin');

-- yoriking_minsu
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'yoriking_minsu',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'ko-KR',
       'KR',
       true,
       (SELECT id FROM bot_personas WHERE name = 'yoriking_minsu')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'yoriking_minsu')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'yoriking_minsu');

-- healthymom_hana
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'healthymom_hana',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'ko-KR',
       'KR',
       true,
       (SELECT id FROM bot_personas WHERE name = 'healthymom_hana')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'healthymom_hana')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'healthymom_hana');

-- bakingmom_jieun
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'bakingmom_jieun',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'ko-KR',
       'KR',
       true,
       (SELECT id FROM bot_personas WHERE name = 'bakingmom_jieun')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'bakingmom_jieun')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'bakingmom_jieun');

-- worldfoodie_junhyuk
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'worldfoodie_junhyuk',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'ko-KR',
       'KR',
       true,
       (SELECT id FROM bot_personas WHERE name = 'worldfoodie_junhyuk')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'worldfoodie_junhyuk')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'worldfoodie_junhyuk');

-- chef_marcus_stone
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'chef_marcus_stone',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'en-US',
       'US',
       true,
       (SELECT id FROM bot_personas WHERE name = 'chef_marcus_stone')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'chef_marcus_stone')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'chef_marcus_stone');

-- broke_college_cook
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'broke_college_cook',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'en-US',
       'US',
       true,
       (SELECT id FROM bot_personas WHERE name = 'broke_college_cook')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'broke_college_cook')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'broke_college_cook');

-- fitfamilyfoods
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'fitfamilyfoods',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'en-US',
       'US',
       true,
       (SELECT id FROM bot_personas WHERE name = 'fitfamilyfoods')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'fitfamilyfoods')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'fitfamilyfoods');

-- sweettoothemma
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'sweettoothemma',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'en-US',
       'US',
       true,
       (SELECT id FROM bot_personas WHERE name = 'sweettoothemma')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'sweettoothemma')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'sweettoothemma');

-- globaleatsalex
INSERT INTO users (username, role, status, locale, default_food_style, is_bot, persona_id)
SELECT 'globaleatsalex',
       'BOT'::user_role,
       'ACTIVE'::account_status,
       'en-US',
       'US',
       true,
       (SELECT id FROM bot_personas WHERE name = 'globaleatsalex')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'globaleatsalex')
  AND EXISTS (SELECT 1 FROM bot_personas WHERE name = 'globaleatsalex');

-- ============================================================================
-- BOT API KEYS
-- Keys match bot_engine/.env - hash computed via SHA-256
-- ============================================================================

-- chef_park_soojin: pp_bot_1d73db3904b04e300fd38aa65760c358bdc074ba9c9adf97
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_1',
       encode(digest('pp_bot_1d73db3904b04e300fd38aa65760c358bdc074ba9c9adf97', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'chef_park_soojin'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'chef_park_soojin')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_1d73db3904b04e300fd38aa65760c358bdc074ba9c9adf97', 'sha256'), 'hex')
  );

-- yoriking_minsu: pp_bot_145c0c1ac1418ae46cd310e976dc1d23dc5886e419c27a5e
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_1',
       encode(digest('pp_bot_145c0c1ac1418ae46cd310e976dc1d23dc5886e419c27a5e', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'yoriking_minsu'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'yoriking_minsu')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_145c0c1ac1418ae46cd310e976dc1d23dc5886e419c27a5e', 'sha256'), 'hex')
  );

-- healthymom_hana: pp_bot_31d6681108db443eb3d753486f201f6d11737e1503714540
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_3',
       encode(digest('pp_bot_31d6681108db443eb3d753486f201f6d11737e1503714540', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'healthymom_hana'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'healthymom_hana')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_31d6681108db443eb3d753486f201f6d11737e1503714540', 'sha256'), 'hex')
  );

-- bakingmom_jieun: pp_bot_590aaf21b909ce1aa9cddd71ae77ebd8e07c7ef32a35fd3d
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_5',
       encode(digest('pp_bot_590aaf21b909ce1aa9cddd71ae77ebd8e07c7ef32a35fd3d', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'bakingmom_jieun'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'bakingmom_jieun')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_590aaf21b909ce1aa9cddd71ae77ebd8e07c7ef32a35fd3d', 'sha256'), 'hex')
  );

-- worldfoodie_junhyuk: pp_bot_5306b1bb57cadcfde007d67edad9d080d52055dd3a98a1b4
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_5',
       encode(digest('pp_bot_5306b1bb57cadcfde007d67edad9d080d52055dd3a98a1b4', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'worldfoodie_junhyuk'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'worldfoodie_junhyuk')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_5306b1bb57cadcfde007d67edad9d080d52055dd3a98a1b4', 'sha256'), 'hex')
  );

-- chef_marcus_stone: pp_bot_e99730538223aa2314def0138e8267861589a15e128d28f6
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_e',
       encode(digest('pp_bot_e99730538223aa2314def0138e8267861589a15e128d28f6', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'chef_marcus_stone'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'chef_marcus_stone')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_e99730538223aa2314def0138e8267861589a15e128d28f6', 'sha256'), 'hex')
  );

-- broke_college_cook: pp_bot_d28c3d865aeb819194124579e1781c2c1ac1b2c39c096959
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_d',
       encode(digest('pp_bot_d28c3d865aeb819194124579e1781c2c1ac1b2c39c096959', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'broke_college_cook'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'broke_college_cook')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_d28c3d865aeb819194124579e1781c2c1ac1b2c39c096959', 'sha256'), 'hex')
  );

-- fitfamilyfoods: pp_bot_225c721d51553f1e58c7f0bab4b7488259df2b5fa6fa969d
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_2',
       encode(digest('pp_bot_225c721d51553f1e58c7f0bab4b7488259df2b5fa6fa969d', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'fitfamilyfoods'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'fitfamilyfoods')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_225c721d51553f1e58c7f0bab4b7488259df2b5fa6fa969d', 'sha256'), 'hex')
  );

-- sweettoothemma: pp_bot_42b94fa8f82cfd66a887f378cd1796e65911d72cca65e79c
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_4',
       encode(digest('pp_bot_42b94fa8f82cfd66a887f378cd1796e65911d72cca65e79c', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'sweettoothemma'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'sweettoothemma')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_42b94fa8f82cfd66a887f378cd1796e65911d72cca65e79c', 'sha256'), 'hex')
  );

-- globaleatsalex: pp_bot_dba4ff058af76f4fd356483608213e2a1072d150eebac6b3
INSERT INTO bot_api_keys (key_prefix, key_hash, bot_user_id, name, is_active)
SELECT 'pp_bot_d',
       encode(digest('pp_bot_dba4ff058af76f4fd356483608213e2a1072d150eebac6b3', 'sha256'), 'hex'),
       (SELECT id FROM users WHERE username = 'globaleatsalex'),
       'Initial Key',
       true
WHERE EXISTS (SELECT 1 FROM users WHERE username = 'globaleatsalex')
  AND NOT EXISTS (
    SELECT 1 FROM bot_api_keys
    WHERE key_hash = encode(digest('pp_bot_dba4ff058af76f4fd356483608213e2a1072d150eebac6b3', 'sha256'), 'hex')
  );
