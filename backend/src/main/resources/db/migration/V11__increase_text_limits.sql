-- =============================================================================
-- INCREASE TEXT FIELD LIMITS
-- Purpose: Increase character limits for various text fields
-- =============================================================================

-- -----------------------------------------------------------------------------
-- RECIPES TABLE
-- -----------------------------------------------------------------------------
-- title: 255 -> 200 (standardize)
ALTER TABLE recipes ALTER COLUMN title TYPE VARCHAR(200);

-- description: 500 -> 2000
ALTER TABLE recipes ALTER COLUMN description TYPE VARCHAR(2000);

-- change_reason: 200 -> 2000
ALTER TABLE recipes ALTER COLUMN change_reason TYPE VARCHAR(2000);

-- -----------------------------------------------------------------------------
-- RECIPE STEPS TABLE
-- -----------------------------------------------------------------------------
-- description: 500 -> 2000
ALTER TABLE recipe_steps ALTER COLUMN description TYPE VARCHAR(2000);

-- -----------------------------------------------------------------------------
-- LOG POSTS TABLE
-- -----------------------------------------------------------------------------
-- title: 500 -> 200 (standardize)
ALTER TABLE log_posts ALTER COLUMN title TYPE VARCHAR(200);

-- content: 500 -> 2000
ALTER TABLE log_posts ALTER COLUMN content TYPE VARCHAR(2000);
