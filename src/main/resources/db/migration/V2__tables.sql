DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS search_index CASCADE;
DROP TABLE IF EXISTS saved_posts CASCADE;
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS post_verdicts CASCADE;
DROP TABLE IF EXISTS images CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS pairing_locale_stats CASCADE;
DROP TABLE IF EXISTS pairing_map CASCADE;
DROP TABLE IF EXISTS context_tags CASCADE;
DROP TABLE IF EXISTS context_dimensions CASCADE;
DROP TABLE IF EXISTS user_suggested_foods CASCADE;
DROP TABLE IF EXISTS foods_master CASCADE;
DROP TABLE IF EXISTS food_categories CASCADE;
DROP TABLE IF EXISTS social_accounts CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS pairing_stats_snapshot CASCADE;

-- 2. Create Tables
CREATE TABLE IF NOT EXISTS users (
                                     id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                     public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    username VARCHAR(50) NOT NULL UNIQUE,
    profile_image_url TEXT,
    email VARCHAR(255),

    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    birth_date DATE,
    locale VARCHAR(10) NOT NULL,

    role VARCHAR(20) DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN', 'CREATOR')),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BANNED', 'DELETED')),

    marketing_agreed BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP WITH TIME ZONE,

                                app_refresh_token VARCHAR(512),

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

CREATE TABLE IF NOT EXISTS social_accounts (
                                               id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                               public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    provider VARCHAR(20) NOT NULL CHECK (provider IN ('GOOGLE', 'NAVER', 'KAKAO', 'APPLE')),
    provider_user_id VARCHAR(255) NOT NULL,

    email VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    UNIQUE(provider, provider_user_id)
    );
CREATE INDEX IF NOT EXISTS idx_social_user_id ON social_accounts(user_id);

