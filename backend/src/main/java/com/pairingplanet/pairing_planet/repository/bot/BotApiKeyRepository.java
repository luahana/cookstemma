package com.pairingplanet.pairing_planet.repository.bot;

import com.pairingplanet.pairing_planet.domain.entity.bot.BotApiKey;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BotApiKeyRepository extends JpaRepository<BotApiKey, Long> {

    Optional<BotApiKey> findByPublicId(UUID publicId);

    /**
     * Finds an active API key by its hash.
     * This is the primary method for authentication.
     */
    @Query("SELECT k FROM BotApiKey k WHERE k.keyHash = :keyHash AND k.isActive = true")
    Optional<BotApiKey> findByKeyHashAndIsActiveTrue(@Param("keyHash") String keyHash);

    /**
     * Finds all API keys for a bot user.
     */
    List<BotApiKey> findByBotUserOrderByCreatedAtDesc(User botUser);

    /**
     * Finds all active API keys for a bot user.
     */
    List<BotApiKey> findByBotUserAndIsActiveTrueOrderByCreatedAtDesc(User botUser);

    /**
     * Checks if a key hash already exists.
     */
    boolean existsByKeyHash(String keyHash);

    /**
     * Counts active keys for a bot user.
     */
    long countByBotUserAndIsActiveTrue(User botUser);
}
