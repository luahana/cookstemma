package com.pairingplanet.pairing_planet.repository.log_post;

import com.pairingplanet.pairing_planet.domain.entity.log_post.SavedLog;
import com.pairingplanet.pairing_planet.domain.entity.log_post.SavedLogId;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SavedLogRepository extends JpaRepository<SavedLog, SavedLogId> {

    boolean existsByUserIdAndLogPostId(Long userId, Long logPostId);

    @Modifying
    @Query("DELETE FROM SavedLog sl WHERE sl.userId = :userId AND sl.logPostId = :logPostId")
    void deleteByUserIdAndLogPostId(@Param("userId") Long userId, @Param("logPostId") Long logPostId);

    @Query("SELECT sl FROM SavedLog sl JOIN FETCH sl.logPost lp WHERE sl.userId = :userId AND lp.isDeleted = false ORDER BY sl.createdAt DESC")
    Slice<SavedLog> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);

    long countByLogPostId(Long logPostId);

    long countByUserId(Long userId);
}
