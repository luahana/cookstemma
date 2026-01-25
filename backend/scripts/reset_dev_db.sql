-- Reset Dev Database
-- WARNING: This will delete ALL data from the dev database!
-- Run with: psql -h <RDS_HOST> -U postgres -d cookstemma -f reset_dev_db.sql

-- Disable foreign key checks temporarily
SET session_replication_role = 'replica';

-- Truncate all tables (in order to handle foreign keys)
TRUNCATE TABLE
    user_follows,
    user_blocks,
    notifications,
    saved_recipes,
    saved_log_posts,
    comments,
    recipe_images,
    log_post_images,
    recipe_ingredients,
    recipe_steps,
    recipe_hashtags,
    log_post_hashtags,
    log_posts,
    recipes,
    images,
    hashtags,
    bot_api_keys,
    social_accounts,
    users,
    bot_personas,
    food_master,
    created_foods
CASCADE;

-- Re-enable foreign key checks
SET session_replication_role = 'origin';

-- Reset sequences
SELECT setval(pg_get_serial_sequence('users', 'id'), 1, false);
SELECT setval(pg_get_serial_sequence('recipes', 'id'), 1, false);
SELECT setval(pg_get_serial_sequence('log_posts', 'id'), 1, false);
SELECT setval(pg_get_serial_sequence('comments', 'id'), 1, false);
SELECT setval(pg_get_serial_sequence('images', 'id'), 1, false);
SELECT setval(pg_get_serial_sequence('hashtags', 'id'), 1, false);
SELECT setval(pg_get_serial_sequence('bot_personas', 'id'), 1, false);

-- Verify tables are empty
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL SELECT 'recipes', COUNT(*) FROM recipes
UNION ALL SELECT 'log_posts', COUNT(*) FROM log_posts
UNION ALL SELECT 'bot_personas', COUNT(*) FROM bot_personas;

-- Note: After running this, you need to re-run Flyway migrations to re-seed bot_personas
-- The application will do this automatically on next startup
