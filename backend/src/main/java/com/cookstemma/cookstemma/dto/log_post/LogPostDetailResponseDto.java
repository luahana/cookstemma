package com.cookstemma.cookstemma.dto.log_post;

import com.cookstemma.cookstemma.dto.hashtag.HashtagDto;
import com.cookstemma.cookstemma.dto.image.ImageResponseDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Log post detail DTO with pre-localized title/content.
 * The title and content fields contain values for the requested locale,
 * resolved server-side from the translations maps.
 */
public record LogPostDetailResponseDto(
        UUID publicId,
        String title,        // Localized title
        String content,      // Localized content
        Integer rating,      // 1-5 star rating
        List<ImageResponseDto> images,
        RecipeSummaryDto linkedRecipe,
        Instant createdAt,
        List<HashtagDto> hashtags,
        Boolean isSavedByCurrentUser,  // null if not logged in
        UUID creatorPublicId,          // for ownership check (UUID for frontend comparison)
        String userName,               // Creator's username for display
        Boolean isPrivate              // Whether this log is private
) {}