package com.pairingplanet.pairing_planet.dto.post;

import java.util.List;

// 공통 커서 응답 래퍼
public record CursorResponse<T>(
        List<T> data,
        String nextCursor,
        boolean hasNext
) {}