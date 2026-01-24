package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.log_post.CreateLogRequestDto;
import com.cookstemma.cookstemma.dto.recipe.CreateRecipeRequestDto;
import com.cookstemma.cookstemma.dto.recipe.IngredientDto;
import com.cookstemma.cookstemma.dto.recipe.StepDto;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.MeasurementUnit;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
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

class OriginalLanguageTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private LogPostService logPostService;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User koreanUser;
    private User englishUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        koreanUser = testUserFactory.createTestUser("korean_user", "ko-KR");
        englishUser = testUserFactory.createTestUser("english_user", "en-US");

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("RecipeService.createRecipe")
    class RecipeOriginalLanguageTests {

        @Test
        @DisplayName("Should set originalLanguage from Korean user's locale")
        void createRecipe_KoreanUser_SetsKoreanOriginalLanguage() {
            // Create a cover image for the recipe
            Image coverImage = Image.builder()
                    .storedFilename("test-cover.jpg")
                    .type(ImageType.COVER)
                    .uploaderId(koreanUser.getId())
                    .build();
            imageRepository.save(coverImage);

            // Create dummy ingredient and step
            IngredientDto ingredient = new IngredientDto("김치", 500.0, MeasurementUnit.G, IngredientType.MAIN);
            StepDto step = new StepDto(1, "김치를 볶습니다", null, null);

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "김치찌개",
                    "맛있는 김치찌개 레시피",
                    "ko-KR",  // cookingStyle
                    testFood.getPublicId(),  // food1MasterPublicId
                    null,  // newFoodName
                    List.of(ingredient),  // ingredients
                    List.of(step),  // steps
                    List.of(coverImage.getPublicId()),  // imagePublicIds
                    null,  // changeCategory
                    null,  // parentPublicId
                    null,  // rootPublicId
                    null,  // changeDiff
                    null,  // changeReason
                    List.of("한식"),  // hashtags
                    2,  // servings
                    "MIN_30_TO_60",  // cookingTimeRange
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(koreanUser);
            recipeService.createRecipe(request, principal);

            // Verify the recipe was created with Korean originalLanguage
            List<Recipe> recipes = recipeRepository.findAll();
            assertThat(recipes).hasSize(1);
            assertThat(recipes.get(0).getOriginalLanguage()).isEqualTo("ko-KR");
        }

        @Test
        @DisplayName("Should set originalLanguage from English user's locale")
        void createRecipe_EnglishUser_SetsEnglishOriginalLanguage() {
            // Create a cover image for the recipe
            Image coverImage = Image.builder()
                    .storedFilename("test-cover.jpg")
                    .type(ImageType.COVER)
                    .uploaderId(englishUser.getId())
                    .build();
            imageRepository.save(coverImage);

            // Create dummy ingredient and step
            IngredientDto ingredient = new IngredientDto("Lettuce", 100.0, MeasurementUnit.G, IngredientType.MAIN);
            StepDto step = new StepDto(1, "Mix the salad", null, null);

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Vegan Salad",
                    "A healthy vegan salad recipe",
                    "en-US",  // cookingStyle
                    testFood.getPublicId(),  // food1MasterPublicId
                    null,  // newFoodName
                    List.of(ingredient),  // ingredients
                    List.of(step),  // steps
                    List.of(coverImage.getPublicId()),  // imagePublicIds
                    null,  // changeCategory
                    null,  // parentPublicId
                    null,  // rootPublicId
                    null,  // changeDiff
                    null,  // changeReason
                    List.of("vegan"),  // hashtags
                    2,  // servings
                    "MIN_30_TO_60",  // cookingTimeRange
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(englishUser);
            recipeService.createRecipe(request, principal);

            // Verify the recipe was created with English originalLanguage
            List<Recipe> recipes = recipeRepository.findAll();
            assertThat(recipes).hasSize(1);
            assertThat(recipes.get(0).getOriginalLanguage()).isEqualTo("en-US");
        }

        @Test
        @DisplayName("originalLanguage should be independent of cookingStyle")
        void createRecipe_DifferentCookingStyle_OriginalLanguageFollowsUserLocale() {
            // Korean user creates recipe with Japanese cooking style
            Image coverImage = Image.builder()
                    .storedFilename("test-cover.jpg")
                    .type(ImageType.COVER)
                    .uploaderId(koreanUser.getId())
                    .build();
            imageRepository.save(coverImage);

            // Create dummy ingredient and step
            IngredientDto ingredient = new IngredientDto("라면", 1.0, MeasurementUnit.PIECE, IngredientType.MAIN);
            StepDto step = new StepDto(1, "물을 끓입니다", null, null);

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "일본식 라멘",
                    "일본식 라멘 레시피",
                    "ja-JP",  // cookingStyle (Japanese, but user is Korean)
                    testFood.getPublicId(),  // food1MasterPublicId
                    null,  // newFoodName
                    List.of(ingredient),  // ingredients
                    List.of(step),  // steps
                    List.of(coverImage.getPublicId()),  // imagePublicIds
                    null,  // changeCategory
                    null,  // parentPublicId
                    null,  // rootPublicId
                    null,  // changeDiff
                    null,  // changeReason
                    List.of("일식"),  // hashtags
                    2,  // servings
                    "MIN_30_TO_60",  // cookingTimeRange
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(koreanUser);
            recipeService.createRecipe(request, principal);

            // Verify originalLanguage is Korean (from user) while cookingStyle is Japanese
            List<Recipe> recipes = recipeRepository.findAll();
            assertThat(recipes).hasSize(1);
            assertThat(recipes.get(0).getOriginalLanguage()).isEqualTo("ko-KR");
            assertThat(recipes.get(0).getCookingStyle()).isEqualTo("ja-JP");
        }
    }

    @Nested
    @DisplayName("LogPostService.createLog")
    class LogPostOriginalLanguageTests {

        private Recipe testRecipe;

        @BeforeEach
        void setUpRecipe() {
            testRecipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .build();
            recipeRepository.save(testRecipe);
        }

        @Test
        @DisplayName("Should set originalLanguage from Korean user's locale")
        void createLog_KoreanUser_SetsKoreanOriginalLanguage() {
            // Create an image for the log
            Image logImage = Image.builder()
                    .storedFilename("test-log.jpg")
                    .type(ImageType.LOG_POST)
                    .uploaderId(koreanUser.getId())
                    .build();
            imageRepository.save(logImage);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    testRecipe.getPublicId(),
                    "오늘 요리 후기",
                    "정말 맛있었어요!",
                    5,  // rating
                    List.of(logImage.getPublicId()),  // imagePublicIds
                    List.of("홈쿡"),  // hashtags
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(koreanUser);
            logPostService.createLog(request, principal);

            // Verify the log was created with Korean originalLanguage
            List<LogPost> logs = logPostRepository.findAll();
            assertThat(logs).hasSize(1);
            assertThat(logs.get(0).getOriginalLanguage()).isEqualTo("ko-KR");
        }

        @Test
        @DisplayName("Should set originalLanguage from English user's locale")
        void createLog_EnglishUser_SetsEnglishOriginalLanguage() {
            // Create an image for the log
            Image logImage = Image.builder()
                    .storedFilename("test-log.jpg")
                    .type(ImageType.LOG_POST)
                    .uploaderId(englishUser.getId())
                    .build();
            imageRepository.save(logImage);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    testRecipe.getPublicId(),
                    "Today's cooking log",
                    "It was delicious!",
                    5,  // rating
                    List.of(logImage.getPublicId()),  // imagePublicIds
                    List.of("homecook"),  // hashtags
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(englishUser);
            logPostService.createLog(request, principal);

            // Verify the log was created with English originalLanguage
            List<LogPost> logs = logPostRepository.findAll();
            assertThat(logs).hasSize(1);
            assertThat(logs.get(0).getOriginalLanguage()).isEqualTo("en-US");
        }

        @Test
        @DisplayName("originalLanguage should be independent of recipe's cookingStyle")
        void createLog_RecipeHasDifferentStyle_OriginalLanguageFollowsUserLocale() {
            // Create a Japanese cooking style recipe
            Recipe japaneseRecipe = Recipe.builder()
                    .title("Japanese Ramen")
                    .description("Authentic ramen recipe")
                    .cookingStyle("ja-JP")
                    .originalLanguage("ja-JP")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .build();
            recipeRepository.save(japaneseRecipe);

            // English user creates a log for the Japanese recipe
            Image logImage = Image.builder()
                    .storedFilename("test-log.jpg")
                    .type(ImageType.LOG_POST)
                    .uploaderId(englishUser.getId())
                    .build();
            imageRepository.save(logImage);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    japaneseRecipe.getPublicId(),
                    "Tried this ramen",
                    "Amazing flavor!",
                    5,  // rating
                    List.of(logImage.getPublicId()),  // imagePublicIds
                    List.of("ramen"),  // hashtags
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(englishUser);
            logPostService.createLog(request, principal);

            // Verify originalLanguage is English (from user) not Japanese (from recipe)
            List<LogPost> logs = logPostRepository.findAll();
            assertThat(logs).hasSize(1);
            assertThat(logs.get(0).getOriginalLanguage()).isEqualTo("en-US");
            // locale should still be from recipe's cookingStyle
            assertThat(logs.get(0).getLocale()).isEqualTo("ja-JP");
        }
    }
}
