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
    preferred_dietary_id BIGINT,

    marketing_agreed BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_bot BOOLEAN NOT NULL DEFAULT FALSE,

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

    category_id BIGINT REFERENCES food_categories(id) ON DELETE RESTRICT,
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
CREATE UNIQUE INDEX IF NOT EXISTS uq_food_name_ko_kr ON foods_master ((name ->> 'ko-KR'));

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
--
-- CREATE TABLE IF NOT EXISTS context_dimensions (
--                                                   id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                                   public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--     name VARCHAR(50) NOT NULL UNIQUE,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
--     );
--
--
-- CREATE TABLE IF NOT EXISTS context_tags (
--                                             id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                             public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     dimension_id BIGINT NOT NULL REFERENCES context_dimensions(id) ON DELETE CASCADE,
--     tag_name VARCHAR(50) NOT NULL, -- 시스템 내부 코드 (예: "vegan")
--
--     display_names JSONB NOT NULL DEFAULT '{}',
--
--     display_orders JSONB NOT NULL DEFAULT '{}',
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     -- 한 디멘션 내에서 동일한 내부 태그명 중복 방지
--     CONSTRAINT unique_tag_per_dimension UNIQUE (dimension_id, tag_name)
--     );
--
-- CREATE INDEX IF NOT EXISTS idx_context_tags_names_gin ON context_tags USING GIN (display_names);
--
-- CREATE TABLE IF NOT EXISTS pairing_map (
--                                            id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                            public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     food1_master_id BIGINT NOT NULL REFERENCES foods_master(id) ON DELETE CASCADE,
--     food2_master_id BIGINT REFERENCES foods_master(id) ON DELETE CASCADE,
--
--     when_context_id BIGINT REFERENCES context_tags(id),
--     dietary_context_id BIGINT REFERENCES context_tags(id),
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     CONSTRAINT chk_food_order CHECK (food1_master_id < food2_master_id),
--     CONSTRAINT chk_food_not_same CHECK (food1_master_id <> food2_master_id)
--     );
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_pairing_def_safe ON pairing_map (
--     food1_master_id,
--     food2_master_id,
--     COALESCE(when_context_id, -1),
--     COALESCE(dietary_context_id, -1)
--     );
-- CREATE INDEX IF NOT EXISTS idx_pairing_food2 ON pairing_map (food2_master_id);
-- CREATE INDEX IF NOT EXISTS idx_pairing_when ON pairing_map (when_context_id);
-- CREATE INDEX IF NOT EXISTS idx_pairing_dietary ON pairing_map (dietary_context_id);
--
-- CREATE TABLE IF NOT EXISTS pairing_locale_stats (
--                                                     id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                                     public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     pairing_id BIGINT NOT NULL REFERENCES pairing_map(id) ON DELETE CASCADE,
--     locale VARCHAR(10) NOT NULL,
--
--     genius_count INT DEFAULT 0,
--     daring_count INT DEFAULT 0,
--     picky_count  INT DEFAULT 0,
--     saved_count INT DEFAULT 0,
--     comment_count INT DEFAULT 0,
--
--     popularity_score DOUBLE PRECISION GENERATED ALWAYS AS (
--                                                               CASE
--                                                               WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
--     ELSE (
-- (genius_count * 1.0) +
-- (comment_count * 3.0) +
-- (saved_count * 5.0)
--     )
--     * (
--     (genius_count + (picky_count * 0.5))::DOUBLE PRECISION / (genius_count + daring_count + picky_count)
--     )
--     END
--     ) STORED,
--
--     controversy_score DOUBLE PRECISION GENERATED ALWAYS AS (
--                                                                CASE
--                                                                WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
--     ELSE
-- (genius_count + daring_count + picky_count)::DOUBLE PRECISION / (ABS(genius_count - daring_count) + 1)
--     END
--     ) STORED,
--
--     trending_score DOUBLE PRECISION DEFAULT 0.0,
--     score_updated_at TIMESTAMP WITH TIME ZONE,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     CONSTRAINT uk_pairing_locale UNIQUE (pairing_id, locale),
--     CONSTRAINT uk_pairing_locale_public_id UNIQUE (public_id)
--     );
-- CREATE INDEX IF NOT EXISTS idx_stats_locale_trending ON pairing_locale_stats (locale, trending_score DESC);
-- CREATE INDEX IF NOT EXISTS idx_stats_locale_popular ON pairing_locale_stats (locale, popularity_score DESC);
-- CREATE INDEX IF NOT EXISTS idx_stats_locale_controversial ON pairing_locale_stats (locale, controversy_score DESC);
-- CREATE INDEX IF NOT EXISTS idx_trending_controversial_filtered ON pairing_locale_stats (locale, trending_score DESC) WHERE controversy_score >= 2.0;
--
-- CREATE TABLE IF NOT EXISTS search_histories (
--                                                 id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                                 public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     pairing_id BIGINT NOT NULL REFERENCES pairing_map(id) ON DELETE CASCADE,
--
--     -- 같은 유저가 동일한 조합을 검색할 경우 하나만 유지하기 위한 유니크 제약
--     CONSTRAINT uq_user_pairing UNIQUE (user_id, pairing_id),
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
--     );
--
-- CREATE INDEX IF NOT EXISTS idx_search_history_user ON search_histories (user_id, updated_at DESC);
--
--
-- CREATE TABLE IF NOT EXISTS posts (
--                                      id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                      public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     dtype VARCHAR(31) NOT NULL,
--
--     pairing_id BIGINT NOT NULL REFERENCES pairing_map(id),
--     locale VARCHAR(10) NOT NULL,
--
--     title           TEXT,
--     content         TEXT,
--
--     genius_count    INT DEFAULT 0,
--     daring_count    INT DEFAULT 0,
--     picky_count     INT DEFAULT 0,
--     saved_count     INT DEFAULT 0,
--     comment_count   INT DEFAULT 0,
--
--     is_private       BOOLEAN NOT NULL DEFAULT FALSE,
--     is_deleted       BOOLEAN NOT NULL DEFAULT FALSE,
--
--     popularity_score DOUBLE PRECISION GENERATED ALWAYS AS (
--                                                               CASE
--                                                               WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
--     ELSE (
-- (genius_count * 1.0) +
-- (comment_count * 3.0) +
-- (saved_count * 5.0)
--     )
--     * (
--     (genius_count + (picky_count * 0.5))::DOUBLE PRECISION / (genius_count + daring_count + picky_count)
--     )
--     END
--     ) STORED,
--
--     controversy_score DOUBLE PRECISION GENERATED ALWAYS AS (
--                                                                CASE
--                                                                WHEN (genius_count + daring_count + picky_count) = 0 THEN 0.0
--     ELSE
-- (genius_count + daring_count + picky_count)::DOUBLE PRECISION / (ABS(genius_count - daring_count) + 1)
--     END
--     ) STORED,
--
--     creator_id BIGINT NOT NULL REFERENCES users(id),
--     comments_enabled BOOLEAN NOT NULL DEFAULT TRUE,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
--     );
-- CREATE INDEX IF NOT EXISTS idx_posts_cursor ON posts (pairing_id, created_at DESC, id DESC);
-- CREATE INDEX IF NOT EXISTS idx_posts_creator_created ON posts (creator_id, created_at DESC);
-- CREATE INDEX IF NOT EXISTS idx_posts_locale_created_at ON posts (locale, created_at DESC);
-- CREATE INDEX IF NOT EXISTS idx_posts_locale_controversy ON posts (locale, controversy_score DESC);
-- CREATE INDEX IF NOT EXISTS idx_post_locale_popularity ON posts (locale, popularity_score DESC);

