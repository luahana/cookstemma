package com.pairingplanet.pairing_planet.repository.recipe;

import com.pairingplanet.pairing_planet.domain.entity.recipe.SavedRecipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.SavedRecipeId;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SavedRecipeRepository extends JpaRepository<SavedRecipe, SavedRecipeId> {

    boolean existsByUserIdAndRecipeId(Long userId, Long recipeId);

    @Modifying
    @Query("DELETE FROM SavedRecipe sr WHERE sr.userId = :userId AND sr.recipeId = :recipeId")
    void deleteByUserIdAndRecipeId(@Param("userId") Long userId, @Param("recipeId") Long recipeId);

    @Query("SELECT sr FROM SavedRecipe sr JOIN FETCH sr.recipe r WHERE sr.userId = :userId AND r.isDeleted = false ORDER BY sr.createdAt DESC")
    Slice<SavedRecipe> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);

    long countByRecipeId(Long recipeId);

    // 사용자가 저장한 레시피 개수
    long countByUserId(Long userId);
}
