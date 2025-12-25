package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.feed.FeedResponseDto;
import com.pairingplanet.pairing_planet.dto.post.PostDto;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FeedService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    private static final String GLOBAL_FEED_KEY = "feed:global:mixed";
    private static final int PAGE_SIZE = 10;
    private static final long HISTORY_TTL_DAYS = 1;

    @Value("${file.upload.url-prefix:http://localhost:9000/pairing-planet-local}")
    private String urlPrefix;

    public FeedResponseDto getMixedFeed(UUID userId, int offset) {
        try {
            // Redis가 정상일 때 시도하는 로직
            return getFeedFromRedis(userId, offset);
        } catch (Exception e) {
            // [핵심] Redis 연결 실패, 타임아웃 등 모든 에러를 잡아서 DB로 돌림
            log.error("Redis connection failed. Switching to DB Fallback. Error: {}", e.getMessage());
            return getFeedFallback(offset);
        }
    }

    // --- 1. Redis 기반 피드 로직 (기존 코드 분리) ---
    private FeedResponseDto getFeedFromRedis(UUID userId, int offset) {
        Long internalUserId = null;
        if (userId != null) {
            internalUserId = userRepository.findByPublicId(userId)
                    .map(User::getId)
                    .orElse(null);
        }

        String historyKey = (internalUserId != null) ? "user:" + internalUserId + ":seen" : "user:anon:seen";
        List<PostDto> finalPosts = new ArrayList<>();
        int currentOffset = offset;
        int attempts = 0;

        while (finalPosts.size() < PAGE_SIZE && attempts < 5) {
            // Redis 호출 (여기서 에러나면 상위 catch로 이동)
            List<Object> rawIds = redisTemplate.opsForList().range(GLOBAL_FEED_KEY, currentOffset, currentOffset + (PAGE_SIZE * 2));

            if (rawIds == null || rawIds.isEmpty()) break;

            List<Long> candidateIds = rawIds.stream()
                    .map(obj -> Long.valueOf(obj.toString()))
                    .collect(Collectors.toList());

            // 중복 필터링
            List<Long> newIds = new ArrayList<>();
            for (Long id : candidateIds) {
                Boolean seen = redisTemplate.opsForSet().isMember(historyKey, id.toString());
                if (Boolean.FALSE.equals(seen)) {
                    newIds.add(id);
                }
            }

            if (!newIds.isEmpty()) {
                int needed = PAGE_SIZE - finalPosts.size();
                List<Long> idsToFetch = newIds.stream().limit(needed).toList();
                List<Post> posts = postRepository.findAllById(idsToFetch);

                // 순서 보장을 위해 Map 변환
                Map<Long, Post> postMap = posts.stream()
                        .filter(p -> !p.isDeleted() && !p.isPrivate())
                        .collect(Collectors.toMap(Post::getId, p -> p));

                for (Long id : idsToFetch) {
                    if (postMap.containsKey(id)) {
                        finalPosts.add(PostDto.from(postMap.get(id), "🔥 Trending", urlPrefix));
                    }
                }

                // History 업데이트 (Redis 호출)
                Object[] seenIdStrings = idsToFetch.stream().map(String::valueOf).toArray(String[]::new);
                if (seenIdStrings.length > 0) {
                    redisTemplate.opsForSet().add(historyKey, seenIdStrings);
                    redisTemplate.expire(historyKey, HISTORY_TTL_DAYS, TimeUnit.DAYS);
                }
            }
            currentOffset += rawIds.size();
            attempts++;
        }

        boolean hasNext = finalPosts.size() == PAGE_SIZE;
        return FeedResponseDto.builder()
                .posts(finalPosts)
                .nextCursor(String.valueOf(currentOffset))
                .hasNext(hasNext)
                .build();
    }

    // --- 2. DB 기반 Fallback 로직 (Redis 장애 시) ---
    private FeedResponseDto getFeedFallback(int offset) {
        // Offset을 Page 번호로 변환 (간단 계산)
        int pageNumber = offset / PAGE_SIZE;

        // DB에서 최신순 조회
        List<Post> posts = postRepository.findAllFallback(PageRequest.of(pageNumber, PAGE_SIZE));

        List<PostDto> postDtos = posts.stream()
                .map(p -> PostDto.from(p, "✨ Latest", urlPrefix)) // 태그를 다르게 주어 구분 가능
                .toList();

        boolean hasNext = postDtos.size() == PAGE_SIZE;
        int nextOffset = offset + postDtos.size(); // 다음 오프셋 계산

        return FeedResponseDto.builder()
                .posts(postDtos)
                .nextCursor(String.valueOf(nextOffset))
                .hasNext(hasNext)
                .build();
    }
}