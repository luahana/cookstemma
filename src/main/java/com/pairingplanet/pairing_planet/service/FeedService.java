package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.dto.feed.FeedResponseDto;
import com.pairingplanet.pairing_planet.dto.post.PostDto;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FeedService {

    private final PostRepository postRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    private static final String GLOBAL_FEED_KEY = "feed:global:mixed";
    private static final int PAGE_SIZE = 10;
    private static final long HISTORY_TTL_DAYS = 1;

    public FeedResponseDto getMixedFeed(Long userId, int offset) {
        String historyKey = "user:" + userId + ":seen";
        List<PostDto> finalPosts = new ArrayList<>();

        int currentOffset = offset;
        // 충분한 개수(10개)를 채울 때까지 Redis에서 계속 가져옴 (최대 시도 횟수 제한 필요)
        int attempts = 0;

        while (finalPosts.size() < PAGE_SIZE && attempts < 5) {
            // 1. Redis에서 후보군 ID 가져오기 (Offset ~ Offset + 20)
            // 이미 본 걸 거를 확률을 고려해 넉넉하게 2배수 조회
            List<Object> rawIds = redisTemplate.opsForList().range(GLOBAL_FEED_KEY, currentOffset, currentOffset + (PAGE_SIZE * 2));

            if (rawIds == null || rawIds.isEmpty()) break;

            List<Long> candidateIds = rawIds.stream()
                    .map(obj -> Long.valueOf(obj.toString()))
                    .collect(Collectors.toList());

            // 2. 중복 필터링 (User History Check)
            List<Long> newIds = new ArrayList<>();
            for (Long id : candidateIds) {
                // SISMEMBER 명령: O(1)
                Boolean seen = redisTemplate.opsForSet().isMember(historyKey, id.toString());
                if (Boolean.FALSE.equals(seen)) {
                    newIds.add(id);
                }
            }

            // 3. 실제 Post 데이터 조회
            if (!newIds.isEmpty()) {
                // 필요한 만큼만 자르기
                int needed = PAGE_SIZE - finalPosts.size();
                List<Long> idsToFetch = newIds.stream().limit(needed).toList();

                // DB 조회 (id IN (...))
                List<Post> posts = postRepository.findAllById(idsToFetch);

                // 중요: DB 조회 결과는 ID 순서를 보장하지 않으므로, 원래 Redis 순서대로 재정렬
                Map<Long, Post> postMap = posts.stream()
                        .filter(p -> !p.isDeleted())
                        .filter(p -> !p.isPrivate())
                        .collect(Collectors.toMap(Post::getId, p -> p));

                for (Long id : idsToFetch) {
                    if (postMap.containsKey(id)) {
                        finalPosts.add(PostDto.from(postMap.get(id), "🔥 Trending"));
                    }
                }

                // 4. 본 목록(History) 업데이트
                Object[] seenIdStrings = idsToFetch.stream().map(String::valueOf).toArray(String[]::new);
                if (seenIdStrings.length > 0) {
                    redisTemplate.opsForSet().add(historyKey, seenIdStrings);
                    redisTemplate.expire(historyKey, HISTORY_TTL_DAYS, TimeUnit.DAYS);
                }
            }

            // 다음 루프를 위해 오프셋 증가
            currentOffset += rawIds.size();
            attempts++;
        }

        boolean hasNext = finalPosts.size() == PAGE_SIZE;

        return FeedResponseDto.builder()
                .posts(finalPosts)
                .nextCursor(String.valueOf(currentOffset)) // 이제 커서는 단순 정수(String형태)
                .hasNext(hasNext)
                .build();
    }
}