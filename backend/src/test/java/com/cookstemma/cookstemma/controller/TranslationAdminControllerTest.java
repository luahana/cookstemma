package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TranslationAdminControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    private User adminUser;
    private User regularUser;
    private String adminToken;
    private String userToken;
    private Recipe testRecipe;

    @BeforeEach
    void setUp() {
        adminUser = testUserFactory.createAdminUser();
        regularUser = testUserFactory.createTestUser();
        adminToken = testJwtTokenProvider.createAccessToken(adminUser.getPublicId(), "ADMIN");
        userToken = testJwtTokenProvider.createAccessToken(regularUser.getPublicId(), "USER");

        // Create food master
        FoodMaster foodMaster = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.saveAndFlush(foodMaster);

        // Create test recipe
        testRecipe = Recipe.builder()
                .title("English Recipe Title")
                .description("English description")
                .cookingStyle("JP")
                .foodMaster(foodMaster)
                .creatorId(regularUser.getId())
                .build();
        recipeRepository.saveAndFlush(testRecipe);
    }

    @Test
    @DisplayName("Admin should be able to retranslate a recipe")
    void retranslateRecipe_AsAdmin_ShouldSucceed() throws Exception {
        mockMvc.perform(post("/api/v1/admin/translations/recipes/{publicId}/retranslate", testRecipe.getPublicId())
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLocale": "en"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Translation queued successfully"))
                .andExpect(jsonPath("$.recipePublicId").value(testRecipe.getPublicId().toString()))
                .andExpect(jsonPath("$.sourceLocale").value("en"))
                .andExpect(jsonPath("$.targetLocales").value(19)); // Excludes source locale

        // Verify translation event was created
        List<TranslationEvent> events = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                TranslatableEntity.RECIPE_FULL, testRecipe.getId(),
                List.of(TranslationStatus.PENDING));

        assertThat(events).hasSize(1);
        assertThat(events.get(0).getSourceLocale()).isEqualTo("en-US");  // BCP47 format
        assertThat(events.get(0).getTargetLocales()).hasSize(19); // Excludes source locale
    }

    @Test
    @DisplayName("Regular user should not be able to retranslate a recipe")
    void retranslateRecipe_AsRegularUser_ShouldReturn403() throws Exception {
        mockMvc.perform(post("/api/v1/admin/translations/recipes/{publicId}/retranslate", testRecipe.getPublicId())
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLocale": "en"}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Should return 400 for non-existent recipe")
    void retranslateRecipe_NonExistentRecipe_ShouldReturn400() throws Exception {
        mockMvc.perform(post("/api/v1/admin/translations/recipes/{publicId}/retranslate",
                        "00000000-0000-0000-0000-000000000000")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLocale": "en"}
                                """))
                .andExpect(status().isBadRequest());
    }
}
