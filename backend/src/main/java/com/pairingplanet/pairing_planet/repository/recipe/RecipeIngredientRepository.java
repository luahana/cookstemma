package com.pairingplanet.pairing_planet.repository.recipe;

import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeIngredient;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecipeIngredientRepository extends JpaRepository<RecipeIngredient, Long> {

    List<RecipeIngredient> findByRecipeIdOrderByDisplayOrderAsc(Long recipeId);
}