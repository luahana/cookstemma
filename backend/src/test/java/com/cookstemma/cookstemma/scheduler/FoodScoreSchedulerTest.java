package com.cookstemma.cookstemma.scheduler;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class FoodScoreSchedulerTest extends BaseIntegrationTest {

    @Autowired
    private FoodScoreScheduler foodScoreScheduler;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private EntityManager entityManager;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser("scheduler_test_user", "en-US");
    }

    private void flushAndClear() {
        entityManager.flush();
        entityManager.clear();
    }

    @Nested
    @DisplayName("updateFoodPopularity")
    class UpdateFoodPopularityTests {

        @Test
        @DisplayName("Should execute without SQL errors using recipes table")
        void updateFoodPopularity_ExecutesWithoutErrors() {
            // Given
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of("en-US", "Test Food"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.save(food);
            flushAndClear();

            // When & Then - should not throw BadSqlGrammarException
            foodScoreScheduler.updateFoodPopularity();
        }

        @Test
        @DisplayName("Should update food_score based on recipe count")
        void updateFoodPopularity_UpdatesScoreBasedOnRecipeCount() {
            // Given - Create a food with 3 recipes
            FoodMaster popularFood = FoodMaster.builder()
                    .name(Map.of("en-US", "Popular Food"))
                    .isVerified(true)
                    .foodScore(0.0)
                    .build();
            foodMasterRepository.save(popularFood);
            Long foodId = popularFood.getId();

            for (int i = 0; i < 3; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .description("Description " + i)
                        .cookingStyle("en-US")
                        .originalLanguage("en-US")
                        .foodMaster(popularFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }
            flushAndClear();

            // When
            foodScoreScheduler.updateFoodPopularity();
            flushAndClear();

            // Then - score should be 3 * 10 = 30
            FoodMaster updatedFood = foodMasterRepository.findById(foodId).orElseThrow();
            assertThat(updatedFood.getFoodScore()).isEqualTo(30.0);
        }

        @Test
        @DisplayName("Should not count deleted recipes")
        void updateFoodPopularity_ExcludesDeletedRecipes() {
            // Given - Create a food with 2 active recipes and 1 deleted recipe
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of("en-US", "Food with deleted recipes"))
                    .isVerified(true)
                    .foodScore(0.0)
                    .build();
            foodMasterRepository.save(food);
            Long foodId = food.getId();

            // Create 2 active recipes
            for (int i = 0; i < 2; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Active Recipe " + i)
                        .description("Description " + i)
                        .cookingStyle("en-US")
                        .originalLanguage("en-US")
                        .foodMaster(food)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 1 deleted recipe
            Recipe deletedRecipe = Recipe.builder()
                    .title("Deleted Recipe")
                    .description("This recipe is deleted")
                    .cookingStyle("en-US")
                    .originalLanguage("en-US")
                    .foodMaster(food)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(deletedRecipe);
            deletedRecipe.softDelete();
            recipeRepository.save(deletedRecipe);
            flushAndClear();

            // When
            foodScoreScheduler.updateFoodPopularity();
            flushAndClear();

            // Then - score should be 2 * 10 = 20 (deleted recipe not counted)
            FoodMaster updatedFood = foodMasterRepository.findById(foodId).orElseThrow();
            assertThat(updatedFood.getFoodScore()).isEqualTo(20.0);
        }

        @Test
        @DisplayName("Should handle food with no recipes")
        void updateFoodPopularity_FoodWithNoRecipes_ScoreUnchanged() {
            // Given - Create a food with no recipes
            FoodMaster food = FoodMaster.builder()
                    .name(Map.of("en-US", "Unpopular Food"))
                    .isVerified(true)
                    .foodScore(0.0)
                    .build();
            foodMasterRepository.save(food);
            Long foodId = food.getId();
            flushAndClear();

            // When
            foodScoreScheduler.updateFoodPopularity();
            flushAndClear();

            // Then - score should remain 0 (no update happens for foods without recipes)
            FoodMaster updatedFood = foodMasterRepository.findById(foodId).orElseThrow();
            assertThat(updatedFood.getFoodScore()).isEqualTo(0.0);
        }

        @Test
        @DisplayName("Should update multiple foods correctly")
        void updateFoodPopularity_MultipleFoods_UpdatesAllCorrectly() {
            // Given
            FoodMaster food1 = FoodMaster.builder()
                    .name(Map.of("en-US", "Food 1"))
                    .isVerified(true)
                    .foodScore(0.0)
                    .build();
            FoodMaster food2 = FoodMaster.builder()
                    .name(Map.of("en-US", "Food 2"))
                    .isVerified(true)
                    .foodScore(0.0)
                    .build();
            foodMasterRepository.save(food1);
            foodMasterRepository.save(food2);
            Long food1Id = food1.getId();
            Long food2Id = food2.getId();

            // Create 2 recipes for food1
            for (int i = 0; i < 2; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Recipe for Food1 " + i)
                        .description("Description " + i)
                        .cookingStyle("en-US")
                        .originalLanguage("en-US")
                        .foodMaster(food1)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 5 recipes for food2
            for (int i = 0; i < 5; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Recipe for Food2 " + i)
                        .description("Description " + i)
                        .cookingStyle("en-US")
                        .originalLanguage("en-US")
                        .foodMaster(food2)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }
            flushAndClear();

            // When
            foodScoreScheduler.updateFoodPopularity();
            flushAndClear();

            // Then
            FoodMaster updatedFood1 = foodMasterRepository.findById(food1Id).orElseThrow();
            FoodMaster updatedFood2 = foodMasterRepository.findById(food2Id).orElseThrow();

            assertThat(updatedFood1.getFoodScore()).isEqualTo(20.0); // 2 * 10
            assertThat(updatedFood2.getFoodScore()).isEqualTo(50.0); // 5 * 10
        }
    }
}
