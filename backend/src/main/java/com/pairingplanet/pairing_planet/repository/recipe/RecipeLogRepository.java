package com.pairingplanet.pairing_planet.repository.recipe;

import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RecipeLogRepository extends JpaRepository<RecipeLog, Long> {
    // 특정 레시피에 달린 모든 후기 로그 조회
    @Query("SELECT rl FROM RecipeLog rl JOIN FETCH rl.logPost WHERE rl.recipe.id = :recipeId")
    List<RecipeLog> findAllByRecipeId(@Param("recipeId") Long recipeId);

    /**
     * [해결] 특정 레시피 노드에 달린 로그 개수 조회
     * SQL: SELECT COUNT(*) FROM recipe_logs WHERE recipe_id = ?
     */
    long countByRecipeId(Long recipeId);

}