package com.cookstemma.cookstemma.repository.history;

import com.cookstemma.cookstemma.domain.entity.history.ViewHistory;
import com.cookstemma.cookstemma.domain.enums.ViewableEntityType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ViewHistoryRepository extends JpaRepository<ViewHistory, Long> {

    /**
     * Find a specific view history entry by user, entity type, and entity ID.
     */
    Optional<ViewHistory> findByUserIdAndEntityTypeAndEntityId(
            Long userId,
            ViewableEntityType entityType,
            Long entityId
    );

    /**
     * Get recently viewed entity IDs by user and type, ordered by most recent.
     */
    @Query("SELECT vh.entityId FROM ViewHistory vh " +
           "WHERE vh.userId = :userId AND vh.entityType = :entityType " +
           "ORDER BY vh.viewedAt DESC")
    List<Long> findRecentEntityIdsByUserAndType(
            @Param("userId") Long userId,
            @Param("entityType") ViewableEntityType entityType,
            Pageable pageable
    );

    /**
     * Get recent view history entries by user and type.
     */
    @Query("SELECT vh FROM ViewHistory vh " +
           "WHERE vh.userId = :userId AND vh.entityType = :entityType " +
           "ORDER BY vh.viewedAt DESC")
    List<ViewHistory> findRecentByUserAndType(
            @Param("userId") Long userId,
            @Param("entityType") ViewableEntityType entityType,
            Pageable pageable
    );

    /**
     * Delete old view history entries for a user, keeping only the most recent.
     * Used to limit history size per user.
     */
    @Query("DELETE FROM ViewHistory vh WHERE vh.userId = :userId AND vh.id NOT IN " +
           "(SELECT vh2.id FROM ViewHistory vh2 WHERE vh2.userId = :userId ORDER BY vh2.viewedAt DESC)")
    void deleteOldEntriesForUser(@Param("userId") Long userId);

    /**
     * Count entries for a user.
     */
    long countByUserId(Long userId);

    /**
     * Find oldest entry IDs for a user (for cleanup).
     */
    @Query("SELECT vh.id FROM ViewHistory vh WHERE vh.userId = :userId ORDER BY vh.viewedAt ASC")
    List<Long> findOldestIdsByUserId(@Param("userId") Long userId, Pageable pageable);

    /**
     * Delete all view history for a user.
     */
    @Modifying
    @Query("DELETE FROM ViewHistory vh WHERE vh.userId = :userId")
    void deleteAllByUserId(@Param("userId") Long userId);
}
