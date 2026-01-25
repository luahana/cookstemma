package com.cookstemma.cookstemma.dto.search;

import java.util.List;

/**
 * Response for unified search across recipes, logs, and hashtags.
 *
 * @param content List of search results (mixed types)
 * @param counts Counts by type for filter chips
 * @param page Current page number (0-indexed)
 * @param size Items per page
 * @param totalElements Total count of items for current filter
 * @param totalPages Total number of pages
 * @param hasNext Whether there are more items to fetch
 */
public record UnifiedSearchResponse(
    List<SearchResultItem> content,
    SearchCounts counts,
    int page,
    int size,
    long totalElements,
    int totalPages,
    boolean hasNext
) {
    public static UnifiedSearchResponse of(
            List<SearchResultItem> content,
            SearchCounts counts,
            int page,
            int size,
            long totalElements
    ) {
        int totalPages = (int) Math.ceil((double) totalElements / size);
        boolean hasNext = page < totalPages - 1;
        return new UnifiedSearchResponse(content, counts, page, size, totalElements, totalPages, hasNext);
    }

    public static UnifiedSearchResponse empty(int size) {
        return new UnifiedSearchResponse(
            List.of(),
            SearchCounts.empty(),
            0,
            size,
            0,
            0,
            false
        );
    }
}
