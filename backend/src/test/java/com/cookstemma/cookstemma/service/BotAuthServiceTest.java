package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.bot.BotApiKey;
import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.*;
import com.cookstemma.cookstemma.dto.bot.BotLoginRequestDto;
import com.cookstemma.cookstemma.dto.bot.BotLoginResponseDto;
import com.cookstemma.cookstemma.repository.bot.BotApiKeyRepository;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BotAuthServiceTest extends BaseIntegrationTest {

    @Autowired
    private BotAuthService botAuthService;

    @Autowired
    private BotApiKeyRepository botApiKeyRepository;

    @Autowired
    private BotPersonaRepository botPersonaRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private BotPersona testPersona;
    private User botUser;
    private String validApiKey;

    @BeforeEach
    void setUp() {
        // Create a test persona
        testPersona = BotPersona.builder()
                .name("test_chef_" + System.currentTimeMillis())
                .displayName(Map.of("en", "Test Chef", "ko", "테스트 셰프"))
                .tone(BotTone.PROFESSIONAL)
                .skillLevel(BotSkillLevel.ADVANCED)
                .dietaryFocus(BotDietaryFocus.FINE_DINING)
                .vocabularyStyle(BotVocabularyStyle.TECHNICAL)
                .locale("ko-KR")
                .cookingStyle("KR")
                .kitchenStylePrompt("Test kitchen prompt")
                .isActive(true)
                .build();
        botPersonaRepository.save(testPersona);

        // Create a bot user
        botUser = testUserFactory.createBotUser("test_bot_" + System.currentTimeMillis(), testPersona);

        // Generate and save an API key
        BotAuthService.ApiKeyPair keyPair = botAuthService.generateApiKey();
        validApiKey = keyPair.fullKey();

        BotApiKey apiKey = BotApiKey.builder()
                .keyPrefix(keyPair.keyPrefix())
                .keyHash(keyPair.keyHash())
                .botUser(botUser)
                .name("Test Key")
                .isActive(true)
                .build();
        botApiKeyRepository.save(apiKey);
    }

    @Nested
    @DisplayName("API Key Generation")
    class GenerateApiKeyTests {

        @Test
        @DisplayName("Should generate API key with correct format")
        void generateApiKey_CorrectFormat() {
            BotAuthService.ApiKeyPair keyPair = botAuthService.generateApiKey();

            assertThat(keyPair.fullKey()).startsWith("pp_bot_");
            assertThat(keyPair.fullKey().length()).isGreaterThan(30);
            assertThat(keyPair.keyPrefix()).hasSize(8);
            assertThat(keyPair.keyHash()).hasSize(64); // SHA-256 hex is 64 chars
        }

        @Test
        @DisplayName("Should generate unique keys each time")
        void generateApiKey_Unique() {
            BotAuthService.ApiKeyPair key1 = botAuthService.generateApiKey();
            BotAuthService.ApiKeyPair key2 = botAuthService.generateApiKey();

            assertThat(key1.fullKey()).isNotEqualTo(key2.fullKey());
            assertThat(key1.keyHash()).isNotEqualTo(key2.keyHash());
        }
    }

    @Nested
    @DisplayName("API Key Hashing")
    class HashApiKeyTests {

        @Test
        @DisplayName("Should produce consistent hash for same input")
        void hashApiKey_Consistent() {
            String key = "pp_bot_test_key_123";

            String hash1 = botAuthService.hashApiKey(key);
            String hash2 = botAuthService.hashApiKey(key);

            assertThat(hash1).isEqualTo(hash2);
        }

        @Test
        @DisplayName("Should produce different hashes for different inputs")
        void hashApiKey_DifferentInputs() {
            String hash1 = botAuthService.hashApiKey("pp_bot_key1");
            String hash2 = botAuthService.hashApiKey("pp_bot_key2");

            assertThat(hash1).isNotEqualTo(hash2);
        }
    }

    @Nested
    @DisplayName("Login with API Key")
    class LoginTests {

        @Test
        @DisplayName("Should login successfully with valid API key")
        void loginWithApiKey_ValidKey_Success() {
            BotLoginRequestDto request = new BotLoginRequestDto(validApiKey);

            BotLoginResponseDto response = botAuthService.loginWithApiKey(request);

            assertThat(response.accessToken()).isNotBlank();
            assertThat(response.refreshToken()).isNotBlank();
            assertThat(response.userPublicId()).isEqualTo(botUser.getPublicId());
            assertThat(response.username()).isEqualTo(botUser.getUsername());
            assertThat(response.personaPublicId()).isEqualTo(testPersona.getPublicId());
            assertThat(response.personaName()).isEqualTo(testPersona.getName());
        }

        @Test
        @DisplayName("Should fail with invalid API key")
        void loginWithApiKey_InvalidKey_Failure() {
            BotLoginRequestDto request = new BotLoginRequestDto("pp_bot_invalid_key_12345678901234");

            assertThatThrownBy(() -> botAuthService.loginWithApiKey(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Invalid or inactive API key");
        }

        @Test
        @DisplayName("Should fail with wrong prefix")
        void loginWithApiKey_WrongPrefix_Failure() {
            BotLoginRequestDto request = new BotLoginRequestDto("wrong_prefix_key");

            assertThatThrownBy(() -> botAuthService.loginWithApiKey(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Invalid API key format");
        }

        @Test
        @DisplayName("Should fail with deactivated API key")
        void loginWithApiKey_DeactivatedKey_Failure() {
            // Deactivate the key
            BotApiKey apiKey = botApiKeyRepository.findByKeyHashAndIsActiveTrue(
                    botAuthService.hashApiKey(validApiKey)).orElseThrow();
            apiKey.setActive(false);
            botApiKeyRepository.save(apiKey);

            BotLoginRequestDto request = new BotLoginRequestDto(validApiKey);

            assertThatThrownBy(() -> botAuthService.loginWithApiKey(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Invalid or inactive API key");
        }

        @Test
        @DisplayName("Should fail with expired API key")
        void loginWithApiKey_ExpiredKey_Failure() {
            // Set expiration in the past
            BotApiKey apiKey = botApiKeyRepository.findByKeyHashAndIsActiveTrue(
                    botAuthService.hashApiKey(validApiKey)).orElseThrow();
            apiKey.setExpiresAt(Instant.now().minus(1, ChronoUnit.DAYS));
            botApiKeyRepository.save(apiKey);

            BotLoginRequestDto request = new BotLoginRequestDto(validApiKey);

            assertThatThrownBy(() -> botAuthService.loginWithApiKey(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("expired");
        }

        @Test
        @DisplayName("Should update last used timestamp on successful login")
        void loginWithApiKey_UpdatesLastUsed() {
            BotLoginRequestDto request = new BotLoginRequestDto(validApiKey);

            botAuthService.loginWithApiKey(request);

            BotApiKey apiKey = botApiKeyRepository.findByKeyHashAndIsActiveTrue(
                    botAuthService.hashApiKey(validApiKey)).orElseThrow();
            assertThat(apiKey.getLastUsedAt()).isNotNull();
            assertThat(apiKey.getLastUsedAt()).isAfter(Instant.now().minus(1, ChronoUnit.MINUTES));
        }
    }
}
