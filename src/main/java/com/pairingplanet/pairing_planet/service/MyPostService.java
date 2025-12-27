package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.DailyPost;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.post.RecipePost;
import com.pairingplanet.pairing_planet.domain.entity.post.ReviewPost;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.CursorResponseTotalCount;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MyPostService {
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    public CursorResponseTotalCount<MyPostResponseDto> getMyPosts(UUID userId, String type, String cursor, int size) {
        User user = userRepository.findByPublicId(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 1. 문자열 타입을 엔티티 클래스로 매핑
        Class<? extends Post> entityType = getEntityType(type);
        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<Post> slice;

        // 2. 쿼리 실행 (기존 커서 파싱 로직 포함)
        if (cursor == null || cursor.isBlank()) {
            slice = postRepository.findMyPostsByTypeFirstPage(user.getId(), entityType, pageRequest);
        } else {
            String[] parts = cursor.split("_");
            Instant cursorTime = Instant.parse(parts[0]);
            UUID cursorPublicId = UUID.fromString(parts[1]);
            Long cursorInternalId = postRepository.findByPublicId(cursorPublicId).map(Post::getId).orElse(0L);

            slice = postRepository.findMyPostsByTypeWithCursor(user.getId(), entityType, cursorTime, cursorInternalId, pageRequest);
        }

        // 3. DTO 변환 및 결과 구성
        List<MyPostResponseDto> dtos = slice.getContent().stream()
                .map(post -> {
                    String nextCursor = post.getCreatedAt().toString() + "_" + post.getPublicId();
                    return MyPostResponseDto.from(post, nextCursor, urlPrefix);
                }).toList();

        long totalCount = postRepository.countMyPostsByType(user.getId(), entityType);
        String nextCursor = slice.hasNext() ? dtos.get(dtos.size() - 1).cursor() : null;

        return new CursorResponseTotalCount<>(dtos, nextCursor, totalCount); // totalCount 포함 구조
    }

    private Class<? extends Post> getEntityType(String type) {
        if (type == null) return null;
        return switch (type.toUpperCase()) {
            case "DAILY" -> DailyPost.class;
            case "REVIEW" -> ReviewPost.class;
            case "RECIPE" -> RecipePost.class;
            default -> null; // ALL
        };
    }
}