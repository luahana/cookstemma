package com.pairingplanet.pairing_planet.repository.comment;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    // 1. 배댓 조회 (필터 옵션이 있을 때와 없을 때)
    // 필터 없음: 전체 중 좋아요 Top 3
    @Query("SELECT c FROM Comment c WHERE c.postId = :postId AND c.parentId IS NULL AND c.isDeleted = false ORDER BY c.likeCount DESC LIMIT 3")
    List<Comment> findGlobalBestComments(@Param("postId") Long postId);

    // 필터 있음: 특정 Verdict 중 좋아요 Top 3
    @Query("SELECT c FROM Comment c WHERE c.postId = :postId AND c.parentId IS NULL AND c.currentVerdict = :verdict AND c.isDeleted = false ORDER BY c.likeCount DESC LIMIT 3")
    List<Comment> findFilteredBestComments(@Param("postId") Long postId, @Param("verdict") VerdictType verdict);


    // 2. 커서 기반 목록 조회 (일반 리스트)
    // 필터 없음
    @Query("""
        SELECT c FROM Comment c 
        WHERE c.postId = :postId 
          AND c.parentId IS NULL 
          AND (c.createdAt < :cursorTime OR (c.createdAt = :cursorTime AND c.id < :cursorId))
        ORDER BY c.createdAt DESC, c.id DESC
    """)
    List<Comment> findAllByCursor(
            @Param("postId") Long postId,
            @Param("cursorTime") Instant cursorTime,
            @Param("cursorId") Long cursorId,
            Pageable pageable);

    // 필터 있음
    @Query("""
        SELECT c FROM Comment c 
        WHERE c.postId = :postId 
          AND c.parentId IS NULL 
          AND c.currentVerdict = :verdict
          AND (c.createdAt < :cursorTime OR (c.createdAt = :cursorTime AND c.id < :cursorId))
        ORDER BY c.createdAt DESC, c.id DESC
    """)
    List<Comment> findFilteredByCursor(
            @Param("postId") Long postId,
            @Param("verdict") VerdictType verdict,
            @Param("cursorTime") Instant cursorTime,
            @Param("cursorId") Long cursorId,
            Pageable pageable);

    // 3. Verdict 변경 시 일괄 업데이트 (FR-52, FR-61-1)
    @Modifying
    @Query("UPDATE Comment c SET c.currentVerdict = :newVerdict WHERE c.postId = :postId AND c.userId = :userId")
    void updateVerdictForUserPost(@Param("userId") Long userId, @Param("postId") Long postId, @Param("newVerdict") VerdictType newVerdict);
}