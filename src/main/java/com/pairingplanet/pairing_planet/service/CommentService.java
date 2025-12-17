package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdict;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdictId;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentListResponseDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentResponseDto;
import com.pairingplanet.pairing_planet.repository.comment.CommentRepository;
import com.pairingplanet.pairing_planet.repository.verdict.PostVerdictRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final PostVerdictRepository verdictRepository; // Verdict 조회용

    // 댓글 작성
    @Transactional
    public void createComment(Long userId, CommentRequestDto request) {
        // 1. 유저의 현재 Verdict 조회 (없으면 예외 혹은 null 처리)
        // FR-64에 의해 Verdict 없이도 댓글은 쓸 수 있다면 null 허용 로직 필요
        // 여기선 Verdict가 있다고 가정 (혹은 NONE)
        PostVerdict postVerdict = verdictRepository.findById(new PostVerdictId(userId, request.postId()))
                .orElse(null);

        VerdictType currentType = (postVerdict != null) ? postVerdict.getVerdictType() : null;

        Comment comment = Comment.builder()
                .postId(request.postId())
                .userId(userId)
                .parentId(request.parentId()) // null이면 부모
                .content(request.content())
                .initialVerdict(currentType)  // 생성 당시
                .currentVerdict(currentType)  // 현재 (동일)
                .build();

        commentRepository.save(comment);
    }

    // Verdict 변경 시 호출되는 메서드 (Event Driven 권장)
    @Transactional
    public void onVerdictSwitched(Long userId, Long postId, VerdictType newType) {
        // FR-61-1: Verdict가 바뀌면 이전 댓글들의 테두리도 바뀜 -> DB 업데이트
        commentRepository.updateVerdictForUserPost(userId, postId, newType);
    }

    // 댓글 목록 조회 (Cursor Pagination + Best Comments)
    @Transactional(readOnly = true)
    public CommentListResponseDto getComments(Long userId, Long postId, VerdictType filterType, String cursor) {

        // 1. 배댓 가져오기 (FR-65)
        List<Comment> bestEntities;
        if (filterType == null) {
            bestEntities = commentRepository.findGlobalBestComments(postId);
        } else {
            bestEntities = commentRepository.findFilteredBestComments(postId, filterType);
        }

        // 2. 커서 파싱 (Base64 등 디코딩 필요, 여기선 단순화)
        // cursor가 null이면 가장 최신값(현재시간, MAX_ID) 설정
        Instant cursorTime = Instant.now();
        Long cursorId = Long.MAX_VALUE;

        if (cursor == null) {
            // 첫 페이지: 아주 먼 미래를 기준으로 잡아서 모든 최신 글이 포함되게 함
            cursorTime = Instant.parse("3000-01-01T00:00:00Z");
            cursorId = Long.MAX_VALUE;
        } else {
            cursorTime = Instant.now();
            cursorId = Long.MAX_VALUE;
        }

        // 3. 리스트 가져오기 (FR-66)
        int fetchSize = 10;
        List<Comment> listEntities;

        if (filterType == null) {
            listEntities = commentRepository.findAllByCursor(postId, cursorTime, cursorId, PageRequest.of(0, fetchSize));
        } else {
            listEntities = commentRepository.findFilteredByCursor(postId, filterType, cursorTime, cursorId, PageRequest.of(0, fetchSize));
        }

        // 4. DTO 변환 및 좋아요 여부 확인
        // (실무에선 batch size 설정으로 N+1 방지하거나 별도 좋아요 map 조회)
        List<CommentResponseDto> bestDtos = bestEntities.stream()
                .map(c -> CommentResponseDto.from(c, false)) // false: 좋아요 여부 로직 추가 필요
                .toList();

        List<CommentResponseDto> listDtos = listEntities.stream()
                .map(c -> CommentResponseDto.from(c, false))
                .toList();

        // 5. 다음 커서 생성
        String nextCursor = null;
        if (!listEntities.isEmpty()) {
            Comment last = listEntities.get(listEntities.size() - 1);
            // TODO: Encode (last.createdAt + last.id) to String
            nextCursor = "encoded_cursor_string";
        }

        return new CommentListResponseDto(bestDtos, listDtos, nextCursor, !listEntities.isEmpty());
    }
}