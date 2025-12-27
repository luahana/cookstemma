package com.pairingplanet.pairing_planet.repository.post;

import com.pairingplanet.pairing_planet.domain.entity.post.SavedPost;
import com.pairingplanet.pairing_planet.domain.entity.post.SavedPost.SavedPostId;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.time.LocalDateTime;

public interface SavedPostRepository extends JpaRepository<SavedPost, SavedPostId> {

    // FR-91: 커서 기반 조회 (저장한 순서 = 최신순)
    // 인덱스: (user_id, created_at DESC) 필요

    // 첫 페이지 조회 (커서 없음)
    @Query("SELECT sp FROM SavedPost sp " +
            "JOIN FETCH sp.post p " +
            "JOIN FETCH p.pairing pm " +
            "WHERE sp.user.id = :userId " +
            "ORDER BY sp.createdAt DESC, sp.post.id DESC")
    Slice<SavedPost> findAllByUserIdFirstPage(@Param("userId") Long userId, Pageable pageable);

    // 두 번째 페이지부터 (커서 있음)
    // (createdAt < cursorTime) OR (createdAt = cursorTime AND postId < cursorId)
    @Query("SELECT sp FROM SavedPost sp " +
            "JOIN FETCH sp.post p " +
            "JOIN FETCH p.pairing pm " +
            "WHERE sp.user.id = :userId " +
            "AND (sp.createdAt < :cursorTime OR (sp.createdAt = :cursorTime AND sp.post.id < :cursorPostId)) " +
            "ORDER BY sp.createdAt DESC, sp.post.id DESC")
    Slice<SavedPost> findAllByUserIdWithCursor(@Param("userId") Long userId,
                                               @Param("cursorTime") Instant cursorTime,
                                               @Param("cursorPostId") Long cursorPostId,
                                               Pageable pageable);

    long countByUserId(Long userId);

    boolean existsById(SavedPostId id);
}