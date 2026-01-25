package com.cookstemma.cookstemma.dto.common;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Slice;

import java.util.List;

/**
 * Unified pagination response supporting both offset-based (web) and cursor-based (mobile) pagination.
 *
 * Strategy:
 * - If client sends `cursor` param → cursor-based pagination (mobile)
 * - If client sends `page` param → offset-based pagination (web)
 * - Default → cursor-based initial page
 *
 * @param content List of items for the current page
 * @param totalElements Total count of items (offset pagination only, null for cursor)
 * @param totalPages Total number of pages (offset pagination only, null for cursor)
 * @param currentPage Current page number, 0-indexed (offset pagination only, null for cursor)
 * @param nextCursor Cursor for the next page (cursor pagination only, null for offset)
 * @param hasNext Whether there are more items to fetch
 * @param size Number of items per page
 */
public record UnifiedPageResponse<T>(
    List<T> content,
    Long totalElements,
    Integer totalPages,
    Integer currentPage,
    String nextCursor,
    boolean hasNext,
    int size
) {
    /**
     * Create a cursor-based response (for mobile clients).
     * Offset fields (totalElements, totalPages, currentPage) will be null.
     */
    public static <T> UnifiedPageResponse<T> fromCursor(List<T> content, String nextCursor, int size) {
        return new UnifiedPageResponse<>(
            content,
            null,           // totalElements - not available for cursor
            null,           // totalPages - not available for cursor
            null,           // currentPage - not available for cursor
            nextCursor,
            nextCursor != null,
            size
        );
    }

    /**
     * Create a cursor-based response from a Slice (for mobile clients).
     */
    public static <T> UnifiedPageResponse<T> fromSlice(Slice<T> slice, String nextCursor, int size) {
        return new UnifiedPageResponse<>(
            slice.getContent(),
            null,           // totalElements - not available for cursor
            null,           // totalPages - not available for cursor
            null,           // currentPage - not available for cursor
            nextCursor,
            slice.hasNext(),
            size
        );
    }

    /**
     * Create an offset-based response from a Page (for web clients).
     * Cursor field (nextCursor) will be null.
     */
    public static <T> UnifiedPageResponse<T> fromPage(Page<T> page, int size) {
        return new UnifiedPageResponse<>(
            page.getContent(),
            page.getTotalElements(),
            page.getTotalPages(),
            page.getNumber(),
            null,           // nextCursor - not used for offset
            page.hasNext(),
            size
        );
    }

    /**
     * Create an empty response (no items).
     */
    public static <T> UnifiedPageResponse<T> empty(int size) {
        return new UnifiedPageResponse<>(
            List.of(),
            0L,
            0,
            0,
            null,
            false,
            size
        );
    }

    /**
     * Create an empty cursor-based response.
     */
    public static <T> UnifiedPageResponse<T> emptyCursor(int size) {
        return new UnifiedPageResponse<>(
            List.of(),
            null,
            null,
            null,
            null,
            false,
            size
        );
    }
}
