package com.pairingplanet.pairing_planet.repository.idempotency;

import com.pairingplanet.pairing_planet.domain.entity.idempotency.IdempotencyKey;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import com.pairingplanet.pairing_planet.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class IdempotencyKeyRepositoryTest extends BaseIntegrationTest {

    @Autowired
    private IdempotencyKeyRepository idempotencyKeyRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
    }

    @Nested
    @DisplayName("Find by idempotency key and user ID")
    class FindByKeyAndUserTests {

        @Test
        @DisplayName("Should find existing key for user")
        void findByIdempotencyKeyAndUserId_Exists_ReturnsKey() {
            String key = UUID.randomUUID().toString();
            IdempotencyKey idempotencyKey = IdempotencyKey.create(key, testUser.getId(), "/api/v1/recipes", "hash123");
            idempotencyKey.storeResponse(201, "{\"publicId\":\"abc\"}");
            idempotencyKeyRepository.save(idempotencyKey);

            Optional<IdempotencyKey> found = idempotencyKeyRepository.findByIdempotencyKeyAndUserId(key, testUser.getId());

            assertThat(found).isPresent();
            assertThat(found.get().getIdempotencyKey()).isEqualTo(key);
            assertThat(found.get().getResponseStatus()).isEqualTo(201);
        }

        @Test
        @DisplayName("Should not find key for different user")
        void findByIdempotencyKeyAndUserId_DifferentUser_ReturnsEmpty() {
            String key = UUID.randomUUID().toString();
            IdempotencyKey idempotencyKey = IdempotencyKey.create(key, testUser.getId(), "/api/v1/recipes", "hash123");
            idempotencyKeyRepository.save(idempotencyKey);

            User otherUser = testUserFactory.createTestUser();
            Optional<IdempotencyKey> found = idempotencyKeyRepository.findByIdempotencyKeyAndUserId(key, otherUser.getId());

            assertThat(found).isEmpty();
        }

        @Test
        @DisplayName("Should not find non-existent key")
        void findByIdempotencyKeyAndUserId_NotExists_ReturnsEmpty() {
            Optional<IdempotencyKey> found = idempotencyKeyRepository.findByIdempotencyKeyAndUserId("nonexistent", testUser.getId());

            assertThat(found).isEmpty();
        }
    }

    @Nested
    @DisplayName("Delete expired keys")
    class DeleteExpiredTests {

        @Test
        @DisplayName("Should delete expired keys")
        void deleteExpiredKeys_ExpiredExists_DeletesThem() {
            // Create expired key (expired 1 hour ago)
            String expiredKey = UUID.randomUUID().toString();
            IdempotencyKey expired = IdempotencyKey.builder()
                    .idempotencyKey(expiredKey)
                    .userId(testUser.getId())
                    .requestPath("/api/v1/recipes")
                    .requestHash("hash123")
                    .expiresAt(Instant.now().minusSeconds(3600))
                    .build();
            idempotencyKeyRepository.save(expired);

            // Create valid key (expires in 24 hours)
            String validKey = UUID.randomUUID().toString();
            IdempotencyKey valid = IdempotencyKey.create(validKey, testUser.getId(), "/api/v1/recipes", "hash456");
            idempotencyKeyRepository.save(valid);

            int deleted = idempotencyKeyRepository.deleteExpiredKeys(Instant.now());

            assertThat(deleted).isEqualTo(1);
            assertThat(idempotencyKeyRepository.findByIdempotencyKey(expiredKey)).isEmpty();
            assertThat(idempotencyKeyRepository.findByIdempotencyKey(validKey)).isPresent();
        }

        @Test
        @DisplayName("Should return 0 when no expired keys")
        void deleteExpiredKeys_NoneExpired_ReturnsZero() {
            String key = UUID.randomUUID().toString();
            IdempotencyKey valid = IdempotencyKey.create(key, testUser.getId(), "/api/v1/recipes", "hash123");
            idempotencyKeyRepository.save(valid);

            int deleted = idempotencyKeyRepository.deleteExpiredKeys(Instant.now());

            assertThat(deleted).isEqualTo(0);
            assertThat(idempotencyKeyRepository.findByIdempotencyKey(key)).isPresent();
        }
    }

    @Nested
    @DisplayName("Count expired keys")
    class CountExpiredTests {

        @Test
        @DisplayName("Should count expired keys")
        void countExpiredKeys_MultipleExpired_ReturnsCount() {
            // Create 3 expired keys
            for (int i = 0; i < 3; i++) {
                IdempotencyKey expired = IdempotencyKey.builder()
                        .idempotencyKey(UUID.randomUUID().toString())
                        .userId(testUser.getId())
                        .requestPath("/api/v1/recipes")
                        .requestHash("hash" + i)
                        .expiresAt(Instant.now().minusSeconds(3600))
                        .build();
                idempotencyKeyRepository.save(expired);
            }

            // Create 1 valid key
            IdempotencyKey valid = IdempotencyKey.create(UUID.randomUUID().toString(), testUser.getId(), "/api/v1/recipes", "valid");
            idempotencyKeyRepository.save(valid);

            long count = idempotencyKeyRepository.countExpiredKeys(Instant.now());

            assertThat(count).isEqualTo(3);
        }
    }

    @Nested
    @DisplayName("IdempotencyKey entity behavior")
    class EntityBehaviorTests {

        @Test
        @DisplayName("Should detect expired key")
        void isExpired_ExpiredKey_ReturnsTrue() {
            IdempotencyKey expired = IdempotencyKey.builder()
                    .idempotencyKey(UUID.randomUUID().toString())
                    .userId(testUser.getId())
                    .requestPath("/api/v1/recipes")
                    .requestHash("hash123")
                    .expiresAt(Instant.now().minusSeconds(1))
                    .build();

            assertThat(expired.isExpired()).isTrue();
        }

        @Test
        @DisplayName("Should detect valid key")
        void isExpired_ValidKey_ReturnsFalse() {
            IdempotencyKey valid = IdempotencyKey.create(UUID.randomUUID().toString(), testUser.getId(), "/api/v1/recipes", "hash123");

            assertThat(valid.isExpired()).isFalse();
        }

        @Test
        @DisplayName("Should detect cached response")
        void hasCachedResponse_WithResponse_ReturnsTrue() {
            IdempotencyKey key = IdempotencyKey.create(UUID.randomUUID().toString(), testUser.getId(), "/api/v1/recipes", "hash123");
            key.storeResponse(200, "{\"status\":\"ok\"}");

            assertThat(key.hasCachedResponse()).isTrue();
        }

        @Test
        @DisplayName("Should detect no cached response")
        void hasCachedResponse_WithoutResponse_ReturnsFalse() {
            IdempotencyKey key = IdempotencyKey.create(UUID.randomUUID().toString(), testUser.getId(), "/api/v1/recipes", "hash123");

            assertThat(key.hasCachedResponse()).isFalse();
        }
    }
}
