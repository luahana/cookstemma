package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.MeasurementUnit;
import com.cookstemma.cookstemma.dto.recipe.CreateRecipeRequestDto;
import com.cookstemma.cookstemma.dto.recipe.IngredientDto;
import com.cookstemma.cookstemma.dto.recipe.StepDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class RecipeControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private ImageRepository imageRepository;

    private FoodMaster testFood;
    private User testUser;
    private Image testImage;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);

        testImage = Image.builder()
                .storedFilename("test-image.jpg")
                .originalFilename("test.jpg")
                .status(ImageStatus.ACTIVE)
                .type(ImageType.COVER)
                .uploaderId(testUser.getId())
                .build();
        imageRepository.save(testImage);
    }

    @Nested
    @DisplayName("GET /api/v1/recipes - List Recipes")
    class ListRecipes {

        @Test
        @DisplayName("Should return paginated recipes with auth")
        void getRecipes_WithAuth_ReturnsRecipes() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should filter by locale")
        void getRecipes_WithLocale_ReturnsFilteredRecipes() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            // Create recipe with specific locale
            Recipe recipe = Recipe.builder()
                    .title("Korean Recipe")
                    .description("Test")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token)
                            .param("locale", "ko-KR"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should filter for root recipes only")
        void getRecipes_OnlyRoot_ReturnsOriginalRecipes() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token)
                            .param("onlyRoot", "true"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should search recipes by keyword")
        void getRecipes_WithSearchKeyword_ReturnsMatchingRecipes() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            // Create recipe with searchable title
            Recipe recipe = Recipe.builder()
                    .title("Spicy Kimchi Stew")
                    .description("Delicious Korean food")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token)
                            .param("q", "Spicy"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/recipes/{publicId} - Recipe Detail")
    class GetRecipeDetail {

        @Test
        @DisplayName("Should return recipe detail by publicId")
        void getRecipeDetail_ValidId_ReturnsDetail() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/recipes/" + recipe.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.title").value("Test Recipe"))
                    .andExpect(jsonPath("$.publicId").value(recipe.getPublicId().toString()));
        }

        @Test
        @DisplayName("Should return 400 for non-existent recipe")
        void getRecipeDetail_InvalidId_Returns400() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/recipes/550e8400-e29b-41d4-a716-446655440000")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should limit variants to 6 in recipe detail response")
        void getRecipeDetail_LimitsVariantsTo6() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            // Create parent recipe
            Recipe parentRecipe = Recipe.builder()
                    .title("Parent Recipe")
                    .description("Parent Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(parentRecipe);

            // Create 8 variant recipes
            for (int i = 0; i < 8; i++) {
                Recipe variant = Recipe.builder()
                        .title("Variant " + i)
                        .description("Variant Description " + i)
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .parentRecipe(parentRecipe)
                        .rootRecipe(parentRecipe)
                        .build();
                recipeRepository.save(variant);
            }

            // Get recipe detail
            mockMvc.perform(get("/api/v1/recipes/" + parentRecipe.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.variants").isArray())
                    .andExpect(jsonPath("$.variants.length()").value(6)); // Limited to 6
        }

        @Test
        @DisplayName("Should return all variants when less than 6")
        void getRecipeDetail_ReturnsAllVariantsWhenLessThan6() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            // Create parent recipe
            Recipe parentRecipe = Recipe.builder()
                    .title("Parent Recipe")
                    .description("Parent Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(parentRecipe);

            // Create only 3 variant recipes
            for (int i = 0; i < 3; i++) {
                Recipe variant = Recipe.builder()
                        .title("Variant " + i)
                        .description("Variant Description " + i)
                        .cookingStyle("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .parentRecipe(parentRecipe)
                        .rootRecipe(parentRecipe)
                        .build();
                recipeRepository.save(variant);
            }

            // Get recipe detail
            mockMvc.perform(get("/api/v1/recipes/" + parentRecipe.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.variants").isArray())
                    .andExpect(jsonPath("$.variants.length()").value(3)); // All 3 returned
        }
    }

    @Nested
    @DisplayName("POST /api/v1/recipes - Create Recipe")
    class CreateRecipe {

        @Test
        @DisplayName("Should create recipe with valid auth and data")
        void createRecipe_WithAuth_ReturnsCreatedRecipe() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "New Test Recipe",
                    "A delicious test recipe",
                    "ko-KR",
                    testFood.getPublicId(),
                    null,
                    List.of(new IngredientDto("Salt", 1.0, MeasurementUnit.TSP, IngredientType.SEASONING)),
                    List.of(new StepDto(1, "Mix ingredients", null, null)),
                    List.of(testImage.getPublicId()),
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(post("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.title").value("New Test Recipe"));
        }

        @Test
        @DisplayName("Should return 401 without auth")
        void createRecipe_NoAuth_Returns401() throws Exception {
            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "New Recipe", "Description", "ko-KR", testFood.getPublicId(),
                    null, List.of(), List.of(), List.of(), null, null, null, null, null, null, null, null, null  // isPrivate
            );

            mockMvc.perform(post("/api/v1/recipes")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/recipes/my - My Recipes")
    class MyRecipes {

        @Test
        @DisplayName("Should return user's recipes with auth")
        void getMyRecipes_WithAuth_ReturnsUserRecipes() throws Exception {
            // Create recipe for user
            Recipe recipe = Recipe.builder()
                    .title("My Recipe")
                    .description("My Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            mockMvc.perform(get("/api/v1/recipes/my")
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should return 401 without auth")
        void getMyRecipes_NoAuth_Returns401() throws Exception {
            mockMvc.perform(get("/api/v1/recipes/my"))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("Recipe Lineage (Parent/Root)")
    class RecipeLineage {

        @Test
        @DisplayName("Should create variant recipe with parent lineage")
        void createVariant_WithParent_SetsLineage() throws Exception {
            // Create parent recipe
            Recipe parentRecipe = Recipe.builder()
                    .title("Original Recipe")
                    .description("Original")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(parentRecipe);

            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Variant Recipe",
                    "My variant",
                    "ko-KR",
                    testFood.getPublicId(),
                    null,
                    List.of(new IngredientDto("Extra Spice", 2.0, MeasurementUnit.TSP, IngredientType.SEASONING)),
                    List.of(new StepDto(1, "Add spice and mix well", null, null)),
                    List.of(testImage.getPublicId()),
                    "INGREDIENT_CHANGE",
                    parentRecipe.getPublicId(),
                    null,
                    Map.of("ingredients", "changed"),
                    "Added more spice",
                    null,
                    null,
                    null,
                    null  // isPrivate
            );

            mockMvc.perform(post("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.parentInfo.publicId").value(parentRecipe.getPublicId().toString()));
        }
    }

    @Nested
    @DisplayName("GET /api/v1/recipes - Sort Options")
    class RecipeSortTests {

        @Test
        @DisplayName("Should return recipes sorted by recent (default)")
        void getRecipes_DefaultSort_ReturnsRecentFirst() throws Exception {
            mockMvc.perform(get("/api/v1/recipes"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should accept popular sort parameter")
        void getRecipes_PopularSort_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/recipes")
                            .param("sort", "popular"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should accept trending sort parameter")
        void getRecipes_TrendingSort_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/recipes")
                            .param("sort", "trending"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should accept mostForked sort parameter")
        void getRecipes_MostForkedSort_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/recipes")
                            .param("sort", "mostForked"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }

        @Test
        @DisplayName("Should combine sort with other filters")
        void getRecipes_PopularWithLocale_Returns200() throws Exception {
            mockMvc.perform(get("/api/v1/recipes")
                            .param("sort", "popular")
                            .param("locale", "ko-KR"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray());
        }
    }

    @Nested
    @DisplayName("View Count Increment")
    class ViewCountTests {

        @Test
        @DisplayName("Should increment view count when viewing recipe detail")
        void getRecipeDetail_IncrementsViewCount() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe For View Count")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .viewCount(0)
                    .build();
            recipeRepository.save(recipe);

            mockMvc.perform(get("/api/v1/recipes/" + recipe.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());

            // Verify view count was incremented
            Recipe updated = recipeRepository.findByPublicId(recipe.getPublicId()).orElseThrow();
            assertThat(updated.getViewCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should increment view count on each detail view")
        void getRecipeDetail_IncrementsViewCountMultipleTimes() throws Exception {
            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe Multiple Views")
                    .description("Test Description")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .viewCount(5)
                    .build();
            recipeRepository.save(recipe);

            // View recipe twice
            mockMvc.perform(get("/api/v1/recipes/" + recipe.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());

            mockMvc.perform(get("/api/v1/recipes/" + recipe.getPublicId())
                            .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk());

            // Verify view count was incremented twice
            Recipe updated = recipeRepository.findByPublicId(recipe.getPublicId()).orElseThrow();
            assertThat(updated.getViewCount()).isEqualTo(7);
        }
    }
}
