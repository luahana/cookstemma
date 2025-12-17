package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto; // DTO 재사용 (구조가 같다면)
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserProfileService {

    private final PostRepository postRepository;

    public CursorResponse<MyPostResponseDto> getOtherUserPosts(Long targetUserId, String cursor, int size) {
        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<Post> slice;

        // Repository 호출 시 'findPublicPosts...' 메서드 사용
        if (cursor == null || cursor.isBlank()) {
            slice = postRepository.findPublicPostsByCreatorFirstPage(targetUserId, pageRequest);
        } else {
            String[] parts = cursor.split("_");
            Instant cursorTime = Instant.parse(parts[0]);
            Long cursorId = Long.parseLong(parts[1]);

            slice = postRepository.findPublicPostsByCreatorWithCursor(targetUserId, cursorTime, cursorId, pageRequest);
        }

        List<MyPostResponseDto> dtos = slice.getContent().stream()
                .map(post -> {
                    String nextCursor = post.getCreatedAt().toString() + "_" + post.getId();
                    // isPrivate 필드는 무조건 false일 수밖에 없지만, DTO 스펙상 넣어줍니다.
                    return MyPostResponseDto.from(post, nextCursor);
                })
                .toList();

        String nextCursor = dtos.isEmpty() ? null : dtos.get(dtos.size() - 1).cursor();

        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }
}