package com.pairingplanet.pairing_planet.repository.user;

import com.pairingplanet.pairing_planet.domain.entity.user.UserFollow;
import com.pairingplanet.pairing_planet.domain.entity.user.UserFollowId;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserFollowRepository extends JpaRepository<UserFollow, UserFollowId> {

    boolean existsById(UserFollowId id);

    /**
     * Get followers of a user (people who follow them)
     */
    @Query("SELECT uf FROM UserFollow uf JOIN FETCH uf.follower WHERE uf.following.id = :userId ORDER BY uf.createdAt DESC")
    Slice<UserFollow> findFollowersByUserId(@Param("userId") Long userId, Pageable pageable);

    /**
     * Get users that a user is following
     */
    @Query("SELECT uf FROM UserFollow uf JOIN FETCH uf.following WHERE uf.follower.id = :userId ORDER BY uf.createdAt DESC")
    Slice<UserFollow> findFollowingByUserId(@Param("userId") Long userId, Pageable pageable);

    /**
     * Count followers of a user
     */
    @Query("SELECT COUNT(uf) FROM UserFollow uf WHERE uf.following.id = :userId")
    long countFollowersByUserId(@Param("userId") Long userId);

    /**
     * Count users that a user is following
     */
    @Query("SELECT COUNT(uf) FROM UserFollow uf WHERE uf.follower.id = :userId")
    long countFollowingByUserId(@Param("userId") Long userId);

    /**
     * Delete follow relationship
     */
    @Modifying
    @Query("DELETE FROM UserFollow uf WHERE uf.follower.id = :followerId AND uf.following.id = :followingId")
    void deleteByFollowerIdAndFollowingId(@Param("followerId") Long followerId, @Param("followingId") Long followingId);

    /**
     * Check if user A follows user B
     */
    @Query("SELECT CASE WHEN COUNT(uf) > 0 THEN true ELSE false END FROM UserFollow uf WHERE uf.follower.id = :followerId AND uf.following.id = :followingId")
    boolean existsByFollowerIdAndFollowingId(@Param("followerId") Long followerId, @Param("followingId") Long followingId);
}
