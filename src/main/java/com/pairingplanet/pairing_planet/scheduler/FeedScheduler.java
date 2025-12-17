package com.pairingplanet.pairing_planet.scheduler;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
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
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class FeedScheduler {

    private final PostRepository postRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    // Redis Key
    private static final String GLOBAL_FEED_KEY = "feed:global:mixed";

    // 5분마다 실행 (300,000ms)
    @Scheduled(fixedRate = 300000)
    public void updateGlobalFeedCache() {
        log.info("Starting Global Feed Update...");
        String locale = "en"; // 글로벌 서비스라면 로케일별로 Key를 분리해야 함 (ex: feed:en:mixed)
        Instant now = Instant.now();

        // 1. 각 카테고리별 상위 게시물 DB 조회 (기존 Repository 활용)
        // 넉넉하게 100~200개씩 가져옴
        List<Long> popTrend = getIds(postRepository.findPopularAndTrending(locale, 100.0, now.minus(30, ChronoUnit.DAYS), Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 100)).getContent());
        List<Long> trendOnly = getIds(postRepository.findTrendingOnly(locale, 30.0, now.minus(7, ChronoUnit.DAYS), Long.MAX_VALUE, Double.MAX_VALUE, Instant.MAX, PageRequest.of(0, 100)).getContent());
        List<Long> popOnly = getIds(postRepository.findPopularOnly(locale, Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 100)).getContent());
        List<Long> fresh = getIds(postRepository.findFresh(locale, Long.MAX_VALUE, Instant.MAX, PageRequest.of(0, 100)).getContent());
        List<Long> trendContro = getIds(postRepository.findTrendingAndControversial(locale, 2.0, now.minus(7, ChronoUnit.DAYS), Long.MAX_VALUE, Integer.MAX_VALUE, PageRequest.of(0, 50)).getContent());
        List<Long> controOnly = getIds(postRepository.findControversialOnly(locale, Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 50)).getContent());

        // 2. Sandwich Strategy로 섞기 (메모리 상에서 수행)
        List<Long> mixedFeed = mixFeeds(popTrend, trendOnly, popOnly, fresh, trendContro, controOnly);

        // 3. Redis에 덮어쓰기
        // 기존 키 삭제 후 전체 푸시 (트랜잭션 or rename 사용 권장되나 간단하게 구현)
        redisTemplate.delete(GLOBAL_FEED_KEY);
        if (!mixedFeed.isEmpty()) {
            redisTemplate.opsForList().rightPushAll(GLOBAL_FEED_KEY, mixedFeed.toArray());
        }

        log.info("Global Feed Updated. Total count: {}", mixedFeed.size());
    }

    private List<Long> getIds(List<Post> posts) {
        return posts.stream().map(Post::getId).toList();
    }

    // 간단한 라운드 로빈 + 비율 섞기
    private List<Long> mixFeeds(List<Long> q1, List<Long> q2, List<Long> q3, List<Long> q4, List<Long> q5, List<Long> q6) {
        List<Long> result = new ArrayList<>();
        Queue<Long> d1 = new LinkedList<>(q1);
        Queue<Long> d2 = new LinkedList<>(q2);
        Queue<Long> d3 = new LinkedList<>(q3);
        Queue<Long> d4 = new LinkedList<>(q4);
        Queue<Long> d5 = new LinkedList<>(q5);
        Queue<Long> d6 = new LinkedList<>(q6);

        // 최대 500개까지만 생성
        while (result.size() < 500 && (!d1.isEmpty() || !d2.isEmpty() || !d3.isEmpty())) {
            // 비율: 1, 2, 3, 4, 5, 6, 1, 2, 4, 3 순서 등 원하는 패턴 적용
            if (!d1.isEmpty()) result.add(d1.poll()); // PopTrend
            if (!d2.isEmpty()) result.add(d2.poll()); // TrendOnly
            if (!d3.isEmpty()) result.add(d3.poll()); // PopOnly
            if (!d4.isEmpty()) result.add(d4.poll()); // Fresh
            if (!d5.isEmpty()) result.add(d5.poll()); // TrendContro
            if (!d6.isEmpty()) result.add(d6.poll()); // ControOnly

            // 인기/트렌드 비중 높이기 위해 한번 더
            if (!d1.isEmpty()) result.add(d1.poll());
            if (!d2.isEmpty()) result.add(d2.poll());
        }
        // 중복 제거 (혹시 모를 상황 대비)
        return result.stream().distinct().toList();
    }
}