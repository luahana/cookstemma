package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
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
            UserDto result = userService.getUserProfile(testUser.getPublicId());

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
                        .culinaryLocale("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);
            }

            UserDto result = userService.getUserProfile(testUser.getPublicId());

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
                    .culinaryLocale("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            Recipe recipe2 = Recipe.builder()
                    .title("Test Recipe 2")
                    .description("Description")
                    .culinaryLocale("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe2);

            // Create 2 successful logs (2 * 30 = 60 XP)
            // Total: 100 + 60 = 160 XP = Level 2
            createLogWithOutcome(recipe, "SUCCESS");
            createLogWithOutcome(recipe2, "SUCCESS");

            UserDto result = userService.getUserProfile(testUser.getPublicId());

            assertThat(result.recipeCount()).isEqualTo(2);
            assertThat(result.level()).isEqualTo(2); // 160 XP = Level 2
            assertThat(result.levelName()).isEqualTo("beginner");
        }

        @Test
        @DisplayName("Should reach homeCook level with enough activity")
        void reachesHomeCookLevel() {
            // Need 700 XP for Level 6 (homeCook)
            // 10 recipes = 500 XP, 7 success logs = 210 XP, total = 710 XP
            for (int i = 0; i < 10; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .description("Description")
                        .culinaryLocale("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .build();
                recipeRepository.save(recipe);

                if (i < 7) {
                    createLogWithOutcome(recipe, "SUCCESS");
                }
            }

            UserDto result = userService.getUserProfile(testUser.getPublicId());

            assertThat(result.level()).isEqualTo(6);
            assertThat(result.levelName()).isEqualTo("homeCook");
        }

        @Test
        @DisplayName("Should include all user profile fields")
        void includesAllProfileFields() {
            UserDto result = userService.getUserProfile(testUser.getPublicId());

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

        private void createLogWithOutcome(Recipe recipe, String outcome) {
            LogPost logPost = LogPost.builder()
                    .title("Log for " + recipe.getTitle())
                    .content("Test content")
                    .locale("ko-KR")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(logPost)
                    .recipe(recipe)
                    .outcome(outcome)
                    .build();
            logPost.setRecipeLog(recipeLog);

            logPostRepository.save(logPost);
        }
    }

    @Nested
    @DisplayName("defaultFoodStyle preference")
    class DefaultFoodStyleTests {

        @Test
        @DisplayName("Should return null defaultFoodStyle for new user")
        void newUser_HasNullDefaultFoodStyle() {
            UserDto result = userService.getUserProfile(testUser.getPublicId());

            assertThat(result.defaultFoodStyle()).isNull();
        }

        @Test
        @DisplayName("Should update defaultFoodStyle in profile")
        void updateProfile_WithDefaultFoodStyle_Success() {
            UserPrincipal principal = new UserPrincipal(testUser);
            UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                    null, null, null, null, null, null, null, "KR", null, null, null
            );

            UserDto result = userService.updateProfile(principal, request);

            assertThat(result.defaultFoodStyle()).isEqualTo("KR");
        }

        @Test
        @DisplayName("Should persist defaultFoodStyle after update")
        void updateProfile_DefaultFoodStyle_Persisted() {
            UserPrincipal principal = new UserPrincipal(testUser);
            UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                    null, null, null, null, null, null, null, "JP", null, null, null
            );

            userService.updateProfile(principal, request);

            // Verify in database
            User updated = userRepository.findById(testUser.getId()).orElseThrow();
            assertThat(updated.getDefaultFoodStyle()).isEqualTo("JP");
        }

        @Test
        @DisplayName("Should return defaultFoodStyle in UserDto after update")
        void getUserProfile_ReturnsDefaultFoodStyle() {
            // Set up user with defaultFoodStyle
            testUser.setDefaultFoodStyle("US");
            userRepository.save(testUser);

            UserDto result = userService.getUserProfile(testUser.getPublicId());

            assertThat(result.defaultFoodStyle()).isEqualTo("US");
        }

        @Test
        @DisplayName("Should accept 'other' as valid food style")
        void updateProfile_OtherFoodStyle_Success() {
            UserPrincipal principal = new UserPrincipal(testUser);
            UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                    null, null, null, null, null, null, null, "other", null, null, null
            );

            UserDto result = userService.updateProfile(principal, request);

            assertThat(result.defaultFoodStyle()).isEqualTo("other");
        }

        @Test
        @DisplayName("Should accept various ISO country codes")
        void updateProfile_VariousCountryCodes_Success() {
            UserPrincipal principal = new UserPrincipal(testUser);

            // Test multiple country codes
            String[] countryCodes = {"KR", "US", "JP", "CN", "IT", "FR", "TH", "IN"};

            for (String code : countryCodes) {
                UpdateProfileRequestDto request = new UpdateProfileRequestDto(
                        null, null, null, null, null, null, null, code, null, null, null
                );

                UserDto result = userService.updateProfile(principal, request);

                assertThat(result.defaultFoodStyle()).isEqualTo(code);
            }
        }
    }
}
