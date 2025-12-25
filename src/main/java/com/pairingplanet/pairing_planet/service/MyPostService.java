package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
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
    private final UserRepository userRepository; // [추가] UUID -> User 변환용

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    private static final Instant SAFE_MIN_DATE = Instant.parse("1970-01-01T00:00:00Z");
    // [FR-160, FR-162] 내 포스트 목록 조회
    public CursorResponse<MyPostResponseDto> getMyPosts(UUID userId, String cursor, int size) {
        // 1. UUID userId -> User Entity (내부 Long ID 사용을 위해)
        User user = userRepository.findByPublicId(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<Post> slice;

        if (cursor == null || cursor.isBlank()) {
            // 첫 페이지 조회 (User Entity의 ID를 사용하여 쿼리 최적화)
            slice = postRepository.findMyPostsFirstPage(user.getId(), pageRequest);
        } else {
            // 2. 커서 디코딩 (형식: "yyyy-MM-ddTHH:mm:ss.SSSZ_publicUUID")
            String[] parts = cursor.split("_");

            Instant cursorTime;
            try {
                cursorTime = Instant.parse(parts[0]);
                if (cursorTime.isBefore(SAFE_MIN_DATE)) {
                    cursorTime = SAFE_MIN_DATE; // 강제로 1970년으로 변경
                }
            } catch (Exception e) {
                cursorTime = SAFE_MIN_DATE; // 파싱 에러 시 안전값 사용
            }

            UUID cursorPublicId = UUID.fromString(parts[1]);

            Long cursorInternalId = postRepository.findByPublicId(cursorPublicId)
                    .map(Post::getId)
                    .orElse(0L);

            slice = postRepository.findMyPostsWithCursor(user.getId(), cursorTime, cursorInternalId, pageRequest);}

        List<MyPostResponseDto> dtos = slice.getContent().stream()
                .map(post -> {
                    // 다음 커서 생성: 보안을 위해 내부 ID 대신 publicId(UUID) 사용
                    String nextCursor = post.getCreatedAt().toString() + "_" + post.getPublicId();
                    return MyPostResponseDto.from(post, nextCursor, urlPrefix);
                })
                .toList();

        String nextCursor = dtos.isEmpty() ? null : dtos.get(dtos.size() - 1).cursor();

        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }

    // [삭제됨] updatePost, deletePost는 PostController/PostService로 통합되어 제거함.
}