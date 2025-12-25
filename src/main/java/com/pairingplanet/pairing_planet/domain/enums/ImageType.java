package com.pairingplanet.pairing_planet.domain.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ImageType {
    PROFILE("profiles"),
    POST_DAILY("posts/daily"),
    POST_REVIEW("posts/review"),
    POST_RECIPE("posts/recipe");

    private final String path; // S3 내 저장될 폴더 경로
}