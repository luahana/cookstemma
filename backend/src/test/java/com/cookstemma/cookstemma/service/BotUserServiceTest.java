package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.bot.BotApiKey;
import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.*;
import com.cookstemma.cookstemma.dto.bot.*;
import com.cookstemma.cookstemma.repository.bot.BotApiKeyRepository;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BotUserServiceTest extends BaseIntegrationTest {

    @Autowired
    private BotUserService botUserService;

    @Autowired
    private BotAuthService botAuthService;

    @Autowired
    private BotPersonaRepository botPersonaRepository;

    @Autowired
    private BotApiKeyRepository botApiKeyRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private BotPersona testPersona;

    @BeforeEach
    void setUp() {
        testPersona = BotPersona.builder()
                .name("test_persona_" + System.currentTimeMillis())
                .displayName(Map.of("en", "Test Persona", "ko", "테스트 페르소나"))
                .tone(BotTone.CASUAL)
                .skillLevel(BotSkillLevel.INTERMEDIATE)
                .dietaryFocus(BotDietaryFocus.BUDGET)
                .vocabularyStyle(BotVocabularyStyle.SIMPLE)
                .locale("en-US")
                .cookingStyle("US")
                .kitchenStylePrompt("Simple kitchen prompt")
                .isActive(true)
                .build();
        botPersonaRepository.save(testPersona);
    }

    @Nested
    @DisplayName("Create Bot User")
    class CreateBotUserTests {

        @Test
        @DisplayName("Should create bot user with API key")
        void createBotUser_Success() {
            String username = "new_bot_" + System.currentTimeMillis();
            CreateBotUserRequestDto request = new CreateBotUserRequestDto(
                    username,
                    testPersona.getPublicId(),
                    "https://example.com/profile.jpg",
                    "Test bot bio"
            );

            CreateBotUserResponseDto response = botUserService.createBotUser(request);

            assertThat(response.userPublicId()).isNotNull();
            assertThat(response.username()).isEqualTo(username);
            assertThat(response.personaPublicId()).isEqualTo(testPersona.getPublicId());
            assertThat(response.personaName()).isEqualTo(testPersona.getName());
            assertThat(response.apiKey()).startsWith("pp_bot_");
            assertThat(response.apiKeyPrefix()).hasSize(8);

            // Verify user was created correctly
            User createdUser = userRepository.findByPublicId(response.userPublicId()).orElseThrow();
            assertThat(createdUser.isBot()).isTrue();
            assertThat(createdUser.getRole()).isEqualTo(Role.BOT);
            assertThat(createdUser.getPersona().getId()).isEqualTo(testPersona.getId());
            assertThat(createdUser.getLocale()).isEqualTo(testPersona.getLocale());
        }

        @Test
        @DisplayName("Should fail with duplicate username")
        void createBotUser_DuplicateUsername_Failure() {
            String username = "duplicate_bot_" + System.currentTimeMillis();
            testUserFactory.createTestUser(username);

            CreateBotUserRequestDto request = new CreateBotUserRequestDto(
                    username,
                    testPersona.getPublicId(),
                    null,
                    null
            );

            assertThatThrownBy(() -> botUserService.createBotUser(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Username already exists");
        }

        @Test
        @DisplayName("Should fail with invalid persona ID")
        void createBotUser_InvalidPersona_Failure() {
            CreateBotUserRequestDto request = new CreateBotUserRequestDto(
                    "new_bot_" + System.currentTimeMillis(),
                    UUID.randomUUID(),
                    null,
                    null
            );

            assertThatThrownBy(() -> botUserService.createBotUser(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Persona not found");
        }
    }

    @Nested
    @DisplayName("Create API Key")
    class CreateApiKeyTests {

        private User botUser;

        @BeforeEach
        void setUp() {
            // Create a bot user first
            String username = "api_key_test_bot_" + System.currentTimeMillis();
            CreateBotUserRequestDto createRequest = new CreateBotUserRequestDto(
                    username,
                    testPersona.getPublicId(),
                    null,
                    null
            );
            CreateBotUserResponseDto createResponse = botUserService.createBotUser(createRequest);
            botUser = userRepository.findByPublicId(createResponse.userPublicId()).orElseThrow();
        }

        @Test
        @DisplayName("Should create additional API key")
        void createApiKey_Success() {
            CreateApiKeyRequestDto request = new CreateApiKeyRequestDto(
                    botUser.getPublicId(),
                    "Second Key",
                    null
            );

            CreateApiKeyResponseDto response = botUserService.createApiKey(request);

            assertThat(response.publicId()).isNotNull();
            assertThat(response.apiKey()).startsWith("pp_bot_");
            assertThat(response.name()).isEqualTo("Second Key");
        }

        @Test
        @DisplayName("Should fail for non-bot user")
        void createApiKey_NonBotUser_Failure() {
            User regularUser = testUserFactory.createTestUser();

            CreateApiKeyRequestDto request = new CreateApiKeyRequestDto(
                    regularUser.getPublicId(),
                    "New Key",
                    null
            );

            assertThatThrownBy(() -> botUserService.createApiKey(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not a bot");
        }

        @Test
        @DisplayName("Should enforce maximum API key limit")
        void createApiKey_MaxLimitReached_Failure() {
            // Create 4 more keys (1 already exists from user creation)
            for (int i = 0; i < 4; i++) {
                CreateApiKeyRequestDto request = new CreateApiKeyRequestDto(
                        botUser.getPublicId(),
                        "Key " + (i + 2),
                        null
                );
                botUserService.createApiKey(request);
            }

            // Try to create a 6th key (should fail, limit is 5)
            CreateApiKeyRequestDto request = new CreateApiKeyRequestDto(
                    botUser.getPublicId(),
                    "Key 6",
                    null
            );

            assertThatThrownBy(() -> botUserService.createApiKey(request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Maximum API keys reached");
        }
    }

    @Nested
    @DisplayName("Revoke API Key")
    class RevokeApiKeyTests {

        private User botUser;
        private BotApiKey apiKey;

        @BeforeEach
        void setUp() {
            String username = "revoke_test_bot_" + System.currentTimeMillis();
            CreateBotUserRequestDto createRequest = new CreateBotUserRequestDto(
                    username,
                    testPersona.getPublicId(),
                    null,
                    null
            );
            CreateBotUserResponseDto createResponse = botUserService.createBotUser(createRequest);
            botUser = userRepository.findByPublicId(createResponse.userPublicId()).orElseThrow();
            apiKey = botApiKeyRepository.findByBotUserAndIsActiveTrueOrderByCreatedAtDesc(botUser).get(0);
        }

        @Test
        @DisplayName("Should revoke API key")
        void revokeApiKey_Success() {
            botUserService.revokeApiKey(apiKey.getPublicId());

            BotApiKey revokedKey = botApiKeyRepository.findByPublicId(apiKey.getPublicId()).orElseThrow();
            assertThat(revokedKey.isActive()).isFalse();
        }

        @Test
        @DisplayName("Should fail with invalid key ID")
        void revokeApiKey_InvalidId_Failure() {
            assertThatThrownBy(() -> botUserService.revokeApiKey(UUID.randomUUID()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("API key not found");
        }
    }

    @Nested
    @DisplayName("Find Or Create Bot User")
    class FindOrCreateBotUserTests {

        @Test
        @DisplayName("Should create bot user with username from English display name")
        void findOrCreateBotUser_UsernameFromDisplayName() {
            BotPersona persona = BotPersona.builder()
                    .name("homecook_sarah_" + System.currentTimeMillis())
                    .displayName(Map.of("en", "Sarah", "ko", "사라"))
                    .tone(BotTone.CASUAL)
                    .skillLevel(BotSkillLevel.BEGINNER)
                    .vocabularyStyle(BotVocabularyStyle.SIMPLE)
                    .locale("en-US")
                    .cookingStyle("US")
                    .kitchenStylePrompt("Cozy home kitchen")
                    .isActive(true)
                    .build();
            botPersonaRepository.save(persona);

            User botUser = botUserService.findOrCreateBotUser(persona);

            assertThat(botUser.getUsername()).isEqualTo("sarah");
            assertThat(botUser.isBot()).isTrue();
            assertThat(botUser.getPersona().getId()).isEqualTo(persona.getId());
        }

        @Test
        @DisplayName("Should return existing bot user if already exists for persona")
        void findOrCreateBotUser_ReturnsExisting() {
            BotPersona persona = BotPersona.builder()
                    .name("existing_persona_" + System.currentTimeMillis())
                    .displayName(Map.of("en", "Maria", "ko", "마리아"))
                    .tone(BotTone.WARM)
                    .skillLevel(BotSkillLevel.ADVANCED)
                    .vocabularyStyle(BotVocabularyStyle.STANDARD)
                    .locale("en-US")
                    .cookingStyle("US")
                    .kitchenStylePrompt("Mediterranean kitchen")
                    .isActive(true)
                    .build();
            botPersonaRepository.save(persona);

            User firstUser = botUserService.findOrCreateBotUser(persona);
            User secondUser = botUserService.findOrCreateBotUser(persona);

            assertThat(firstUser.getId()).isEqualTo(secondUser.getId());
            assertThat(firstUser.getUsername()).isEqualTo("maria");
        }

        @Test
        @DisplayName("Should add suffix when username collision occurs")
        void findOrCreateBotUser_HandlesDuplicateUsername() {
            // Create two personas with same English display name
            BotPersona persona1 = BotPersona.builder()
                    .name("mediterranean_maria_" + System.currentTimeMillis())
                    .displayName(Map.of("en", "Sophia", "ko", "소피아"))
                    .tone(BotTone.CASUAL)
                    .skillLevel(BotSkillLevel.INTERMEDIATE)
                    .vocabularyStyle(BotVocabularyStyle.SIMPLE)
                    .locale("en-US")
                    .cookingStyle("US")
                    .kitchenStylePrompt("Kitchen 1")
                    .isActive(true)
                    .build();
            botPersonaRepository.save(persona1);

            BotPersona persona2 = BotPersona.builder()
                    .name("homecook_sophia_" + System.currentTimeMillis())
                    .displayName(Map.of("en", "Sophia", "ko", "소피아"))
                    .tone(BotTone.WARM)
                    .skillLevel(BotSkillLevel.BEGINNER)
                    .vocabularyStyle(BotVocabularyStyle.STANDARD)
                    .locale("ko-KR")
                    .cookingStyle("KO")
                    .kitchenStylePrompt("Kitchen 2")
                    .isActive(true)
                    .build();
            botPersonaRepository.save(persona2);

            User user1 = botUserService.findOrCreateBotUser(persona1);
            User user2 = botUserService.findOrCreateBotUser(persona2);

            assertThat(user1.getUsername()).isEqualTo("sophia");
            assertThat(user2.getUsername()).isEqualTo("sophia_1");
        }
    }

    @Nested
    @DisplayName("Get API Keys")
    class GetApiKeysTests {

        private User botUser;

        @BeforeEach
        void setUp() {
            String username = "get_keys_test_bot_" + System.currentTimeMillis();
            CreateBotUserRequestDto createRequest = new CreateBotUserRequestDto(
                    username,
                    testPersona.getPublicId(),
                    null,
                    null
            );
            CreateBotUserResponseDto createResponse = botUserService.createBotUser(createRequest);
            botUser = userRepository.findByPublicId(createResponse.userPublicId()).orElseThrow();

            // Create a second key
            CreateApiKeyRequestDto keyRequest = new CreateApiKeyRequestDto(
                    botUser.getPublicId(),
                    "Second Key",
                    null
            );
            botUserService.createApiKey(keyRequest);
        }

        @Test
        @DisplayName("Should return all API keys for bot user")
        void getApiKeysForBot_Success() {
            List<BotApiKeyDto> keys = botUserService.getApiKeysForBot(botUser.getPublicId());

            assertThat(keys).hasSize(2);
            assertThat(keys).extracting(BotApiKeyDto::name)
                    .containsExactlyInAnyOrder("Initial Key", "Second Key");
        }

        @Test
        @DisplayName("Should fail for non-bot user")
        void getApiKeysForBot_NonBotUser_Failure() {
            User regularUser = testUserFactory.createTestUser();

            assertThatThrownBy(() -> botUserService.getApiKeysForBot(regularUser.getPublicId()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not a bot");
        }
    }
}
