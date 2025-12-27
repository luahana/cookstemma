package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.post.SavedPost;
import com.pairingplanet.pairing_planet.domain.entity.post.SavedPost.SavedPostId;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.CursorResponseTotalCount;
import com.pairingplanet.pairing_planet.dto.post.SavedPostDto;
import com.pairingplanet.pairing_planet.repository.post.SavedPostRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static com.pairingplanet.pairing_planet.dto.search.SearchCursorDto.SAFE_MIN_DATE;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SavedPostService {

    private final SavedPostRepository savedPostRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    // FR-90: 저장 토글 (Save / Unsave)
    @Transactional
    public boolean toggleSave(UUID userPublicId, UUID postPublicId) {
        User user = userRepository.findByPublicId(userPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Post post = postRepository.findByPublicId(postPublicId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found"));

        SavedPostId id = new SavedPostId(user.getId(), post.getId());

        if (savedPostRepository.existsById(id)) {
            savedPostRepository.deleteById(id);
            return false;
        } else {
            if (post.isDeleted()) throw new IllegalStateException("Cannot save a deleted post");
            savedPostRepository.save(new SavedPost(user, post));
            return true;
        }
    }

    // FR-90, FR-91: 저장 목록 조회 (Ghost Card + Cursor Pagination)
    public CursorResponseTotalCount<SavedPostDto> getSavedPosts(UUID userPublicId, String cursor, int size) {
        User user = userRepository.findByPublicId(userPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Long userId = user.getId();

        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<SavedPost> slice;

        // 1. 페이징 조회 로직 (기존과 동일)
        if (cursor == null || cursor.isBlank()) {
            slice = savedPostRepository.findAllByUserIdFirstPage(userId, pageRequest);
        } else {
            String[] parts = cursor.split("_");
            Instant cursorTime = Instant.parse(parts[0]);
            UUID postPublicId = UUID.fromString(parts[1]);
            Long internalPostId = postRepository.findByPublicId(postPublicId).map(Post::getId).orElse(0L);
            slice = savedPostRepository.findAllByUserIdWithCursor(userId, cursorTime, internalPostId, pageRequest);
        }

        // 2. DTO 변환
        List<SavedPostDto> dtos = slice.getContent().stream()
                .map(sp -> {
                    String nextCursorItem = sp.getCreatedAt().toString() + "_" + sp.getPost().getPublicId();
                    return SavedPostDto.from(sp.getPost(), sp.getCreatedAt(), nextCursorItem, urlPrefix);
                })
                .toList();

        // 3. 전체 개수 조회 (요구사항 반영)
        long totalCount = savedPostRepository.countByUserId(userId);
        String nextCursor = slice.hasNext() && !dtos.isEmpty() ? dtos.get(dtos.size() - 1).cursor() : null;

        // CursorResponse 구조: { data: [...], nextCursor: "...", totalCount: ... }
        return new CursorResponseTotalCount<>(dtos, nextCursor, totalCount);
    }
}