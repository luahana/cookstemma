package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.dto.image.ImageUploadResponseDto;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
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

        // Enum 타입명을 경로로 사용 (예: THUMBNAIL -> thumbnail)
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

    // [수정] 이미지 활성화 시 연관 엔티티와 순서(displayOrder) 부여
    @Transactional
    public void activateImages(List<UUID> imagePublicIds, Object target) {
        if (imagePublicIds == null || imagePublicIds.isEmpty()) return;

        for (int i = 0; i < imagePublicIds.size(); i++) {
            // [해결] 람다 내부에서 사용하기 위해 effectively final 변수로 복사합니다.
            final int index = i;
            final UUID currentId = imagePublicIds.get(i);

            // 이제 람다 안에서 index나 currentId를 안전하게 참조할 수 있습니다.
            Image image = imageRepository.findByPublicId(currentId)
                    .orElseThrow(() -> new IllegalArgumentException("Image not found: " + currentId));

            if (target instanceof Recipe recipe) {
                image.setRecipe(recipe);
            } else if (target instanceof LogPost logPost) {
                image.setLogPost(logPost);
            } else if (target instanceof User user) {
                // 유저 프로필 이미지의 경우, 파일명은 User 엔티티에 저장되므로
                // 여기서는 상태만 ACTIVE로 변경하여 가비지 컬렉션을 방지합니다.
            }

            image.setStatus(ImageStatus.ACTIVE);
            image.setDisplayOrder(index); // 복사한 상수를 사용

            // Trigger async variant generation
            imageProcessingService.generateVariantsAsync(image.getId());
        }
    }

    @Transactional
    public void deleteUnusedImages() {
        Instant cutoffTime = Instant.now().minus(24, ChronoUnit.HOURS);
        // [수정] SQL 상태에 맞춰 PROCESSING 조회
        List<Image> unusedImages = imageRepository.findByStatusAndCreatedAtBefore(ImageStatus.PROCESSING, cutoffTime);

        if (unusedImages.isEmpty()) return;

        for (Image image : unusedImages) {
            try {
                s3Client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(image.getStoredFilename()).build());
                imageRepository.delete(image);
            } catch (Exception e) {
                log.error("Failed to delete image: {}", image.getStoredFilename(), e);
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
}