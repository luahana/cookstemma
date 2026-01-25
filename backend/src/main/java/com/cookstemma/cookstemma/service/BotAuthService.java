package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.bot.BotApiKey;
import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.bot.BotLoginRequestDto;
import com.cookstemma.cookstemma.dto.bot.BotLoginResponseDto;
import com.cookstemma.cookstemma.repository.bot.BotApiKeyRepository;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.security.JwtTokenProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

/**
 * Service for bot API key authentication.
 * Handles login via API key, persona-based login (with auto-creation), and token generation.
 */
@Service
@Slf4j
public class BotAuthService {

    private static final String API_KEY_PREFIX = "pp_bot_";
    private static final int API_KEY_RANDOM_LENGTH = 32; // 256 bits of entropy

    private final BotApiKeyRepository botApiKeyRepository;
    private final BotPersonaRepository botPersonaRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final String botInternalSecret;

    // Circular dependency: BotUserService depends on BotAuthService for generateApiKey()
    // Use setter injection for optional dependency
    private BotUserService botUserService;

    public BotAuthService(
            BotApiKeyRepository botApiKeyRepository,
            BotPersonaRepository botPersonaRepository,
            JwtTokenProvider jwtTokenProvider,
            @Value("${bot.internal-secret}") String botInternalSecret) {
        this.botApiKeyRepository = botApiKeyRepository;
        this.botPersonaRepository = botPersonaRepository;
        this.jwtTokenProvider = jwtTokenProvider;
        this.botInternalSecret = botInternalSecret;
    }

    @org.springframework.beans.factory.annotation.Autowired
    public void setBotUserService(@org.springframework.context.annotation.Lazy BotUserService botUserService) {
        this.botUserService = botUserService;
    }

    /**
     * Authenticates a bot using its API key and returns JWT tokens.
     */
    @Transactional
    public BotLoginResponseDto loginWithApiKey(BotLoginRequestDto request) {
        String apiKey = request.apiKey();

        // Validate prefix
        if (!apiKey.startsWith(API_KEY_PREFIX)) {
            throw new IllegalArgumentException("Invalid API key format");
        }

        // Hash the key to look it up
        String keyHash = hashApiKey(apiKey);

        // Find the API key
        BotApiKey botApiKey = botApiKeyRepository.findByKeyHashAndIsActiveTrue(keyHash)
                .orElseThrow(() -> new IllegalArgumentException("Invalid or inactive API key"));

        // Check if the key is valid (not expired)
        if (!botApiKey.isValid()) {
            throw new IllegalArgumentException("API key has expired");
        }

        // Get the bot user
        User botUser = botApiKey.getBotUser();
        BotPersona persona = botUser.getPersona();

        // Record key usage
        botApiKey.recordUsage();

        // Generate tokens
        String accessToken = jwtTokenProvider.createAccessToken(
                botUser.getPublicId(),
                botUser.getRole().name()
        );
        String refreshToken = jwtTokenProvider.createRefreshToken(botUser.getPublicId());

        // Update bot user's refresh token
        botUser.setAppRefreshToken(refreshToken);
        botUser.setLastLoginAt(Instant.now());

        log.info("Bot login successful: user={}, persona={}",
                botUser.getUsername(),
                persona != null ? persona.getName() : "none");

        return new BotLoginResponseDto(
                accessToken,
                refreshToken,
                botUser.getPublicId(),
                botUser.getUsername(),
                persona != null ? persona.getPublicId() : null,
                persona != null ? persona.getName() : null
        );
    }

    /**
     * Generates a new API key with Stripe-style format: pp_bot_<random>
     * Returns the full key (only shown once) and the key prefix for identification.
     */
    public ApiKeyPair generateApiKey() {
        SecureRandom random = new SecureRandom();
        byte[] randomBytes = new byte[API_KEY_RANDOM_LENGTH];
        random.nextBytes(randomBytes);

        String randomPart = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
        String fullKey = API_KEY_PREFIX + randomPart;
        String keyPrefix = fullKey.substring(0, 8); // "pp_bot_x"
        String keyHash = hashApiKey(fullKey);

        return new ApiKeyPair(fullKey, keyPrefix, keyHash);
    }

    /**
     * Hashes an API key using SHA-256.
     */
    public String hashApiKey(String apiKey) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(apiKey.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    /**
     * Data class for generated API key components.
     */
    public record ApiKeyPair(String fullKey, String keyPrefix, String keyHash) {}

    /**
     * Validates the internal secret for bot operations.
     * Throws AccessDeniedException if the secret is invalid.
     */
    public void validateInternalSecret(String secret) {
        if (secret == null || !secret.equals(botInternalSecret)) {
            throw new AccessDeniedException("Invalid bot internal secret");
        }
    }

    /**
     * Authenticates a bot by persona name, auto-creating the user if needed.
     * This is used for internal bot scripts that need to authenticate without pre-created API keys.
     *
     * @param personaName The persona name to authenticate as
     * @return JWT tokens and user info
     */
    @Transactional
    public BotLoginResponseDto loginByPersonaName(String personaName) {
        // 1. Find the persona
        BotPersona persona = botPersonaRepository.findByName(personaName)
                .orElseThrow(() -> new IllegalArgumentException("Persona not found: " + personaName));

        if (!persona.isActive()) {
            throw new IllegalArgumentException("Persona is not active: " + personaName);
        }

        // 2. Find or create bot user for this persona
        User botUser = botUserService.findOrCreateBotUser(persona);

        // 3. Find or create API key (needed for consistent behavior, even though we're bypassing it)
        botUserService.findOrCreateApiKey(botUser);

        // 4. Generate tokens
        String accessToken = jwtTokenProvider.createAccessToken(
                botUser.getPublicId(),
                botUser.getRole().name()
        );
        String refreshToken = jwtTokenProvider.createRefreshToken(botUser.getPublicId());

        // 5. Update bot user
        botUser.setAppRefreshToken(refreshToken);
        botUser.setLastLoginAt(Instant.now());

        log.info("Bot login by persona successful: user={}, persona={}",
                botUser.getUsername(), persona.getName());

        return new BotLoginResponseDto(
                accessToken,
                refreshToken,
                botUser.getPublicId(),
                botUser.getUsername(),
                persona.getPublicId(),
                persona.getName()
        );
    }
}
