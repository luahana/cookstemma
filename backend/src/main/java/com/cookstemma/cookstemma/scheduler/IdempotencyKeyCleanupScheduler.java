package com.cookstemma.cookstemma.scheduler;

import com.cookstemma.cookstemma.repository.idempotency.IdempotencyKeyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

/**
 * Scheduled job to clean up expired idempotency keys.
 * Runs every hour to remove keys that have exceeded their 24-hour TTL.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class IdempotencyKeyCleanupScheduler {

    private final IdempotencyKeyRepository idempotencyKeyRepository;

    /**
     * Delete expired idempotency keys every hour.
     * Cron: 0 minutes, every hour, every day
     */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void cleanupExpiredKeys() {
        Instant now = Instant.now();
        long expiredCount = idempotencyKeyRepository.countExpiredKeys(now);

        if (expiredCount > 0) {
            int deleted = idempotencyKeyRepository.deleteExpiredKeys(now);
            log.info("Deleted {} expired idempotency keys", deleted);
        } else {
            log.debug("No expired idempotency keys to clean up");
        }
    }
}
