package com.cookstemma.cookstemma.repository.recipe;

import com.cookstemma.cookstemma.domain.entity.recipe.RecipeStep;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeStepRepository extends JpaRepository<RecipeStep, Long> {

    List<RecipeStep> findByRecipeIdOrderByStepNumberAsc(Long recipeId);

    // For recipe update: delete all steps before re-adding
    void deleteAllByRecipeId(Long recipeId);
}