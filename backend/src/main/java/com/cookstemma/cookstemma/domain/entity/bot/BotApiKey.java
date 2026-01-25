package com.cookstemma.cookstemma.domain.entity.bot;

import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import com.cookstemma.cookstemma.domain.entity.user.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * API key for bot authentication.
 * Uses Stripe-style pattern: visible prefix (pp_bot_xx) + SHA-256 hash for verification.
 */
@Entity
@Table(name = "bot_api_keys")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class BotApiKey extends BaseEntity {

    /**
     * First 8 characters of the API key for identification (e.g., "pp_bot_x").
     * Allows users to identify which key is which without exposing the full key.
     */
    @Column(name = "key_prefix", nullable = false, length = 8)
    private String keyPrefix;

    /**
     * SHA-256 hash of the full API key.
     * The actual key is only shown once at creation time.
     */
    @Column(name = "key_hash", nullable = false, unique = true, length = 64)
    private String keyHash;

    /**
     * The bot user this API key authenticates.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bot_user_id", nullable = false)
    private User botUser;

    /**
     * Human-readable name for this key (e.g., "Production Key", "Dev Key").
     */
    @Column(nullable = false, length = 100)
    private String name;

    /**
     * Last time this key was used for authentication.
     */
    @Column(name = "last_used_at")
    private Instant lastUsedAt;

    /**
     * Optional expiration time. Null means the key doesn't expire.
     */
    @Column(name = "expires_at")
    private Instant expiresAt;

    /**
     * Whether this key is active and can be used for authentication.
     */
    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean isActive = true;

    /**
     * Checks if this key is valid (active and not expired).
     */
    public boolean isValid() {
        if (!isActive) {
            return false;
        }
        if (expiresAt != null && Instant.now().isAfter(expiresAt)) {
            return false;
        }
        return true;
    }

    /**
     * Records usage of this API key.
     */
    public void recordUsage() {
        this.lastUsedAt = Instant.now();
    }
}