CREATE TABLE IF NOT EXISTS food_categories (
                                               id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                               public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    parent_id BIGINT REFERENCES food_categories(id),
    code VARCHAR(50) UNIQUE NOT NULL,
    depth INT DEFAULT 1,
    name JSONB NOT NULL DEFAULT '{}',

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_food_categories_parent ON food_categories (parent_id);
CREATE INDEX IF NOT EXISTS idx_food_categories_name_gin ON food_categories USING GIN (name);

CREATE TABLE IF NOT EXISTS foods_master (
                                            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                            public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    category_id BIGINT NOT NULL REFERENCES food_categories(id) ON DELETE RESTRICT,
    name JSONB NOT NULL DEFAULT '{}',
    description JSONB DEFAULT '{}',
    search_keywords TEXT,
    food_score DOUBLE PRECISION DEFAULT 0.0,

    is_verified BOOLEAN NOT NULL DEFAULT TRUE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_foods_master_category ON foods_master (category_id);
CREATE INDEX IF NOT EXISTS idx_foods_master_name_gin ON foods_master USING GIN (name);
CREATE INDEX IF NOT EXISTS idx_foods_master_search_gin ON foods_master USING GIN (search_keywords gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_food_popularity ON foods_master (food_score DESC);

CREATE TABLE IF NOT EXISTS food_tags (
                                         id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                         public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    tag_group VARCHAR(20) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,

    name JSONB NOT NULL DEFAULT '{}',

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_food_tags_group ON food_tags (tag_group);
CREATE INDEX IF NOT EXISTS idx_food_tags_name_gin ON food_tags USING GIN (name);

CREATE TABLE IF NOT EXISTS food_tag_map (
                                            food_id BIGINT NOT NULL,
                                            tag_id BIGINT NOT NULL,

                                            updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    PRIMARY KEY (food_id, tag_id),

    CONSTRAINT fk_food FOREIGN KEY (food_id) REFERENCES foods_master(id) ON DELETE CASCADE,
    CONSTRAINT fk_tag FOREIGN KEY (tag_id) REFERENCES food_tags(id) ON DELETE CASCADE
    );
CREATE INDEX IF NOT EXISTS idx_food_tag_map_tag_id ON food_tag_map (tag_id);

CREATE TABLE IF NOT EXISTS user_suggested_foods (
                                                    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                                    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    suggested_name VARCHAR(100) NOT NULL,
    locale_code VARCHAR(5) NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(id),

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    master_food_id_ref BIGINT REFERENCES foods_master(id) ON DELETE SET NULL,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_user_suggested_status ON user_suggested_foods (status, created_at DESC);

CREATE TABLE IF NOT EXISTS context_dimensions (
                                                  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                                  public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

CREATE TABLE IF NOT EXISTS context_tags (
                                            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                            public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    dimension_id BIGINT NOT NULL REFERENCES context_dimensions(id) ON DELETE CASCADE,
    tag_name VARCHAR(50) NOT NULL,
    display_name VARCHAR(50) NOT NULL,
    locale VARCHAR(10) NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT unique_tag_locale UNIQUE (dimension_id, tag_name, locale)
    );

CREATE TABLE IF NOT EXISTS pairing_map (
                                           id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                           public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    food1_master_id BIGINT NOT NULL REFERENCES foods_master(id) ON DELETE CASCADE,
    food2_master_id BIGINT REFERENCES foods_master(id) ON DELETE CASCADE,

    when_context_id BIGINT REFERENCES context_tags(id),
    dietary_context_id BIGINT REFERENCES context_tags(id),

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_food_order CHECK (food1_master_id < food2_master_id),
    CONSTRAINT chk_food_not_same CHECK (food1_master_id <> food2_master_id)
    );
CREATE UNIQUE INDEX IF NOT EXISTS uq_pairing_def_safe ON pairing_map (
    food1_master_id,
    food2_master_id,
    COALESCE(when_context_id, -1),
    COALESCE(dietary_context_id, -1)
    );
CREATE INDEX IF NOT EXISTS idx_pairing_food2 ON pairing_map (food2_master_id);
CREATE INDEX IF NOT EXISTS idx_pairing_when ON pairing_map (when_context_id);
CREATE INDEX IF NOT EXISTS idx_pairing_dietary ON pairing_map (dietary_context_id);

CREATE TABLE IF NOT EXISTS pairing_locale_stats (
                                                    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                                    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    pairing_id BIGINT NOT NULL REFERENCES pairing_map(id) ON DELETE CASCADE,
    locale VARCHAR(10) NOT NULL,

    genius_count INT DEFAULT 0,
    daring_count INT DEFAULT 0,
    picky_count  INT DEFAULT 0,
    saved_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,

    popularity_score DOUBLE PRECISION GENERATED ALWAYS AS (
                                                              CASE
                                                              WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
    ELSE (
(genius_count * 1.0) +
(comment_count * 3.0) +
(saved_count * 5.0)
    )
    * (
    (genius_count + (picky_count * 0.5))::DOUBLE PRECISION / (genius_count + daring_count + picky_count)
    )
    END
    ) STORED,

    controversy_score DOUBLE PRECISION GENERATED ALWAYS AS (
                                                               CASE
                                                               WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
    ELSE
(genius_count + daring_count + picky_count)::DOUBLE PRECISION / (ABS(genius_count - daring_count) + 1)
    END
    ) STORED,

    trending_score DOUBLE PRECISION DEFAULT 0.0,
    score_updated_at TIMESTAMP WITH TIME ZONE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT uk_pairing_locale UNIQUE (pairing_id, locale),
    CONSTRAINT uk_pairing_locale_public_id UNIQUE (public_id)
    );
CREATE INDEX IF NOT EXISTS idx_stats_locale_trending ON pairing_locale_stats (locale, trending_score DESC);
CREATE INDEX IF NOT EXISTS idx_stats_locale_popular ON pairing_locale_stats (locale, popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_stats_locale_controversial ON pairing_locale_stats (locale, controversy_score DESC);
CREATE INDEX IF NOT EXISTS idx_trending_controversial_filtered ON pairing_locale_stats (locale, trending_score DESC) WHERE controversy_score >= 2.0;

-- [수정된 부분] posts 테이블 (USING 구문 제거)
CREATE TABLE IF NOT EXISTS posts (
                                     id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                     public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    dtype VARCHAR(31) NOT NULL,

    pairing_id BIGINT NOT NULL REFERENCES pairing_map(id),
    locale VARCHAR(10) NOT NULL,

    content         TEXT,
    image_urls      TEXT[],

    title           TEXT,

    genius_count    INT DEFAULT 0,
    daring_count    INT DEFAULT 0,
    picky_count     INT DEFAULT 0,
    saved_count     INT DEFAULT 0,
    comment_count   INT DEFAULT 0,

    cooking_time INTEGER,
    difficulty INTEGER, -- [수정] 단순 INTEGER 타입 선언만 해야 합니다.
    ingredients TEXT,
    recipe_data JSONB,

    is_private       BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted       BOOLEAN NOT NULL DEFAULT FALSE,

    popularity_score DOUBLE PRECISION GENERATED ALWAYS AS (
                                                              CASE
                                                              WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
    ELSE (
(genius_count * 1.0) +
(comment_count * 3.0) +
(saved_count * 5.0)
    )
    * (
    (genius_count + (picky_count * 0.5))::DOUBLE PRECISION / (genius_count + daring_count + picky_count)
    )
    END
    ) STORED,

    controversy_score DOUBLE PRECISION GENERATED ALWAYS AS (
                                                               CASE
                                                               WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
    ELSE
(genius_count + daring_count + picky_count)::DOUBLE PRECISION / (ABS(genius_count - daring_count) + 1)
    END
    ) STORED,

    creator_id BIGINT NOT NULL REFERENCES users(id),
    verdict_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    comments_enabled BOOLEAN NOT NULL DEFAULT TRUE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_posts_cursor ON posts (pairing_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_posts_creator_created ON posts (creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_locale_created_at ON posts (locale, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_locale_controversy ON posts (locale, controversy_score DESC);
CREATE INDEX IF NOT EXISTS idx_post_locale_popularity ON posts (locale, popularity_score DESC);
CREATE INDEX IF NOT EXISTS idx_posts_recipe_data ON posts USING GIN (recipe_data);

CREATE TABLE IF NOT EXISTS post_verdicts (
                                             user_id BIGINT REFERENCES users(id),
    post_id BIGINT REFERENCES posts(id),

    verdict_type VARCHAR(10) CHECK (verdict_type IN ('GENIUS', 'DARING', 'PICKY')),

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, post_id)
    );
CREATE INDEX IF NOT EXISTS idx_post_verdicts_post_id ON post_verdicts (post_id);

CREATE TABLE IF NOT EXISTS comments (
                                        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                        public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    post_id BIGINT REFERENCES posts(id),
    user_id BIGINT REFERENCES users(id),
    parent_id BIGINT REFERENCES comments(id),

    content TEXT NOT NULL,

    initial_verdict VARCHAR(10) CHECK (initial_verdict IN ('GENIUS', 'DARING', 'PICKY')),
    current_verdict VARCHAR(10) CHECK (current_verdict IN ('GENIUS', 'DARING', 'PICKY')),

    like_count INT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_comments_default ON comments (post_id, parent_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_comments_filter ON comments (post_id, parent_id, current_verdict, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_comments_best ON comments (post_id, parent_id, like_count DESC);

CREATE TABLE IF NOT EXISTS comment_likes (
                                             user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    comment_id BIGINT REFERENCES comments(id) ON DELETE CASCADE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, comment_id)
    );

CREATE TABLE IF NOT EXISTS saved_posts (
                                           user_id BIGINT REFERENCES users(id),
    post_id BIGINT REFERENCES posts(id),

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    PRIMARY KEY (user_id, post_id)
    );

CREATE TABLE IF NOT EXISTS search_index (
                                            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                            public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    target_id BIGINT NOT NULL,
    target_type VARCHAR(20) NOT NULL,

    keyword TEXT NOT NULL,
    locale_code VARCHAR(10) NOT NULL,

    icon_url TEXT,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_search_target UNIQUE (target_id, target_type, keyword, locale_code)
    );
CREATE INDEX IF NOT EXISTS idx_search_keyword ON search_index USING GIN (keyword gin_trgm_ops);

CREATE TABLE IF NOT EXISTS notifications (
                                             id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                             public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    recipient_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_id BIGINT REFERENCES users(id) ON DELETE CASCADE,

    type VARCHAR(50) NOT NULL,
    reference_id BIGINT,
    is_read BOOLEAN DEFAULT FALSE,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (recipient_id) WHERE is_read = FALSE;

CREATE TABLE IF NOT EXISTS pairing_stats_snapshot (
                                                      pairing_id BIGINT NOT NULL,
                                                      locale VARCHAR(10) NOT NULL,

    last_genius_count INT DEFAULT 0,
    last_picky_count INT DEFAULT 0,
    last_comment_count INT DEFAULT 0,
    last_saved_count INT DEFAULT 0,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (pairing_id, locale)
    );

-- [추가됨] images 테이블
CREATE TABLE IF NOT EXISTS images (
                                      id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                      public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),

    stored_filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,

    status VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,

    uploader_id BIGINT NOT NULL,
    post_id BIGINT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT fk_images_post FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE SET NULL
    );

CREATE INDEX IF NOT EXISTS idx_images_status_created_at ON images (status, created_at);
CREATE INDEX IF NOT EXISTS idx_images_type ON images (type);
CREATE INDEX IF NOT EXISTS idx_images_post_id ON images (post_id);