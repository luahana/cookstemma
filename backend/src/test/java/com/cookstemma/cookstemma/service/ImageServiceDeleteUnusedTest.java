package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.image.RecipeImageRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;

import java.lang.reflect.Field;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ImageServiceDeleteUnusedTest {

    @Mock
    private S3Client s3Client;

    @Mock
    private ImageRepository imageRepository;

    @Mock
    private RecipeImageRepository recipeImageRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ImageProcessingService imageProcessingService;

    private ImageService imageService;

    private static final String TEST_BUCKET = "test-bucket";
    private static final String TEST_URL_PREFIX = "https://cdn.example.com/";

    @BeforeEach
    void setUp() throws Exception {
        imageService = new ImageService(
            s3Client,
            imageRepository,
            recipeImageRepository,
            userRepository,
            imageProcessingService
        );

        // Set private fields using reflection
        setPrivateField(imageService, "bucket", TEST_BUCKET);
        setPrivateField(imageService, "urlPrefix", TEST_URL_PREFIX);
    }

    private void setPrivateField(Object target, String fieldName, Object value) throws Exception {
        Field field = target.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(target, value);
    }

    private Image createTestImage(Long id, String storedFilename) {
        Image image = Image.builder()
            .storedFilename(storedFilename)
            .originalFilename("original.jpg")
            .status(ImageStatus.PROCESSING)
            .build();

        // Set id using reflection since it's typically auto-generated
        try {
            Field idField = image.getClass().getSuperclass().getDeclaredField("id");
            idField.setAccessible(true);
            idField.set(image, id);
        } catch (Exception e) {
            throw new RuntimeException("Failed to set id", e);
        }

        return image;
    }

    @Nested
    @DisplayName("deleteUnusedImages")
    class DeleteUnusedImagesTests {

        @Test
        @DisplayName("Should skip already activated images gracefully")
        void deleteUnusedImages_shouldSkipActivatedImages() {
            // Given: Image in PROCESSING status older than 24h
            Image image = createTestImage(1L, "test-image-1.jpg");
            Instant oldTime = Instant.now().minus(25, ChronoUnit.HOURS);

            when(imageRepository.findByStatusAndCreatedAtBefore(
                eq(ImageStatus.PROCESSING), any(Instant.class)))
                .thenReturn(List.of(image));

            // Simulate: Another transaction activated the image before deletion
            when(imageRepository.deleteByIdAndStatus(1L, ImageStatus.PROCESSING))
                .thenReturn(0);

            // When
            imageService.deleteUnusedImages();

            // Then: DB delete was attempted but returned 0 (image was already activated)
            verify(imageRepository).deleteByIdAndStatus(1L, ImageStatus.PROCESSING);

            // S3 delete should NOT be called since DB delete returned 0
            verify(s3Client, never()).deleteObject(any(DeleteObjectRequest.class));
        }

        @Test
        @DisplayName("Should delete S3 object after successful DB deletion")
        void deleteUnusedImages_shouldDeleteS3AfterDbSuccess() {
            // Given: Image in PROCESSING status older than 24h
            Image image = createTestImage(1L, "test-image-1.jpg");

            when(imageRepository.findByStatusAndCreatedAtBefore(
                eq(ImageStatus.PROCESSING), any(Instant.class)))
                .thenReturn(List.of(image));

            // DB deletion succeeds
            when(imageRepository.deleteByIdAndStatus(1L, ImageStatus.PROCESSING))
                .thenReturn(1);

            // When
            imageService.deleteUnusedImages();

            // Then: DB record deleted first
            verify(imageRepository).deleteByIdAndStatus(1L, ImageStatus.PROCESSING);

            // Then: S3 object deleted
            ArgumentCaptor<DeleteObjectRequest> s3RequestCaptor = 
                ArgumentCaptor.forClass(DeleteObjectRequest.class);
            verify(s3Client).deleteObject(s3RequestCaptor.capture());

            DeleteObjectRequest capturedRequest = s3RequestCaptor.getValue();
            assertThat(capturedRequest.bucket()).isEqualTo(TEST_BUCKET);
            assertThat(capturedRequest.key()).isEqualTo("test-image-1.jpg");
        }

        @Test
        @DisplayName("Should continue processing other images when one fails")
        void deleteUnusedImages_shouldContinueOnFailure() {
            // Given: Multiple images
            Image image1 = createTestImage(1L, "test-image-1.jpg");
            Image image2 = createTestImage(2L, "test-image-2.jpg");

            when(imageRepository.findByStatusAndCreatedAtBefore(
                eq(ImageStatus.PROCESSING), any(Instant.class)))
                .thenReturn(List.of(image1, image2));

            // First image deletion throws exception
            when(imageRepository.deleteByIdAndStatus(1L, ImageStatus.PROCESSING))
                .thenThrow(new RuntimeException("DB connection error"));

            // Second image deletion succeeds
            when(imageRepository.deleteByIdAndStatus(2L, ImageStatus.PROCESSING))
                .thenReturn(1);

            // When
            imageService.deleteUnusedImages();

            // Then: Both deletions were attempted
            verify(imageRepository).deleteByIdAndStatus(1L, ImageStatus.PROCESSING);
            verify(imageRepository).deleteByIdAndStatus(2L, ImageStatus.PROCESSING);

            // S3 should only be called for the successful one
            verify(s3Client, times(1)).deleteObject(any(DeleteObjectRequest.class));
        }

        @Test
        @DisplayName("Should handle empty list gracefully")
        void deleteUnusedImages_shouldHandleEmptyList() {
            // Given: No unused images
            when(imageRepository.findByStatusAndCreatedAtBefore(
                eq(ImageStatus.PROCESSING), any(Instant.class)))
                .thenReturn(Collections.emptyList());

            // When
            imageService.deleteUnusedImages();

            // Then: No deletion attempts
            verify(imageRepository, never()).deleteByIdAndStatus(anyLong(), any());
            verify(s3Client, never()).deleteObject(any(DeleteObjectRequest.class));
        }

        @Test
        @DisplayName("Should log warning but not fail when S3 deletion fails")
        void deleteUnusedImages_shouldLogWarningOnS3Failure() {
            // Given: Image that can be deleted from DB
            Image image = createTestImage(1L, "test-image-1.jpg");

            when(imageRepository.findByStatusAndCreatedAtBefore(
                eq(ImageStatus.PROCESSING), any(Instant.class)))
                .thenReturn(List.of(image));

            when(imageRepository.deleteByIdAndStatus(1L, ImageStatus.PROCESSING))
                .thenReturn(1);

            // S3 deletion fails
            when(s3Client.deleteObject(any(DeleteObjectRequest.class)))
                .thenThrow(new RuntimeException("S3 connection error"));

            // When - should not throw
            imageService.deleteUnusedImages();

            // Then: DB was deleted, S3 was attempted
            verify(imageRepository).deleteByIdAndStatus(1L, ImageStatus.PROCESSING);
            verify(s3Client).deleteObject(any(DeleteObjectRequest.class));
            // Note: In production, this would log a warning for manual cleanup
        }
    }
}
