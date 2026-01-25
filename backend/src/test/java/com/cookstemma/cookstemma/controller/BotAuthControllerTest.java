package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.bot.BotApiKey;
import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.*;
import com.cookstemma.cookstemma.dto.bot.BotLoginRequestDto;
import com.cookstemma.cookstemma.repository.bot.BotApiKeyRepository;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.service.BotAuthService;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class BotAuthControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private BotAuthService botAuthService;

    @Autowired
    private BotPersonaRepository botPersonaRepository;

    @Autowired
    private BotApiKeyRepository botApiKeyRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private BotPersona testPersona;
    private User botUser;
    private String validApiKey;

    @BeforeEach
    void setUp() {
        testPersona = BotPersona.builder()
                .name("controller_test_persona_" + System.currentTimeMillis())
                .displayName(Map.of("en", "Test Chef", "ko", "테스트 셰프"))
                .tone(BotTone.PROFESSIONAL)
                .skillLevel(BotSkillLevel.ADVANCED)
                .dietaryFocus(BotDietaryFocus.FINE_DINING)
                .vocabularyStyle(BotVocabularyStyle.TECHNICAL)
                .locale("ko-KR")
                .cookingStyle("KR")
                .kitchenStylePrompt("Test kitchen")
                .isActive(true)
                .build();
        botPersonaRepository.saveAndFlush(testPersona);

        botUser = testUserFactory.createBotUser("controller_test_bot_" + System.currentTimeMillis(), testPersona);

        BotAuthService.ApiKeyPair keyPair = botAuthService.generateApiKey();
        validApiKey = keyPair.fullKey();

        BotApiKey apiKey = BotApiKey.builder()
                .keyPrefix(keyPair.keyPrefix())
                .keyHash(keyPair.keyHash())
                .botUser(botUser)
                .name("Test Key")
                .isActive(true)
                .build();
        botApiKeyRepository.saveAndFlush(apiKey);
    }

    @Nested
    @DisplayName("POST /api/v1/auth/bot-login")
    class BotLogin {

        @Test
        @DisplayName("Valid API key should return tokens")
        void botLogin_ValidKey_ReturnsTokens() throws Exception {
            BotLoginRequestDto request = new BotLoginRequestDto(validApiKey);

            mockMvc.perform(post("/api/v1/auth/bot-login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.accessToken").exists())
                    .andExpect(jsonPath("$.refreshToken").exists())
                    .andExpect(jsonPath("$.userPublicId").value(botUser.getPublicId().toString()))
                    .andExpect(jsonPath("$.username").value(botUser.getUsername()))
                    .andExpect(jsonPath("$.personaPublicId").value(testPersona.getPublicId().toString()))
                    .andExpect(jsonPath("$.personaName").value(testPersona.getName()));
        }

        @Test
        @DisplayName("Invalid API key should return 400")
        void botLogin_InvalidKey_Returns400() throws Exception {
            BotLoginRequestDto request = new BotLoginRequestDto("pp_bot_invalid_key_abcdefghijklmnopqrstuvwx");

            mockMvc.perform(post("/api/v1/auth/bot-login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Wrong prefix should return 400")
        void botLogin_WrongPrefix_Returns400() throws Exception {
            BotLoginRequestDto request = new BotLoginRequestDto("wrong_prefix_key_12345678");

            mockMvc.perform(post("/api/v1/auth/bot-login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Missing API key should return 400")
        void botLogin_MissingKey_Returns400() throws Exception {
            mockMvc.perform(post("/api/v1/auth/bot-login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Deactivated API key should return 400")
        void botLogin_DeactivatedKey_Returns400() throws Exception {
            // Deactivate the key
            BotApiKey apiKey = botApiKeyRepository.findByKeyHashAndIsActiveTrue(
                    botAuthService.hashApiKey(validApiKey)).orElseThrow();
            apiKey.setActive(false);
            botApiKeyRepository.save(apiKey);

            BotLoginRequestDto request = new BotLoginRequestDto(validApiKey);

            mockMvc.perform(post("/api/v1/auth/bot-login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }
}
