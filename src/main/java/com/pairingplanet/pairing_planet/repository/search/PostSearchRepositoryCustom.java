package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.dto.search.PairingSearchRequestDto;
import com.pairingplanet.pairing_planet.dto.search.PostSearchResultDto;
import com.pairingplanet.pairing_planet.dto.search.SearchCursorDto;

import java.util.List;

public interface PostSearchRepositoryCustom {
    // 일반 검색
    List<PostSearchResultDto> searchPosts(PairingSearchRequestDto request, SearchCursorDto cursor, int limit);

    // Fallback 검색 (When 태그 무시)
    List<PostSearchResultDto> searchPostsFallback(PairingSearchRequestDto request, SearchCursorDto cursor, int limit);
}