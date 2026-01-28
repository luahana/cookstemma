package com.cookstemma.cookstemma.dto.search;

import java.util.List;

public record UnifiedSearchResponse(
    List<SearchResultItem> content,
    SearchCounts counts,
    int page,
    int size,
    long totalElements,
    int totalPages,
    boolean hasNext,
    String nextCursor
) {
    public static UnifiedSearchResponse of(
            List<SearchResultItem> content,
            SearchCounts counts,
            int page,
            int size,
            long totalElements,
            String nextCursor
    ) {
        int totalPages = (int) Math.ceil((double) totalElements / size);
        boolean hasNext = nextCursor != null;
        return new UnifiedSearchResponse(content, counts, page, size, totalElements, totalPages, hasNext, nextCursor);
    }

    public static UnifiedSearchResponse empty(int size) {
        return new UnifiedSearchResponse(
            List.of(),
            SearchCounts.empty(),
            0,
            size,
            0,
            0,
            false,
            null
        );
    }
}
