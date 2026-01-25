package com.cookstemma.cookstemma.dto.image;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.enums.ImageVariant;

import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

public record ImageVariantsDto(
        UUID imagePublicId,
        String original,
        String large,
        String medium,
        String thumbnail,
        String small
) {
    public static ImageVariantsDto from(Image image, String urlPrefix) {
        if (image == null) return null;

        String baseUrl = urlPrefix + "/" + image.getStoredFilename();

        // If no variants, return original for all sizes
        if (!image.hasVariants()) {
            return new ImageVariantsDto(
                    image.getPublicId(),
                    baseUrl,
                    baseUrl,
                    baseUrl,
                    baseUrl,
                    baseUrl
            );
        }

        // Map variants by type
        Map<ImageVariant, String> variantUrls = image.getVariants().stream()
                .collect(Collectors.toMap(
                        Image::getVariantType,
                        v -> urlPrefix + "/" + v.getStoredFilename(),
                        (a, b) -> a
                ));

        return new ImageVariantsDto(
                image.getPublicId(),
                baseUrl,
                variantUrls.getOrDefault(ImageVariant.LARGE_1200, baseUrl),
                variantUrls.getOrDefault(ImageVariant.MEDIUM_800, baseUrl),
                variantUrls.getOrDefault(ImageVariant.THUMB_400, baseUrl),
                variantUrls.getOrDefault(ImageVariant.THUMB_200, baseUrl)
        );
    }

    public String getBestUrl(int displayWidth) {
        if (displayWidth <= 200) return small;
        if (displayWidth <= 400) return thumbnail;
        if (displayWidth <= 800) return medium;
        if (displayWidth <= 1200) return large;
        return original;
    }
}
