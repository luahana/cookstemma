package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.post.ReviewPost;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdict;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdictId;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentListResponseDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentResponseDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.repository.comment.CommentRepository;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.repository.verdict.PostVerdictRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final PostVerdictRepository verdictRepository;
    private final UserRepository userRepository;
    private final PostRepository postRepository;

    @Value("${file.upload.url-prefix:http://localhost:9000/pairing-planet-local}")
    private String urlPrefix;

    private static final Instant SAFE_MIN_DATE = Instant.parse("1970-01-01T00:00:00Z");
    private static final Instant SAFE_MAX_DATE = Instant.parse("3000-01-01T00:00:00Z");

    /**
     * 댓글 작성 로직
     * 1. 대댓글은 1단계까지만 허용
     * 2. 리뷰 포스트만 유저의 Verdict 반영, 일상/레시피는 null 처리
     */
    @Transactional
    public void createComment(UUID userId, CommentRequestDto request) {
        User user = userRepository.findByPublicId(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Post post = postRepository.findByPublicId(request.postId())
                .orElseThrow(() -> new IllegalArgumentException("Post not found"));

        // [핵심] 포스트 타입에 따른 Verdict 결정
        VerdictType currentType = null;
        if (post instanceof ReviewPost) {
            // 리뷰 포스트인 경우에만 사용자의 투표(Verdict) 상태를 가져옴
            PostVerdict postVerdict = verdictRepository.findById(new PostVerdictId(user.getId(), post.getId()))
                    .orElse(null);
            currentType = (postVerdict != null) ? postVerdict.getVerdictType() : null;
        }

        // [핵심] 대댓글 깊이 제한 (1단계: 부모-자식까지만 가능)
        Long parentId = null;
        if (request.parentId() != null) {
            Comment parent = commentRepository.findByPublicId(request.parentId())
                    .orElseThrow(() -> new IllegalArgumentException("Parent comment not found"));

            // 부모 댓글이 이미 다른 댓글의 자식이라면(parentId가 존재하면) 에러
            if (parent.getParentId() != null) {
                throw new IllegalStateException("Only up to 1-level of nested comments are allowed.");
            }
            parentId = parent.getId();
        }

        Comment comment = Comment.builder()
                .postId(post.getId())
                .userId(user.getId())
                .parentId(parentId)
                .content(request.content())
                .initialVerdict(currentType)
                .currentVerdict(currentType)
                .build();

        commentRepository.save(comment);
    }

    /**
     * 댓글 목록 조회 로직
     * 1. 일상/레시피 포스트는 Verdict 필터 무시 (전체 조회)
     * 2. 커서 기반 페이징 처리
     */
    @Transactional(readOnly = true)
    public CommentListResponseDto getComments(UUID userId, UUID postId, VerdictType filterType, String cursor) {
        Post post = postRepository.findByPublicId(postId)
                .orElseThrow(() -> new IllegalArgumentException("Post not found"));
        Long internalPostId = post.getId();

        // 일상/레시피 포스트는 프론트에서 필터를 보내도 null로 강제 (일반 댓글 취급)
        if (!(post instanceof ReviewPost)) {
            filterType = null;
        }

        // 1. 배댓(Best Comments) 조회
        List<Comment> bestEntities = (filterType == null) ?
                commentRepository.findGlobalBestComments(internalPostId) :
                commentRepository.findFilteredBestComments(internalPostId, filterType);

        // 2. 커서 파싱 (Time_UUID 포맷)
        Instant cursorTime = SAFE_MAX_DATE;
        Long cursorInternalId = Long.MAX_VALUE;

        if (cursor != null) {
            String[] parts = cursor.split("_");
            try {
                cursorTime = Instant.parse(parts[0]);
                if (cursorTime.isBefore(SAFE_MIN_DATE)) cursorTime = SAFE_MIN_DATE;
            } catch (Exception e) {
                cursorTime = SAFE_MAX_DATE;
            }
            cursorInternalId = commentRepository.findByPublicId(UUID.fromString(parts[1]))
                    .map(Comment::getId).orElse(0L);
        }

        // 3. 일반 댓글 리스트 조회
        int fetchSize = 10;
        List<Comment> listEntities = (filterType == null) ?
                commentRepository.findAllByCursor(internalPostId, cursorTime, cursorInternalId, PageRequest.of(0, fetchSize)) :
                commentRepository.findFilteredByCursor(internalPostId, filterType, cursorTime, cursorInternalId, PageRequest.of(0, fetchSize));

        // 4. DTO 변환 (작성자 정보 연동 포함)
        List<CommentResponseDto> bestDtos = bestEntities.stream()
                .map(c -> convertToResponseDto(c, userId))
                .collect(Collectors.toList());

        List<CommentResponseDto> listDtos = listEntities.stream()
                .map(c -> convertToResponseDto(c, userId))
                .collect(Collectors.toList());

        // 5. 다음 커서 생성
        String nextCursor = null;
        if (!listEntities.isEmpty()) {
            Comment last = listEntities.get(listEntities.size() - 1);
            nextCursor = last.getCreatedAt().toString() + "_" + last.getPublicId();
        }

        return new CommentListResponseDto(bestDtos, listDtos, nextCursor, !listEntities.isEmpty());
    }

    private CommentResponseDto convertToResponseDto(Comment comment, UUID viewerId) {
        // 실제 작성자 정보 조회 (N+1 방지를 위해 추후 fetch join 쿼리로 개선 권장)
        User writer = userRepository.findById(comment.getUserId()).orElse(null);

        // 좋아요 여부 확인 (실제 로직 구현 필요, 여기서는 false 처리)
        boolean isLikedByMe = false;

        return CommentResponseDto.from(comment, writer, isLikedByMe, urlPrefix);
    }
}