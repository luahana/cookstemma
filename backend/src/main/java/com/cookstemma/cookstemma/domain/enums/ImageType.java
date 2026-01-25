package com.cookstemma.cookstemma.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ImageType {
    COVER,
    STEP,
    LOG_POST,
    PROFILE;

    /**
     * Profile images only need small thumbnails (circular avatars).
     * Other types need all variants including large sizes.
     */
    public boolean needsLargeVariants() {
        return this != PROFILE;
    }
}