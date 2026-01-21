package com.cookstemma.cookstemma.repository.recipe;

import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RecipeRepository extends JpaRepository<Recipe, Long>, JpaSpecificationExecutor<Recipe> {

    // [보안] publicId로 상세 조회 시, 음식 정보와 계보 정보를 한 번에 가져옴 (N+1 방지)
    @EntityGraph(attributePaths = {"foodMaster", "rootRecipe", "parentRecipe", "hashtags", "images"})
    Optional<Recipe> findByPublicId(UUID publicId);

    @Query("SELECT r FROM Recipe r WHERE r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    Slice<Recipe> findPublicRecipes(Pageable pageable);

    // [계보 조회용] 특정 레시피로부터 직접 파생된 변형들
    List<Recipe> findByParentRecipeIdAndDeletedAtIsNull(Long parentId);

    // [계보 조회용] 한 뿌리(Root) 아래의 모든 가족 레시피 조회
    List<Recipe> findByRootRecipeIdAndDeletedAtIsNull(Long rootId);

    long countByCreatorIdAndDeletedAtIsNull(Long creatorId);

    // Count original recipes (no parent) created by user
    long countByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNull(Long creatorId);

    // Count variant recipes (has parent) created by user
    long countByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNotNull(Long creatorId);

    // [Home] 오리지널 레시피(Root) 중 로케일에 맞는 것만 슬라이스로 조회
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    Slice<Recipe> findRootRecipesByLocale(@Param("locale") String locale, Pageable pageable);

    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    Slice<Recipe> findAllRootRecipes(Pageable pageable);

    // [Home] 최근 생성된 공개 레시피 5개
    List<Recipe> findTop5ByDeletedAtIsNullAndIsPrivateFalseOrderByCreatedAtDesc();

    // [Home] 활발한 변형 트리 (가장 최근에 변형/로그가 발생한 오리지널 중심)
    @Query("""
        SELECT r FROM Recipe r 
        LEFT JOIN Recipe v ON v.rootRecipe = r 
        WHERE r.rootRecipe IS NULL AND r.deletedAt IS NULL
        GROUP BY r.id 
        ORDER BY MAX(COALESCE(v.createdAt, r.createdAt)) DESC
    """)
    List<Recipe> findTrendingOriginals(Pageable pageable);

    // 특정 루트 레시피를 기준으로 생성된 모든 변형 레시피의 개수
    long countByRootRecipeIdAndDeletedAtIsNull(Long rootId);

    // [수정/삭제 검증] 특정 레시피의 직접 자식 변형 개수 (parentRecipe로 참조하는 레시피)
    long countByParentRecipeIdAndDeletedAtIsNull(Long parentId);

    // [추가] 음식 ID(Long)를 사용하는 레시피가 있는지 확인 (삭제 방지용 등)
    boolean existsByFoodMasterId(Long foodMasterId);


    // 2. [필터] 특정 로케일의 모든 공개 레시피 (에러 해결 지점)
    @Query("SELECT r FROM Recipe r WHERE r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    Slice<Recipe> findPublicRecipesByLocale(@Param("locale") String locale, Pageable pageable);

    // [마이페이지] 내가 만든 레시피 (최신순)
    Slice<Recipe> findByCreatorIdAndDeletedAtIsNullOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // [마이페이지] 내가 만든 레시피 with visibility filter (최신순)
    Slice<Recipe> findByCreatorIdAndDeletedAtIsNullAndIsPrivateOrderByCreatedAtDesc(Long creatorId, Boolean isPrivate, Pageable pageable);

    // [마이페이지] 내가 만든 오리지널 레시피 (parentRecipe가 없는 것)
    Slice<Recipe> findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNullOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // [마이페이지] 내가 만든 오리지널 레시피 with visibility filter (parentRecipe가 없는 것)
    Slice<Recipe> findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNullAndIsPrivateOrderByCreatedAtDesc(Long creatorId, Boolean isPrivate, Pageable pageable);

    // [마이페이지] 내가 만든 변형 레시피 (parentRecipe가 있는 것)
    Slice<Recipe> findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNotNullOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // [마이페이지] 내가 만든 변형 레시피 with visibility filter (parentRecipe가 있는 것)
    Slice<Recipe> findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNotNullAndIsPrivateOrderByCreatedAtDesc(Long creatorId, Boolean isPrivate, Pageable pageable);

    // [필터] 변형 레시피만 조회 (rootRecipe가 있는 레시피)
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    Slice<Recipe> findOnlyVariantsPublic(Pageable pageable);

    // [필터] 특정 로케일의 변형 레시피만 조회
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    Slice<Recipe> findOnlyVariantsByLocale(@Param("locale") String locale, Pageable pageable);

    // [검색] pg_trgm 기반 레시피 검색 (제목, 설명, 재료명, 번역 필드 포함) - 퍼지 매칭 + 관련도 정렬
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM (
            SELECT DISTINCT ON (r2.id) r2.*,
                GREATEST(
                    COALESCE(SIMILARITY(r2.title, :keyword), 0),
                    COALESCE(SIMILARITY(r2.description, :keyword), 0),
                    COALESCE(SIMILARITY(jsonb_values_text(r2.title_translations), :keyword), 0),
                    COALESCE(SIMILARITY(jsonb_values_text(r2.description_translations), :keyword), 0),
                    COALESCE(SIMILARITY(jsonb_values_text(fm.name), :keyword), 0)
                ) AS relevance_score
            FROM recipes r2
            LEFT JOIN foods_master fm ON fm.id = r2.food_master_id
            LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r2.id
            LEFT JOIN recipe_steps rs ON rs.recipe_id = r2.id
            WHERE r2.deleted_at IS NULL AND (r2.is_private IS NULL OR r2.is_private = false)
            AND (SUBSTRING(r2.cooking_style FROM 1 FOR 2) = :langCode
                 OR jsonb_exists(r2.title_translations, :langCode))
            AND (
                -- Base fields
                r2.title % :keyword OR r2.title ILIKE '%' || :keyword || '%'
                OR r2.description % :keyword OR r2.description ILIKE '%' || :keyword || '%'
                -- Title translations
                OR jsonb_values_text(r2.title_translations) % :keyword
                OR jsonb_values_text(r2.title_translations) ILIKE '%' || :keyword || '%'
                -- Description translations
                OR jsonb_values_text(r2.description_translations) % :keyword
                OR jsonb_values_text(r2.description_translations) ILIKE '%' || :keyword || '%'
                -- FoodMaster name (all locales)
                OR jsonb_values_text(fm.name) % :keyword
                OR jsonb_values_text(fm.name) ILIKE '%' || :keyword || '%'
                -- Ingredients (base + translations)
                OR ri.name % :keyword OR ri.name ILIKE '%' || :keyword || '%'
                OR jsonb_values_text(ri.name_translations) % :keyword
                OR jsonb_values_text(ri.name_translations) ILIKE '%' || :keyword || '%'
                -- Steps (base + translations)
                OR rs.description % :keyword OR rs.description ILIKE '%' || :keyword || '%'
                OR jsonb_values_text(rs.description_translations) % :keyword
                OR jsonb_values_text(rs.description_translations) ILIKE '%' || :keyword || '%'
            )
        ) r
        ORDER BY r.relevance_score DESC, r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(DISTINCT r.id) FROM recipes r
        LEFT JOIN foods_master fm ON fm.id = r.food_master_id
        LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r.id
        LEFT JOIN recipe_steps rs ON rs.recipe_id = r.id
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        AND (
            r.title % :keyword OR r.title ILIKE '%' || :keyword || '%'
            OR r.description % :keyword OR r.description ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) % :keyword
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.description_translations) % :keyword
            OR jsonb_values_text(r.description_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(fm.name) % :keyword
            OR jsonb_values_text(fm.name) ILIKE '%' || :keyword || '%'
            OR ri.name % :keyword OR ri.name ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(ri.name_translations) % :keyword
            OR jsonb_values_text(ri.name_translations) ILIKE '%' || :keyword || '%'
            OR rs.description % :keyword OR rs.description ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(rs.description_translations) % :keyword
            OR jsonb_values_text(rs.description_translations) ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    Slice<Recipe> searchRecipes(@Param("keyword") String keyword, @Param("langCode") String langCode, Pageable pageable);

    // ==================== CURSOR-BASED PAGINATION ====================

    // [Cursor] All public recipes - initial page (no cursor)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findPublicRecipesWithCursorInitial(@Param("langCode") String langCode, Pageable pageable);

    // [Cursor] All public recipes - with cursor
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        AND (r.created_at < :cursorTime OR (r.created_at = :cursorTime AND r.id < :cursorId))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findPublicRecipesWithCursor(@Param("langCode") String langCode, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] Public recipes by locale - initial page
    @Query("SELECT r FROM Recipe r WHERE r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findPublicRecipesByLocaleWithCursorInitial(@Param("locale") String locale, Pageable pageable);

    // [Cursor] Public recipes by locale - with cursor
    @Query("SELECT r FROM Recipe r WHERE r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) " +
           "AND (r.createdAt < :cursorTime OR (r.createdAt = :cursorTime AND r.id < :cursorId)) " +
           "ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findPublicRecipesByLocaleWithCursor(@Param("locale") String locale, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] Only original recipes - initial page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.root_recipe_id IS NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findOriginalRecipesWithCursorInitial(@Param("langCode") String langCode, Pageable pageable);

    // [Cursor] Only original recipes - with cursor
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.root_recipe_id IS NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        AND (r.created_at < :cursorTime OR (r.created_at = :cursorTime AND r.id < :cursorId))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findOriginalRecipesWithCursor(@Param("langCode") String langCode, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] Only original recipes by locale - initial page
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findOriginalRecipesByLocaleWithCursorInitial(@Param("locale") String locale, Pageable pageable);

    // [Cursor] Only original recipes by locale - with cursor
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) " +
           "AND (r.createdAt < :cursorTime OR (r.createdAt = :cursorTime AND r.id < :cursorId)) " +
           "ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findOriginalRecipesByLocaleWithCursor(@Param("locale") String locale, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] Only variant recipes - initial page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.root_recipe_id IS NOT NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findVariantRecipesWithCursorInitial(@Param("langCode") String langCode, Pageable pageable);

    // [Cursor] Only variant recipes - with cursor
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.root_recipe_id IS NOT NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        AND (r.created_at < :cursorTime OR (r.created_at = :cursorTime AND r.id < :cursorId))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findVariantRecipesWithCursor(@Param("langCode") String langCode, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] Only variant recipes by locale - initial page
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findVariantRecipesByLocaleWithCursorInitial(@Param("locale") String locale, Pageable pageable);

    // [Cursor] Only variant recipes by locale - with cursor
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) " +
           "AND (r.createdAt < :cursorTime OR (r.createdAt = :cursorTime AND r.id < :cursorId)) " +
           "ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findVariantRecipesByLocaleWithCursor(@Param("locale") String locale, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] My recipes - initial page
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findMyRecipesWithCursorInitial(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Cursor] My recipes - with cursor
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL " +
           "AND (r.createdAt < :cursorTime OR (r.createdAt = :cursorTime AND r.id < :cursorId)) " +
           "ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findMyRecipesWithCursor(@Param("creatorId") Long creatorId, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] My original recipes - initial page
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL AND r.parentRecipe IS NULL ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findMyOriginalRecipesWithCursorInitial(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Cursor] My original recipes - with cursor
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL AND r.parentRecipe IS NULL " +
           "AND (r.createdAt < :cursorTime OR (r.createdAt = :cursorTime AND r.id < :cursorId)) " +
           "ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findMyOriginalRecipesWithCursor(@Param("creatorId") Long creatorId, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] My variant recipes - initial page
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL AND r.parentRecipe IS NOT NULL ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findMyVariantRecipesWithCursorInitial(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Cursor] My variant recipes - with cursor
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL AND r.parentRecipe IS NOT NULL " +
           "AND (r.createdAt < :cursorTime OR (r.createdAt = :cursorTime AND r.id < :cursorId)) " +
           "ORDER BY r.createdAt DESC, r.id DESC")
    Slice<Recipe> findMyVariantRecipesWithCursor(@Param("creatorId") Long creatorId, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // ==================== OFFSET-BASED PAGINATION (for Web) ====================

    // [Offset] All public recipes with Page (includes total count)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findPublicRecipesPage(@Param("langCode") String langCode, Pageable pageable);

    // [Offset] Public recipes by locale with Page
    @Query("SELECT r FROM Recipe r WHERE r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    org.springframework.data.domain.Page<Recipe> findPublicRecipesByLocalePage(@Param("locale") String locale, Pageable pageable);

    // [Offset] Only original recipes with Page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.root_recipe_id IS NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM recipes r
        WHERE r.root_recipe_id IS NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findOriginalRecipesPage(@Param("langCode") String langCode, Pageable pageable);

    // [Offset] Only original recipes by locale with Page
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    org.springframework.data.domain.Page<Recipe> findOriginalRecipesByLocalePage(@Param("locale") String locale, Pageable pageable);

    // [Offset] Only variant recipes with Page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        WHERE r.root_recipe_id IS NOT NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM recipes r
        WHERE r.root_recipe_id IS NOT NULL AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findVariantRecipesPage(@Param("langCode") String langCode, Pageable pageable);

    // [Offset] Only variant recipes by locale with Page
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.cookingStyle = :locale AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    org.springframework.data.domain.Page<Recipe> findVariantRecipesByLocalePage(@Param("locale") String locale, Pageable pageable);

    // [Offset] My recipes with Page
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL")
    org.springframework.data.domain.Page<Recipe> findMyRecipesPage(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Offset] My original recipes with Page
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL AND r.parentRecipe IS NULL")
    org.springframework.data.domain.Page<Recipe> findMyOriginalRecipesPage(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Offset] My variant recipes with Page
    @Query("SELECT r FROM Recipe r WHERE r.creatorId = :creatorId AND r.deletedAt IS NULL AND r.parentRecipe IS NOT NULL")
    org.springframework.data.domain.Page<Recipe> findMyVariantRecipesPage(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Offset] Search recipes with Page (includes total count for pagination UI, multi-language)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM (
            SELECT DISTINCT ON (r2.id) r2.*,
                GREATEST(
                    COALESCE(SIMILARITY(r2.title, :keyword), 0),
                    COALESCE(SIMILARITY(r2.description, :keyword), 0),
                    COALESCE(SIMILARITY(jsonb_values_text(r2.title_translations), :keyword), 0),
                    COALESCE(SIMILARITY(jsonb_values_text(r2.description_translations), :keyword), 0),
                    COALESCE(SIMILARITY(jsonb_values_text(fm.name), :keyword), 0)
                ) AS relevance_score
            FROM recipes r2
            LEFT JOIN foods_master fm ON fm.id = r2.food_master_id
            LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r2.id
            LEFT JOIN recipe_steps rs ON rs.recipe_id = r2.id
            WHERE r2.deleted_at IS NULL AND (r2.is_private IS NULL OR r2.is_private = false)
            AND (SUBSTRING(r2.cooking_style FROM 1 FOR 2) = :langCode
                 OR jsonb_exists(r2.title_translations, :langCode))
            AND (
                -- Base fields
                r2.title % :keyword OR r2.title ILIKE '%' || :keyword || '%'
                OR r2.description % :keyword OR r2.description ILIKE '%' || :keyword || '%'
                -- Title translations
                OR jsonb_values_text(r2.title_translations) % :keyword
                OR jsonb_values_text(r2.title_translations) ILIKE '%' || :keyword || '%'
                -- Description translations
                OR jsonb_values_text(r2.description_translations) % :keyword
                OR jsonb_values_text(r2.description_translations) ILIKE '%' || :keyword || '%'
                -- FoodMaster name (all locales)
                OR jsonb_values_text(fm.name) % :keyword
                OR jsonb_values_text(fm.name) ILIKE '%' || :keyword || '%'
                -- Ingredients (base + translations)
                OR ri.name % :keyword OR ri.name ILIKE '%' || :keyword || '%'
                OR jsonb_values_text(ri.name_translations) % :keyword
                OR jsonb_values_text(ri.name_translations) ILIKE '%' || :keyword || '%'
                -- Steps (base + translations)
                OR rs.description % :keyword OR rs.description ILIKE '%' || :keyword || '%'
                OR jsonb_values_text(rs.description_translations) % :keyword
                OR jsonb_values_text(rs.description_translations) ILIKE '%' || :keyword || '%'
            )
        ) r
        ORDER BY r.relevance_score DESC, r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(DISTINCT r.id) FROM recipes r
        LEFT JOIN foods_master fm ON fm.id = r.food_master_id
        LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r.id
        LEFT JOIN recipe_steps rs ON rs.recipe_id = r.id
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        AND (
            r.title % :keyword OR r.title ILIKE '%' || :keyword || '%'
            OR r.description % :keyword OR r.description ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) % :keyword
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.description_translations) % :keyword
            OR jsonb_values_text(r.description_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(fm.name) % :keyword
            OR jsonb_values_text(fm.name) ILIKE '%' || :keyword || '%'
            OR ri.name % :keyword OR ri.name ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(ri.name_translations) % :keyword
            OR jsonb_values_text(ri.name_translations) ILIKE '%' || :keyword || '%'
            OR rs.description % :keyword OR rs.description ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(rs.description_translations) % :keyword
            OR jsonb_values_text(rs.description_translations) ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> searchRecipesPage(@Param("keyword") String keyword, @Param("langCode") String langCode, Pageable pageable);

    // ================================================================
    // Sorted queries for View More navigation
    // ================================================================

    /**
     * Find recipes ordered by variant count (most forked/evolved).
     * Only returns root recipes (originals) that have the most variants.
     * Filters by translation availability: source locale matches OR translation exists
     */
    @Query(value = """
        SELECT r.* FROM recipes r
        LEFT JOIN (
            SELECT root_recipe_id, COUNT(*) as variant_count
            FROM recipes
            WHERE root_recipe_id IS NOT NULL AND deleted_at IS NULL
            GROUP BY root_recipe_id
        ) vc ON r.id = vc.root_recipe_id
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false) AND r.parent_recipe_id IS NULL
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY COALESCE(vc.variant_count, 0) DESC, r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false) AND r.parent_recipe_id IS NULL
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findRecipesOrderByVariantCount(@Param("langCode") String langCode, Pageable pageable);

    /**
     * Find recipes ordered by recent activity (trending).
     * Activity = variants + logs created in last 7 days.
     * Filters by translation availability: source locale matches OR translation exists
     */
    @Query(value = """
        SELECT r.* FROM recipes r
        LEFT JOIN (
            SELECT root_recipe_id, COUNT(*) as recent_variants
            FROM recipes
            WHERE root_recipe_id IS NOT NULL
            AND deleted_at IS NULL
            AND created_at > NOW() - INTERVAL '7 days'
            GROUP BY root_recipe_id
        ) rv ON r.id = rv.root_recipe_id
        LEFT JOIN (
            SELECT rl.recipe_id, COUNT(*) as recent_logs
            FROM recipe_logs rl
            JOIN log_posts lp ON rl.log_post_id = lp.id
            WHERE lp.created_at > NOW() - INTERVAL '7 days'
            GROUP BY rl.recipe_id
        ) rlc ON r.id = rlc.recipe_id
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false) AND r.parent_recipe_id IS NULL
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY (COALESCE(rv.recent_variants, 0) + COALESCE(rlc.recent_logs, 0)) DESC, r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false) AND r.parent_recipe_id IS NULL
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findRecipesOrderByTrending(@Param("langCode") String langCode, Pageable pageable);

    /**
     * Find recipes ordered by popularity score.
     * Score = viewCount * 1 + savedCount * 3 + variantCount * 5 + logCount * 2
     * Filters by translation availability: source locale matches OR translation exists
     */
    @Query(value = """
        SELECT r.* FROM recipes r
        LEFT JOIN (
            SELECT root_recipe_id, COUNT(*) as variant_count
            FROM recipes
            WHERE root_recipe_id IS NOT NULL AND deleted_at IS NULL
            GROUP BY root_recipe_id
        ) vc ON r.id = vc.root_recipe_id
        LEFT JOIN (
            SELECT rl.recipe_id, COUNT(*) as log_count
            FROM recipe_logs rl
            JOIN log_posts lp ON rl.log_post_id = lp.id
            WHERE lp.deleted_at IS NULL
            GROUP BY rl.recipe_id
        ) lc ON r.id = lc.recipe_id
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false) AND r.parent_recipe_id IS NULL
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY (COALESCE(r.view_count, 0) * 1 + COALESCE(r.saved_count, 0) * 3 + COALESCE(vc.variant_count, 0) * 5 + COALESCE(lc.log_count, 0) * 2) DESC,
                 r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM recipes r
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false) AND r.parent_recipe_id IS NULL
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findRecipesOrderByPopular(@Param("langCode") String langCode, Pageable pageable);

    // ==================== HASHTAG-BASED QUERIES ====================

    // [Cursor] Recipes by hashtag - initial page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        JOIN recipe_hashtag_map rh ON rh.recipe_id = r.id
        JOIN hashtags h ON h.id = rh.hashtag_id
        WHERE h.name = :hashtagName AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findByHashtagWithCursorInitial(
            @Param("hashtagName") String hashtagName,
            @Param("langCode") String langCode,
            Pageable pageable);

    // [Cursor] Recipes by hashtag - with cursor
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        JOIN recipe_hashtag_map rh ON rh.recipe_id = r.id
        JOIN hashtags h ON h.id = rh.hashtag_id
        WHERE h.name = :hashtagName AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        AND (r.created_at < :cursorTime OR (r.created_at = :cursorTime AND r.id < :cursorId))
        ORDER BY r.created_at DESC, r.id DESC
        """, nativeQuery = true)
    Slice<Recipe> findByHashtagWithCursor(
            @Param("hashtagName") String hashtagName,
            @Param("langCode") String langCode,
            @Param("cursorTime") Instant cursorTime,
            @Param("cursorId") Long cursorId,
            Pageable pageable);

    // [Offset] Recipes by hashtag - page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT r.* FROM recipes r
        JOIN recipe_hashtag_map rh ON rh.recipe_id = r.id
        JOIN hashtags h ON h.id = rh.hashtag_id
        WHERE h.name = :hashtagName AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        countQuery = """
        SELECT COUNT(r.id) FROM recipes r
        JOIN recipe_hashtag_map rh ON rh.recipe_id = r.id
        JOIN hashtags h ON h.id = rh.hashtag_id
        WHERE h.name = :hashtagName AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (SUBSTRING(r.cooking_style FROM 1 FOR 2) = :langCode
             OR jsonb_exists(r.title_translations, :langCode))
        """,
        nativeQuery = true)
    org.springframework.data.domain.Page<Recipe> findByHashtagPage(
            @Param("hashtagName") String hashtagName,
            @Param("langCode") String langCode,
            Pageable pageable);

    // Count recipes by hashtag (unfiltered - for hashtag display purposes)
    @Query("SELECT COUNT(r) FROM Recipe r JOIN r.hashtags h " +
           "WHERE h.name = :hashtagName AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    long countByHashtag(@Param("hashtagName") String hashtagName);

    // ==================== UNIFIED SEARCH COUNT ====================

    /**
     * Count recipes matching search keyword (for unified search chips, multi-language).
     */
    @Query(value = """
        SELECT COUNT(DISTINCT r.id) FROM recipes r
        LEFT JOIN foods_master fm ON fm.id = r.food_master_id
        LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r.id
        LEFT JOIN recipe_steps rs ON rs.recipe_id = r.id
        WHERE r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        AND (
            r.title % :keyword OR r.title ILIKE '%' || :keyword || '%'
            OR r.description % :keyword OR r.description ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) % :keyword
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.description_translations) % :keyword
            OR jsonb_values_text(r.description_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(fm.name) % :keyword
            OR jsonb_values_text(fm.name) ILIKE '%' || :keyword || '%'
            OR ri.name % :keyword OR ri.name ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(ri.name_translations) % :keyword
            OR jsonb_values_text(ri.name_translations) ILIKE '%' || :keyword || '%'
            OR rs.description % :keyword OR rs.description ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(rs.description_translations) % :keyword
            OR jsonb_values_text(rs.description_translations) ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    long countSearchResults(@Param("keyword") String keyword);
}