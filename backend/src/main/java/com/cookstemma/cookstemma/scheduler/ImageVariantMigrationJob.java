package com.cookstemma.cookstemma.scheduler;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.service.ImageProcessingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class ImageVariantMigrationJob {

    private final ImageRepository imageRepository;
    private final ImageProcessingService imageProcessingService;

    @Value("${image.variant.migration.enabled:false}")
    private boolean migrationEnabled;

    @Value("${image.variant.migration.delay-seconds:60}")
    private int delaySeconds;

    @Async
    @EventListener(ApplicationReadyEvent.class)
    public void migrateExistingImages() {
        if (!migrationEnabled) {
            log.info("Image variant migration is disabled");
            return;
        }

        // Delay to allow health checks to pass first
        try {
            log.info("Image variant migration will start in {} seconds", delaySeconds);
            Thread.sleep(delaySeconds * 1000L);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("Image variant migration interrupted during startup delay");
            return;
        }

        log.info("Starting image variant migration check...");

        List<Image> imagesWithoutVariants = imageRepository.findOriginalImagesWithoutVariants(ImageStatus.ACTIVE);

        if (imagesWithoutVariants.isEmpty()) {
            log.info("No images need variant generation");
            return;
        }

        log.info("Found {} images without variants, starting migration", imagesWithoutVariants.size());

        int processed = 0;
        for (Image image : imagesWithoutVariants) {
            try {
                imageProcessingService.generateVariantsAsync(image.getId());
                processed++;

                // Log progress every 100 images
                if (processed % 100 == 0) {
                    log.info("Queued {} images for variant generation", processed);
                }
            } catch (Exception e) {
                log.error("Failed to queue image {} for variant generation", image.getId(), e);
            }
        }

        log.info("Image variant migration queued: {} images", processed);
    }
}
