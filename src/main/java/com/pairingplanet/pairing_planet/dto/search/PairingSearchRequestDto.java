package com.pairingplanet.pairing_planet.dto.search;

import java.util.List;
import java.util.UUID;

// 검색 요청
public record PairingSearchRequestDto(
        List<UUID> foodIds,          // 유저가 선택한 음식 ID 리스트 (0개, 1개, 또는 2개)
        String rawQuery,             // 음식 선택 없이 텍스트로 검색할 때 사용 (Fallback)
        Long whenContextId,          // FR-84: 시간/상황 태그 (Soft Filter)
        Long dietaryContextId,       // FR-83: 식이요법 태그 (Hard Filter)
        String locale,                // 유저의 언어/지역 코드 (예: "ko", "en")

        String cursor
) {}