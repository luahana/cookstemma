-- =============================================================================
-- CORE TABLES: Users, Authentication, Food Master Data
-- =============================================================================

-- -----------------------------------------------------------------------------
-- USERS
-- Purpose: User accounts including both human users and bot accounts
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    -- Identity
    username        VARCHAR(50) NOT NULL,
    email           VARCHAR(255),
    profile_image_url TEXT,

    -- Demographics
    gender          gender_type,
    birth_date      DATE,
    bio             VARCHAR(150),

    -- Social links
    youtube_url     TEXT,
    instagram_handle VARCHAR(30),

    -- Preferences
    locale          VARCHAR(10) NOT NULL DEFAULT 'en-US',
    measurement_preference VARCHAR(20) DEFAULT 'ORIGINAL',
    default_food_style VARCHAR(5),

    -- Authorization
    role            user_role NOT NULL DEFAULT 'USER',
    status          account_status NOT NULL DEFAULT 'ACTIVE',

    -- Bot identification
    is_bot          BOOLEAN NOT NULL DEFAULT FALSE,
    persona_id      BIGINT,  -- FK added after bot_personas table

    -- Social metrics (denormalized for performance)
    follower_count  INTEGER NOT NULL DEFAULT 0,
    following_count INTEGER NOT NULL DEFAULT 0,

    -- Consent tracking
    terms_accepted_at    TIMESTAMPTZ,
    terms_version        VARCHAR(20),
    privacy_accepted_at  TIMESTAMPTZ,
    privacy_version      VARCHAR(20),
    marketing_agreed     BOOLEAN NOT NULL DEFAULT FALSE,

    -- Session
    last_login_at        TIMESTAMPTZ,
    app_refresh_token    VARCHAR(512),

    -- Soft delete
    deleted_at           TIMESTAMPTZ,
    delete_scheduled_at  TIMESTAMPTZ,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT chk_users_follower_count CHECK (follower_count >= 0),
    CONSTRAINT chk_users_following_count CHECK (following_count >= 0)
);

COMMENT ON TABLE users IS 'User accounts including human users and bot accounts';
COMMENT ON COLUMN users.public_id IS 'UUID exposed to external APIs - never expose internal id';
COMMENT ON COLUMN users.locale IS 'User interface language (e.g., ko-KR, en-US)';
COMMENT ON COLUMN users.is_bot IS 'TRUE for automated bot accounts';
COMMENT ON COLUMN users.deleted_at IS 'Soft delete - NULL means active, timestamp means deleted';

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- SOCIAL ACCOUNTS
-- Purpose: OAuth provider connections for users
-- -----------------------------------------------------------------------------
CREATE TABLE social_accounts (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider        social_provider NOT NULL,
    provider_user_id VARCHAR(255) NOT NULL,
    email           VARCHAR(255),

    -- Tokens (encrypted at application level)
    access_token    TEXT,
    refresh_token   TEXT,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_social_provider_user UNIQUE (provider, provider_user_id)
);

COMMENT ON TABLE social_accounts IS 'OAuth provider connections for user authentication';

CREATE INDEX idx_social_accounts_user_id ON social_accounts(user_id);

CREATE TRIGGER trg_social_accounts_updated_at
    BEFORE UPDATE ON social_accounts
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- FOOD CATEGORIES
-- Purpose: Hierarchical food classification (3-level depth)
-- -----------------------------------------------------------------------------
CREATE TABLE food_categories (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    parent_id       BIGINT REFERENCES food_categories(id) ON DELETE RESTRICT,
    code            VARCHAR(50) NOT NULL UNIQUE,
    depth           INTEGER NOT NULL DEFAULT 1,

    -- Multilingual name {"ko-KR": "한식", "en-US": "Korean"}
    name            JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_food_categories_depth CHECK (depth BETWEEN 1 AND 3),
    CONSTRAINT chk_food_categories_name CHECK (jsonb_typeof(name) = 'object')
);

COMMENT ON TABLE food_categories IS 'Hierarchical food classification (DISH > Subcategory > Item)';
COMMENT ON COLUMN food_categories.name IS 'Multilingual: {"ko-KR": "한식", "en-US": "Korean"}';

