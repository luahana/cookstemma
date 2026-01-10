package com.pairingplanet.pairing_planet.dto.log_post;

import com.pairingplanet.pairing_planet.dto.hashtag.HashtagDto;
import com.pairingplanet.pairing_planet.dto.image.ImageResponseDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record LogPostDetailResponseDto(
        UUID publicId,
        String title,
        String content,
        String outcome,  // SUCCESS, PARTIAL, FAILED
        List<ImageResponseDto> images,
        RecipeSummaryDto linkedRecipe,
        Instant createdAt,
        List<HashtagDto> hashtags,
        Boolean isSavedByCurrentUser  // null if not logged in
) {}