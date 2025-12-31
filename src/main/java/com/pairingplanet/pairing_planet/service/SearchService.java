package com.pairingplanet.pairing_planet.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.search.SearchHistory;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.search.*;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.pairing.PairingMapRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.search.PostSearchRepositoryCustom;
import com.pairingplanet.pairing_planet.repository.search.SearchHistoryRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SearchService {
    private final PostRepository postRepository;
    private final PostSearchRepositoryCustom postSearchRepository;
    private final ObjectMapper objectMapper;
    private final UserRepository userRepository;
    private final PairingMapRepository pairingMapRepository;
    private final SearchHistoryRepository searchHistoryRepository;
    private final FoodMasterRepository foodMasterRepository;

    private static final Instant SAFE_MIN_DATE = Instant.parse("1970-01-01T00:00:00Z");

    @Value("${file.upload.url-prefix:http://localhost:9000/pairing-planet-local}")
    private String urlPrefix;

    /**
     * 포스트 검색 및 히스토리 자동 저장
     */
    @Transactional
    public SearchResponseDto searchPosts(UUID userPublicId, PairingSearchRequestDto request) {

        // 1. 로그인 유저인 경우 검색 조건에 맞는 페어링을 찾아 히스토리 저장
        if (userPublicId != null) {
            handleAutomaticHistorySave(userPublicId, request);
        }

        // 2. 커서 디코딩
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
                    safeCreatedAt,
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

        // 3. 다음 커서 생성
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

    /**
     * 검색 조건으로부터 Pairing ID를 추출하여 히스토리에 저장
     */
    private void handleAutomaticHistorySave(UUID userPublicId, PairingSearchRequestDto request) {
        // [수정] DTO의 List<UUID>를 DB 조회를 위해 List<Long>으로 변환
        if (request.foodIds() != null && !request.foodIds().isEmpty()) {
            List<Long> internalFoodIds = request.foodIds().stream()
                    .map(publicId -> foodMasterRepository.findByPublicId(publicId)
                            .map(FoodMaster::getId)
                            .orElse(null))
                    .filter(Objects::nonNull)
                    .toList();

            if (internalFoodIds.isEmpty()) return;

            // 변환된 내부 ID(Long)를 사용
            Long f1 = internalFoodIds.get(0);
            Long f2 = internalFoodIds.size() > 1 ? internalFoodIds.get(1) : null;

            pairingMapRepository.findExistingPairing(f1, f2, request.whenContextId(), request.dietaryContextId())
                    .ifPresent(pairing -> saveSearchHistory(userPublicId, pairing.getId()));
        }
    }

    @Transactional
    public void saveSearchHistory(UUID userPublicId, Long pairingId) {
        User user = userRepository.findByPublicId(userPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        PairingMap pairing = pairingMapRepository.findById(pairingId)
                .orElseThrow(() -> new IllegalArgumentException("Pairing not found"));

        // 이미 기록이 있다면 시간만 갱신, 없으면 새로 저장 (Upsert)
        searchHistoryRepository.findByUserIdAndPairingId(user.getId(), pairingId)
                .ifPresentOrElse(
                        SearchHistory::updateTimestamp,
                        () -> searchHistoryRepository.save(SearchHistory.builder().user(user).pairing(pairing).build())
                );
    }

    /**
     * 내 검색 기록 조회 (최근 10개)
     */
    @Transactional(readOnly = true)
    public List<SearchHistoryDto> getMyHistory(UUID userPublicId) {
        User user = userRepository.findByPublicId(userPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return searchHistoryRepository.findTop10ByUserIdOrderByUpdatedAtDesc(user.getId())
                .stream()
                .map(sh -> new SearchHistoryDto(
                        sh.getPublicId(),
                        sh.getPairing().getPublicId(),
                        sh.getPairing().getFood1().getNameByLocale("ko"),
                        sh.getPairing().getFood2() != null ? sh.getPairing().getFood2().getNameByLocale("ko") : null,
                        sh.getPairing().getWhenContext() != null ? sh.getPairing().getWhenContext().getDisplayName() : null,
                        sh.getPairing().getDietaryContext() != null ? sh.getPairing().getDietaryContext().getDisplayName() : null,
                        sh.getUpdatedAt()
                )).toList();
    }

    /**
     * 검색 기록 개별 삭제
     */
    @Transactional
    public void deleteHistory(UUID userPublicId, UUID historyPublicId) {
        User user = userRepository.findByPublicId(userPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        searchHistoryRepository.deleteByPublicIdAndUserId(historyPublicId, user.getId());
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