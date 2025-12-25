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
    public CursorResponse<SavedPostDto> getSavedPosts(UUID userPublicId, String cursor, int size) {
        // 1. 외부 UUID를 내부 Long ID로 변환 (성능 및 DB 참조 무결성)
        User user = userRepository.findByPublicId(userPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Long userId = user.getId();

        PageRequest pageRequest = PageRequest.of(0, size);
        Slice<SavedPost> slice;

        if (cursor == null || cursor.isBlank()) {
            slice = savedPostRepository.findAllByUserIdFirstPage(userId, pageRequest);
        } else {
            // 커서 포맷: "yyyy-MM-ddTHH:mm:ssZ_postPublicUUID" (보안상 UUID 사용)
            String[] parts = cursor.split("_");

            // 날짜 파싱 및 SAFE_MIN_DATE 보정 로직
            Instant cursorTime;
            try {
                cursorTime = Instant.parse(parts[0]);
                if (cursorTime.isBefore(SAFE_MIN_DATE)) {
                    cursorTime = SAFE_MIN_DATE;
                }
            } catch (Exception e) {
                cursorTime = SAFE_MIN_DATE;
            }

            // 2. 커서의 Post UUID를 내부 ID(Long)로 변환
            UUID postPublicId = UUID.fromString(parts[1]);
            Long internalPostId = postRepository.findByPublicId(postPublicId)
                    .map(Post::getId)
                    .orElse(0L);

            slice = savedPostRepository.findAllByUserIdWithCursor(userId, cursorTime, internalPostId, pageRequest);
        }

        // 3. DTO 변환 시 urlPrefix 주입
        List<SavedPostDto> dtos = slice.getContent().stream()
                .map(sp -> {
                    // 다음 페이지 요청을 위한 커서 생성 (Public UUID 사용)
                    String nextCursorItem = sp.getCreatedAt().toString() + "_" + sp.getPost().getPublicId();
                    return SavedPostDto.from(sp.getPost(), sp.getCreatedAt(), nextCursorItem, urlPrefix);
                })
                .toList();

        String nextCursor = dtos.isEmpty() ? null : dtos.get(dtos.size() - 1).cursor();

        return new CursorResponse<>(dtos, nextCursor, slice.hasNext());
    }
}