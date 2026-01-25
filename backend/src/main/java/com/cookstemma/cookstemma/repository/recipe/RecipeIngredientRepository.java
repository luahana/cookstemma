package com.cookstemma.cookstemma.repository.recipe;

import com.cookstemma.cookstemma.domain.entity.recipe.RecipeIngredient;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeIngredientRepository extends JpaRepository<RecipeIngredient, Long> {

    List<RecipeIngredient> findByRecipeIdOrderByDisplayOrderAsc(Long recipeId);

    // For recipe update: delete all ingredients before re-adding
    void deleteAllByRecipeId(Long recipeId);
}