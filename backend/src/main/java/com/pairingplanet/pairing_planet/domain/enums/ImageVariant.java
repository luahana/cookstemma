package com.pairingplanet.pairing_planet.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ImageVariant {
    ORIGINAL(0, 100),        // Original size, no compression
    LARGE_1200(1200, 85),    // Web full-screen, high quality
    MEDIUM_800(800, 80),     // Mobile full, web detail view
    THUMB_400(400, 75),      // Grid thumbnails
    THUMB_200(200, 70);      // Small previews

    private final int maxDimension;
    private final int quality;

    public boolean shouldResize() {
        return maxDimension > 0;
    }

    public String getPathPrefix() {
        return name().toLowerCase();
    }
}
