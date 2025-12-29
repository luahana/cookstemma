package com.pairingplanet.pairing_planet.scheduler;

import com.pairingplanet.pairing_planet.domain.entity.post.*;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Slf4j
@Component
@RequiredArgsConstructor
public class FeedScheduler {

    private final PostRepository postRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    private static final Instant SAFE_MAX_DATE = Instant.parse("3000-01-01T00:00:00Z");

    // 5분마다 실행
    @Scheduled(fixedRate = 300000)
    public void updateAllFeedCaches() {
        log.info("Starting Multi-Type Feed Cache Update...");

        // 처리할 타입 정의
        List<Class<? extends Post>> postTypes = List.of(DailyPost.class, ReviewPost.class, RecipePost.class);

        // [참고] 주요 식이 취향 ID 리스트 (실제 DB ID에 맞춰 관리 필요)
        // null은 글로벌(필터 없음) 피드를 의미함
        List<Long> dietaryIds = Arrays.asList(null, 1L, 2L, 3L);

        for (Class<? extends Post> type : postTypes) {
            for (Long dietaryId : dietaryIds) {
                updateCacheForTypeAndDietary(type, dietaryId);
            }
        }

        log.info("All Feed Caches Updated.");
    }

    private void updateCacheForTypeAndDietary(Class<? extends Post> type, Long dietaryId) {
        String locale = "en";
        Instant now = Instant.now();
        String typeKey = type.getSimpleName().replace("Post", "").toLowerCase(); // daily, review, recipe
        String redisKey = (dietaryId == null) ? "feed:" + typeKey : "feed:" + typeKey + ":" + dietaryId;

        try {
            // 1. Sandwich Strategy를 위한 카테고리별 데이터 수집 (필터 적용)
            // 아래 메서드들은 Repository에 type과 dietaryId를 받도록 수정되었다고 가정함
            List<Long> popTrend = getIds(postRepository.findPopularAndTrendingWithType(locale, type, dietaryId, 100.0, now.minus(30, ChronoUnit.DAYS), Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 50)).getContent());
            List<Long> trendOnly = getIds(postRepository.findTrendingOnlyWithType(locale, type, dietaryId, 30.0, now.minus(7, ChronoUnit.DAYS), Long.MAX_VALUE, Double.MAX_VALUE, SAFE_MAX_DATE, PageRequest.of(0, 50)).getContent());
            List<Long> popOnly = getIds(postRepository.findPopularOnlyWithType(locale, type, dietaryId, Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 50)).getContent());
            List<Long> fresh = getIds(postRepository.findFreshWithType(locale, type, dietaryId, Long.MAX_VALUE, SAFE_MAX_DATE, PageRequest.of(0, 50)).getContent());
            List<Long> trendContro = getIds(postRepository.findTrendingAndControversialWithType(locale, type, dietaryId, 2.0, now.minus(7, ChronoUnit.DAYS), Long.MAX_VALUE, Integer.MAX_VALUE, PageRequest.of(0, 30)).getContent());
            List<Long> controOnly = getIds(postRepository.findControversialOnlyWithType(locale, type, dietaryId, Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 30)).getContent());

            // 2. Sandwich Strategy로 섞기
            List<Long> mixedIds = mixFeeds(popTrend, trendOnly, popOnly, fresh, trendContro, controOnly);

            // 3. Redis 갱신
            redisTemplate.delete(redisKey);
            if (!mixedIds.isEmpty()) {
                redisTemplate.opsForList().rightPushAll(redisKey, mixedIds.toArray());
            }
        } catch (Exception e) {
            log.error("Failed to update cache for {}: {}", redisKey, e.getMessage());
        }
    }

    private List<Long> getIds(List<Post> posts) {
        return posts.stream().map(Post::getId).toList();
    }

    private List<Long> mixFeeds(List<Long> q1, List<Long> q2, List<Long> q3, List<Long> q4, List<Long> q5, List<Long> q6) {
        List<Long> result = new ArrayList<>();
        Queue<Long> d1 = new LinkedList<>(q1); Queue<Long> d2 = new LinkedList<>(q2);
        Queue<Long> d3 = new LinkedList<>(q3); Queue<Long> d4 = new LinkedList<>(q4);
        Queue<Long> d5 = new LinkedList<>(q5); Queue<Long> d6 = new LinkedList<>(q6);

        while (result.size() < 200 && (!d1.isEmpty() || !d2.isEmpty() || !d3.isEmpty() || !d4.isEmpty())) {
            if (!d1.isEmpty()) result.add(d1.poll());
            if (!d2.isEmpty()) result.add(d2.poll());
            if (!d3.isEmpty()) result.add(d3.poll());
            if (!d4.isEmpty()) result.add(d4.poll());
            if (!d5.isEmpty()) result.add(d5.poll());
            if (!d6.isEmpty()) result.add(d6.poll());
            // 인기 비중 가중치
            if (!d1.isEmpty()) result.add(d1.poll());
            if (!d2.isEmpty()) result.add(d2.poll());
        }
        return result.stream().distinct().toList();
    }
}