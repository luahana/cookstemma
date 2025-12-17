package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.dto.feed.FeedResponseDto;
import com.pairingplanet.pairing_planet.dto.post.PostDto;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.ListOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.SetOperations;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FeedServiceTest {

    @InjectMocks
    private FeedService feedService;

    @Mock
    private PostRepository postRepository;

    @Mock
    private RedisTemplate<String, Object> redisTemplate;

    @Mock
    private ListOperations<String, Object> listOps;

    @Mock
    private SetOperations<String, Object> setOps;

    @BeforeEach
    void setUp() {
        // Mock Redis Operations
        lenient().when(redisTemplate.opsForList()).thenReturn(listOps);
        lenient().when(redisTemplate.opsForSet()).thenReturn(setOps);
    }

    @Test
    @DisplayName("getMixedFeed: Redis에서 가져온 ID 목록으로 DB를 조회하고 피드를 반환해야 한다")
    void getMixedFeed_basicFlow() {
        // given
        Long userId = 100L;
        int offset = 10;
        String globalKey = "feed:global:mixed";
        String historyKey = "user:100:seen";

        // Redis: 첫 호출 [10, 11, 12], 두 번째 빈 리스트
        List<Object> cachedIds = List.of("10", "11", "12");
        given(listOps.range(eq(globalKey), anyLong(), anyLong()))
                .willReturn(cachedIds)
                .willReturn(Collections.emptyList());

        // Mock: ID 11 is SEEN
        given(setOps.isMember(historyKey, "10")).willReturn(false);
        given(setOps.isMember(historyKey, "11")).willReturn(true); // 봤음
        given(setOps.isMember(historyKey, "12")).willReturn(false);

        // DB Fetch: [10, 12]만 요청됨
        Post p10 = createPost(10L);
        Post p12 = createPost(12L);

        // List 형변환 후 contains 체크
        given(postRepository.findAllById(argThat(iterable -> {
            List<Long> list = (List<Long>) iterable;
            return list.contains(10L) && list.contains(12L) && !list.contains(11L);
        }))).willReturn(List.of(p10, p12));

        // when
        FeedResponseDto response = feedService.getMixedFeed(userId, offset);

        // then
        assertThat(response.posts()).hasSize(2);
        assertThat(response.posts()).extracting(PostDto::id).containsExactly(10L, 12L);

        // Cursor는 Redis에서 읽은 만큼(3개) 증가해야 함
        assertThat(response.nextCursor()).isEqualTo(String.valueOf(offset + 3));
    }

    @Test
    @DisplayName("getMixedFeed: 이미 본(Seen) 포스트는 필터링되어야 한다")
    void getMixedFeed_filterSeen() {
        // given
        Long userId = 100L;
        int offset = 10;
        String globalKey = "feed:global:mixed";
        String historyKey = "user:100:seen";

        // Redis: 첫 호출 [10, 11, 12], 두 번째 빈 리스트
        List<Object> cachedIds = List.of("10", "11", "12");
        given(listOps.range(eq(globalKey), anyLong(), anyLong()))
                .willReturn(cachedIds)
                .willReturn(Collections.emptyList());

        // Mock: ID 11 is SEEN
        given(setOps.isMember(historyKey, "10")).willReturn(false);
        given(setOps.isMember(historyKey, "11")).willReturn(true); // 봤음
        given(setOps.isMember(historyKey, "12")).willReturn(false);

        // DB Fetch: [10, 12]만 요청됨
        Post p10 = createPost(10L);
        Post p12 = createPost(12L);

        // List 형변환 후 contains 체크
        given(postRepository.findAllById(argThat(iterable -> {
            List<Long> list = (List<Long>) iterable;
            return list.contains(10L) && list.contains(12L) && !list.contains(11L);
        }))).willReturn(List.of(p10, p12));

        // when
        FeedResponseDto response = feedService.getMixedFeed(userId, offset);

        // then
        assertThat(response.posts()).hasSize(2);
        assertThat(response.posts()).extracting(PostDto::id).containsExactly(10L, 12L);

        // Cursor는 Redis에서 읽은 만큼(3개) 증가해야 함
        assertThat(response.nextCursor()).isEqualTo(String.valueOf(offset + 3));
    }

    @Test
    @DisplayName("getMixedFeed: Redis 리스트가 비어있으면 빈 결과를 반환하고 hasNext는 false여야 한다")
    void getMixedFeed_empty() {
        // given
        Long userId = 100L;
        int offset = 500;
        String globalKey = "feed:global:mixed";

        // Redis returns empty list or null
        given(listOps.range(eq(globalKey), anyLong(), anyLong())).willReturn(Collections.emptyList());

        // when
        FeedResponseDto response = feedService.getMixedFeed(userId, offset);

        // then
        assertThat(response.posts()).isEmpty();
        assertThat(response.hasNext()).isFalse();
        verify(postRepository, never()).findAllById(anyList());
    }

    // --- Helpers ---

    private Post createPost(Long id) {
        Post post = Post.builder()
                .content("Content " + id)
                .popularityScore(0.0)
                .controversyScore(0.0)
                .commentCount(0)
                .savedCount(0)
                .locale("en")
                .imageUrls(Collections.emptyList())
                .build();

        ReflectionTestUtils.setField(post, "id", id);
        return post;
    }
}