package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.user.UpdateProfileRequestDto;
import com.cookstemma.cookstemma.dto.user.UserDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class UserServiceTest extends BaseIntegrationTest {

    @Autowired
    private UserService userService;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private UserRepository userRepository;

    private User testUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("getUserProfile")
    class GetUserProfileTests {

        @Test
        @DisplayName("Should return level 1 and 'beginner' for new user with no activity")
        void newUserHasLevel1Beginner() {
            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            assertThat(result.id()).isEqualTo(testUser.getPublicId());
            assertThat(result.username()).isEqualTo(testUser.getUsername());
            assertThat(result.level()).isEqualTo(1);
            assertThat(result.levelName()).isEqualTo("beginner");
            assertThat(result.recipeCount()).isEqualTo(0);
            assertThat(result.logCount()).isEqualTo(0);
        }

        @Test
        @DisplayName("Should calculate level based on recipes created")
        void calculatesLevelFromRecipes() {
            // Create 3 recipes (3 * 50 = 150 XP = Level 2)
            for (int i = 0; i < 3; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Test Recipe " + i)
                        .description("Description")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            assertThat(result.recipeCount()).isEqualTo(3);
            assertThat(result.level()).isEqualTo(2); // 150 XP = Level 2
            assertThat(result.levelName()).isEqualTo("beginner");
        }

        @Test
        @DisplayName("Should calculate level from recipes and successful logs")
        void calculatesLevelFromRecipesAndLogs() {
            // Create 2 recipes (2 * 50 = 100 XP)
            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            Recipe recipe2 = Recipe.builder()
                    .title("Test Recipe 2")
                    .description("Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe2);

            // Create 2 successful logs (2 * 30 = 60 XP)
            // Total: 100 + 60 = 160 XP = Level 2
            createLogWithRating(recipe, 5);
            createLogWithRating(recipe2, 5);

            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            assertThat(result.recipeCount()).isEqualTo(2);
            assertThat(result.level()).isEqualTo(2); // 160 XP = Level 2
            assertThat(result.levelName()).isEqualTo("beginner");
        }

        @Test
        @DisplayName("Should reach higher level with more activity")
        void reachesHigherLevelWithActivity() {
            // 10 original recipes = 500 XP, 7 logs created = 140 XP
            // Total: 640 XP -> Level 5 (Beginner tier, since L6 requires ~686 XP)
            for (int i = 0; i < 10; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .description("Description")
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);

                if (i < 7) {
                    createLogWithRating(recipe, 5);
                }
            }

            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            // 640 XP should give level 5 (beginner tier)
            assertThat(result.level()).isGreaterThanOrEqualTo(5);
            assertThat(result.levelName()).isEqualTo("beginner");
        }

        @Test
        @DisplayName("Should include all user profile fields")
        void includesAllProfileFields() {
            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            assertThat(result.id()).isNotNull();
            assertThat(result.username()).isNotNull();
            // profileImageUrl can be null when user has no profile image (clients handle fallback)
            assertThat(result.followerCount()).isGreaterThanOrEqualTo(0);
            assertThat(result.followingCount()).isGreaterThanOrEqualTo(0);
            assertThat(result.recipeCount()).isGreaterThanOrEqualTo(0);
            assertThat(result.logCount()).isGreaterThanOrEqualTo(0);
            assertThat(result.level()).isGreaterThanOrEqualTo(1);
            assertThat(result.levelName()).isNotNull();
        }

        private void createLogWithRating(Recipe recipe, Integer rating) {
            LogPost logPost = LogPost.builder()
                    .title("Log for " + recipe.getTitle())
                    .content("Test content")
                    .locale("ko-KR")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(logPost)
                    .recipe(recipe)
                    .rating(rating)
                    .build();
            logPost.setRecipeLog(recipeLog);

            logPostRepository.save(logPost);
        }
    }

    @Nested
    @DisplayName("defaultCookingStyle preference")
    class DefaultFoodStyleTests {

        @Test
        @DisplayName("Should return null defaultCookingStyle for new user")
        void newUser_HasNullDefaultFoodStyle() {
            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            assertThat(result.defaultCookingStyle()).isNull();
        }

        @Test
        @DisplayName("Should update defaultCookingStyle in profile")
        void updateProfile_WithDefaultFoodStyle_Success() {
            UserPrincipal principal = new UserPrincipal(testUser);
            UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                    null, null, null, null, null, null, null, "KR", null, null, null, null
            );

            UserDto result = userService.updateProfile(principal, request);

            assertThat(result.defaultCookingStyle()).isEqualTo("KR");
        }

        @Test
        @DisplayName("Should persist defaultCookingStyle after update")
        void updateProfile_DefaultFoodStyle_Persisted() {
            UserPrincipal principal = new UserPrincipal(testUser);
            UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                    null, null, null, null, null, null, null, "JP", null, null, null, null
            );

            userService.updateProfile(principal, request);

            // Verify in database
            User updated = userRepository.findById(testUser.getId()).orElseThrow();
            assertThat(updated.getDefaultCookingStyle()).isEqualTo("JP");
        }

        @Test
        @DisplayName("Should return defaultCookingStyle in UserDto after update")
        void getUserProfile_ReturnsDefaultFoodStyle() {
            // Set up user with defaultCookingStyle
            testUser.setDefaultCookingStyle("US");
            userRepository.save(testUser);

            UserDto result = userService.getUserProfile(testUser.getPublicId(), "ko");

            assertThat(result.defaultCookingStyle()).isEqualTo("US");
        }

        @Test
        @DisplayName("Should accept 'other' as valid food style")
        void updateProfile_OtherFoodStyle_Success() {
            UserPrincipal principal = new UserPrincipal(testUser);
            UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                    null, null, null, null, null, null, null, "other", null, null, null, null
            );

            UserDto result = userService.updateProfile(principal, request);

            assertThat(result.defaultCookingStyle()).isEqualTo("other");
        }

        @Test
        @DisplayName("Should accept various ISO country codes")
        void updateProfile_VariousCountryCodes_Success() {
            UserPrincipal principal = new UserPrincipal(testUser);

            // Test multiple country codes
            String[] countryCodes = {"KR", "US", "JP", "CN", "IT", "FR", "TH", "IN"};

            for (String code : countryCodes) {
                UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                        null, null, null, null, null, null, null, code, null, null, null, null
                );

                UserDto result = userService.updateProfile(principal, request);

                assertThat(result.defaultCookingStyle()).isEqualTo(code);
            }
        }
    }
}
