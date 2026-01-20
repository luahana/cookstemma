package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeIngredient;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.MeasurementUnit;
import com.cookstemma.cookstemma.dto.recipe.CreateRecipeRequestDto;
import com.cookstemma.cookstemma.dto.recipe.IngredientDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeDetailResponseDto;
import com.cookstemma.cookstemma.dto.recipe.StepDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeIngredientRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Ingredient Type Mapping Tests")
class IngredientTypeMappingTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private RecipeIngredientRepository ingredientRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private FoodMaster testFood;
    private UserPrincipal userPrincipal;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);

        userPrincipal = new UserPrincipal(testUser);
    }

    @Nested
    @DisplayName("IngredientType Enum Mapping")
    class IngredientTypeEnumMapping {

        @Test
        @DisplayName("Should have all three ingredient types")
        void allIngredientTypesAreDefined() {
            assertThat(IngredientType.values())
                    .containsExactly(IngredientType.MAIN, IngredientType.SECONDARY, IngredientType.SEASONING);
        }

        @Test
        @DisplayName("Should serialize IngredientType.MAIN as 'MAIN'")
        void ingredientTypeMainSerializesCorrectly() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .type(IngredientType.MAIN)
                    .build();

            assertThat(ingredient.getType().name()).isEqualTo("MAIN");
        }

        @Test
        @DisplayName("Should serialize IngredientType.SECONDARY as 'SECONDARY'")
        void ingredientTypeSecondarySerializesCorrectly() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .type(IngredientType.SECONDARY)
                    .build();

            assertThat(ingredient.getType().name()).isEqualTo("SECONDARY");
        }

        @Test
        @DisplayName("Should serialize IngredientType.SEASONING as 'SEASONING'")
        void ingredientTypeSeasoningSerializesCorrectly() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .type(IngredientType.SEASONING)
                    .build();

            assertThat(ingredient.getType().name()).isEqualTo("SEASONING");
        }
    }

    @Nested
    @DisplayName("Recipe Creation with Different Ingredient Types")
    class RecipeCreationWithIngredientTypes {

        @Test
        @DisplayName("Should preserve MAIN ingredient type through creation and retrieval")
        void createRecipe_WithMainIngredient_PreservesType() {
            // Arrange
            IngredientDto mainIngredient = new IngredientDto(
                    "Chicken",
                    500.0,
                    MeasurementUnit.G,
                    IngredientType.MAIN
            );

            CreateRecipeRequestDto request = createRecipeRequest(List.of(mainIngredient));

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result.ingredients()).hasSize(1);
            assertThat(result.ingredients().get(0).type()).isEqualTo(IngredientType.MAIN);
        }

        @Test
        @DisplayName("Should preserve SECONDARY ingredient type through creation and retrieval")
        void createRecipe_WithSecondaryIngredient_PreservesType() {
            // Arrange
            IngredientDto secondaryIngredient = new IngredientDto(
                    "Onion",
                    1.0,
                    MeasurementUnit.PIECE,
                    IngredientType.SECONDARY
            );

            CreateRecipeRequestDto request = createRecipeRequest(List.of(secondaryIngredient));

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result.ingredients()).hasSize(1);
            assertThat(result.ingredients().get(0).type()).isEqualTo(IngredientType.SECONDARY);
        }

        @Test
        @DisplayName("Should preserve SEASONING ingredient type through creation and retrieval")
        void createRecipe_WithSeasoningIngredient_PreservesType() {
            // Arrange
            IngredientDto seasoningIngredient = new IngredientDto(
                    "Salt",
                    1.0,
                    MeasurementUnit.TSP,
                    IngredientType.SEASONING
            );

            CreateRecipeRequestDto request = createRecipeRequest(List.of(seasoningIngredient));

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result.ingredients()).hasSize(1);
            assertThat(result.ingredients().get(0).type()).isEqualTo(IngredientType.SEASONING);
        }

        @Test
        @DisplayName("Should preserve all ingredient types in single recipe")
        void createRecipe_WithMixedTypes_PreservesAllTypes() {
            // Arrange
            IngredientDto mainIngredient = new IngredientDto(
                    "Beef",
                    300.0,
                    MeasurementUnit.G,
                    IngredientType.MAIN
            );
            IngredientDto secondaryIngredient = new IngredientDto(
                    "Carrot",
                    2.0,
                    MeasurementUnit.PIECE,
                    IngredientType.SECONDARY
            );
            IngredientDto seasoningIngredient = new IngredientDto(
                    "Pepper",
                    1.0,
                    MeasurementUnit.PINCH,
                    IngredientType.SEASONING
            );

            CreateRecipeRequestDto request = createRecipeRequest(
                    List.of(mainIngredient, secondaryIngredient, seasoningIngredient)
            );

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result.ingredients()).hasSize(3);

            // Check each type is preserved
            var mainIngredients = result.ingredients().stream()
                    .filter(i -> i.type() == IngredientType.MAIN)
                    .toList();
            var secondaryIngredients = result.ingredients().stream()
                    .filter(i -> i.type() == IngredientType.SECONDARY)
                    .toList();
            var seasoningIngredients = result.ingredients().stream()
                    .filter(i -> i.type() == IngredientType.SEASONING)
                    .toList();

            assertThat(mainIngredients).hasSize(1);
            assertThat(mainIngredients.get(0).name()).isEqualTo("Beef");

            assertThat(secondaryIngredients).hasSize(1);
            assertThat(secondaryIngredients.get(0).name()).isEqualTo("Carrot");

            assertThat(seasoningIngredients).hasSize(1);
            assertThat(seasoningIngredients.get(0).name()).isEqualTo("Pepper");
        }
    }

    @Nested
    @DisplayName("Recipe Retrieval with Ingredient Types")
    class RecipeRetrievalWithIngredientTypes {

        @Test
        @DisplayName("Should return correct ingredient types when retrieving recipe detail")
        void getRecipeDetail_WithMixedTypes_ReturnsCorrectTypes() {
            // Arrange - Create recipe with mixed ingredient types
            IngredientDto mainIngredient = new IngredientDto(
                    "Salmon",
                    200.0,
                    MeasurementUnit.G,
                    IngredientType.MAIN
            );
            IngredientDto seasoningIngredient = new IngredientDto(
                    "Dill",
                    1.0,
                    MeasurementUnit.TBSP,
                    IngredientType.SEASONING
            );

            CreateRecipeRequestDto request = createRecipeRequest(
                    List.of(mainIngredient, seasoningIngredient)
            );
            RecipeDetailResponseDto created = recipeService.createRecipe(request, userPrincipal);

            // Act - Retrieve the recipe
            RecipeDetailResponseDto retrieved = recipeService.getRecipeDetail(
                    created.publicId(),
                    testUser.getId()
            );

            // Assert
            assertThat(retrieved.ingredients()).hasSize(2);

            var retrievedMain = retrieved.ingredients().stream()
                    .filter(i -> i.type() == IngredientType.MAIN)
                    .findFirst()
                    .orElseThrow();
            assertThat(retrievedMain.name()).isEqualTo("Salmon");

            var retrievedSeasoning = retrieved.ingredients().stream()
                    .filter(i -> i.type() == IngredientType.SEASONING)
                    .findFirst()
                    .orElseThrow();
            assertThat(retrievedSeasoning.name()).isEqualTo("Dill");
        }
    }

    private CreateRecipeRequestDto createRecipeRequest(List<IngredientDto> ingredients) {
        return new CreateRecipeRequestDto(
                "Test Recipe",
                "A test recipe description",
                "en-US",
                testFood.getPublicId(),
                null, // newFoodName
                ingredients,
                List.of(new StepDto(1, "Test step", null, null)),
                List.of(), // images
                null, // changeCategory
                null, // parentPublicId
                null, // rootPublicId
                null, // changeDiff
                null, // changeReason
                null, // hashtags
                null, // servings
                null  // cookingTimeRange
        );
    }
}
