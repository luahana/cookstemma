package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.dto.image.ImageUploadResponseDto;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
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

    private final S3Client s3Client;
    private final ImageRepository imageRepository;
    private final UserRepository userRepository; // UUID -> Long 변환용

    @Value("${spring.file.upload.bucket}")
    private String bucket;

    @Value("${spring.cloud.aws.s3.endpoint}")
    private String endpoint;

    @PostConstruct
    public void initBucket() {
        try {
            // S3 연결 시도
            boolean bucketExists = s3Client.listBuckets().buckets().stream()
                    .anyMatch(b -> b.name().equals(bucket));

            if (!bucketExists) {
                s3Client.createBucket(b -> b.bucket(bucket));
                log.info("Created MinIO bucket: {}", bucket);
            }
        } catch (Exception e) {
            // [중요] 에러가 나도 앱이 죽지 않도록 방지하고, 로그만 남김
            log.error("WARNING: Failed to initialize MinIO bucket. Image upload will fail.", e);
            // e.printStackTrace(); // 개발 단계에서 콘솔에 상세 에러 출력
        }
    }

    // 1. 이미지 업로드 (상태: TEMP)
    @Transactional
    public ImageUploadResponseDto uploadImage(MultipartFile file, ImageType imageType, UUID uploaderPublicId) {
        if (file.isEmpty()) throw new IllegalArgumentException("File is empty");

        // 유저 내부 ID 조회
        Long uploaderId = userRepository.findByPublicId(uploaderPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found")).getId();

        String originalFilename = file.getOriginalFilename();
        String extension = getExtension(originalFilename);
        String savedFilename = UUID.randomUUID() + extension;
        String key = imageType.getPath() + "/" + savedFilename; // S3 Key

        try {
            // S3 업로드
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucket)
                    .key(key)
                    .contentType(file.getContentType())
                    .build();
            s3Client.putObject(putObjectRequest, RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            String imageUrl = String.format("%s/%s/%s", endpoint, bucket, key);

            // DB 저장 (TEMP 상태)
            Image image = Image.builder()
                    .url(imageUrl)
                    .storedFilename(key)
                    .originalFilename(originalFilename)
                    .type(imageType)
                    .uploaderId(uploaderId)
                    .build();
            imageRepository.save(image);

            return ImageUploadResponseDto.builder()
                    .imageUrl(imageUrl)
                    .originalFilename(originalFilename)
                    .build();

        } catch (IOException e) {
            log.error("Image upload failed", e);
            throw new RuntimeException("Failed to upload image");
        }
    }

    // 2. 이미지 활성화 (TEMP -> ACTIVE) : 포스트 등록 성공 시 호출
    @Transactional
    public void activateImages(List<String> imageUrls) {
        if (imageUrls == null || imageUrls.isEmpty()) return;

        List<Image> images = imageRepository.findByUrlIn(imageUrls);
        for (Image image : images) {
            image.activate(); // 상태 변경 (Dirty Checking)
        }
    }

    // 3. 사용하지 않는 이미지 삭제 (Garbage Collection)
    @Transactional
    public void deleteUnusedImages() {
        // 24시간 이전 시간 계산
        Instant cutoffTime = Instant.now().minus(24, ChronoUnit.HOURS);

        List<Image> unusedImages = imageRepository.findByStatusAndCreatedAtBefore(ImageStatus.TEMP, cutoffTime);

        if (unusedImages.isEmpty()) return;

        log.info("Found {} unused images. Starting cleanup...", unusedImages.size());

        for (Image image : unusedImages) {
            try {
                // S3 삭제
                s3Client.deleteObject(DeleteObjectRequest.builder()
                        .bucket(bucket)
                        .key(image.getStoredFilename())
                        .build());

                // DB 삭제
                imageRepository.delete(image);
            } catch (Exception e) {
                log.error("Failed to delete image: {}", image.getUrl(), e);
            }
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf("."));
    }
}