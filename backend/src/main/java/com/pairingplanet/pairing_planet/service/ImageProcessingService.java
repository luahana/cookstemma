package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageVariant;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ImageProcessingService {

    private final S3Client s3Client;
    private final ImageRepository imageRepository;

    @Value("${file.upload.bucket}")
    private String bucket;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    @Async("imageProcessingExecutor")
    @Transactional
    public void generateVariantsAsync(Long originalImageId) {
        // Add a small delay to ensure the calling transaction has committed
        // This prevents race condition where we read recipe_id as NULL
        try {
            Thread.sleep(500);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return;
        }

        try {
            Image original = imageRepository.findById(originalImageId)
                    .orElseThrow(() -> new IllegalArgumentException("Image not found: " + originalImageId));

            // Skip if already has variants or is a variant itself
            if (original.getOriginalImage() != null || original.hasVariants()) {
                log.debug("Skipping variant generation for image {}: already processed", originalImageId);
                return;
            }

            // Download original from S3
            byte[] originalBytes = downloadFromS3(original.getStoredFilename());
            BufferedImage originalImage = ImageIO.read(new ByteArrayInputStream(originalBytes));

            if (originalImage == null) {
                log.error("Failed to read image: {}", original.getStoredFilename());
                return;
            }

            // Update original with metadata
            original.setVariantType(ImageVariant.ORIGINAL);
            original.setWidth(originalImage.getWidth());
            original.setHeight(originalImage.getHeight());
            original.setFileSize((long) originalBytes.length);
            original.setFormat(getFormatFromFilename(original.getStoredFilename()));

            // Generate each variant
            for (ImageVariant variant : ImageVariant.values()) {
                if (variant == ImageVariant.ORIGINAL) continue;

                try {
                    generateVariant(original, originalImage, variant);
                } catch (Exception e) {
                    log.error("Failed to generate {} variant for image {}", variant, originalImageId, e);
                }
            }

            imageRepository.save(original);
            log.info("Successfully generated variants for image {}", originalImageId);

        } catch (Exception e) {
            log.error("Failed to generate variants for image {}", originalImageId, e);
        }
    }

    private void generateVariant(Image original, BufferedImage sourceImage, ImageVariant variant) throws IOException {
        int originalWidth = sourceImage.getWidth();
        int originalHeight = sourceImage.getHeight();
        int maxDim = variant.getMaxDimension();

        // Skip if image is smaller than target
        if (originalWidth <= maxDim && originalHeight <= maxDim) {
            log.debug("Skipping {} variant: original is smaller", variant);
            return;
        }

        // Calculate new dimensions maintaining aspect ratio
        double scale = Math.min((double) maxDim / originalWidth, (double) maxDim / originalHeight);
        int newWidth = (int) (originalWidth * scale);
        int newHeight = (int) (originalHeight * scale);

        // Generate resized image
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        Thumbnails.of(sourceImage)
                .size(newWidth, newHeight)
                .outputQuality(variant.getQuality() / 100.0)
                .outputFormat("jpg")
                .toOutputStream(baos);

        byte[] resizedBytes = baos.toByteArray();

        // Generate new filename
        String originalKey = original.getStoredFilename();
        String baseName = originalKey.substring(originalKey.lastIndexOf('/') + 1);
        String nameWithoutExt = baseName.contains(".") ? baseName.substring(0, baseName.lastIndexOf('.')) : baseName;
        String newKey = variant.getPathPrefix() + "/" + nameWithoutExt + "_" + variant.name().toLowerCase() + ".jpg";

        // Upload to S3
        uploadToS3(newKey, resizedBytes, "image/jpeg");

        // Save variant record
        Image variantImage = Image.builder()
                .storedFilename(newKey)
                .originalFilename(original.getOriginalFilename())
                .status(ImageStatus.ACTIVE)
                .type(original.getType())
                .displayOrder(original.getDisplayOrder())
                .uploaderId(original.getUploaderId())
                .variantType(variant)
                .originalImage(original)
                .width(newWidth)
                .height(newHeight)
                .fileSize((long) resizedBytes.length)
                .format("jpg")
                .build();

        original.getVariants().add(variantImage);
        log.debug("Generated {} variant: {}x{}, {} bytes", variant, newWidth, newHeight, resizedBytes.length);
    }

    private byte[] downloadFromS3(String key) throws IOException {
        try (InputStream is = s3Client.getObject(GetObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .build())) {
            return is.readAllBytes();
        }
    }

    private void uploadToS3(String key, byte[] data, String contentType) {
        PutObjectRequest putRequest = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .contentType(contentType)
                .cacheControl("public, max-age=31536000") // 1 year cache
                .build();

        s3Client.putObject(putRequest, RequestBody.fromBytes(data));
    }

    private String getFormatFromFilename(String filename) {
        if (filename == null || !filename.contains(".")) return "unknown";
        String ext = filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
        return switch (ext) {
            case "jpg", "jpeg" -> "jpeg";
            case "png" -> "png";
            case "gif" -> "gif";
            case "webp" -> "webp";
            default -> ext;
        };
    }

    public String getVariantUrl(Image image, ImageVariant variant) {
        if (image == null) return null;

        // If requesting original or no variants exist, return original
        if (variant == ImageVariant.ORIGINAL || !image.hasVariants()) {
            return urlPrefix + "/" + image.getStoredFilename();
        }

        // Find the requested variant
        return image.getVariants().stream()
                .filter(v -> v.getVariantType() == variant)
                .findFirst()
                .map(v -> urlPrefix + "/" + v.getStoredFilename())
                .orElse(urlPrefix + "/" + image.getStoredFilename());
    }
}
