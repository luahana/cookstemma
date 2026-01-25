-- =============================================================================
-- CONTENT TABLES: Recipes, Log Posts, Images
-- =============================================================================

-- -----------------------------------------------------------------------------
-- RECIPES
-- Purpose: User-created recipes with variation/fork relationships
-- -----------------------------------------------------------------------------
CREATE TABLE recipes (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- Creator
    creator_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Main food reference
    food_master_id  BIGINT NOT NULL REFERENCES foods_master(id) ON DELETE RESTRICT,

    -- Content
    cooking_style   VARCHAR(15) NOT NULL,  -- ISO country code or 'international'
    title           VARCHAR(255) NOT NULL,
    description     VARCHAR(500),

    -- Cooking details
    cooking_time_range cooking_time_range DEFAULT 'MIN_30_TO_60',
    servings        INTEGER NOT NULL DEFAULT 2,

    -- Recipe genealogy (for forks/variations)
    root_recipe_id   BIGINT REFERENCES recipes(id) ON DELETE SET NULL,
    parent_recipe_id BIGINT REFERENCES recipes(id) ON DELETE SET NULL,

    -- Change tracking
    change_category  VARCHAR(50),
    change_reason    VARCHAR(200),
    change_diff      JSONB,
    change_categories JSONB,  -- Array of change types

    -- Metrics (denormalized)
    saved_count     INTEGER NOT NULL DEFAULT 0,
    view_count      INTEGER NOT NULL DEFAULT 0,

    -- Visibility
    is_private      BOOLEAN NOT NULL DEFAULT FALSE,

    -- Translation support
    title_translations JSONB DEFAULT '{}',
    description_translations JSONB DEFAULT '{}',

    -- Soft delete (standardized pattern)
    deleted_at      TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by_id   BIGINT REFERENCES users(id),

    -- Constraints
    CONSTRAINT chk_recipes_saved_count CHECK (saved_count >= 0),
    CONSTRAINT chk_recipes_view_count CHECK (view_count >= 0),
    CONSTRAINT chk_recipes_servings CHECK (servings > 0)
);

COMMENT ON TABLE recipes IS 'User-created recipes with variation/fork relationships';
COMMENT ON COLUMN recipes.cooking_style IS 'Cuisine style: ISO country code (KR, US, JP, etc.) or international';
COMMENT ON COLUMN recipes.root_recipe_id IS 'Original recipe this was forked from (NULL if original)';
COMMENT ON COLUMN recipes.parent_recipe_id IS 'Immediate parent in variation chain';
COMMENT ON COLUMN recipes.change_diff IS 'JSON diff showing modifications from parent';
COMMENT ON COLUMN recipes.deleted_at IS 'Soft delete timestamp - NULL means active';
COMMENT ON COLUMN recipes.title_translations IS 'Translated titles: {"en": "...", "ja": "...", ...}';
COMMENT ON COLUMN recipes.description_translations IS 'Translated descriptions: {"en": "...", "ja": "...", ...}';

