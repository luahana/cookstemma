package com.pairingplanet.pairing_planet.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.dto.search.*;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.search.PostSearchRepositoryCustom;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SearchService {
    private final PostRepository postRepository;
    private final PostSearchRepositoryCustom postSearchRepository;
    private final ObjectMapper objectMapper;

    private static final Instant SAFE_MIN_DATE = Instant.parse("1970-01-01T00:00:00Z");

    @Value("${file.upload.url-prefix:http://localhost:9000/pairing-planet-local}")
    private String urlPrefix;

    @Transactional(readOnly = true)
    public SearchResponseDto searchPosts(PairingSearchRequestDto request) {
        // 1. 커서 디코딩 (이제 DTO 생성자에서 자동으로 날짜가 보정됨)
        SearchCursorDto cursor = decodeCursor(request.cursor());

        Instant safeCreatedAt = cursor.lastCreatedAt();
        if (safeCreatedAt == null || safeCreatedAt.isBefore(SAFE_MIN_DATE)) {
            safeCreatedAt = SAFE_MIN_DATE;
        }
        int limit = 10;

        List<PostSearchResultDto> results;

        // Case 1: 텍스트 검색
        if ((request.foodIds() == null || request.foodIds().isEmpty())
                && request.rawQuery() != null && !request.rawQuery().isBlank()) {

            var posts = postRepository.searchByContentNative(
                    request.rawQuery(),
                    request.locale(),
                    cursor.lastScore(),
                    safeCreatedAt, // 무조건 안전한 날짜임
                    limit
            );
            results = posts.stream().map(this::convertToDto).toList();

        } else {
            // Case 2: 고급 검색 (QueryDSL)
            SearchCursorDto safeCursor = new SearchCursorDto(cursor.lastScore(), cursor.lastId(), safeCreatedAt);

            results = postSearchRepository.searchPosts(request, safeCursor, limit);

            // Case 3: Fallback
            if (results.isEmpty() && request.whenContextId() != null && isFirstPage(cursor)) {
                results = postSearchRepository.searchPostsFallback(request, safeCursor, limit);
            }
        }

        // 2. 다음 커서 생성
        String nextCursor = null;
        boolean hasNext = !results.isEmpty();

        if (hasNext) {
            PostSearchResultDto last = results.get(results.size() - 1);
            nextCursor = encodeCursor(new SearchCursorDto(
                    last.popularityScore(),
                    last.postId(),
                    last.createdAt()
            ));
        }

        List<PostSearchResultDto> finalResults = results.stream()
                .map(dto -> new PostSearchResultDto(
                        dto.postId(),
                        dto.postPublicId(),
                        dto.content(),
                        dto.imageUrls().stream()
                                .map(key -> urlPrefix + "/" + key)
                                .toList(),
                        dto.createdAt(),
                        dto.creatorName(),
                        dto.creatorPublicId(),
                        dto.food1Name(),
                        dto.food1PublicId(),
                        dto.food2Name(),
                        dto.food2PublicId(),
                        dto.whenTagName(),
                        dto.dietaryTagName(),
                        dto.geniusCount(),
                        dto.daringCount(),
                        dto.pickyCount(),
                        dto.commentCount(),
                        dto.savedCount(),
                        dto.popularityScore(),
                        dto.isWhenFallback()
                ))
                .toList();

        return new SearchResponseDto(finalResults, nextCursor, hasNext);
    }

    private PostSearchResultDto convertToDto(com.pairingplanet.pairing_planet.domain.entity.post.Post p) {
        return new PostSearchResultDto(
                p.getId(), p.getPublicId(), p.getContent(),
                p.getImages().stream().map(Image::getStoredFilename).toList(),
                p.getCreatedAt(),
                p.getCreator().getUsername(),
                p.getCreator().getPublicId(),
                "Unknown", null, null, null,
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
        if (cursorStr == null || cursorStr.isBlank()) {
            return SearchCursorDto.initial();
        }
        try {
            String json = new String(Base64.getUrlDecoder().decode(cursorStr), StandardCharsets.UTF_8);
            // Jackson이 JSON을 파싱하여 생성자를 호출할 때, Record 생성자 내부 로직이 실행되어 날짜가 보정됩니다.
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