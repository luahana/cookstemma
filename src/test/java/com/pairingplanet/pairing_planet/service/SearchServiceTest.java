package com.pairingplanet.pairing_planet.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.dto.search.*;
import com.pairingplanet.pairing_planet.repository.food.FoodCategoryRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.search.PostSearchRepositoryImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageRequest;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class SearchServiceTest {

    @InjectMocks
    private SearchService searchService;

    @Mock private FoodMasterRepository foodMasterRepository;
    @Mock private FoodCategoryRepository foodCategoryRepository;
    @Mock private PostRepository postRepository;
    @Mock private PostSearchRepositoryImpl postSearchRepositoryImpl;

    // 실제 ObjectMapper 사용 (커서 인코딩/디코딩 로직 검증용)
    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();


    @Test
    @DisplayName("포스트 검색: 음식ID 없이 텍스트만 있으면 Native Query를 사용한다")
    void searchPosts_nativeQuery() {
        // given
        // 조건: foodIds 없음, rawQuery 있음
        PairingSearchRequestDto request = new PairingSearchRequestDto(
                null, "delicious", null, null, "en", null
        );

        Post post = Post.builder()
                .content("content")
                .popularityScore(10.0)
                .imageUrls(Collections.emptyList())
                .build();

        // Native Query는 보통 List<Post> 반환
        given(postRepository.searchByContentNative(anyString(), anyString(), anyDouble(), anyInt()))
                .willReturn(List.of(post));

        // when
        SearchResponseDto response = searchService.searchPosts(request);

        // then
        assertThat(response.results()).hasSize(1);
        verify(postRepository).searchByContentNative(eq("delicious"), eq("en"), anyDouble(), eq(10));
    }

    @Test
    @DisplayName("포스트 검색: 일반 검색(필터)이 성공하면 QueryDSL Repository를 호출한다")
    void searchPosts_normal() {
        // given
        // 조건: foodIds 있음
        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(1L), null, 100L, null, "en", null
        );

        PostSearchResultDto dto = createSearchResultDto(false);

        given(postSearchRepositoryImpl.searchPosts(any(), any(), anyInt()))
                .willReturn(List.of(dto));

        // when
        SearchResponseDto response = searchService.searchPosts(request);

        // then
        assertThat(response.results()).hasSize(1);
        assertThat(response.results().get(0).isWhenFallback()).isFalse();
        verify(postSearchRepositoryImpl).searchPosts(any(), any(), anyInt());
    }

    @Test
    @DisplayName("포스트 검색: 검색 결과가 없고(첫페이지), When조건이 있으면 Fallback 검색을 수행한다")
    void searchPosts_fallback() {
        // given
        // 조건: foodIds 있음, whenContextId 있음, cursor 없음(첫페이지)
        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(1L), null, 100L, null, "en", null
        );

        // 1. 일반 검색 -> 결과 없음
        given(postSearchRepositoryImpl.searchPosts(any(), any(), anyInt()))
                .willReturn(Collections.emptyList());

        // 2. Fallback 검색 -> 결과 있음 (Fallback 플래그 true)
        PostSearchResultDto fallbackDto = createSearchResultDto(true);
        given(postSearchRepositoryImpl.searchPostsFallback(any(), any(), anyInt()))
                .willReturn(List.of(fallbackDto));

        // when
        SearchResponseDto response = searchService.searchPosts(request);

        // then
        assertThat(response.results()).hasSize(1);
        assertThat(response.results().get(0).isWhenFallback()).isTrue();

        // 두 메서드가 순차적으로 호출되었는지 검증
        verify(postSearchRepositoryImpl).searchPosts(any(), any(), anyInt());
        verify(postSearchRepositoryImpl).searchPostsFallback(any(), any(), anyInt());
    }

    @Test
    @DisplayName("커서 디코딩/인코딩: 다음 페이지 커서가 정상적으로 생성된다")
    void searchPosts_cursorHandling() {
        // given
        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(1L), null, null, null, "en", null
        );

        // 마지막 아이템 정보 (Score: 50.0, ID: 999)
        PostSearchResultDto dto = new PostSearchResultDto(
                999L, UUID.randomUUID(), "content", Collections.emptyList(), Instant.now(),
                "creator", UUID.randomUUID(), "food", UUID.randomUUID(), null, null,
                null, null, 0, 0, 0, 0, 0, 50.0, false
        );

        given(postSearchRepositoryImpl.searchPosts(any(), any(), anyInt()))
                .willReturn(List.of(dto));

        // when
        SearchResponseDto response = searchService.searchPosts(request);

        // then
        assertThat(response.hasNext()).isTrue();
        assertThat(response.nextCursor()).isNotNull();

        // 생성된 커서를 다시 디코딩해서 값 확인 (Service 내부 로직과 동일하게 검증)
        SearchCursorDto decoded = decodeCursorHelper(response.nextCursor());
        assertThat(decoded.lastScore()).isEqualTo(50.0);
        assertThat(decoded.lastId()).isEqualTo(999L);
    }

    // --- Helpers ---

    private PostSearchResultDto createSearchResultDto(boolean isFallback) {
        return new PostSearchResultDto(
                1L, UUID.randomUUID(), "content", Collections.emptyList(), Instant.now(),
                "creator", UUID.randomUUID(), "food", UUID.randomUUID(), null, null,
                "lunch", "vegan", 0, 0, 0, 0, 0, 10.0,
                isFallback
        );
    }

    // 테스트 검증용 디코더
    private SearchCursorDto decodeCursorHelper(String cursorStr) {
        try {
            String json = new String(java.util.Base64.getUrlDecoder().decode(cursorStr));
            return new ObjectMapper().readValue(json, SearchCursorDto.class);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}