-- Performance indexes
CREATE INDEX idx_recipes_creator ON recipes(creator_id, created_at DESC);
CREATE INDEX idx_recipes_food_master ON recipes(food_master_id);
CREATE INDEX idx_recipes_cooking_style ON recipes(cooking_style);
CREATE INDEX idx_recipes_root ON recipes(root_recipe_id) WHERE root_recipe_id IS NOT NULL;
CREATE INDEX idx_recipes_parent ON recipes(parent_recipe_id) WHERE parent_recipe_id IS NOT NULL;
CREATE INDEX idx_recipes_discovery ON recipes(cooking_style, created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;
CREATE INDEX idx_recipes_title_trgm ON recipes USING GIN(title gin_trgm_ops);
CREATE INDEX idx_recipes_change_categories ON recipes USING GIN(change_categories);
CREATE INDEX idx_recipes_title_trans ON recipes USING GIN(title_translations jsonb_path_ops);
CREATE INDEX idx_recipes_desc_trans ON recipes USING GIN(description_translations jsonb_path_ops);
CREATE INDEX idx_recipes_view_count ON recipes(view_count DESC);
CREATE INDEX idx_recipes_saved_count ON recipes(saved_count DESC);

CREATE TRIGGER trg_recipes_updated_at
    BEFORE UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- RECIPE INGREDIENTS
-- Purpose: Ingredients list for each recipe
-- -----------------------------------------------------------------------------
CREATE TABLE recipe_ingredients (
    id              BIGSERIAL PRIMARY KEY,

    recipe_id       BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,

    -- Ingredient info
    name            VARCHAR(100) NOT NULL,

    -- Structured measurement
    quantity        DOUBLE PRECISION,
    unit            measurement_unit,

    type            ingredient_type,
    display_order   INTEGER NOT NULL DEFAULT 0,

    -- Translation support
    name_translations JSONB DEFAULT '{}'
);

COMMENT ON TABLE recipe_ingredients IS 'Ingredients list for recipes';
COMMENT ON COLUMN recipe_ingredients.quantity IS 'Numeric quantity for structured measurement';
COMMENT ON COLUMN recipe_ingredients.unit IS 'Standardized measurement unit';
COMMENT ON COLUMN recipe_ingredients.name_translations IS 'Translated ingredient names: {"en": "...", "ja": "...", ...}';

CREATE INDEX idx_recipe_ingredients_recipe ON recipe_ingredients(recipe_id);
CREATE INDEX idx_recipe_ingredients_name_trgm ON recipe_ingredients USING GIN(name gin_trgm_ops);
CREATE INDEX idx_recipe_ingredients_unit ON recipe_ingredients(unit) WHERE unit IS NOT NULL;

-- -----------------------------------------------------------------------------
-- RECIPE STEPS
-- Purpose: Cooking instructions for each recipe
-- -----------------------------------------------------------------------------
CREATE TABLE recipe_steps (
    id              BIGSERIAL PRIMARY KEY,

    recipe_id       BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    step_number     INTEGER NOT NULL,
    description     VARCHAR(500) NOT NULL,

    image_id        BIGINT,  -- FK added after images table

    -- Translation support
    description_translations JSONB DEFAULT '{}'
);

COMMENT ON TABLE recipe_steps IS 'Step-by-step cooking instructions';
COMMENT ON COLUMN recipe_steps.description_translations IS 'Translated step descriptions: {"en": "...", "ja": "...", ...}';

CREATE INDEX idx_recipe_steps_recipe ON recipe_steps(recipe_id, step_number);

-- -----------------------------------------------------------------------------
-- LOG POSTS
-- Purpose: User's cooking diary/log entries
-- -----------------------------------------------------------------------------
CREATE TABLE log_posts (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    creator_id      BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Content
    locale          VARCHAR(10) NOT NULL,
    title           VARCHAR(500),
    content         VARCHAR(500),

    -- Settings
    comments_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    is_private      BOOLEAN NOT NULL DEFAULT FALSE,

    -- Metrics
    saved_count     INTEGER NOT NULL DEFAULT 0,
    comment_count   INTEGER NOT NULL DEFAULT 0,
    view_count      INTEGER NOT NULL DEFAULT 0,

    -- Translation support
    title_translations JSONB DEFAULT '{}',
    content_translations JSONB DEFAULT '{}',

    -- Soft delete
    deleted_at      TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by_id   BIGINT REFERENCES users(id),

    CONSTRAINT chk_log_posts_saved_count CHECK (saved_count >= 0),
    CONSTRAINT chk_log_posts_comment_count CHECK (comment_count >= 0),
    CONSTRAINT chk_log_posts_view_count CHECK (view_count >= 0)
);

COMMENT ON TABLE log_posts IS 'User cooking diary/log entries';
COMMENT ON COLUMN log_posts.deleted_at IS 'Soft delete timestamp - NULL means active';
COMMENT ON COLUMN log_posts.title_translations IS 'Translated titles: {"en": "...", "ja": "...", ...}';
COMMENT ON COLUMN log_posts.content_translations IS 'Translated content: {"en": "...", "ja": "...", ...}';

CREATE INDEX idx_log_posts_creator ON log_posts(creator_id, created_at DESC);
CREATE INDEX idx_log_posts_locale ON log_posts(locale);
CREATE INDEX idx_log_posts_discovery ON log_posts(deleted_at, is_private, locale, created_at DESC)
    WHERE deleted_at IS NULL AND is_private = FALSE;
CREATE INDEX idx_log_posts_title_trans ON log_posts USING GIN(title_translations jsonb_path_ops);
CREATE INDEX idx_log_posts_content_trans ON log_posts USING GIN(content_translations jsonb_path_ops);
CREATE INDEX idx_log_posts_view_count ON log_posts(view_count DESC);
CREATE INDEX idx_log_posts_saved_count ON log_posts(saved_count DESC);

CREATE TRIGGER trg_log_posts_updated_at
    BEFORE UPDATE ON log_posts
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- RECIPE LOGS
-- Purpose: Links log posts to recipes with rating
-- -----------------------------------------------------------------------------
CREATE TABLE recipe_logs (
    log_post_id     BIGINT PRIMARY KEY REFERENCES log_posts(id) ON DELETE CASCADE,
    recipe_id       BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,

    rating          INTEGER NOT NULL,

    CONSTRAINT chk_recipe_logs_rating CHECK (rating >= 1 AND rating <= 5)
);

COMMENT ON TABLE recipe_logs IS 'Links log posts to recipes with star rating (1-5)';

CREATE INDEX idx_recipe_logs_recipe ON recipe_logs(recipe_id);
CREATE INDEX idx_recipe_logs_rating ON recipe_logs(rating);

-- -----------------------------------------------------------------------------
-- IMAGES
-- Purpose: All uploaded images with variant support
-- -----------------------------------------------------------------------------
CREATE TABLE images (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- File info
    stored_filename  VARCHAR(255),
    original_filename VARCHAR(255),
    width           INTEGER,
    height          INTEGER,
    file_size       BIGINT,
    format          VARCHAR(10),

    -- Status
    status          image_status NOT NULL DEFAULT 'PROCESSING',
    type            image_type,
    display_order   INTEGER NOT NULL DEFAULT 0,

    -- Variant support
    variant_type    image_variant,
    original_image_id BIGINT REFERENCES images(id) ON DELETE CASCADE,

    -- Ownership (polymorphic - only one should be set)
    log_post_id     BIGINT REFERENCES log_posts(id) ON DELETE SET NULL,
    recipe_id       BIGINT REFERENCES recipes(id) ON DELETE SET NULL,
    uploader_id     BIGINT REFERENCES users(id) ON DELETE SET NULL,

    -- Soft delete
    deleted_at      TIMESTAMPTZ,
    delete_scheduled_at TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by_id   BIGINT REFERENCES users(id),

    -- At least one parent reference required (except for orphaned uploads)
    CONSTRAINT chk_images_has_parent CHECK (
        log_post_id IS NOT NULL OR
        recipe_id IS NOT NULL OR
        original_image_id IS NOT NULL OR
        status = 'PROCESSING'  -- Allow temporarily orphaned during upload
    )
);

COMMENT ON TABLE images IS 'All uploaded images with variant support (thumbnails, etc.)';
COMMENT ON COLUMN images.variant_type IS 'Size variant: ORIGINAL, LARGE_1200, MEDIUM_800, etc.';
COMMENT ON COLUMN images.original_image_id IS 'For variants, reference to the original image';
COMMENT ON COLUMN images.deleted_at IS 'Soft delete timestamp';

CREATE INDEX idx_images_recipe ON images(recipe_id, display_order) WHERE recipe_id IS NOT NULL;
CREATE INDEX idx_images_log_post ON images(log_post_id, display_order) WHERE log_post_id IS NOT NULL;
CREATE INDEX idx_images_original ON images(original_image_id) WHERE original_image_id IS NOT NULL;
CREATE INDEX idx_images_variant ON images(original_image_id, variant_type);
CREATE INDEX idx_images_uploader ON images(uploader_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_images_delete_scheduled ON images(delete_scheduled_at) WHERE deleted_at IS NOT NULL;

CREATE TRIGGER trg_images_updated_at
    BEFORE UPDATE ON images
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Add FK from recipe_steps to images
ALTER TABLE recipe_steps
    ADD CONSTRAINT fk_recipe_steps_image
    FOREIGN KEY (image_id) REFERENCES images(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- HASHTAGS
-- Purpose: Tag definitions for content
-- -----------------------------------------------------------------------------
CREATE TABLE hashtags (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    name            VARCHAR(50) NOT NULL UNIQUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hashtags IS 'Hashtag definitions for recipes and logs';

-- -----------------------------------------------------------------------------
-- RECIPE HASHTAG MAP
-- -----------------------------------------------------------------------------
CREATE TABLE recipe_hashtag_map (
    recipe_id       BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    hashtag_id      BIGINT NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,

    PRIMARY KEY (recipe_id, hashtag_id)
);

CREATE INDEX idx_recipe_hashtag_map_hashtag ON recipe_hashtag_map(hashtag_id);

-- -----------------------------------------------------------------------------
-- LOG POST HASHTAG MAP
-- -----------------------------------------------------------------------------
CREATE TABLE log_post_hashtag_map (
    log_post_id     BIGINT NOT NULL REFERENCES log_posts(id) ON DELETE CASCADE,
    hashtag_id      BIGINT NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,

    PRIMARY KEY (log_post_id, hashtag_id)
);

CREATE INDEX idx_log_post_hashtag_map_hashtag ON log_post_hashtag_map(hashtag_id);

-- -----------------------------------------------------------------------------
-- SAVED RECIPES
-- Purpose: User bookmarks for recipes
-- -----------------------------------------------------------------------------
CREATE TABLE saved_recipes (
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id       BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, recipe_id)
);

COMMENT ON TABLE saved_recipes IS 'User bookmarked recipes';

CREATE INDEX idx_saved_recipes_user ON saved_recipes(user_id, created_at DESC);
CREATE INDEX idx_saved_recipes_recipe ON saved_recipes(recipe_id);

-- -----------------------------------------------------------------------------
-- SAVED LOGS
-- Purpose: User bookmarks for log posts
-- -----------------------------------------------------------------------------
CREATE TABLE saved_logs (
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_post_id     BIGINT NOT NULL REFERENCES log_posts(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, log_post_id)
);

COMMENT ON TABLE saved_logs IS 'User bookmarked log posts';

CREATE INDEX idx_saved_logs_user ON saved_logs(user_id, created_at DESC);
CREATE INDEX idx_saved_logs_log ON saved_logs(log_post_id);
