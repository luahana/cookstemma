package com.cookstemma.cookstemma.dto.search;

import java.util.List;
import java.util.UUID;

/**
 * Rich hashtag result for unified search with preview data.
 *
 * @param publicId Hashtag's public ID
 * @param name Hashtag name (without # prefix)
 * @param recipeCount Number of recipes using this hashtag
 * @param logCount Number of cooking logs using this hashtag
 * @param sampleThumbnails Sample thumbnail URLs from tagged content (3-4)
 * @param topContributors Top users who use this hashtag (2-3)
 */
public record HashtagSearchDto(
    UUID publicId,
    String name,
    int recipeCount,
    int logCount,
    List<String> sampleThumbnails,
    List<ContributorPreview> topContributors
) {
    public static HashtagSearchDto simple(UUID publicId, String name, int recipeCount, int logCount) {
        return new HashtagSearchDto(publicId, name, recipeCount, logCount, List.of(), List.of());
    }
}
