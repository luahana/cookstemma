package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeIngredient;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementPreference;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementUnit;
import com.pairingplanet.pairing_planet.dto.recipe.CreateRecipeRequestDto;
import com.pairingplanet.pairing_planet.dto.recipe.IngredientDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeDetailResponseDto;
import com.pairingplanet.pairing_planet.dto.recipe.StepDto;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeIngredientRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import com.pairingplanet.pairing_planet.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@DisplayName("Recipe Measurement Integration Tests")
class RecipeMeasurementIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private RecipeIngredientRepository ingredientRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private UserRepository userRepository;

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
    @DisplayName("Create Recipe with Structured Ingredients")
    class CreateRecipeWithStructuredIngredients {

        @Test
        @DisplayName("Should create recipe with quantity and unit")
        void createRecipe_WithStructuredIngredients_Success() {
            // Arrange
            IngredientDto structuredIngredient = new IngredientDto(
                    "Flour",
                    null, // no legacy amount
                    2.0,  // quantity
                    MeasurementUnit.CUP, // unit
                    IngredientType.MAIN
            );

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Test Recipe",
                    "A test recipe with structured ingredients",
                    "en-US",
                    testFood.getPublicId(),
                    null, // newFoodName
                    List.of(structuredIngredient),
                    List.of(new StepDto(1, "Mix ingredients", null, null)),
                    List.of(), // images
                    null, // changeCategory
                    null, // parentPublicId
                    null, // newFoodName
                    null, // changeDiff
                    null, // changeReason
                    null  // hashtags
            );

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.ingredients()).hasSize(1);

            IngredientDto savedIngredient = result.ingredients().get(0);
            assertThat(savedIngredient.name()).isEqualTo("Flour");
            assertThat(savedIngredient.quantity()).isEqualTo(2.0);
            assertThat(savedIngredient.unit()).isEqualTo(MeasurementUnit.CUP);
            assertThat(savedIngredient.hasStructuredMeasurement()).isTrue();
        }

        @Test
        @DisplayName("Should create recipe with legacy amount string")
        void createRecipe_WithLegacyAmount_Success() {
            // Arrange
            IngredientDto legacyIngredient = new IngredientDto(
                    "Salt",
                    "a pinch", // legacy amount
                    null, // no quantity
                    null, // no unit
                    IngredientType.SEASONING
            );

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Legacy Recipe",
                    "A recipe with legacy amount",
                    "en-US",
                    testFood.getPublicId(),
                    null,
                    List.of(legacyIngredient),
                    List.of(new StepDto(1, "Add salt", null, null)),
                    List.of(),
                    null, null, null, null, null, null
            );

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.ingredients()).hasSize(1);

            IngredientDto savedIngredient = result.ingredients().get(0);
            assertThat(savedIngredient.name()).isEqualTo("Salt");
            assertThat(savedIngredient.amount()).isEqualTo("a pinch");
            assertThat(savedIngredient.quantity()).isNull();
            assertThat(savedIngredient.unit()).isNull();
            assertThat(savedIngredient.hasStructuredMeasurement()).isFalse();
        }

        @Test
        @DisplayName("Should create recipe with mixed ingredient types")
        void createRecipe_WithMixedIngredients_Success() {
            // Arrange
            IngredientDto structuredIngredient = new IngredientDto(
                    "Sugar",
                    null,
                    100.0,
                    MeasurementUnit.G,
                    IngredientType.MAIN
            );

            IngredientDto legacyIngredient = new IngredientDto(
                    "Vanilla",
                    "to taste",
                    null,
                    null,
                    IngredientType.SEASONING
            );

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Mixed Recipe",
                    "Recipe with both types",
                    "en-US",
                    testFood.getPublicId(),
                    null,
                    List.of(structuredIngredient, legacyIngredient),
                    List.of(new StepDto(1, "Combine", null, null)),
                    List.of(),
                    null, null, null, null, null, null
            );

            // Act
            RecipeDetailResponseDto result = recipeService.createRecipe(request, userPrincipal);

            // Assert
            assertThat(result.ingredients()).hasSize(2);

            IngredientDto sugar = result.ingredients().stream()
                    .filter(i -> i.name().equals("Sugar"))
                    .findFirst().orElseThrow();
            assertThat(sugar.quantity()).isEqualTo(100.0);
            assertThat(sugar.unit()).isEqualTo(MeasurementUnit.G);
            assertThat(sugar.hasStructuredMeasurement()).isTrue();

            IngredientDto vanilla = result.ingredients().stream()
                    .filter(i -> i.name().equals("Vanilla"))
                    .findFirst().orElseThrow();
            assertThat(vanilla.amount()).isEqualTo("to taste");
            assertThat(vanilla.hasStructuredMeasurement()).isFalse();
        }
    }

    @Nested
    @DisplayName("Retrieve Recipe with Structured Ingredients")
    class RetrieveRecipeWithStructuredIngredients {

        @Test
        @DisplayName("Should return structured ingredient data")
        void getRecipeDetail_WithStructuredIngredients_ReturnsData() {
            // Arrange - Create recipe directly in DB
            Recipe recipe = Recipe.builder()
                    .title("DB Recipe")
                    .description("Test")
                    .culinaryLocale("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .recipe(recipe)
                    .name("Milk")
                    .quantity(500.0)
                    .unit(MeasurementUnit.ML)
                    .type(IngredientType.MAIN)
                    .build();
            ingredientRepository.save(ingredient);
            // Maintain bidirectional relationship
            recipe.getIngredients().add(ingredient);

            // Act
            RecipeDetailResponseDto result = recipeService.getRecipeDetail(recipe.getPublicId());

            // Assert
            assertThat(result.ingredients()).hasSize(1);
            IngredientDto milk = result.ingredients().get(0);
            assertThat(milk.name()).isEqualTo("Milk");
            assertThat(milk.quantity()).isEqualTo(500.0);
            assertThat(milk.unit()).isEqualTo(MeasurementUnit.ML);
        }
    }

    @Nested
    @DisplayName("User Measurement Preference")
    class UserMeasurementPreference {

        @Test
        @DisplayName("Should save measurement preference to user")
        void userMeasurementPreference_SavesCorrectly() {
            // Arrange
            testUser.setMeasurementPreference(MeasurementPreference.METRIC);
            userRepository.save(testUser);

            // Act
            User savedUser = userRepository.findById(testUser.getId()).orElseThrow();

            // Assert
            assertThat(savedUser.getMeasurementPreference()).isEqualTo(MeasurementPreference.METRIC);
        }

        @Test
        @DisplayName("Should default to ORIGINAL when not set")
        void userMeasurementPreference_DefaultsToOriginal() {
            // Act - create new user without setting preference
            User newUser = testUserFactory.createTestUser();

            // Assert
            assertThat(newUser.getMeasurementPreference()).isEqualTo(MeasurementPreference.ORIGINAL);
        }
    }

    @Nested
    @DisplayName("RecipeIngredient Entity")
    class RecipeIngredientEntity {

        @Test
        @DisplayName("Should identify structured measurement")
        void hasStructuredMeasurement_WithBothFields_ReturnsTrue() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .quantity(1.0)
                    .unit(MeasurementUnit.CUP)
                    .type(IngredientType.MAIN)
                    .build();

            assertThat(ingredient.hasStructuredMeasurement()).isTrue();
        }

        @Test
        @DisplayName("Should identify legacy measurement")
        void hasStructuredMeasurement_WithOnlyAmount_ReturnsFalse() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .amount("1 cup")
                    .type(IngredientType.MAIN)
                    .build();

            assertThat(ingredient.hasStructuredMeasurement()).isFalse();
        }

        @Test
        @DisplayName("Should return false when only quantity is set")
        void hasStructuredMeasurement_WithOnlyQuantity_ReturnsFalse() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .quantity(1.0)
                    .type(IngredientType.MAIN)
                    .build();

            assertThat(ingredient.hasStructuredMeasurement()).isFalse();
        }

        @Test
        @DisplayName("Should return false when only unit is set")
        void hasStructuredMeasurement_WithOnlyUnit_ReturnsFalse() {
            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Test")
                    .unit(MeasurementUnit.CUP)
                    .type(IngredientType.MAIN)
                    .build();

            assertThat(ingredient.hasStructuredMeasurement()).isFalse();
        }
    }

    @Nested
    @DisplayName("All MeasurementUnit Types")
    class AllMeasurementUnitTypes {

        @Test
        @DisplayName("Volume units should be identified correctly")
        void volumeUnits_AreIdentifiedCorrectly() {
            assertThat(MeasurementUnit.ML.isVolume()).isTrue();
            assertThat(MeasurementUnit.L.isVolume()).isTrue();
            assertThat(MeasurementUnit.CUP.isVolume()).isTrue();
            assertThat(MeasurementUnit.TBSP.isVolume()).isTrue();
            assertThat(MeasurementUnit.TSP.isVolume()).isTrue();
            assertThat(MeasurementUnit.FL_OZ.isVolume()).isTrue();
            assertThat(MeasurementUnit.PINT.isVolume()).isTrue();
            assertThat(MeasurementUnit.QUART.isVolume()).isTrue();
        }

        @Test
        @DisplayName("Weight units should be identified correctly")
        void weightUnits_AreIdentifiedCorrectly() {
            assertThat(MeasurementUnit.G.isWeight()).isTrue();
            assertThat(MeasurementUnit.KG.isWeight()).isTrue();
            assertThat(MeasurementUnit.OZ.isWeight()).isTrue();
            assertThat(MeasurementUnit.LB.isWeight()).isTrue();
        }

        @Test
        @DisplayName("Count units should be identified correctly")
        void countUnits_AreIdentifiedCorrectly() {
            assertThat(MeasurementUnit.PIECE.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.PINCH.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.DASH.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.TO_TASTE.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.CLOVE.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.BUNCH.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.CAN.isCountOrOther()).isTrue();
            assertThat(MeasurementUnit.PACKAGE.isCountOrOther()).isTrue();
        }

        @Test
        @DisplayName("Metric units should be identified correctly")
        void metricUnits_AreIdentifiedCorrectly() {
            assertThat(MeasurementUnit.ML.isMetric()).isTrue();
            assertThat(MeasurementUnit.L.isMetric()).isTrue();
            assertThat(MeasurementUnit.G.isMetric()).isTrue();
            assertThat(MeasurementUnit.KG.isMetric()).isTrue();

            assertThat(MeasurementUnit.CUP.isMetric()).isFalse();
            assertThat(MeasurementUnit.OZ.isMetric()).isFalse();
        }

        @Test
        @DisplayName("Imperial units should be identified correctly")
        void imperialUnits_AreIdentifiedCorrectly() {
            assertThat(MeasurementUnit.CUP.isImperial()).isTrue();
            assertThat(MeasurementUnit.TBSP.isImperial()).isTrue();
            assertThat(MeasurementUnit.TSP.isImperial()).isTrue();
            assertThat(MeasurementUnit.FL_OZ.isImperial()).isTrue();
            assertThat(MeasurementUnit.PINT.isImperial()).isTrue();
            assertThat(MeasurementUnit.QUART.isImperial()).isTrue();
            assertThat(MeasurementUnit.OZ.isImperial()).isTrue();
            assertThat(MeasurementUnit.LB.isImperial()).isTrue();

            assertThat(MeasurementUnit.ML.isImperial()).isFalse();
            assertThat(MeasurementUnit.G.isImperial()).isFalse();
        }
    }
}
