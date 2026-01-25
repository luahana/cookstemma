package com.cookstemma.cookstemma.repository.image;

import com.cookstemma.cookstemma.domain.entity.image.RecipeImage;
import com.cookstemma.cookstemma.domain.entity.image.RecipeImageId;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

/**
 * Repository for the Recipe-Image join table.
 * Manages the many-to-many relationship between recipes and cover images,
 * allowing images to be shared across multiple recipes (e.g., variants).
 */
public interface RecipeImageRepository extends JpaRepository<RecipeImage, RecipeImageId> {

    /**
     * Find all recipe-image mappings for a recipe, ordered by display order.
     */
    List<RecipeImage> findByRecipeOrderByDisplayOrderAsc(Recipe recipe);

    /**
     * Find all recipe-image mappings for a recipe by recipe ID.
     */
    List<RecipeImage> findByRecipeIdOrderByDisplayOrderAsc(Long recipeId);

    /**
     * Delete all image mappings for a recipe.
     */
    @Modifying
    @Query("DELETE FROM RecipeImage ri WHERE ri.recipe = :recipe")
    void deleteByRecipe(@Param("recipe") Recipe recipe);

    /**
     * Delete all image mappings for a recipe by recipe ID.
     */
    @Modifying
    @Query("DELETE FROM RecipeImage ri WHERE ri.recipe.id = :recipeId")
    void deleteByRecipeId(@Param("recipeId") Long recipeId);

    /**
     * Check if a recipe-image mapping exists.
     */
    boolean existsByRecipeAndImageId(Recipe recipe, Long imageId);

    /**
     * Check if an image is used by any recipe.
     */
    boolean existsByImageId(Long imageId);

    /**
     * Count how many recipes use a specific image.
     */
    long countByImageId(Long imageId);

    /**
     * Find all recipes that use a specific image.
     */
    @Query("SELECT ri.recipe FROM RecipeImage ri WHERE ri.image.id = :imageId")
    List<Recipe> findRecipesByImageId(@Param("imageId") Long imageId);

    /**
     * Find all recipe-image mappings for an image by image public ID.
     */
    @Query("SELECT ri FROM RecipeImage ri WHERE ri.image.publicId = :imagePublicId")
    List<RecipeImage> findByImagePublicId(@Param("imagePublicId") UUID imagePublicId);
}
