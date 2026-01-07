package com.pairingplanet.pairing_planet.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.recipe.CreateRecipeRequestDto;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import com.pairingplanet.pairing_planet.support.TestJwtTokenProvider;
import com.pairingplanet.pairing_planet.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

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

    private FoodMaster testFood;
    private User testUser;

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
                    .culinaryLocale("ko-KR")
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
                    .culinaryLocale("ko-KR")
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
                    .culinaryLocale("ko-KR")
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
                    List.of(),
                    List.of(),
                    List.of(),
                    null,
                    null,
                    null,
                    null,
                    null,
                    null
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
                    null, List.of(), List.of(), List.of(), null, null, null, null, null, null
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
                    .culinaryLocale("ko-KR")
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
                    .culinaryLocale("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(parentRecipe);

            String token = testJwtTokenProvider.createAccessToken(testUser.getPublicId(), "USER");

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Variant Recipe",
                    "My variant",
                    "ko-KR",
                    null,
                    null,
                    List.of(),
                    List.of(),
                    List.of(),
                    "INGREDIENT_CHANGE",
                    parentRecipe.getPublicId(),
                    null,
                    Map.of("ingredients", "changed"),
                    "Added more spice",
                    null
            );

            mockMvc.perform(post("/api/v1/recipes")
                            .header("Authorization", "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.parentInfo.publicId").value(parentRecipe.getPublicId().toString()));
        }
    }
}
