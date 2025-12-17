package com.pairingplanet.pairing_planet.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.dto.search.*;
import com.pairingplanet.pairing_planet.repository.food.FoodCategoryRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.search.PostSearchRepositoryImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SearchService {
    private final PostRepository postRepository;
    private final PostSearchRepositoryImpl postSearchRepositoryImpl;
    private final ObjectMapper objectMapper;

    // FR-80 ~ FR-88: 메인 포스트 검색 (Cursor Pagination 적용)
    @Transactional(readOnly = true)
    public SearchResponseDto searchPosts(PairingSearchRequestDto request) {
        // 1. 커서 디코딩
        SearchCursorDto cursor = decodeCursor(request.cursor());
        int limit = 10;

        List<PostSearchResultDto> results;

        // Case 1: 태그/음식 없이 검색어만 있는 경우 -> 본문 검색 (PostRepository Native Query)
        if ((request.foodIds() == null || request.foodIds().isEmpty())
                && request.rawQuery() != null && !request.rawQuery().isBlank()) {

            // PostRepository.searchByContentNative 사용 (지난번 수정된 커서 지원 메서드)
            var posts = postRepository.searchByContentNative(
                    request.rawQuery(),
                    request.locale(),
                    cursor.lastScore(), // Popularity Score 기준 커서
                    limit
            );

            // Entity -> DTO 변환
            results = posts.stream().map(this::convertToDto).toList();

        } else {
            // Case 2: 일반/고급 검색 (PostSearchRepository - QueryDSL 등 사용 가정)
            // Repository 메서드도 (request, cursorScore, cursorId, limit)을 받도록 수정 필요
            results = postSearchRepositoryImpl.searchPosts(request, cursor, limit);

            // Case 3: Fallback (검색 결과 없고 When 컨텍스트가 있었을 경우) -> When 무시 재검색
            // 주의: 첫 페이지(cursor가 초기값)일 때만 Fallback을 시도해야 함. 스크롤 중간에 갑자기 Fallback하면 이상함.
            if (results.isEmpty() && request.whenContextId() != null && isFirstPage(cursor)) {
                results = postSearchRepositoryImpl.searchPostsFallback(request, cursor, limit);
            }
        }

        // 2. 다음 커서 생성
        String nextCursor = null;
        boolean hasNext = !results.isEmpty();

        if (hasNext) {
            PostSearchResultDto last = results.get(results.size() - 1);
            // 검색은 보통 '관련도'나 '인기도' 순이므로 score와 id를 잡음
            nextCursor = encodeCursor(new SearchCursorDto(last.popularityScore(), last.postId()));
        }

        return new SearchResponseDto(results, nextCursor, hasNext);
    }

    // --- Helpers ---

    private PostSearchResultDto convertToDto(com.pairingplanet.pairing_planet.domain.entity.post.Post p) {
        return new PostSearchResultDto(
                p.getId(), p.getPublicId(), p.getContent(), p.getImageUrls(), p.getCreatedAt(),
                "Unknown", null, // Creator Info 필요시 추가 조회
                null, null, null, null,
                null, null,
                p.getGeniusCount(), p.getDaringCount(), p.getPickyCount(),
                p.getCommentCount(), p.getSavedCount(), p.getPopularityScore(),
                false
        );
    }

    private boolean isFirstPage(SearchCursorDto cursor) {
        return cursor.lastScore().equals(Double.MAX_VALUE);
    }

    private SearchCursorDto decodeCursor(String cursorStr) {
        if (cursorStr == null || cursorStr.isBlank()) return SearchCursorDto.initial();
        try {
            String json = new String(Base64.getUrlDecoder().decode(cursorStr), StandardCharsets.UTF_8);
            return objectMapper.readValue(json, SearchCursorDto.class);
        } catch (Exception e) {
            return SearchCursorDto.initial();
        }
    }

    private String encodeCursor(SearchCursorDto cursor) {
        try {
            String json = objectMapper.writeValueAsString(cursor);
            return Base64.getUrlEncoder().encodeToString(json.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            return "";
        }
    }
}