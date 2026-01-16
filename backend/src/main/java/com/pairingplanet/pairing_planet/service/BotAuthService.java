package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.bot.BotApiKey;
import com.pairingplanet.pairing_planet.domain.entity.bot.BotPersona;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.bot.BotLoginRequestDto;
import com.pairingplanet.pairing_planet.dto.bot.BotLoginResponseDto;
import com.pairingplanet.pairing_planet.repository.bot.BotApiKeyRepository;
import com.pairingplanet.pairing_planet.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
 * Handles login via API key and token generation.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BotAuthService {

    private static final String API_KEY_PREFIX = "pp_bot_";
    private static final int API_KEY_RANDOM_LENGTH = 32; // 256 bits of entropy

    private final BotApiKeyRepository botApiKeyRepository;
    private final JwtTokenProvider jwtTokenProvider;

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
}
