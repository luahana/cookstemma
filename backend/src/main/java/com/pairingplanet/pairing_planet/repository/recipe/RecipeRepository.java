package com.pairingplanet.pairing_planet.repository.recipe;

import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RecipeRepository extends JpaRepository<Recipe, Long> {

    // [보안] publicId로 상세 조회 시, 음식 정보와 계보 정보를 한 번에 가져옴 (N+1 방지)
    @EntityGraph(attributePaths = {"foodMaster", "rootRecipe", "parentRecipe", "hashtags"})
    Optional<Recipe> findByPublicId(UUID publicId);

    @Query("SELECT r FROM Recipe r WHERE r.isDeleted = false AND r.isPrivate = false")
    Slice<Recipe> findPublicRecipes(Pageable pageable);

    // [계보 조회용] 특정 레시피로부터 직접 파생된 변형들
    List<Recipe> findByParentRecipeIdAndIsDeletedFalse(Long parentId);

    // [계보 조회용] 한 뿌리(Root) 아래의 모든 가족 레시피 조회
    List<Recipe> findByRootRecipeIdAndIsDeletedFalse(Long rootId);

    long countByCreatorIdAndIsDeletedFalse(Long creatorId);

    // [Home] 오리지널 레시피(Root) 중 로케일에 맞는 것만 슬라이스로 조회
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.culinaryLocale = :locale AND r.isDeleted = false")
    Slice<Recipe> findRootRecipesByLocale(@Param("locale") String locale, Pageable pageable);

    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NULL AND r.isDeleted = false")
    Slice<Recipe> findAllRootRecipes(Pageable pageable);

    // [Home] 최근 생성된 공개 레시피 5개
    List<Recipe> findTop5ByIsDeletedFalseAndIsPrivateFalseOrderByCreatedAtDesc();

    // [Home] 활발한 변형 트리 (가장 최근에 변형/로그가 발생한 오리지널 중심)
    @Query("""
        SELECT r FROM Recipe r 
        LEFT JOIN Recipe v ON v.rootRecipe = r 
        WHERE r.rootRecipe IS NULL AND r.isDeleted = false
        GROUP BY r.id 
        ORDER BY MAX(COALESCE(v.createdAt, r.createdAt)) DESC
    """)
    List<Recipe> findTrendingOriginals(Pageable pageable);

    // 특정 루트 레시피를 기준으로 생성된 모든 변형 레시피의 개수
    long countByRootRecipeIdAndIsDeletedFalse(Long rootId);

    // [추가] 음식 ID(Long)를 사용하는 레시피가 있는지 확인 (삭제 방지용 등)
    boolean existsByFoodMasterId(Long foodMasterId);


    // 2. [필터] 특정 로케일의 모든 공개 레시피 (에러 해결 지점)
    @Query("SELECT r FROM Recipe r WHERE r.culinaryLocale = :locale AND r.isDeleted = false AND r.isPrivate = false")
    Slice<Recipe> findPublicRecipesByLocale(@Param("locale") String locale, Pageable pageable);

    // [마이페이지] 내가 만든 레시피 (최신순)
    Slice<Recipe> findByCreatorIdAndIsDeletedFalseOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // [마이페이지] 내가 만든 오리지널 레시피 (parentRecipe가 없는 것)
    Slice<Recipe> findByCreatorIdAndIsDeletedFalseAndParentRecipeIsNullOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // [마이페이지] 내가 만든 변형 레시피 (parentRecipe가 있는 것)
    Slice<Recipe> findByCreatorIdAndIsDeletedFalseAndParentRecipeIsNotNullOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // [필터] 변형 레시피만 조회 (rootRecipe가 있는 레시피)
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.isDeleted = false AND r.isPrivate = false")
    Slice<Recipe> findOnlyVariantsPublic(Pageable pageable);

    // [필터] 특정 로케일의 변형 레시피만 조회
    @Query("SELECT r FROM Recipe r WHERE r.rootRecipe IS NOT NULL AND r.culinaryLocale = :locale AND r.isDeleted = false AND r.isPrivate = false")
    Slice<Recipe> findOnlyVariantsByLocale(@Param("locale") String locale, Pageable pageable);

    // [검색] pg_trgm 기반 레시피 검색 (제목, 설명, 재료명) - 퍼지 매칭 + 관련도 정렬
    @Query(value = """
        SELECT r.* FROM (
            SELECT DISTINCT ON (r2.id) r2.*,
                GREATEST(
                    COALESCE(SIMILARITY(r2.title, :keyword), 0),
                    COALESCE(SIMILARITY(r2.description, :keyword), 0)
                ) AS relevance_score
            FROM recipes r2
            LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r2.id
            WHERE r2.is_deleted = false AND r2.is_private = false
            AND (
                r2.title % :keyword
                OR r2.description % :keyword
                OR ri.name % :keyword
                OR r2.title ILIKE '%' || :keyword || '%'
                OR r2.description ILIKE '%' || :keyword || '%'
                OR ri.name ILIKE '%' || :keyword || '%'
            )
        ) r
        ORDER BY r.relevance_score DESC, r.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(DISTINCT r.id) FROM recipes r
        LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r.id
        WHERE r.is_deleted = false AND r.is_private = false
        AND (
            r.title % :keyword
            OR r.description % :keyword
            OR ri.name % :keyword
            OR r.title ILIKE '%' || :keyword || '%'
            OR r.description ILIKE '%' || :keyword || '%'
            OR ri.name ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    Slice<Recipe> searchRecipes(@Param("keyword") String keyword, Pageable pageable);
}