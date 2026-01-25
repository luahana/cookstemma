package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.*;
import com.cookstemma.cookstemma.dto.bot.CreateApiKeyRequestDto;
import com.cookstemma.cookstemma.dto.bot.CreateBotUserRequestDto;
import com.cookstemma.cookstemma.dto.bot.CreateBotUserResponseDto;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.service.BotUserService;
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

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class BotAdminControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private BotPersonaRepository botPersonaRepository;

    @Autowired
    private BotUserService botUserService;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    private User adminUser;
    private User regularUser;
    private String adminToken;
    private String userToken;
    private BotPersona testPersona;

    @BeforeEach
    void setUp() {
        adminUser = testUserFactory.createAdminUser();
        regularUser = testUserFactory.createTestUser();
        adminToken = testJwtTokenProvider.createAccessToken(adminUser.getPublicId(), "ADMIN");
        userToken = testJwtTokenProvider.createAccessToken(regularUser.getPublicId(), "USER");

        testPersona = BotPersona.builder()
                .name("admin_test_persona_" + System.currentTimeMillis())
                .displayName(Map.of("en", "Admin Test Chef", "ko", "관리자 테스트 셰프"))
                .tone(BotTone.CASUAL)
                .skillLevel(BotSkillLevel.INTERMEDIATE)
                .dietaryFocus(BotDietaryFocus.BUDGET)
                .vocabularyStyle(BotVocabularyStyle.SIMPLE)
                .locale("en-US")
                .cookingStyle("US")
                .kitchenStylePrompt("Admin test kitchen")
                .isActive(true)
                .build();
        botPersonaRepository.save(testPersona);
    }

    @Nested
    @DisplayName("POST /api/v1/admin/bots/users - Create Bot User")
    class CreateBotUser {

        @Test
        @DisplayName("Admin can create bot user")
        void createBotUser_AsAdmin_Success() throws Exception {
            String username = "new_admin_bot_" + System.currentTimeMillis();
            CreateBotUserRequestDto request = new CreateBotUserRequestDto(
                    username,
                    testPersona.getPublicId(),
                    "https://example.com/avatar.jpg",
                    "Test bot bio"
            );

            mockMvc.perform(post("/api/v1/admin/bots/users")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.userPublicId").exists())
                    .andExpect(jsonPath("$.username").value(username))
                    .andExpect(jsonPath("$.personaPublicId").value(testPersona.getPublicId().toString()))
                    .andExpect(jsonPath("$.apiKey").exists())
                    .andExpect(jsonPath("$.apiKeyPrefix").exists());
        }

        @Test
        @DisplayName("Non-admin cannot create bot user")
        void createBotUser_AsUser_Forbidden() throws Exception {
            CreateBotUserRequestDto request = new CreateBotUserRequestDto(
                    "forbidden_bot_" + System.currentTimeMillis(),
                    testPersona.getPublicId(),
                    null,
                    null
            );

            mockMvc.perform(post("/api/v1/admin/bots/users")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Unauthenticated request returns 401")
        void createBotUser_NoAuth_Unauthorized() throws Exception {
            CreateBotUserRequestDto request = new CreateBotUserRequestDto(
                    "unauth_bot_" + System.currentTimeMillis(),
                    testPersona.getPublicId(),
                    null,
                    null
            );

            mockMvc.perform(post("/api/v1/admin/bots/users")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/admin/bots/api-keys - Create API Key")
    class CreateApiKey {

        private User existingBot;

        @BeforeEach
        void setUp() {
            CreateBotUserRequestDto createRequest = new CreateBotUserRequestDto(
                    "existing_bot_" + System.currentTimeMillis(),
                    testPersona.getPublicId(),
                    null,
                    null
            );
            CreateBotUserResponseDto response = botUserService.createBotUser(createRequest);
            existingBot = User.builder().build();
            existingBot.setPublicId(response.userPublicId());
        }

        @Test
        @DisplayName("Admin can create additional API key")
        void createApiKey_AsAdmin_Success() throws Exception {
            CreateApiKeyRequestDto request = new CreateApiKeyRequestDto(
                    existingBot.getPublicId(),
                    "New Admin Key",
                    null
            );

            mockMvc.perform(post("/api/v1/admin/bots/api-keys")
                            .header("Authorization", "Bearer " + adminToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.publicId").exists())
                    .andExpect(jsonPath("$.apiKey").exists())
                    .andExpect(jsonPath("$.name").value("New Admin Key"));
        }

        @Test
        @DisplayName("Non-admin cannot create API key")
        void createApiKey_AsUser_Forbidden() throws Exception {
            CreateApiKeyRequestDto request = new CreateApiKeyRequestDto(
                    existingBot.getPublicId(),
                    "Forbidden Key",
                    null
            );

            mockMvc.perform(post("/api/v1/admin/bots/api-keys")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/admin/bots/personas - Get Personas")
    class GetPersonas {

        @Test
        @DisplayName("Admin can get all personas")
        void getAllPersonas_AsAdmin_Success() throws Exception {
            mockMvc.perform(get("/api/v1/admin/bots/personas")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$").isArray())
                    .andExpect(jsonPath("$[0].publicId").exists())
                    .andExpect(jsonPath("$[0].name").exists());
        }

        @Test
        @DisplayName("Non-admin cannot get personas")
        void getAllPersonas_AsUser_Forbidden() throws Exception {
            mockMvc.perform(get("/api/v1/admin/bots/personas")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/admin/bots/personas/{id}/activate - Activate Persona")
    class ActivatePersona {

        @Test
        @DisplayName("Admin can activate persona")
        void activatePersona_AsAdmin_Success() throws Exception {
            mockMvc.perform(post("/api/v1/admin/bots/personas/" + testPersona.getPublicId() + "/activate")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Non-admin cannot activate persona")
        void activatePersona_AsUser_Forbidden() throws Exception {
            mockMvc.perform(post("/api/v1/admin/bots/personas/" + testPersona.getPublicId() + "/activate")
                            .header("Authorization", "Bearer " + userToken))
                    .andExpect(status().isForbidden());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/admin/bots/personas/{id}/deactivate - Deactivate Persona")
    class DeactivatePersona {

        @Test
        @DisplayName("Admin can deactivate persona")
        void deactivatePersona_AsAdmin_Success() throws Exception {
            mockMvc.perform(post("/api/v1/admin/bots/personas/" + testPersona.getPublicId() + "/deactivate")
                            .header("Authorization", "Bearer " + adminToken))
                    .andExpect(status().isOk());
        }
    }
}
