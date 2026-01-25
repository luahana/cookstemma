package com.cookstemma.cookstemma.dto.search;

import java.util.UUID;

/**
 * Preview of a contributor for hashtag search results.
 *
 * @param publicId User's public ID
 * @param username User's display name
 * @param avatarUrl User's profile image URL
 */
public record ContributorPreview(
    UUID publicId,
    String username,
    String avatarUrl
) {}
