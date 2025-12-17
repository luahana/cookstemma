package com.pairingplanet.pairing_planet.repository.comment;

import com.pairingplanet.pairing_planet.domain.entity.common.CommentLike;
import org.springframework.data.jpa.repository.JpaRepository;


public interface CommentLikeRepository extends JpaRepository<CommentLike, CommentLike.CommentLikeId> {
    // 특정 댓글에 좋아요 눌렀는지 확인 (토글용)
    boolean existsByUserIdAndCommentId(Long userId, Long commentId);
}