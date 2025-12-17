package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdict;
import com.pairingplanet.pairing_planet.domain.entity.verdict.PostVerdictId;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentListResponseDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.repository.comment.CommentRepository;
import com.pairingplanet.pairing_planet.repository.verdict.PostVerdictRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class CommentServiceTest {

    @InjectMocks
    private CommentService commentService;

    @Mock
    private CommentRepository commentRepository;

    @Mock
    private PostVerdictRepository verdictRepository;

    @Test
    @DisplayName("댓글 작성 시 유저의 Verdict가 있다면 해당 상태가 저장되어야 한다")
    void createComment_withVerdict() {
        // given
        Long userId = 1L;
        Long postId = 100L;
        CommentRequestDto request = new CommentRequestDto(postId, null, "맛있어요");

        // 유저가 미리 GENIUS 판결을 내린 상태
        PostVerdict mockVerdict = PostVerdict.builder()
                .id(new PostVerdictId(userId, postId))
                .verdictType(VerdictType.GENIUS)
                .build();

        given(verdictRepository.findById(any())).willReturn(Optional.of(mockVerdict));

        // when
        commentService.createComment(userId, request);

        // then
        // Repository save 호출 시 verdict가 GENIUS로 세팅되었는지 캡쳐/검증
        verify(commentRepository).save(org.mockito.ArgumentMatchers.argThat(comment ->
                comment.getInitialVerdict() == VerdictType.GENIUS &&
                        comment.getCurrentVerdict() == VerdictType.GENIUS &&
                        comment.getContent().equals("맛있어요")
        ));
    }

    @Test
    @DisplayName("FR-65, FR-66: 목록 조회 시 배댓과 일반 리스트를 모두 반환한다 (중복 포함)")
    void getComments_returnsBestAndList() {
        // given
        Long postId = 1L;
        Comment bestComment = createMockComment(100L, 50, Instant.now()); // 배댓이면서
        Comment normalComment = createMockComment(101L, 1, Instant.now());

        // Mocking: 배댓 쿼리
        given(commentRepository.findGlobalBestComments(postId))
                .willReturn(List.of(bestComment)); // 배댓 1개 리턴

        // Mocking: 일반 리스트 쿼리 (여기서도 bestComment가 나올 수 있음 - 중복 시나리오)
        given(commentRepository.findAllByCursor(eq(postId), any(), any(), any(Pageable.class)))
                .willReturn(List.of(bestComment, normalComment));

        // when
        CommentListResponseDto response = commentService.getComments(1L, postId, null, null);

        // then
        assertThat(response.bestComments()).hasSize(1);
        assertThat(response.list()).hasSize(2); // 서버는 필터링하지 않고 다 줌

        // 배댓 DTO 확인
        assertThat(response.bestComments().get(0).likeCount()).isEqualTo(50);

        // 다음 커서 존재 여부
        assertThat(response.hasNext()).isTrue();
    }

    @Test
    @DisplayName("FR-61-1: Switched 여부(Boolean)가 DTO에 올바르게 매핑되는지 확인")
    void checkSwitchedFlagInDto() {
        // given
        // Initial = GENIUS, Current = DARING (바뀜)
        Comment switchedComment = Comment.builder()
                .initialVerdict(VerdictType.GENIUS)
                .currentVerdict(VerdictType.DARING)
                .build();

        given(commentRepository.findGlobalBestComments(any())).willReturn(Collections.emptyList());
        given(commentRepository.findAllByCursor(any(), any(), any(), any()))
                .willReturn(List.of(switchedComment));

        // when
        CommentListResponseDto response = commentService.getComments(1L, 1L, null, null);

        // then
        assertThat(response.list().get(0).isSwitched()).isTrue(); // true여야 함
    }

    private Comment createMockComment(Long id, int likeCount, Instant createdAt) {
        return Comment.builder()
                .userId(1L)
                .likeCount(likeCount)
                .content("test")
                .initialVerdict(VerdictType.GENIUS)
                .currentVerdict(VerdictType.GENIUS)
                .build();
    }
}