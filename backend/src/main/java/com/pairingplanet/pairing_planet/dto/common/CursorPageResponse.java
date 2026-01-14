package com.pairingplanet.pairing_planet.dto.common;

import java.util.List;

/**
 * Cursor-based pagination response DTO.
 * Uses createdAt + id as cursor for stable pagination.
 *
 * @param content List of items for the current page
 * @param nextCursor Cursor for the next page (null if no more pages)
 * @param hasNext Whether there are more items to fetch
 * @param size Number of items per page
 */
public record CursorPageResponse<T>(
    List<T> content,
    String nextCursor,
    boolean hasNext,
    int size
) {
    /**
     * Create a response with items and calculate hasNext based on fetched count.
     */
    public static <T> CursorPageResponse<T> of(List<T> content, String nextCursor, int requestedSize) {
        boolean hasNext = nextCursor != null;
        return new CursorPageResponse<>(content, nextCursor, hasNext, requestedSize);
    }

    /**
     * Create an empty response (no items).
     */
    public static <T> CursorPageResponse<T> empty(int size) {
        return new CursorPageResponse<>(List.of(), null, false, size);
    }
}
