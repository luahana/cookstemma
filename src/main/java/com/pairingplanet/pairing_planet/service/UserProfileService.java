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

import static com.pairingplanet.pairing_planet.dto.search.SearchCursorDto.SAFE_MIN_DATE;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserProfileService {

    private final PostRepository postRepository;
    private final UserRepository userRepository; // [추가] UUID -> User 변환용

    @Value("${file.upload.url-prefix}") // [추가]
    private String urlPrefix;

    public CursorResponse<MyPostResponseDto> getOtherUserPosts(UUID targetUserId, String cursor, int size) {
        // 1. UUID -> User Entity (내부 Long ID 획득)
        User targetUser = userRepository.findByPublicId(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<Post> slice;

        if (cursor == null || cursor.isBlank()) {
            // Long ID 사용 (targetUser.getId())
            slice = postRepository.findPublicPostsByCreatorFirstPage(targetUser.getId(), pageRequest);
        } else {
            // 커서 디코딩 (UUID -> Long 변환 포함)
            String[] parts = cursor.split("_");
            Instant cursorTime;
            try {
                cursorTime = Instant.parse(parts[0]);
                if (cursorTime.isBefore(SAFE_MIN_DATE)) {
                    cursorTime = SAFE_MIN_DATE; // 기원전 날짜면 1970년으로 강제 변경
                }
            } catch (Exception e) {
                cursorTime = SAFE_MIN_DATE;
            }
            UUID cursorPublicId = UUID.fromString(parts[1]);

            // 커서의 UUID로 내부 Long ID 조회 (최적화)
            Long cursorInternalId = postRepository.findByPublicId(cursorPublicId)
                    .map(Post::getId)
                    .orElse(0L);

            slice = postRepository.findPublicPostsByCreatorWithCursor(targetUser.getId(), cursorTime, cursorInternalId, pageRequest);
        }

        List<MyPostResponseDto> dtos = slice.getContent().stream()
                .map(post -> {
                    String nextCursor = post.getCreatedAt().toString() + "_" + post.getPublicId();
                    // [수정] urlPrefix 파라미터 추가
                    return MyPostResponseDto.from(post, nextCursor, urlPrefix);
                })
                .toList();

        String nextCursor = dtos.isEmpty() ? null : dtos.get(dtos.size() - 1).cursor();

        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }
}