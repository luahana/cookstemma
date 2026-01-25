package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.recipe.SavedRecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class SavedRecipeServiceTest extends BaseIntegrationTest {

    @Autowired
    private SavedRecipeService savedRecipeService;

    @Autowired
    private SavedRecipeRepository savedRecipeRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private Recipe testRecipe;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        FoodMaster food = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(food);

        testRecipe = Recipe.builder()
                .title("Test Recipe")
                .description("Test Description")
                .cookingStyle("ko-KR")
                .foodMaster(food)
                .creatorId(testUser.getId())
                .build();
        recipeRepository.save(testRecipe);
    }

    @Nested
    @DisplayName("Save Recipe (Bookmark)")
    class SaveRecipeTests {

        @Test
        @DisplayName("Should save recipe and increment saved count")
        void saveRecipe_NewSave_IncrementsCount() {
            savedRecipeService.saveRecipe(testRecipe.getPublicId(), testUser.getId());

            assertThat(savedRecipeRepository.existsByUserIdAndRecipeId(testUser.getId(), testRecipe.getId()))
                    .isTrue();

            Recipe updated = recipeRepository.findById(testRecipe.getId()).orElseThrow();
            assertThat(updated.getSavedCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should not duplicate save or increment count on repeat")
        void saveRecipe_AlreadySaved_NoChange() {
            savedRecipeService.saveRecipe(testRecipe.getPublicId(), testUser.getId());
            savedRecipeService.saveRecipe(testRecipe.getPublicId(), testUser.getId()); // Duplicate

            Recipe updated = recipeRepository.findById(testRecipe.getId()).orElseThrow();
            assertThat(updated.getSavedCount()).isEqualTo(1); // Still 1
        }
    }

    @Nested
    @DisplayName("Unsave Recipe")
    class UnsaveRecipeTests {

        @Test
        @DisplayName("Should unsave recipe and decrement saved count")
        void unsaveRecipe_Saved_DecrementsCount() {
            savedRecipeService.saveRecipe(testRecipe.getPublicId(), testUser.getId());
            savedRecipeService.unsaveRecipe(testRecipe.getPublicId(), testUser.getId());

            assertThat(savedRecipeRepository.existsByUserIdAndRecipeId(testUser.getId(), testRecipe.getId()))
                    .isFalse();

            Recipe updated = recipeRepository.findById(testRecipe.getId()).orElseThrow();
            assertThat(updated.getSavedCount()).isEqualTo(0);
        }

        @Test
        @DisplayName("Should handle unsave of not-saved recipe gracefully")
        void unsaveRecipe_NotSaved_NoError() {
            // Should not throw
            savedRecipeService.unsaveRecipe(testRecipe.getPublicId(), testUser.getId());

            Recipe updated = recipeRepository.findById(testRecipe.getId()).orElseThrow();
            assertThat(updated.getSavedCount()).isGreaterThanOrEqualTo(0);
        }
    }

    @Nested
    @DisplayName("Check if Saved")
    class IsSavedTests {

        @Test
        @DisplayName("Should return true when recipe is saved")
        void isSavedByUser_Saved_ReturnsTrue() {
            savedRecipeService.saveRecipe(testRecipe.getPublicId(), testUser.getId());

            boolean result = savedRecipeService.isSavedByUser(testRecipe.getId(), testUser.getId());

            assertThat(result).isTrue();
        }

        @Test
        @DisplayName("Should return false when recipe is not saved")
        void isSavedByUser_NotSaved_ReturnsFalse() {
            boolean result = savedRecipeService.isSavedByUser(testRecipe.getId(), testUser.getId());

            assertThat(result).isFalse();
        }
    }
}
