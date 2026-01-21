package com.cookstemma.cookstemma.repository.recipe;

import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;

import java.time.LocalDate;
import java.util.List;

public interface RecipeLogRepository extends JpaRepository<RecipeLog, Long> {
    // 특정 레시피에 달린 모든 후기 로그 조회
    @Query("SELECT rl FROM RecipeLog rl JOIN FETCH rl.logPost WHERE rl.recipe.id = :recipeId")
    List<RecipeLog> findAllByRecipeId(@Param("recipeId") Long recipeId);

    // 특정 레시피에 달린 로그 조회 (페이지네이션)
    @Query("SELECT rl FROM RecipeLog rl JOIN FETCH rl.logPost lp WHERE rl.recipe.id = :recipeId AND lp.deletedAt IS NULL ORDER BY lp.createdAt DESC")
    Slice<RecipeLog> findByRecipeIdOrderByCreatedAtDesc(@Param("recipeId") Long recipeId, Pageable pageable);

    /**
     * [해결] 특정 레시피 노드에 달린 로그 개수 조회
     * SQL: SELECT COUNT(*) FROM recipe_logs WHERE recipe_id = ?
     */
    long countByRecipeId(Long recipeId);

    // ===== Cooking DNA Stats Queries =====

    /**
     * Count logs by rating for a user (1-5 stars)
     */
    @Query("""
        SELECT rl.rating, COUNT(rl)
        FROM RecipeLog rl
        JOIN rl.logPost lp
        WHERE lp.creatorId = :userId AND lp.deletedAt IS NULL
        GROUP BY rl.rating
        """)
    List<Object[]> countByRatingForUser(@Param("userId") Long userId);

    /**
     * Get average rating for a user
     */
    @Query("SELECT AVG(CAST(rl.rating AS double)) FROM RecipeLog rl JOIN rl.logPost lp WHERE lp.creatorId = :userId AND lp.deletedAt IS NULL")
    Double getAverageRatingForUser(@Param("userId") Long userId);

    /**
     * Get cuisine distribution for a user (category code and count)
     */
    @Query(value = """
        SELECT fc.code as category_code, COUNT(*) as count
        FROM recipe_logs rl
        JOIN log_posts lp ON rl.log_post_id = lp.id
        JOIN recipes r ON rl.recipe_id = r.id
        JOIN foods_master fm ON r.food_master_id = fm.id
        LEFT JOIN food_categories fc ON fm.category_id = fc.id
        WHERE lp.creator_id = :userId AND lp.deleted_at IS NULL
        GROUP BY fc.code
        ORDER BY count DESC
        """, nativeQuery = true)
    List<Object[]> getCuisineDistributionForUser(@Param("userId") Long userId);

    /**
     * Get distinct cooking dates for a user (for streak calculation)
     */
    @Query(value = """
        SELECT DISTINCT DATE(lp.created_at) as cook_date
        FROM recipe_logs rl
        JOIN log_posts lp ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :userId AND lp.deleted_at IS NULL
        ORDER BY cook_date DESC
        """, nativeQuery = true)
    List<java.sql.Date> getCookingDatesForUser(@Param("userId") Long userId);

    /**
     * Sum of ratings received on recipes created by a user (when others log their recipes).
     * This calculates XP for recipe authors when others cook their recipes.
     */
    @Query(value = """
        SELECT COALESCE(SUM(rl.rating), 0)
        FROM recipe_logs rl
        JOIN log_posts lp ON rl.log_post_id = lp.id
        JOIN recipes r ON rl.recipe_id = r.id
        WHERE r.creator_id = :userId
        AND lp.creator_id != :userId
        AND lp.deleted_at IS NULL
        AND r.deleted_at IS NULL
        """, nativeQuery = true)
    int sumRatingsReceivedOnUserRecipes(@Param("userId") Long userId);

    /**
     * Count logs created by a user (for log creator XP).
     */
    @Query("""
        SELECT COUNT(rl)
        FROM RecipeLog rl
        JOIN rl.logPost lp
        WHERE lp.creatorId = :userId AND lp.deletedAt IS NULL
        """)
    long countLogsCreatedByUser(@Param("userId") Long userId);

}