package com.pairingplanet.pairing_planet.util;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;

/**
 * Utility for encoding/decoding cursor-based pagination cursors.
 * Format: Base64(epochMillis_id)
 * Example: "1705142400000_12345678" -> "MTcwNTE0MjQwMDAwMF8xMjM0NTY3OA=="
 */
public class CursorUtil {

    private static final String SEPARATOR = "_";

    /**
     * Encode a cursor from createdAt timestamp and id.
     */
    public static String encode(Instant createdAt, Long id) {
        if (createdAt == null || id == null) {
            return null;
        }
        String raw = createdAt.toEpochMilli() + SEPARATOR + id;
        return Base64.getEncoder().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Decode a cursor string back to CursorData.
     * Returns null if the cursor is null, empty, or invalid.
     */
    public static CursorData decode(String cursor) {
        if (cursor == null || cursor.isBlank()) {
            return null;
        }
        try {
            String decoded = new String(Base64.getDecoder().decode(cursor), StandardCharsets.UTF_8);
            int separatorIndex = decoded.lastIndexOf(SEPARATOR);
            if (separatorIndex == -1) {
                return null;
            }
            String epochPart = decoded.substring(0, separatorIndex);
            String idPart = decoded.substring(separatorIndex + 1);

            Instant createdAt = Instant.ofEpochMilli(Long.parseLong(epochPart));
            Long id = Long.parseLong(idPart);

            return new CursorData(createdAt, id);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Data class holding decoded cursor values.
     */
    public record CursorData(Instant createdAt, Long id) {}
}
