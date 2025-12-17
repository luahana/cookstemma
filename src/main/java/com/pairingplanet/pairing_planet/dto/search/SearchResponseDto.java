package com.pairingplanet.pairing_planet.dto.search;

import java.util.List;

public record SearchResponseDto(
        List<PostSearchResultDto> results, // 검색 결과 리스트
        String nextCursor,                 // 다음 페이지 요청용 커서
        boolean hasNext                    // 다음 페이지 존재 여부
) {}