DO $$ BEGIN
CREATE TYPE image_status AS ENUM ('ACTIVE', 'DELETED', 'PROCESSING');
CREATE TYPE image_type AS ENUM ('THUMBNAIL', 'STEP', 'LOG', 'COVER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 1. 해시태그 마스터
CREATE TABLE IF NOT EXISTS hashtags (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

-- 2. 로그 포스트 (일상/후기 기본 테이블)
CREATE TABLE IF NOT EXISTS log_posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    locale VARCHAR(10) NOT NULL,
    title TEXT,
    content TEXT,
    saved_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    creator_id BIGINT NOT NULL REFERENCES users(id),
    comments_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

-- 3. 레시피 상세 (버전 관리 제거, 단일 행 구조)
CREATE TABLE IF NOT EXISTS recipes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    food1_master_id BIGINT NOT NULL REFERENCES foods_master(id),
    culinary_locale VARCHAR(10) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    cooking_time INTEGER,
    difficulty VARCHAR(20),
    saved_count INT DEFAULT 0,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    -- 계보 관리 (단일 ID 참조)
    root_recipe_id BIGINT REFERENCES recipes(id),
    parent_recipe_id BIGINT REFERENCES recipes(id),
    change_category VARCHAR(50),

    creator_id BIGINT NOT NULL REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );

-- 4. 이미지 (통합 관리)
CREATE TABLE IF NOT EXISTS images (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    stored_filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    log_post_id BIGINT REFERENCES log_posts(id) ON DELETE SET NULL,
    recipe_id BIGINT REFERENCES recipes(id) ON DELETE SET NULL,
    status image_status NOT NULL DEFAULT 'PROCESSING', -- [개선] Enum 사용
    type image_type NOT NULL,                           -- [개선] Enum 사용
    display_order INTEGER NOT NULL DEFAULT 0,           -- [추가] 정렬용 필드
    uploader_id BIGINT NOT NULL REFERENCES users(id),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_image_target CHECK (
        (log_post_id IS NOT NULL AND recipe_id IS NULL) OR
        (log_post_id IS NULL AND recipe_id IS NOT NULL) OR
        (recipe_id IS NULL AND log_post_id IS NULL)
    )
    );

-- 5. 매핑 테이블 (해시태그)
CREATE TABLE IF NOT EXISTS recipe_hashtag_map (
    recipe_id BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    hashtag_id BIGINT NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (recipe_id, hashtag_id) -- [수정] 끝에 있던 잘못된 쉼표 제거
    );

CREATE TABLE IF NOT EXISTS log_post_hashtag_map (
    log_post_id BIGINT NOT NULL REFERENCES log_posts(id) ON DELETE CASCADE,
    hashtag_id BIGINT NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (log_post_id, hashtag_id)
    );

-- 6. 레시피 하위 요소 (재료/단계)
CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT REFERENCES recipes(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    amount VARCHAR(50),
    type VARCHAR(20),
    display_order INTEGER DEFAULT 0
    );

CREATE TABLE IF NOT EXISTS recipe_steps (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT REFERENCES recipes(id) ON DELETE CASCADE,
    -- [수정] version 컬럼 제거 (사용하지 않기로 함)
    step_number INTEGER NOT NULL,
    description TEXT NOT NULL,
    image_id BIGINT REFERENCES images(id) ON DELETE SET NULL
    );

-- 7. 레시피 로그 (연결)
CREATE TABLE IF NOT EXISTS recipe_logs (
    log_post_id BIGINT PRIMARY KEY REFERENCES log_posts(id) ON DELETE CASCADE,
    recipe_id BIGINT NOT NULL REFERENCES recipes(id),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5)
    );