CREATE INDEX idx_food_categories_parent ON food_categories(parent_id);
CREATE INDEX idx_food_categories_name_gin ON food_categories USING GIN(name);

CREATE TRIGGER trg_food_categories_updated_at
    BEFORE UPDATE ON food_categories
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- FOODS MASTER
-- Purpose: Master catalog of foods/ingredients with multilingual names
-- -----------------------------------------------------------------------------
CREATE TABLE foods_master (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    category_id     BIGINT REFERENCES food_categories(id) ON DELETE RESTRICT,

    -- Multilingual content
    name            JSONB NOT NULL DEFAULT '{}'::jsonb,
    description     JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Search optimization
    search_keywords TEXT,

    -- Ranking
    food_score      DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    is_verified     BOOLEAN NOT NULL DEFAULT TRUE,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_foods_master_name CHECK (jsonb_typeof(name) = 'object'),
    CONSTRAINT chk_foods_master_description CHECK (jsonb_typeof(description) = 'object')
);

COMMENT ON TABLE foods_master IS 'Master catalog of foods/ingredients';
COMMENT ON COLUMN foods_master.name IS 'Multilingual: {"ko-KR": "김치", "en-US": "Kimchi"}';
COMMENT ON COLUMN foods_master.food_score IS 'Popularity ranking score';

CREATE INDEX idx_foods_master_category ON foods_master(category_id);
CREATE INDEX idx_foods_master_name_gin ON foods_master USING GIN(name);
CREATE INDEX idx_foods_master_search_trgm ON foods_master USING GIN(search_keywords gin_trgm_ops);
CREATE INDEX idx_foods_master_score ON foods_master(food_score DESC);

CREATE TRIGGER trg_foods_master_updated_at
    BEFORE UPDATE ON foods_master
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- FOOD TAGS
-- Purpose: Tag definitions for categorizing foods (dietary, style, etc.)
-- -----------------------------------------------------------------------------
CREATE TABLE food_tags (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    tag_group       VARCHAR(20) NOT NULL,
    code            VARCHAR(50) NOT NULL UNIQUE,
    name            JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_food_tags_name CHECK (jsonb_typeof(name) = 'object')
);

COMMENT ON TABLE food_tags IS 'Tag definitions for food categorization';

CREATE INDEX idx_food_tags_group ON food_tags(tag_group);
CREATE INDEX idx_food_tags_name_gin ON food_tags USING GIN(name);

CREATE TRIGGER trg_food_tags_updated_at
    BEFORE UPDATE ON food_tags
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- -----------------------------------------------------------------------------
-- FOOD TAG MAP
-- Purpose: Many-to-many relationship between foods and tags
-- -----------------------------------------------------------------------------
CREATE TABLE food_tag_map (
    food_id         BIGINT NOT NULL REFERENCES foods_master(id) ON DELETE CASCADE,
    tag_id          BIGINT NOT NULL REFERENCES food_tags(id) ON DELETE CASCADE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (food_id, tag_id)
);

COMMENT ON TABLE food_tag_map IS 'Links foods to their tags';

CREATE INDEX idx_food_tag_map_tag ON food_tag_map(tag_id);

-- -----------------------------------------------------------------------------
-- USER SUGGESTED FOODS
-- Purpose: User submissions for new foods to be reviewed
-- -----------------------------------------------------------------------------
CREATE TABLE user_suggested_foods (
    id              BIGSERIAL PRIMARY KEY,
    public_id       UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

    user_id         BIGINT REFERENCES users(id) ON DELETE SET NULL,
    suggested_name  VARCHAR(100) NOT NULL,
    locale_code     VARCHAR(5) NOT NULL,

    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    master_food_id  BIGINT REFERENCES foods_master(id) ON DELETE SET NULL,

    -- Audit
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_user_suggested_foods_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

COMMENT ON TABLE user_suggested_foods IS 'User submissions for new food items';

CREATE INDEX idx_user_suggested_foods_status ON user_suggested_foods(status);
CREATE INDEX idx_user_suggested_foods_user ON user_suggested_foods(user_id);

CREATE TRIGGER trg_user_suggested_foods_updated_at
    BEFORE UPDATE ON user_suggested_foods
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
