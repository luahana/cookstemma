package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.SavedPost;
import com.pairingplanet.pairing_planet.domain.entity.post.SavedPost.SavedPostId;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.SavedPostDto;
import com.pairingplanet.pairing_planet.repository.post.SavedPostRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SavedPostService {

    private final SavedPostRepository savedPostRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    // FR-90: 저장 토글 (Save / Unsave)
    @Transactional
    public boolean toggleSave(Long userId, Long postId) {
        SavedPostId id = new SavedPostId(userId, postId);

        if (savedPostRepository.existsById(id)) {
            savedPostRepository.deleteById(id);
            return false; // 저장 취소됨
        } else {
            User user = userRepository.getReferenceById(userId);
            Post post = postRepository.findById(postId)
                    .orElseThrow(() -> new IllegalArgumentException("Post not found"));

            // 삭제된 포스트는 새로 저장 불가
            if (post.isDeleted()) {
                throw new IllegalStateException("Cannot save a deleted post");
            }

            savedPostRepository.save(new SavedPost(user, post));
            return true; // 저장됨
        }
    }

    // FR-90, FR-91: 저장 목록 조회 (Ghost Card + Cursor Pagination)
    public CursorResponse<SavedPostDto> getSavedPosts(Long userId, String cursor, int size) {
        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<SavedPost> slice;

        if (cursor == null || cursor.isBlank()) {
            slice = savedPostRepository.findAllByUserIdFirstPage(userId, pageRequest);
        } else {
            // 커서 포맷: "yyyy-MM-dd'T'HH:mm:ss.SSSSSS_postId"
            String[] parts = cursor.split("_");
            LocalDateTime cursorTime = LocalDateTime.parse(parts[0]);
            Long cursorPostId = Long.parseLong(parts[1]);

            slice = savedPostRepository.findAllByUserIdWithCursor(userId, cursorTime, cursorPostId, pageRequest);
        }

        List<SavedPostDto> dtos = slice.getContent().stream()
                .map(sp -> {
                    // 다음 커서 생성
                    String nextCursorItem = sp.getCreatedAt().toString() + "_" + sp.getPost().getId();
                    return SavedPostDto.from(sp.getPost(), sp.getCreatedAt(), nextCursorItem);
                })
                .toList();

        // 마지막 아이템의 커서를 nextCursor로 설정
        String nextCursor = null;
        if (!dtos.isEmpty()) {
            nextCursor = dtos.get(dtos.size() - 1).cursor();
        }

        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }
}