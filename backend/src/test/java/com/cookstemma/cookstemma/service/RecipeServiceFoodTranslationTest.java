package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.dto.recipe.CreateRecipeRequestDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
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

class RecipeServiceFoodTranslationTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private TranslationEventService translationEventService;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private UserPrincipal principal;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
        principal = UserPrincipal.create(testUser);
    }

    @Nested
    @DisplayName("Recipe Creation with New Food Name")
    class CreateRecipeWithNewFoodTests {

        @Test
        @DisplayName("Should queue FoodMaster translation when creating recipe with new food name")
        void createRecipe_WithNewFoodName_QueuesFoodMasterTranslation() {
            // Arrange
            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    null,  // no parentPublicId
                    null,  // no food1MasterPublicId (new food)
                    "New Test Food",  // newFoodName
                    "Test Recipe Title",
                    "Test description",
                    "ko-KR",  // cookingStyle
                    List.of(),  // ingredients
                    List.of(),  // steps
                    List.of(),  // imagePublicIds
                    null,  // changeCategory
                    null,  // changeDiff
                    null,  // changeReason
                    2,     // servings
                    "MIN_30_TO_60",  // cookingTimeRange
                    List.of()  // hashtags
            );

            // Act
            recipeService.createRecipe(request, principal);

            // Assert - Find the new FoodMaster
            FoodMaster newFood = foodMasterRepository.findByNameInAnyLocale("New Test Food")
                    .orElseThrow(() -> new AssertionError("FoodMaster not created"));

            // Verify translation event was queued
            List<TranslationEvent> events = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.FOOD_MASTER, newFood.getId(),
                    List.of(TranslationStatus.PENDING, TranslationStatus.PROCESSING));

            assertThat(events).hasSize(1);
            assertThat(events.get(0).getEntityType()).isEqualTo(TranslatableEntity.FOOD_MASTER);
            assertThat(events.get(0).getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should not queue duplicate translation for same FoodMaster")
        void createRecipe_WithExistingFood_DoesNotQueueDuplicateTranslation() {
            // Arrange - Create first recipe with new food
            CreateRecipeRequestDto request1 = new CreateRecipeRequestDto(
                    null, null, "Unique Food Name", "Recipe 1", "Desc 1", "ko-KR",
                    List.of(), List.of(), List.of(), null, null, null, 2, null, List.of()
            );
            recipeService.createRecipe(request1, principal);

            // Get the food master
            FoodMaster food = foodMasterRepository.findByNameInAnyLocale("Unique Food Name")
                    .orElseThrow();

            // Count events after first creation
            long countAfterFirst = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.FOOD_MASTER)
                    .filter(e -> e.getEntityId().equals(food.getId()))
                    .count();

            // Act - Create second recipe with same food name
            CreateRecipeRequestDto request2 = new CreateRecipeRequestDto(
                    null, null, "Unique Food Name", "Recipe 2", "Desc 2", "ko-KR",
                    List.of(), List.of(), List.of(), null, null, null, 2, null, List.of()
            );
            recipeService.createRecipe(request2, principal);

            // Assert - Should still have only one translation event (no duplicate)
            long countAfterSecond = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.FOOD_MASTER)
                    .filter(e -> e.getEntityId().equals(food.getId()))
                    .count();

            assertThat(countAfterSecond).isEqualTo(countAfterFirst);
        }

        @Test
        @DisplayName("Should set correct target locales excluding source")
        void createRecipe_WithNewFood_SetsCorrectTargetLocales() {
            // Arrange
            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    null, null, "Another Test Food", "Test Recipe", "Desc", "ja-JP",
                    List.of(), List.of(), List.of(), null, null, null, 2, null, List.of()
            );

            // Act
            recipeService.createRecipe(request, principal);

            // Assert
            FoodMaster newFood = foodMasterRepository.findByNameInAnyLocale("Another Test Food")
                    .orElseThrow();

            TranslationEvent event = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.FOOD_MASTER, newFood.getId(),
                    List.of(TranslationStatus.PENDING)).get(0);

            assertThat(event.getSourceLocale()).isEqualTo("ja");
            assertThat(event.getTargetLocales()).hasSize(19);
            assertThat(event.getTargetLocales()).doesNotContain("ja");
            assertThat(event.getTargetLocales()).contains("ko", "en", "zh", "es");
        }
    }

    @Nested
    @DisplayName("Backfill Untranslated Foods")
    class BackfillUntranslatedFoodsTests {

        @Test
        @DisplayName("Should queue translations for foods with only one locale")
        void queueUntranslatedFoodMasters_QueuesTranslationsForSingleLocaleFoods() {
            // Arrange - Create a food with only one locale (simulating legacy data)
            FoodMaster legacyFood = FoodMaster.builder()
                    .name(Map.of("id-ID", "Nasi Goreng"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.saveAndFlush(legacyFood);

            // Act
            int count = translationEventService.queueUntranslatedFoodMasters();

            // Assert
            assertThat(count).isGreaterThanOrEqualTo(1);

            List<TranslationEvent> events = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.FOOD_MASTER, legacyFood.getId(),
                    List.of(TranslationStatus.PENDING));

            assertThat(events).hasSize(1);
            assertThat(events.get(0).getSourceLocale()).isEqualTo("id");
        }

        @Test
        @DisplayName("Should not queue translations for foods already translated")
        void queueUntranslatedFoodMasters_SkipsFoodsWithMultipleLocales() {
            // Arrange - Create a food with multiple locales (already translated)
            FoodMaster translatedFood = FoodMaster.builder()
                    .name(Map.of(
                            "ko-KR", "김치찌개",
                            "en-US", "Kimchi Stew",
                            "ja-JP", "キムチチゲ"
                    ))
                    .isVerified(true)
                    .build();
            foodMasterRepository.saveAndFlush(translatedFood);

            // Act
            translationEventService.queueUntranslatedFoodMasters();

            // Assert - Should not have queued translation for already translated food
            List<TranslationEvent> events = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                    TranslatableEntity.FOOD_MASTER, translatedFood.getId(),
                    List.of(TranslationStatus.PENDING, TranslationStatus.PROCESSING));

            assertThat(events).isEmpty();
        }

        @Test
        @DisplayName("Should return count of queued foods")
        void queueUntranslatedFoodMasters_ReturnsCorrectCount() {
            // Arrange - Create multiple untranslated foods
            FoodMaster food1 = FoodMaster.builder()
                    .name(Map.of("th-TH", "ผัดไทย"))
                    .isVerified(false)
                    .build();
            FoodMaster food2 = FoodMaster.builder()
                    .name(Map.of("vi-VN", "Phở"))
                    .isVerified(false)
                    .build();
            foodMasterRepository.saveAllAndFlush(List.of(food1, food2));

            // Act
            int count = translationEventService.queueUntranslatedFoodMasters();

            // Assert - At least 2 should be queued
            assertThat(count).isGreaterThanOrEqualTo(2);
        }
    }
}
