package com.cookstemma.cookstemma.repository.image;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.domain.enums.ImageVariant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ImageRepository extends JpaRepository<Image, Long> {
    // 1. 레시피/로그별 이미지 목록 (정렬 순서 준수)
    List<Image> findByRecipeIdAndStatusOrderByDisplayOrderAsc(Long recipeId, ImageStatus status);
    List<Image> findByLogPostIdAndStatusOrderByDisplayOrderAsc(Long logPostId, ImageStatus status);

    // 2. 파일명 리스트로 대량 조회 (활성화 처리용)
    List<Image> findByStoredFilenameIn(List<String> filenames);

    // 3. 특정 조리 단계의 이미지 조회
    Optional<Image> findByTypeAndRecipeIdAndDisplayOrder(ImageType type, Long recipeId, Integer displayOrder);

    // 파일명으로 이미지 조회 (활성화용)
    Optional<Image> findByStoredFilename(String storedFilename);

    // [수정] 가비지 컬렉션용 (TEMP 대신 PROCESSING 사용)
    List<Image> findByStatusAndCreatedAtBefore(ImageStatus status, Instant dateTime);

    // Conditional delete for cleanup (prevents StaleObjectStateException)
    @Modifying
    @Query("DELETE FROM Image i WHERE i.id = :imageId AND i.status = :status")
    int deleteByIdAndStatus(@Param("imageId") Long imageId, @Param("status") ImageStatus status);

    Optional<Image> findByPublicId(UUID publicId);

    // Variant-related queries
    List<Image> findByOriginalImageId(Long originalImageId);

    Optional<Image> findByOriginalImageIdAndVariantType(Long originalImageId, ImageVariant variantType);

    @Query("SELECT i FROM Image i WHERE i.originalImage IS NULL AND i.variantType IS NULL AND i.status = :status")
    List<Image> findOriginalImagesWithoutVariants(@Param("status") ImageStatus status);

    @Query("SELECT i FROM Image i LEFT JOIN FETCH i.variants WHERE i.publicId = :publicId")
    Optional<Image> findByPublicIdWithVariants(@Param("publicId") UUID publicId);

    // Soft delete queries for user account deletion
    List<Image> findByUploaderIdAndDeletedAtIsNull(Long uploaderId);

    List<Image> findByUploaderIdAndDeletedAtIsNotNull(Long uploaderId);

    List<Image> findByUploaderId(Long uploaderId);
}