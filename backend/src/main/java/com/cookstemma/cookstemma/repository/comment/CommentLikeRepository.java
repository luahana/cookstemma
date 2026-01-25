package com.cookstemma.cookstemma.repository.comment;

import com.cookstemma.cookstemma.domain.entity.comment.CommentLike;
import com.cookstemma.cookstemma.domain.entity.comment.CommentLikeId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Set;

public interface CommentLikeRepository extends JpaRepository<CommentLike, CommentLikeId> {

    boolean existsByUserIdAndCommentId(Long userId, Long commentId);

    @Modifying
    @Query("DELETE FROM CommentLike cl WHERE cl.userId = :userId AND cl.commentId = :commentId")
    void deleteByUserIdAndCommentId(@Param("userId") Long userId, @Param("commentId") Long commentId);

    long countByCommentId(Long commentId);

    // Get liked comment IDs for a user from a list of comment IDs
    @Query("SELECT cl.commentId FROM CommentLike cl WHERE cl.userId = :userId AND cl.commentId IN :commentIds")
    Set<Long> findLikedCommentIdsByUserIdAndCommentIds(
        @Param("userId") Long userId,
        @Param("commentIds") List<Long> commentIds
    );
}
