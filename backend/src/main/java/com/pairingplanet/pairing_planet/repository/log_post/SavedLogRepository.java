package com.pairingplanet.pairing_planet.repository.log_post;

import com.pairingplanet.pairing_planet.domain.entity.log_post.SavedLog;
import com.pairingplanet.pairing_planet.domain.entity.log_post.SavedLogId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;

public interface SavedLogRepository extends JpaRepository<SavedLog, SavedLogId> {

    boolean existsByUserIdAndLogPostId(Long userId, Long logPostId);

    @Modifying
    @Query("DELETE FROM SavedLog sl WHERE sl.userId = :userId AND sl.logPostId = :logPostId")
    void deleteByUserIdAndLogPostId(@Param("userId") Long userId, @Param("logPostId") Long logPostId);

    @Query("SELECT sl FROM SavedLog sl JOIN FETCH sl.logPost lp WHERE sl.userId = :userId AND lp.deletedAt IS NULL ORDER BY sl.createdAt DESC")
    Slice<SavedLog> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);

    long countByLogPostId(Long logPostId);

    long countByUserId(Long userId);

    // ==================== CURSOR-BASED PAGINATION ====================

    // [Cursor] Saved logs - initial page
    @Query("SELECT sl FROM SavedLog sl JOIN FETCH sl.logPost lp WHERE sl.userId = :userId AND lp.deletedAt IS NULL ORDER BY sl.createdAt DESC, sl.logPostId DESC")
    Slice<SavedLog> findSavedLogsWithCursorInitial(@Param("userId") Long userId, Pageable pageable);

    // [Cursor] Saved logs - with cursor
    @Query("SELECT sl FROM SavedLog sl JOIN FETCH sl.logPost lp WHERE sl.userId = :userId AND lp.deletedAt IS NULL " +
           "AND (sl.createdAt < :cursorTime OR (sl.createdAt = :cursorTime AND sl.logPostId < :cursorId)) " +
           "ORDER BY sl.createdAt DESC, sl.logPostId DESC")
    Slice<SavedLog> findSavedLogsWithCursor(@Param("userId") Long userId, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // ==================== OFFSET-BASED PAGINATION (for Web) ====================

    // [Offset] Saved logs - page
    @Query("SELECT sl FROM SavedLog sl JOIN FETCH sl.logPost lp WHERE sl.userId = :userId AND lp.deletedAt IS NULL")
    Page<SavedLog> findSavedLogsPage(@Param("userId") Long userId, Pageable pageable);
}
