package com.pairingplanet.pairing_planet.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ImageVariant {
    // Original
    ORIGINAL(0, 100, "jpeg"),

    // JPEG variants (for browsers without WebP support)
    LARGE_1200(1200, 85, "jpeg"),
    MEDIUM_800(800, 80, "jpeg"),
    THUMB_400(400, 75, "jpeg"),
    THUMB_200(200, 70, "jpeg"),

    // WebP variants (25-35% smaller, better quality)
    LARGE_1200_WEBP(1200, 85, "webp"),
    MEDIUM_800_WEBP(800, 80, "webp"),
    THUMB_400_WEBP(400, 75, "webp"),
    THUMB_200_WEBP(200, 70, "webp");

    private final int maxDimension;
    private final int quality;
    private final String format;

    public boolean shouldResize() {
        return maxDimension > 0;
    }

    public boolean isWebP() {
        return "webp".equals(format);
    }

    public String getPathPrefix() {
        return name();
    }

    public String getFileExtension() {
        return isWebP() ? ".webp" : ".jpg";
    }

    /**
     * Get the JPEG equivalent for a WebP variant (for fallback).
     */
    public ImageVariant getJpegEquivalent() {
        return switch (this) {
            case LARGE_1200_WEBP -> LARGE_1200;
            case MEDIUM_800_WEBP -> MEDIUM_800;
            case THUMB_400_WEBP -> THUMB_400;
            case THUMB_200_WEBP -> THUMB_200;
            default -> this;
        };
    }

    /**
     * Get the WebP equivalent for a JPEG variant.
     */
    public ImageVariant getWebPEquivalent() {
        return switch (this) {
            case LARGE_1200 -> LARGE_1200_WEBP;
            case MEDIUM_800 -> MEDIUM_800_WEBP;
            case THUMB_400 -> THUMB_400_WEBP;
            case THUMB_200 -> THUMB_200_WEBP;
            default -> this;
        };
    }
}
