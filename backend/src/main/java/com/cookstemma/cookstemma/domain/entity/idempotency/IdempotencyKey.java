package com.cookstemma.cookstemma.domain.entity.idempotency;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

/**
 * Entity for storing idempotency keys to prevent duplicate writes on network retries.
 * Keys are scoped per user and expire after 24 hours.
 */
@Entity
@Table(name = "idempotency_keys")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class IdempotencyKey {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "idempotency_key", nullable = false, unique = true, length = 64)
    private String idempotencyKey;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "request_path", nullable = false)
    private String requestPath;

    @Column(name = "request_hash", nullable = false, length = 64)
    private String requestHash;

    @Column(name = "response_status")
    private Integer responseStatus;

    @Column(name = "response_body", columnDefinition = "TEXT")
    private String responseBody;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    /**
     * Create a new idempotency key entry (before response is known)
     */
    public static IdempotencyKey create(String key, Long userId, String requestPath, String requestHash) {
        return IdempotencyKey.builder()
                .idempotencyKey(key)
                .userId(userId)
                .requestPath(requestPath)
                .requestHash(requestHash)
                .expiresAt(Instant.now().plusSeconds(24 * 60 * 60)) // 24 hours TTL
                .build();
    }

    /**
     * Store the response after request execution
     */
    public void storeResponse(int status, String body) {
        this.responseStatus = status;
        this.responseBody = body;
    }

    /**
     * Check if this key has a cached response
     */
    public boolean hasCachedResponse() {
        return responseStatus != null;
    }

    /**
     * Check if this key has expired
     */
    public boolean isExpired() {
        return Instant.now().isAfter(expiresAt);
    }
}
