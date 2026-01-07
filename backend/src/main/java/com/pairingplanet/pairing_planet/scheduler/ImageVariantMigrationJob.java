package com.pairingplanet.pairing_planet.scheduler;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.service.ImageProcessingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class ImageVariantMigrationJob {

    private final ImageRepository imageRepository;
    private final ImageProcessingService imageProcessingService;

    @EventListener(ApplicationReadyEvent.class)
    public void migrateExistingImages() {
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