-- 조회 성능을 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_recipes_root ON recipes(root_recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipes_parent ON recipes(parent_recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_logs_target ON recipe_logs(recipe_id);

CREATE INDEX IF NOT EXISTS idx_recipes_creator ON recipes(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recipes_locale ON recipes(culinary_locale);

CREATE INDEX IF NOT EXISTS idx_log_posts_creator ON log_posts(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_log_posts_locale ON log_posts(locale);

CREATE INDEX IF NOT EXISTS idx_recipe_hashtag_tag ON recipe_hashtag_map(hashtag_id);

CREATE INDEX IF NOT EXISTS idx_recipes_discovery ON recipes(is_deleted, is_private, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_images_recipe_order ON images(recipe_id, display_order) WHERE recipe_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_images_log_order ON images(log_post_id, display_order) WHERE log_post_id IS NOT NULL;

-- 이벤트 트래킹 테이블 생성
CREATE TABLE IF NOT EXISTS analytics_events (
                                  id BIGSERIAL PRIMARY KEY,
                                  event_id UUID UNIQUE NOT NULL,      -- 중복 수집 방지(Idempotency)를 위한 식별자
                                  event_type VARCHAR(100) NOT NULL,   -- recipeViewed, logCreated 등
                                  user_id UUID,                       -- 익명 사용자인 경우 NULL 허용
                                  recipe_id UUID,                     -- 관련 레시피 (선택)
                                  log_id UUID,                        -- 관련 로그 (선택)
                                  timestamp TIMESTAMPTZ NOT NULL,     -- 이벤트 발생 시각 (기기 기준)
                                  properties JSONB,                   -- 상세 속성 (Rating, 길이 등 가변 데이터)
                                  created_at TIMESTAMPTZ DEFAULT NOW() -- 서버 수신 시각
);

-- 검색 성능 최적화를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON analytics_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_user ON analytics_events(user_id) WHERE user_id IS NOT NULL;


-- CREATE TABLE IF NOT EXISTS post_verdicts (
--                                              user_id BIGINT REFERENCES users(id),
--     post_id BIGINT REFERENCES posts(id),
--
--     verdict_type VARCHAR(10) CHECK (verdict_type IN ('GENIUS', 'DARING', 'PICKY')),
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     PRIMARY KEY (user_id, post_id)
--     );
-- CREATE INDEX IF NOT EXISTS idx_post_verdicts_post_id ON post_verdicts (post_id);
--
-- CREATE TABLE IF NOT EXISTS comments (
--                                         id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                         public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     post_id BIGINT REFERENCES posts(id),
--     user_id BIGINT REFERENCES users(id),
--     parent_id BIGINT REFERENCES comments(id),
--
--     content TEXT NOT NULL,
--
--     initial_verdict VARCHAR(10) CHECK (initial_verdict IN ('GENIUS', 'DARING', 'PICKY')),
--     current_verdict VARCHAR(10) CHECK (current_verdict IN ('GENIUS', 'DARING', 'PICKY')),
--
--     like_count INT DEFAULT 0,
--     is_deleted BOOLEAN DEFAULT FALSE,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
--     );
-- CREATE INDEX IF NOT EXISTS idx_comments_default ON comments (post_id, parent_id, created_at DESC, id DESC);
-- CREATE INDEX IF NOT EXISTS idx_comments_filter ON comments (post_id, parent_id, current_verdict, created_at DESC, id DESC);
-- CREATE INDEX IF NOT EXISTS idx_comments_best ON comments (post_id, parent_id, like_count DESC);
--
-- CREATE TABLE IF NOT EXISTS comment_likes (
--                                              user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
--     comment_id BIGINT REFERENCES comments(id) ON DELETE CASCADE,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     PRIMARY KEY (user_id, comment_id)
--     );
--
-- CREATE TABLE IF NOT EXISTS saved_posts (
--                                            user_id BIGINT REFERENCES users(id),
--     post_id BIGINT REFERENCES posts(id),
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     PRIMARY KEY (user_id, post_id)
--     );
--
-- CREATE TABLE IF NOT EXISTS search_index (
--                                             id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                             public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     target_id BIGINT NOT NULL,
--     target_type VARCHAR(20) NOT NULL,
--
--     keyword TEXT NOT NULL,
--     locale_code VARCHAR(10) NOT NULL,
--
--     icon_url TEXT,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--
--     CONSTRAINT uq_search_target UNIQUE (target_id, target_type, keyword, locale_code)
--     );
-- CREATE INDEX IF NOT EXISTS idx_search_keyword ON search_index USING GIN (keyword gin_trgm_ops);
--
-- CREATE TABLE IF NOT EXISTS notifications (
--                                              id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--                                              public_id UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
--
--     recipient_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     sender_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
--
--     type VARCHAR(50) NOT NULL,
--     reference_id BIGINT,
--     is_read BOOLEAN DEFAULT FALSE,
--
--     updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
--     created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
--     );
-- CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (recipient_id) WHERE is_read = FALSE;
--
-- CREATE TABLE IF NOT EXISTS pairing_stats_snapshot (
--                                                       pairing_id BIGINT NOT NULL,
--                                                       locale VARCHAR(10) NOT NULL,
--
--     last_genius_count INT DEFAULT 0,
--     last_picky_count INT DEFAULT 0,
--     last_comment_count INT DEFAULT 0,
--     last_saved_count INT DEFAULT 0,
--
--     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--     PRIMARY KEY (pairing_id, locale)
--     );

-- ALTER TABLE users
--     ADD CONSTRAINT fk_users_preferred_dietary
--         FOREIGN KEY (preferred_dietary_id) REFERENCES context_tags(id);