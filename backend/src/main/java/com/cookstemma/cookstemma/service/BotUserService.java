package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.bot.BotApiKey;
import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.dto.bot.*;
import com.cookstemma.cookstemma.repository.bot.BotApiKeyRepository;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Service for managing bot users.
 * Handles bot user creation, API key management, and bot user queries.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class BotUserService {

    private static final int MAX_API_KEYS_PER_BOT = 5;

    private final UserRepository userRepository;
    private final BotPersonaRepository botPersonaRepository;
    private final BotApiKeyRepository botApiKeyRepository;
    private final BotAuthService botAuthService;

    /**
     * Creates a new bot user with an associated persona and initial API key.
     * Admin only.
     */
    @Transactional
    public CreateBotUserResponseDto createBotUser(CreateBotUserRequestDto request) {
        // Validate username uniqueness
        if (userRepository.existsByUsername(request.username())) {
            throw new IllegalArgumentException("Username already exists: " + request.username());
        }

        // Find the persona
        BotPersona persona = botPersonaRepository.findByPublicId(request.personaPublicId())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Persona not found: " + request.personaPublicId()));

        // Create the bot user
        User botUser = User.builder()
                .username(request.username())
                .profileImageUrl(request.profileImageUrl())
                .bio(request.bio())
                .role(Role.BOT)
                .status(AccountStatus.ACTIVE)
                .locale(persona.getLocale())
                .defaultCookingStyle(persona.getCookingStyle())
                .isBot(true)
                .persona(persona)
                .build();

        userRepository.save(botUser);

        // Generate an initial API key
        BotAuthService.ApiKeyPair keyPair = botAuthService.generateApiKey();

        BotApiKey apiKey = BotApiKey.builder()
                .keyPrefix(keyPair.keyPrefix())
                .keyHash(keyPair.keyHash())
                .botUser(botUser)
                .name("Initial Key")
                .isActive(true)
                .build();

        botApiKeyRepository.save(apiKey);

        log.info("Created bot user: username={}, persona={}",
                botUser.getUsername(), persona.getName());

        return new CreateBotUserResponseDto(
                botUser.getPublicId(),
                botUser.getUsername(),
                persona.getPublicId(),
                persona.getName(),
                keyPair.fullKey(),
                keyPair.keyPrefix()
        );
    }

    /**
     * Creates a new API key for an existing bot user.
     * Admin only.
     */
    @Transactional
    public CreateApiKeyResponseDto createApiKey(CreateApiKeyRequestDto request) {
        // Find the bot user
        User botUser = userRepository.findByPublicId(request.botUserPublicId())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Bot user not found: " + request.botUserPublicId()));

        if (!botUser.isBot()) {
            throw new IllegalArgumentException("User is not a bot");
        }

        // Check key limit
        long activeKeyCount = botApiKeyRepository.countByBotUserAndIsActiveTrue(botUser);
        if (activeKeyCount >= MAX_API_KEYS_PER_BOT) {
            throw new IllegalArgumentException(
                    "Maximum API keys reached (" + MAX_API_KEYS_PER_BOT + "). " +
                    "Please revoke an existing key first.");
        }

        // Generate the new key
        BotAuthService.ApiKeyPair keyPair = botAuthService.generateApiKey();

        BotApiKey apiKey = BotApiKey.builder()
                .keyPrefix(keyPair.keyPrefix())
                .keyHash(keyPair.keyHash())
                .botUser(botUser)
                .name(request.name())
                .expiresAt(request.expiresAt())
                .isActive(true)
                .build();

        botApiKeyRepository.save(apiKey);

        log.info("Created API key for bot: user={}, keyPrefix={}",
                botUser.getUsername(), keyPair.keyPrefix());

        return new CreateApiKeyResponseDto(
                apiKey.getPublicId(),
                keyPair.fullKey(),
                keyPair.keyPrefix(),
                apiKey.getName(),
                apiKey.getExpiresAt(),
                apiKey.getCreatedAt()
        );
    }

    /**
     * Revokes (deactivates) an API key.
     * Admin only.
     */
    @Transactional
    public void revokeApiKey(UUID apiKeyPublicId) {
        BotApiKey apiKey = botApiKeyRepository.findByPublicId(apiKeyPublicId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "API key not found: " + apiKeyPublicId));

        apiKey.setActive(false);

        log.info("Revoked API key: prefix={}", apiKey.getKeyPrefix());
    }

    /**
     * Gets all API keys for a bot user (without exposing the actual keys).
     */
    public List<BotApiKeyDto> getApiKeysForBot(UUID botUserPublicId) {
        User botUser = userRepository.findByPublicId(botUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Bot user not found: " + botUserPublicId));

        if (!botUser.isBot()) {
            throw new IllegalArgumentException("User is not a bot");
        }

        return botApiKeyRepository.findByBotUserOrderByCreatedAtDesc(botUser)
                .stream()
                .map(BotApiKeyDto::from)
                .toList();
    }

    /**
     * Gets all bot users.
     */
    public List<User> getAllBotUsers() {
        return userRepository.findAll().stream()
                .filter(User::isBot)
                .toList();
    }

    /**
     * Gets all bot users as DTOs.
     */
    public List<BotUserDto> getAllBotUsersDto() {
        return getAllBotUsers().stream()
                .map(BotUserDto::from)
                .toList();
    }

    /**
     * Gets a bot user by public ID.
     */
    public User getBotUser(UUID publicId) {
        User user = userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + publicId));

        if (!user.isBot()) {
            throw new IllegalArgumentException("User is not a bot");
        }

        return user;
    }

    /**
     * Finds an existing bot user for a persona, or creates one if it doesn't exist.
     * Used for auto-creation flow when logging in by persona name.
     */
    @Transactional
    public User findOrCreateBotUser(BotPersona persona) {
        // Check if a bot user already exists for this persona
        return userRepository.findByPersona(persona)
                .orElseGet(() -> createBotUserForPersona(persona));
    }

    /**
     * Creates a new bot user for a persona with an auto-generated username.
     */
    private User createBotUserForPersona(BotPersona persona) {
        // Generate username from persona's English display name (e.g., "Sarah" -> "sarah")
        String displayName = persona.getDisplayNameForLocale("en");
        String baseUsername = displayName.toLowerCase().replaceAll("[^a-z0-9]", "");
        String username = baseUsername;

        // Ensure uniqueness (unlikely but handle collision)
        int suffix = 1;
        while (userRepository.existsByUsername(username)) {
            username = baseUsername + "_" + suffix++;
        }

        User botUser = User.builder()
                .username(username)
                .role(Role.BOT)
                .status(AccountStatus.ACTIVE)
                .locale(persona.getLocale())
                .defaultCookingStyle(persona.getCookingStyle())
                .isBot(true)
                .persona(persona)
                .build();

        userRepository.save(botUser);

        log.info("Auto-created bot user: username={}, persona={}",
                username, persona.getName());

        return botUser;
    }

    /**
     * Finds or creates an API key for a bot user.
     * Used for auto-creation flow.
     */
    @Transactional
    public BotApiKey findOrCreateApiKey(User botUser) {
        // Check for existing active key
        return botApiKeyRepository.findByBotUserAndIsActiveTrue(botUser)
                .stream()
                .findFirst()
                .orElseGet(() -> createApiKeyForBotUser(botUser));
    }

    /**
     * Creates an API key for a bot user.
     */
    private BotApiKey createApiKeyForBotUser(User botUser) {
        BotAuthService.ApiKeyPair keyPair = botAuthService.generateApiKey();

        BotApiKey apiKey = BotApiKey.builder()
                .keyPrefix(keyPair.keyPrefix())
                .keyHash(keyPair.keyHash())
                .botUser(botUser)
                .name("Auto-generated Key")
                .isActive(true)
                .build();

        botApiKeyRepository.save(apiKey);

        log.info("Auto-created API key for bot: user={}, keyPrefix={}",
                botUser.getUsername(), keyPair.keyPrefix());

        return apiKey;
    }
}
