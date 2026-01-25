package com.cookstemma.cookstemma.repository.user;

import com.cookstemma.cookstemma.domain.entity.user.UserBlock;
import com.cookstemma.cookstemma.domain.entity.user.UserBlockId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Set;

public interface UserBlockRepository extends JpaRepository<UserBlock, UserBlockId> {

    boolean existsById(UserBlockId id);

    /**
     * Get IDs of users that a user has blocked
     */
    @Query("SELECT ub.blocked.id FROM UserBlock ub WHERE ub.blocker.id = :blockerId")
    Set<Long> findBlockedUserIdsByBlockerId(@Param("blockerId") Long blockerId);

    /**
     * Get IDs of users who have blocked a specific user
     */
    @Query("SELECT ub.blocker.id FROM UserBlock ub WHERE ub.blocked.id = :blockedId")
    Set<Long> findBlockerIdsByBlockedId(@Param("blockedId") Long blockedId);

    /**
     * Get blocked users with user details (paginated)
     */
    @Query("SELECT ub FROM UserBlock ub JOIN FETCH ub.blocked WHERE ub.blocker.id = :blockerId ORDER BY ub.createdAt DESC")
    Page<UserBlock> findBlockedUsersByBlockerId(@Param("blockerId") Long blockerId, Pageable pageable);

    /**
     * Delete block relationship
     */
    @Modifying
    @Query("DELETE FROM UserBlock ub WHERE ub.blocker.id = :blockerId AND ub.blocked.id = :blockedId")
    void deleteByBlockerIdAndBlockedId(@Param("blockerId") Long blockerId, @Param("blockedId") Long blockedId);

    /**
     * Check if user A has blocked user B
     */
    @Query("SELECT CASE WHEN COUNT(ub) > 0 THEN true ELSE false END FROM UserBlock ub WHERE ub.blocker.id = :blockerId AND ub.blocked.id = :blockedId")
    boolean existsByBlockerIdAndBlockedId(@Param("blockerId") Long blockerId, @Param("blockedId") Long blockedId);

    /**
     * Check if either user has blocked the other (mutual block check)
     */
    @Query("SELECT CASE WHEN COUNT(ub) > 0 THEN true ELSE false END FROM UserBlock ub " +
           "WHERE (ub.blocker.id = :userId1 AND ub.blocked.id = :userId2) " +
           "OR (ub.blocker.id = :userId2 AND ub.blocked.id = :userId1)")
    boolean existsBlockBetweenUsers(@Param("userId1") Long userId1, @Param("userId2") Long userId2);
}
