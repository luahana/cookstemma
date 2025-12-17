package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.dto.post.PostUpdateRequestDto;
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
public class MyPostService {

    private final PostRepository postRepository;

    // [FR-160, FR-162] 내 포스트 목록 조회
    public CursorResponse<MyPostResponseDto> getMyPosts(Long userId, String cursor, int size) {
        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<Post> slice;

        if (cursor == null || cursor.isBlank()) {
            slice = postRepository.findMyPostsFirstPage(userId, pageRequest);
        } else {
            // 커서 디코딩 (형식: "yyyy-MM-ddTHH:mm:ss.SSSZ_postId")
            String[] parts = cursor.split("_");
            Instant cursorTime = Instant.parse(parts[0]);
            Long cursorId = Long.parseLong(parts[1]);

            slice = postRepository.findMyPostsWithCursor(userId, cursorTime, cursorId, pageRequest);
        }

        List<MyPostResponseDto> dtos = slice.getContent().stream()
                .map(post -> {
                    String nextCursor = post.getCreatedAt().toString() + "_" + post.getId();
                    return MyPostResponseDto.from(post, nextCursor);
                })
                .toList();

        String nextCursor = dtos.isEmpty() ? null : dtos.get(dtos.size() - 1).cursor();

        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }

    // [FR-161] 포스트 수정
    @Transactional
    public void updatePost(Long userId, Long postId, PostUpdateRequestDto requestDto) {
        Post post = getPostAndCheckOwner(userId, postId);

        // 더티 체킹(Dirty Checking)으로 업데이트
        if (requestDto.content() != null) {
            // (주의) Post 엔티티에 updateContent 메서드나 Setter 필요
            // 여기서는 임의로 가정하여 작성하거나 Reflection 등을 써야 함.
            // Post.java에 update 메서드를 추가하는 것이 가장 좋습니다.
            post.updateContent(requestDto.content());
        }

        if (requestDto.isPrivate() != null) {
            post.setPrivate(requestDto.isPrivate());
        }
    }

    // [FR-161] 포스트 삭제 (Soft Delete)
    @Transactional
    public void deletePost(Long userId, Long postId) {
        Post post = getPostAndCheckOwner(userId, postId);
        post.softDelete();
    }

    // 공통: 포스트 조회 및 소유권 확인
    private Post getPostAndCheckOwner(Long userId, Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found"));

        if (!post.getCreator().getId().equals(userId)) {
            throw new IllegalArgumentException("Unauthorized: Not the owner of this post");
        }

        if (post.isDeleted()) {
            throw new IllegalArgumentException("Post is already deleted");
        }

        return post;
    }
}