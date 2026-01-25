package com.cookstemma.cookstemma.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

/**
 * Image variant types for responsive image delivery.
 * Each variant has a max dimension and quality setting.
 */
@Getter
@RequiredArgsConstructor
public enum ImageVariant {
    ORIGINAL(0, 100),
    LARGE_1200(1200, 85),
    MEDIUM_800(800, 80),
    THUMB_400(400, 75),
    THUMB_200(200, 70);

    private final int maxDimension;
    private final int quality;

    public boolean shouldResize() {
        return maxDimension > 0;
    }

    public String getPathPrefix() {
        return name();
    }
}
