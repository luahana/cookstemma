package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.image.RecipeImage;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.image.ImageUploadResponseDto;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.image.RecipeImageRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ImageService {

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    private final S3Client s3Client;
    private final ImageRepository imageRepository;
    private final RecipeImageRepository recipeImageRepository;
    private final UserRepository userRepository;
    private final ImageProcessingService imageProcessingService;

    @Value("${file.upload.bucket}")
    private String bucket;

    @Transactional
    public ImageUploadResponseDto uploadImage(MultipartFile file, ImageType imageType, UserPrincipal principal) {
        if (file.isEmpty()) throw new IllegalArgumentException("File is empty");

        Long uploaderId = principal.getId();
        String originalFilename = file.getOriginalFilename();
        String extension = getExtension(originalFilename);
        String savedFilename = UUID.randomUUID() + extension;

        // Enum 타입명을 경로로 사용 (예: COVER -> cover)
        String key = imageType.name().toLowerCase() + "/" + savedFilename;

        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .build();
            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            // DB 저장 (SQL과 일치하게 PROCESSING 상태로 시작)
            Image image = Image.builder()
                    .storedFilename(key)
                    .originalFilename(originalFilename)
                    .type(imageType)
                    .status(ImageStatus.PROCESSING)
                    .uploaderId(uploaderId)
                    .build();
            imageRepository.save(image); //

            return ImageUploadResponseDto.builder()
                    .imagePublicId(image.getPublicId())
                    .imageUrl(urlPrefix + "/" + key)
                    .originalFilename(originalFilename)
                    .build();

        } catch (IOException e) {
            log.error("Image upload failed (IO error)", e);
            throw new RuntimeException("Failed to upload image: " + e.getMessage());
        } catch (Exception e) {
            log.error("Image upload failed (S3/other error)", e);
            throw new RuntimeException("Failed to upload image: " + e.getMessage());
        }
    }

    /**
     * Activates images and links them to their target entity.
     * For recipes, uses the join table (recipe_image_map) to allow image sharing across variants.
     * For log posts and users, uses direct FK relationship.
     */
    @Transactional
    public void activateImages(List<UUID> imagePublicIds, Object target) {
        if (imagePublicIds == null || imagePublicIds.isEmpty()) return;

        for (int i = 0; i < imagePublicIds.size(); i++) {
            final int index = i;
            final UUID currentId = imagePublicIds.get(i);

            Image image = imageRepository.findByPublicId(currentId)
                    .orElseThrow(() -> new IllegalArgumentException("Image not found: " + currentId));

            if (target instanceof Recipe recipe) {
                // Use join table for recipe images (allows sharing across variants)
                RecipeImage recipeImage = RecipeImage.of(recipe, image, index);
                RecipeImage savedRecipeImage = recipeImageRepository.save(recipeImage);
                // Add to in-memory collection for immediate access (within same transaction)
                // This ensures getCoverImages() works without requiring a DB reload
                recipe.getRecipeImages().add(savedRecipeImage);

                // Set recipe_id and displayOrder on image for backward compatibility
                // This ensures:
                // 1. Constraint satisfaction (images need a parent reference)
                // 2. Legacy code/tests that use recipe.getImages() still work
                // 3. displayOrder is accessible from the Image entity
                if (image.getRecipe() == null) {
                    image.setRecipe(recipe);
                    image.setDisplayOrder(index);
                    recipe.getImages().add(image);
                }
            } else if (target instanceof LogPost logPost) {
                image.setLogPost(logPost);
                image.setDisplayOrder(index);
                // Maintain bidirectional relationship
                logPost.getImages().add(image);
            } else if (target instanceof User user) {
                // Profile images: just activate, filename stored in User entity
            }

            image.setStatus(ImageStatus.ACTIVE);

            // Save image (needed for log posts and constraint satisfaction)
            imageRepository.save(image);

            // Trigger async variant generation
            imageProcessingService.generateVariantsAsync(image.getId());
        }
    }

    /**
     * Update recipe images: removes old mappings and creates new ones.
     * Uses the join table to track recipe-image relationships.
     * Images that are no longer used by any recipe will be garbage collected.
     */
    @Transactional
    public void updateRecipeImages(Recipe recipe, List<UUID> newImagePublicIds) {
        // 1. Get old image mappings and clear them
        List<RecipeImage> oldMappings = recipeImageRepository.findByRecipeIdOrderByDisplayOrderAsc(recipe.getId());
        List<Long> oldImageIds = oldMappings.stream()
                .map(ri -> ri.getImage().getId())
                .toList();

        // Clear all existing mappings for this recipe
        recipeImageRepository.deleteByRecipeId(recipe.getId());
        recipe.getRecipeImages().clear();

        // 2. Activate new images (creates new mappings)
        activateImages(newImagePublicIds, recipe);

        // 3. Check if any old images are orphaned (not used by any recipe)
        // and mark them for garbage collection
        for (Long oldImageId : oldImageIds) {
            boolean stillUsed = recipeImageRepository.existsByImageId(oldImageId);
            if (!stillUsed) {
                imageRepository.findById(oldImageId).ifPresent(image -> {
                    // Check if this image is used as a step image
                    if (image.getType() != ImageType.STEP) {
                        image.setRecipe(null);
                        image.setStatus(ImageStatus.PROCESSING);
                        imageRepository.save(image);
                    }
                });
            }
        }
    }

    /**
     * Update log post images: deactivate old images and activate new ones.
     * Used when editing a log post.
     */
    @Transactional
    public void updateLogPostImages(LogPost logPost, List<UUID> newImagePublicIds) {
        // 1. Mark old images as PROCESSING (will be garbage collected)
        List<Image> oldImages = imageRepository.findByLogPostIdAndStatusOrderByDisplayOrderAsc(
                logPost.getId(), ImageStatus.ACTIVE);
        for (Image oldImage : oldImages) {
            // Only deactivate if not in the new list
            if (newImagePublicIds == null || !newImagePublicIds.contains(oldImage.getPublicId())) {
                oldImage.setLogPost(null);
                oldImage.setStatus(ImageStatus.PROCESSING);
            }
        }

        // 2. Activate new images
        activateImages(newImagePublicIds, logPost);
    }

    @Transactional
    public void deleteUnusedImages() {
        Instant cutoffTime = Instant.now().minus(24, ChronoUnit.HOURS);
        List<Image> unusedImages = imageRepository.findByStatusAndCreatedAtBefore(
            ImageStatus.PROCESSING, cutoffTime);

        if (unusedImages.isEmpty()) return;

        for (Image image : unusedImages) {
            String storedFilename = image.getStoredFilename();
            Long imageId = image.getId();

            try {
                // Delete from DB first (atomic, status-conditional)
                int deleted = imageRepository.deleteByIdAndStatus(imageId, ImageStatus.PROCESSING);

                if (deleted == 0) {
                    // Image was modified (activated) by another transaction - skip
                    log.info("Image {} was already activated, skipping cleanup", storedFilename);
                    continue;
                }

                // DB deletion succeeded, now clean up S3
                try {
                    s3Client.deleteObject(DeleteObjectRequest.builder()
                        .bucket(bucket)
                        .key(storedFilename)
                        .build());
                } catch (Exception e) {
                    log.warn("Failed to delete S3 object {}, may need manual cleanup", storedFilename, e);
                }
            } catch (Exception e) {
                log.error("Failed to delete image: {}", storedFilename, e);
            }
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf("."));
    }

    private String extractKeyFromUrl(String fullUrl) {
        if (fullUrl == null) return "";
        return fullUrl.replace(urlPrefix + "/", "");
    }

    /**
     * Soft delete all images uploaded by a user.
     * Called when user closes their account.
     */
    @Transactional
    public void softDeleteAllByUploader(Long uploaderId, Instant deletedAt, Instant scheduledAt) {
        List<Image> userImages = imageRepository.findByUploaderIdAndDeletedAtIsNull(uploaderId);
        for (Image image : userImages) {
            image.setDeletedAt(deletedAt);
            image.setDeleteScheduledAt(scheduledAt);
        }
        log.info("Soft deleted {} images for uploader {}", userImages.size(), uploaderId);
    }

    /**
     * Restore all soft-deleted images for a user.
     * Called when user restores their account within grace period.
     */
    @Transactional
    public void restoreAllByUploader(Long uploaderId) {
        List<Image> deletedImages = imageRepository.findByUploaderIdAndDeletedAtIsNotNull(uploaderId);
        for (Image image : deletedImages) {
            image.setDeletedAt(null);
            image.setDeleteScheduledAt(null);
        }
        log.info("Restored {} images for uploader {}", deletedImages.size(), uploaderId);
    }

    /**
     * Hard delete all images for a user from S3 and database.
     * Called when user account is permanently purged after grace period.
     */
    @Transactional
    public void hardDeleteAllByUploader(Long uploaderId) {
        List<Image> images = imageRepository.findByUploaderId(uploaderId);
        for (Image image : images) {
            try {
                // Delete original image from S3
                s3Client.deleteObject(DeleteObjectRequest.builder()
                        .bucket(bucket)
                        .key(image.getStoredFilename())
                        .build());

                // Delete variants from S3
                if (image.hasVariants()) {
                    for (Image variant : image.getVariants()) {
                        s3Client.deleteObject(DeleteObjectRequest.builder()
                                .bucket(bucket)
                                .key(variant.getStoredFilename())
                                .build());
                    }
                }

                // Delete from DB (variants cascade due to orphanRemoval)
                imageRepository.delete(image);
            } catch (Exception e) {
                log.error("Failed to hard delete image: {}", image.getStoredFilename(), e);
            }
        }
        log.info("Hard deleted {} images for uploader {}", images.size(), uploaderId);
    }
}