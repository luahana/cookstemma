package com.cookstemma.cookstemma.repository.idempotency;

import com.cookstemma.cookstemma.domain.entity.idempotency.IdempotencyKey;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;

public interface IdempotencyKeyRepository extends JpaRepository<IdempotencyKey, Long> {

    /**
     * Find an idempotency key by its key value and user ID
     */
    Optional<IdempotencyKey> findByIdempotencyKeyAndUserId(String idempotencyKey, Long userId);

    /**
     * Find an idempotency key by its key value only (for global lookup)
     */
    Optional<IdempotencyKey> findByIdempotencyKey(String idempotencyKey);

    /**
     * Delete all expired keys (for cleanup scheduler)
     */
    @Modifying
    @Query("DELETE FROM IdempotencyKey ik WHERE ik.expiresAt < :now")
    int deleteExpiredKeys(@Param("now") Instant now);

    /**
     * Count expired keys (for metrics/logging)
     */
    @Query("SELECT COUNT(ik) FROM IdempotencyKey ik WHERE ik.expiresAt < :now")
    long countExpiredKeys(@Param("now") Instant now);
}
