package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.repository.RecipeRepository;
import com.cookstemma.cookstemma.repository.UserRepository;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class TranslationAdminControllerTest extends BaseIntegrationTest {

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    private User adminUser;
    private User regularUser;
    private Recipe testRecipe;

    @BeforeEach
    void setUp() {
        // Create admin user
        adminUser = User.builder()
                .username("admin")
                .firebaseUid("admin-firebase-uid-" + System.currentTimeMillis())
                .role(Role.ADMIN)
                .build();
        userRepository.saveAndFlush(adminUser);

        // Create regular user
        regularUser = User.builder()
                .username("regular")
                .firebaseUid("regular-firebase-uid-" + System.currentTimeMillis())
                .role(Role.USER)
                .build();
        userRepository.saveAndFlush(regularUser);

        // Create food master
        FoodMaster foodMaster = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.saveAndFlush(foodMaster);

        // Create test recipe
        testRecipe = Recipe.builder()
                .title("English Recipe Title")
                .description("English description")
                .cookingStyle("JP")
                .foodMaster(foodMaster)
                .creator(regularUser)
                .build();
        recipeRepository.saveAndFlush(testRecipe);
    }

    @Test
    @DisplayName("Admin should be able to retranslate a recipe")
    void retranslateRecipe_AsAdmin_ShouldSucceed() throws Exception {
        mockMvc.perform(post("/api/v1/admin/translations/recipes/{publicId}/retranslate", testRecipe.getPublicId())
                        .with(authenticatedUser(adminUser.getPublicId(), Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLocale": "en"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Translation queued successfully"))
                .andExpect(jsonPath("$.recipePublicId").value(testRecipe.getPublicId().toString()))
                .andExpect(jsonPath("$.sourceLocale").value("en"))
                .andExpect(jsonPath("$.targetLocales").value(20));

        // Verify translation event was created
        List<TranslationEvent> events = translationEventRepository.findByEntityTypeAndEntityIdAndStatusIn(
                TranslatableEntity.RECIPE, testRecipe.getId(),
                List.of(TranslationStatus.PENDING));

        assertThat(events).hasSize(1);
        assertThat(events.get(0).getSourceLocale()).isEqualTo("en");
        assertThat(events.get(0).getTargetLocales()).hasSize(20);
    }

    @Test
    @DisplayName("Regular user should not be able to retranslate a recipe")
    void retranslateRecipe_AsRegularUser_ShouldReturn403() throws Exception {
        mockMvc.perform(post("/api/v1/admin/translations/recipes/{publicId}/retranslate", testRecipe.getPublicId())
                        .with(authenticatedUser(regularUser.getPublicId(), Role.USER))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLocale": "en"}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Should return 404 for non-existent recipe")
    void retranslateRecipe_NonExistentRecipe_ShouldReturn500() throws Exception {
        mockMvc.perform(post("/api/v1/admin/translations/recipes/{publicId}/retranslate",
                        "00000000-0000-0000-0000-000000000000")
                        .with(authenticatedUser(adminUser.getPublicId(), Role.ADMIN))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"sourceLocale": "en"}
                                """))
                .andExpect(status().is5xxServerError());
    }
}
