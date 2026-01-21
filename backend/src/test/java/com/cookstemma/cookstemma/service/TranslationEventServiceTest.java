package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeIngredient;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeStep;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class TranslationEventServiceTest extends BaseIntegrationTest {

    @Autowired
    private TranslationEventService translationEventService;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    private FoodMaster testFoodMaster;

    @BeforeEach
    void setUp() {
        testFoodMaster = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.saveAndFlush(testFoodMaster);
    }

    @Nested
    @DisplayName("Queue Food Master Translation")
    class QueueFoodMasterTranslationTests {

        @Test
        @DisplayName("Should create translation event with correct entity type")
        void queueFoodMasterTranslation_CreatesEvent() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            Optional<TranslationEvent> event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId());

            assertThat(event).isPresent();
            assertThat(event.get().getEntityType()).isEqualTo(TranslatableEntity.FOOD_MASTER);
            assertThat(event.get().getEntityId()).isEqualTo(testFoodMaster.getId());
        }

        @Test
        @DisplayName("Should set source locale correctly")
        void queueFoodMasterTranslation_SetsSourceLocale() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should set all target locales except source")
        void queueFoodMasterTranslation_SetsTargetLocales() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getTargetLocales()).hasSize(19);
            assertThat(event.getTargetLocales()).contains("en", "ja", "zh", "fr", "es", "it", "de", "ru", "pt", "ar", "id", "vi", "hi", "th", "pl", "tr", "nl", "sv", "fa");
            assertThat(event.getTargetLocales()).doesNotContain("ko");
        }

        @Test
        @DisplayName("Should set status to PENDING")
        void queueFoodMasterTranslation_StatusIsPending() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getStatus()).isEqualTo(TranslationStatus.PENDING);
        }

        @Test
        @DisplayName("Should normalize BCP47 locale to short format")
        void queueFoodMasterTranslation_NormalizesLocale() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko-KR");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should not create duplicate event if one is pending")
        void queueFoodMasterTranslation_NoDuplicateWhenPending() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            long count = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.FOOD_MASTER)
                    .filter(e -> e.getEntityId().equals(testFoodMaster.getId()))
                    .count();

            assertThat(count).isEqualTo(1);
        }

        @Test
        @DisplayName("Should handle English as source locale")
        void queueFoodMasterTranslation_EnglishSource() {
            FoodMaster englishFood = FoodMaster.builder()
                    .name(Map.of("en-US", "Test Food"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.saveAndFlush(englishFood);

            translationEventService.queueFoodMasterTranslation(englishFood, "en");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, englishFood.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("en");
            assertThat(event.getTargetLocales()).contains("ko");
            assertThat(event.getTargetLocales()).doesNotContain("en");
        }

        @Test
        @DisplayName("Should default to ko for unknown locale")
        void queueFoodMasterTranslation_DefaultsToKorean() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "xx-XX");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should handle null locale gracefully")
        void queueFoodMasterTranslation_NullLocale() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, null);

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }
    }

    @Nested
    @DisplayName("Force Recipe Translation")
    class ForceRecipeTranslationTests {

        @Autowired
        private RecipeRepository recipeRepository;

        @Autowired
        private TestUserFactory testUserFactory;

        private Recipe testRecipe;
        private User testUser;

        @BeforeEach
        void setUpRecipe() {
            testUser = testUserFactory.createTestUser();

            testRecipe = Recipe.builder()
                    .title("Test Recipe Title")
                    .description("Test description")
                    .cookingStyle("JP")
                    .foodMaster(testFoodMaster)
                    .creatorId(testUser.getId())
                    .build();

            RecipeStep step = RecipeStep.builder()
                    .stepNumber(1)
                    .description("Step 1 description")
                    .recipe(testRecipe)
                    .build();
            testRecipe.getSteps().add(step);

            RecipeIngredient ingredient = RecipeIngredient.builder()
                    .name("Ingredient 1")
                    .quantity(1.0)
                    .recipe(testRecipe)
                    .build();
            testRecipe.getIngredients().add(ingredient);

            recipeRepository.saveAndFlush(testRecipe);
        }

        @Test
        @DisplayName("Should create RECIPE_FULL translation event with specified source locale")
        void forceRecipeTranslation_CreatesEvent() {
            translationEventService.forceRecipeTranslation(testRecipe, "en");

            List<TranslationEvent> events = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING));

            assertThat(events).hasSize(1);
            assertThat(events.get(0).getSourceLocale()).isEqualTo("en");
        }

        @Test
        @DisplayName("Should target ALL 20 locales when force translating")
        void forceRecipeTranslation_TargetsAllLocales() {
            translationEventService.forceRecipeTranslation(testRecipe, "en");

            TranslationEvent event = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING)).get(0);

            // Force translation includes ALL locales (including source)
            assertThat(event.getTargetLocales()).hasSize(20);
            assertThat(event.getTargetLocales()).contains("ja", "ko", "zh", "en");
        }

        @Test
        @DisplayName("Should NOT create separate step/ingredient events (handled by RECIPE_FULL)")
        void forceRecipeTranslation_NoSeparateStepIngredientEvents() {
            translationEventService.forceRecipeTranslation(testRecipe, "en");

            // Should NOT have separate RECIPE_STEP events
            List<TranslationEvent> stepEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_STEP, testRecipe.getSteps().get(0).getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(stepEvents).isEmpty();

            // Should NOT have separate RECIPE_INGREDIENT events
            List<TranslationEvent> ingredientEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_INGREDIENT, testRecipe.getIngredients().get(0).getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(ingredientEvents).isEmpty();

            // Should only have ONE RECIPE_FULL event
            List<TranslationEvent> fullEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(fullEvents).hasSize(1);
        }

        @Test
        @DisplayName("Should cancel existing pending events when force re-translating")
        void forceRecipeTranslation_CancelsExistingPending() {
            // First translation
            translationEventService.queueRecipeTranslation(testRecipe);

            List<TranslationEvent> initialEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(initialEvents).hasSize(1);
            Long initialEventId = initialEvents.get(0).getId();

            // Force re-translation with different source
            translationEventService.forceRecipeTranslation(testRecipe, "en");

            // Check initial event is now FAILED
            TranslationEvent initialEvent = translationEventRepository.findById(initialEventId).orElseThrow();
            assertThat(initialEvent.getStatus()).isEqualTo(TranslationStatus.FAILED);
            assertThat(initialEvent.getLastError()).contains("Cancelled for re-translation");

            // Check new event is PENDING with new source
            List<TranslationEvent> newEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(newEvents).hasSize(1);
            assertThat(newEvents.get(0).getSourceLocale()).isEqualTo("en");
        }
    }

    @Nested
    @DisplayName("Queue Recipe Translation (RECIPE_FULL)")
    class QueueRecipeTranslationTests {

        @Autowired
        private RecipeRepository recipeRepository;

        @Autowired
        private TestUserFactory testUserFactory;

        private Recipe testRecipe;
        private User testUser;

        @BeforeEach
        void setUpRecipe() {
            testUser = testUserFactory.createTestUser();

            testRecipe = Recipe.builder()
                    .title("Test Recipe Title")
                    .description("Test description")
                    .cookingStyle("KR")
                    .foodMaster(testFoodMaster)
                    .creatorId(testUser.getId())
                    .build();

            RecipeStep step1 = RecipeStep.builder()
                    .stepNumber(1)
                    .description("Step 1 description")
                    .recipe(testRecipe)
                    .build();
            RecipeStep step2 = RecipeStep.builder()
                    .stepNumber(2)
                    .description("Step 2 description")
                    .recipe(testRecipe)
                    .build();
            testRecipe.getSteps().add(step1);
            testRecipe.getSteps().add(step2);

            RecipeIngredient ingredient1 = RecipeIngredient.builder()
                    .name("Ingredient 1")
                    .quantity(1.0)
                    .recipe(testRecipe)
                    .build();
            RecipeIngredient ingredient2 = RecipeIngredient.builder()
                    .name("Ingredient 2")
                    .quantity(2.0)
                    .recipe(testRecipe)
                    .build();
            testRecipe.getIngredients().add(ingredient1);
            testRecipe.getIngredients().add(ingredient2);

            recipeRepository.saveAndFlush(testRecipe);
        }

        @Test
        @DisplayName("Should create single RECIPE_FULL event for recipe with steps and ingredients")
        void queueRecipeTranslation_CreatesSingleEvent() {
            translationEventService.queueRecipeTranslation(testRecipe);

            // Should have exactly ONE RECIPE_FULL event
            List<TranslationEvent> fullEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(fullEvents).hasSize(1);

            // Should NOT have separate RECIPE events
            List<TranslationEvent> recipeEvents = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING));
            assertThat(recipeEvents).isEmpty();

            // Should NOT have separate RECIPE_STEP events
            long stepEventCount = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.RECIPE_STEP)
                    .filter(e -> e.getStatus() == TranslationStatus.PENDING)
                    .count();
            assertThat(stepEventCount).isZero();

            // Should NOT have separate RECIPE_INGREDIENT events
            long ingredientEventCount = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.RECIPE_INGREDIENT)
                    .filter(e -> e.getStatus() == TranslationStatus.PENDING)
                    .count();
            assertThat(ingredientEventCount).isZero();
        }

        @Test
        @DisplayName("Should set source locale based on cooking style")
        void queueRecipeTranslation_SetsSourceLocale() {
            translationEventService.queueRecipeTranslation(testRecipe);

            TranslationEvent event = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING)).get(0);

            // KR cooking style should map to ko locale
            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should set 19 target locales (all except source)")
        void queueRecipeTranslation_SetsTargetLocales() {
            translationEventService.queueRecipeTranslation(testRecipe);

            TranslationEvent event = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                    List.of(TranslationStatus.PENDING)).get(0);

            assertThat(event.getTargetLocales()).hasSize(19);
            assertThat(event.getTargetLocales()).contains("en", "ja", "zh", "fr", "es");
            assertThat(event.getTargetLocales()).doesNotContain("ko");
        }

        @Test
        @DisplayName("Should not create duplicate event if one is pending")
        void queueRecipeTranslation_NoDuplicateWhenPending() {
            translationEventService.queueRecipeTranslation(testRecipe);
            translationEventService.queueRecipeTranslation(testRecipe);

            long count = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.RECIPE_FULL)
                    .filter(e -> e.getEntityId().equals(testRecipe.getId()))
                    .count();

            assertThat(count).isEqualTo(1);
        }
    }
}
