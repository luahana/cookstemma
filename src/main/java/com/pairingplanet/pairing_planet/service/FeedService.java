package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.post.*;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.feed.FeedResponseDto;
import com.pairingplanet.pairing_planet.dto.post.PostDto;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FeedService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    // 타입별 Redis Key (4:4:2 비율 유지용)
    private static final String KEY_DAILY = "feed:daily";
    private static final String KEY_REVIEW = "feed:review";
    private static final String KEY_RECIPE = "feed:recipe";

    private static final int PAGE_SIZE = 10;
    private static final long HISTORY_TTL_DAYS = 1;

    @Value("${file.upload.url-prefix:http://localhost:9000/pairing-planet-local}")
    private String urlPrefix;

    /**
     * 메인 피드 진입점: 취향 필터링 여부에 따라 로직 분기
     */
    public FeedResponseDto getMixedFeed(UUID userId, int offset) {
        // 1. 유저의 식이 취향(Dietary) 정보 가져오기
        User user = (userId != null) ? userRepository.findByPublicId(userId).orElse(null) : null;
        Long preferredDietaryId = (user != null) ? user.getPreferredDietaryId() : null;

        try {
            // 2. 사용자의 식이 취향 설정이 있다면 DB에서 필터링된 피드 제공 (개인화)
            if (preferredDietaryId != null) {
                return getPersonalizedFeedFromDb(preferredDietaryId, offset);
            }

            // 3. 설정이 없다면 글로벌 Redis 피드 시도
            return getFeedFromRedis(userId, offset);
        } catch (Exception e) {
            log.error("Feed error, switching to Global DB Fallback: {}", e.getMessage());
            return getFeedFallback(offset);
        }
    }

    /**
     * 개인화 피드 (DB 기반, 식이 취향 필터 적용)
     */
    private FeedResponseDto getPersonalizedFeedFromDb(Long dietaryId, int offset) {
        List<PostDto> combinedPosts = new ArrayList<>();

        // 4:4:2 비율로 DB 필터링 조회
        combinedPosts.addAll(fetchFromDbWithFilter(DailyPost.class, dietaryId, 4, offset));
        combinedPosts.addAll(fetchFromDbWithFilter(ReviewPost.class, dietaryId, 4, offset));
        combinedPosts.addAll(fetchFromDbWithFilter(RecipePost.class, dietaryId, 2, offset));

        Collections.shuffle(combinedPosts);

        return FeedResponseDto.builder()
                .posts(combinedPosts)
                .nextCursor(String.valueOf(offset + 1))
                .hasNext(combinedPosts.size() >= PAGE_SIZE)
                .build();
    }

    /**
     * 일반 피드 (Redis 기반, 중복 제거 적용)
     */
    private FeedResponseDto getFeedFromRedis(UUID userId, int offset) {
        Long internalUserId = (userId != null) ?
                userRepository.findByPublicId(userId).map(User::getId).orElse(null) : null;
        String historyKey = (internalUserId != null) ? "user:" + internalUserId + ":seen" : "user:anon:seen";

        List<PostDto> finalPosts = new ArrayList<>();

        // 4:4:2 비율로 Redis에서 데이터 추출
        finalPosts.addAll(fetchAndFilterFromRedis(KEY_DAILY, 4, offset, historyKey));
        finalPosts.addAll(fetchAndFilterFromRedis(KEY_REVIEW, 4, offset, historyKey));
        finalPosts.addAll(fetchAndFilterFromRedis(KEY_RECIPE, 2, offset, historyKey));

        Collections.shuffle(finalPosts);

        return FeedResponseDto.builder()
                .posts(finalPosts)
                .nextCursor(String.valueOf(offset + 1))
                .hasNext(finalPosts.size() >= PAGE_SIZE)
                .build();
    }

    /**
     * 장애 대응 피드 (DB 기반, 글로벌 최신순)
     */
    private FeedResponseDto getFeedFallback(int offset) {
        List<PostDto> combinedPosts = new ArrayList<>();

        combinedPosts.addAll(fetchFromDbWithFilter(DailyPost.class, null, 4, offset));
        combinedPosts.addAll(fetchFromDbWithFilter(ReviewPost.class, null, 4, offset));
        combinedPosts.addAll(fetchFromDbWithFilter(RecipePost.class, null, 2, offset));

        return FeedResponseDto.builder()
                .posts(combinedPosts)
                .nextCursor(String.valueOf(offset + 1))
                .hasNext(combinedPosts.size() >= PAGE_SIZE)
                .build();
    }

    // --- Helper Methods ---

    private List<PostDto> fetchAndFilterFromRedis(String key, int count, int offset, String historyKey) {
        int start = offset * count;
        List<Object> rawIds = redisTemplate.opsForList().range(key, start, start + (count * 2));
        if (rawIds == null || rawIds.isEmpty()) return new ArrayList<>();

        List<Long> filteredIds = new ArrayList<>();
        for (Object obj : rawIds) {
            String idStr = obj.toString();
            if (Boolean.FALSE.equals(redisTemplate.opsForSet().isMember(historyKey, idStr))) {
                filteredIds.add(Long.valueOf(idStr));
                if (filteredIds.size() >= count) break;
            }
        }

        if (filteredIds.isEmpty()) return new ArrayList<>();

        redisTemplate.opsForSet().add(historyKey, filteredIds.stream().map(String::valueOf).toArray(String[]::new));
        redisTemplate.expire(historyKey, HISTORY_TTL_DAYS, TimeUnit.DAYS);

        return postRepository.findAllWithDetailsByIdIn(filteredIds).stream()
                .map(p -> PostDto.from(p, resolveDietaryLabel(p), urlPrefix))
                .toList();
    }

    private List<PostDto> fetchFromDbWithFilter(Class<? extends Post> type, Long dietaryId, int limit, int offset) {
        return postRepository.findPublicPostsWithPreference(type, dietaryId, PageRequest.of(offset, limit))
                .getContent().stream()
                .map(p -> PostDto.from(p, resolveDietaryLabel(p), urlPrefix))
                .toList();
    }

    private String resolveDietaryLabel(Post post) {
        if (post.getPairing() != null && post.getPairing().getDietaryContext() != null) {
            return post.getPairing().getDietaryContext().getDisplayName(); // Dietary Context만 반환
        }
        return "";
    }
}