package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import com.pairingplanet.pairing_planet.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ImageSoftDeleteTest extends BaseIntegrationTest {

    @Autowired
    private UserService userService;

    @Autowired
    private ImageService imageService;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private Image testImage1;
    private Image testImage2;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        // Create test images for the user
        testImage1 = Image.builder()
                .storedFilename("thumbnail/test1.jpg")
                .originalFilename("test1.jpg")
                .type(ImageType.THUMBNAIL)
                .status(ImageStatus.ACTIVE)
                .uploaderId(testUser.getId())
                .build();
        imageRepository.save(testImage1);

        testImage2 = Image.builder()
                .storedFilename("thumbnail/test2.jpg")
                .originalFilename("test2.jpg")
                .type(ImageType.THUMBNAIL)
                .status(ImageStatus.ACTIVE)
                .uploaderId(testUser.getId())
                .build();
        imageRepository.save(testImage2);
    }

    @Nested
    @DisplayName("Soft Delete Images with User Account")
    class SoftDeleteTests {

        @Test
        @DisplayName("Should soft-delete user's images when account is deleted")
        void deleteAccount_SoftDeletesImages() {
            // Given
            UserPrincipal principal = new UserPrincipal(testUser);

            // When
            userService.deleteAccount(principal);

            // Then
            User updatedUser = userRepository.findById(testUser.getId()).orElseThrow();
            assertThat(updatedUser.getStatus()).isEqualTo(AccountStatus.DELETED);
            assertThat(updatedUser.getDeletedAt()).isNotNull();
            assertThat(updatedUser.getDeleteScheduledAt()).isNotNull();

            // Check images are soft-deleted
            List<Image> userImages = imageRepository.findByUploaderId(testUser.getId());
            assertThat(userImages).hasSize(2);
            for (Image image : userImages) {
                assertThat(image.getDeletedAt()).isNotNull();
                assertThat(image.getDeleteScheduledAt()).isNotNull();
                assertThat(image.isDeleted()).isTrue();
            }

            // Verify non-deleted query returns empty
            List<Image> activeImages = imageRepository.findByUploaderIdAndDeletedAtIsNull(testUser.getId());
            assertThat(activeImages).isEmpty();
        }

        @Test
        @DisplayName("Should set same deletion schedule for images as user")
        void deleteAccount_ImageScheduleMatchesUser() {
            // Given
            UserPrincipal principal = new UserPrincipal(testUser);

            // When
            userService.deleteAccount(principal);

            // Then
            User updatedUser = userRepository.findById(testUser.getId()).orElseThrow();
            List<Image> userImages = imageRepository.findByUploaderId(testUser.getId());

            for (Image image : userImages) {
                assertThat(image.getDeleteScheduledAt()).isEqualTo(updatedUser.getDeleteScheduledAt());
            }
        }
    }

    @Nested
    @DisplayName("Restore Images with User Account")
    class RestoreTests {

        @Test
        @DisplayName("Should restore user's images when account is restored")
        void restoreAccount_RestoresImages() {
            // Given - delete account first
            UserPrincipal principal = new UserPrincipal(testUser);
            userService.deleteAccount(principal);

            // Verify images are soft-deleted
            List<Image> deletedImages = imageRepository.findByUploaderIdAndDeletedAtIsNotNull(testUser.getId());
            assertThat(deletedImages).hasSize(2);

            // When - restore account
            User userToRestore = userRepository.findById(testUser.getId()).orElseThrow();
            userService.restoreDeletedAccount(userToRestore);

            // Then
            User restoredUser = userRepository.findById(testUser.getId()).orElseThrow();
            assertThat(restoredUser.getStatus()).isEqualTo(AccountStatus.ACTIVE);
            assertThat(restoredUser.getDeletedAt()).isNull();
            assertThat(restoredUser.getDeleteScheduledAt()).isNull();

            // Check images are restored
            List<Image> activeImages = imageRepository.findByUploaderIdAndDeletedAtIsNull(testUser.getId());
            assertThat(activeImages).hasSize(2);
            for (Image image : activeImages) {
                assertThat(image.getDeletedAt()).isNull();
                assertThat(image.getDeleteScheduledAt()).isNull();
                assertThat(image.isDeleted()).isFalse();
            }
        }

        @Test
        @DisplayName("Should not restore already active account")
        void restoreAccount_AlreadyActive_NoChange() {
            // Given - user is active
            assertThat(testUser.getStatus()).isEqualTo(AccountStatus.ACTIVE);

            // When
            userService.restoreDeletedAccount(testUser);

            // Then - images unchanged
            List<Image> images = imageRepository.findByUploaderId(testUser.getId());
            assertThat(images).hasSize(2);
            for (Image image : images) {
                assertThat(image.getDeletedAt()).isNull();
            }
        }
    }

    @Nested
    @DisplayName("Hard Delete Images After Grace Period")
    class HardDeleteTests {

        @Test
        @DisplayName("Should hard-delete images when user account is purged")
        void purgeExpiredAccounts_HardDeletesImages() {
            // Given - delete account with past scheduled date
            Instant past = Instant.now().minus(1, ChronoUnit.DAYS);
            testUser.setStatus(AccountStatus.DELETED);
            testUser.setDeletedAt(past.minus(30, ChronoUnit.DAYS));
            testUser.setDeleteScheduledAt(past);
            userRepository.save(testUser);

            // Soft-delete images with past schedule
            for (Image image : imageRepository.findByUploaderId(testUser.getId())) {
                image.setDeletedAt(past.minus(30, ChronoUnit.DAYS));
                image.setDeleteScheduledAt(past);
            }

            // When
            userService.purgeExpiredDeletedAccounts();

            // Then - user should be deleted
            assertThat(userRepository.findById(testUser.getId())).isEmpty();

            // Images should be hard-deleted from DB
            List<Image> remainingImages = imageRepository.findByUploaderId(testUser.getId());
            assertThat(remainingImages).isEmpty();
        }

        @Test
        @DisplayName("Should not purge accounts within grace period")
        void purgeExpiredAccounts_WithinGracePeriod_NoChange() {
            // Given - delete account with future scheduled date
            Instant future = Instant.now().plus(29, ChronoUnit.DAYS);
            testUser.setStatus(AccountStatus.DELETED);
            testUser.setDeletedAt(Instant.now());
            testUser.setDeleteScheduledAt(future);
            userRepository.save(testUser);

            Long userId = testUser.getId();

            // When
            userService.purgeExpiredDeletedAccounts();

            // Then - user should still exist
            assertThat(userRepository.findById(userId)).isPresent();

            // Images should still exist
            List<Image> images = imageRepository.findByUploaderId(userId);
            assertThat(images).hasSize(2);
        }
    }

    @Nested
    @DisplayName("ImageService Direct Methods")
    class ImageServiceTests {

        @Test
        @DisplayName("Should soft-delete only non-deleted images")
        void softDeleteAllByUploader_OnlyNonDeleted() {
            // Given - one image already deleted
            testImage1.setDeletedAt(Instant.now().minus(1, ChronoUnit.DAYS));
            testImage1.setDeleteScheduledAt(Instant.now().plus(29, ChronoUnit.DAYS));
            imageRepository.save(testImage1);

            Instant now = Instant.now();
            Instant scheduled = now.plus(30, ChronoUnit.DAYS);

            // When
            imageService.softDeleteAllByUploader(testUser.getId(), now, scheduled);

            // Then - only testImage2 should have new timestamps
            Image image1 = imageRepository.findById(testImage1.getId()).orElseThrow();
            Image image2 = imageRepository.findById(testImage2.getId()).orElseThrow();

            // image1 keeps old timestamps (was already deleted)
            assertThat(image1.getDeletedAt()).isBefore(now);

            // image2 gets new timestamps
            assertThat(image2.getDeletedAt()).isEqualTo(now);
            assertThat(image2.getDeleteScheduledAt()).isEqualTo(scheduled);
        }

        @Test
        @DisplayName("Should restore only deleted images")
        void restoreAllByUploader_OnlyDeleted() {
            // Given - soft-delete both images
            Instant now = Instant.now();
            testImage1.setDeletedAt(now);
            testImage1.setDeleteScheduledAt(now.plus(30, ChronoUnit.DAYS));
            testImage2.setDeletedAt(now);
            testImage2.setDeleteScheduledAt(now.plus(30, ChronoUnit.DAYS));
            imageRepository.saveAll(List.of(testImage1, testImage2));

            // When
            imageService.restoreAllByUploader(testUser.getId());

            // Then
            List<Image> images = imageRepository.findByUploaderId(testUser.getId());
            for (Image image : images) {
                assertThat(image.getDeletedAt()).isNull();
                assertThat(image.getDeleteScheduledAt()).isNull();
            }
        }
    }
}
