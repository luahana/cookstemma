package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.entity.user.UserFollow;
import com.pairingplanet.pairing_planet.domain.entity.user.UserFollowId;
import com.pairingplanet.pairing_planet.dto.follow.FollowListResponse;
import com.pairingplanet.pairing_planet.dto.follow.FollowStatusResponse;
import com.pairingplanet.pairing_planet.dto.follow.FollowerDto;
import com.pairingplanet.pairing_planet.repository.user.UserFollowRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FollowService {

    private final UserFollowRepository userFollowRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * Follow a user
     */
    @Transactional
    public void follow(Long followerId, UUID targetUserPublicId) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long followingId = targetUser.getId();

        // Cannot follow yourself
        if (followerId.equals(followingId)) {
            throw new IllegalArgumentException("Cannot follow yourself");
        }

        // Check if already following
        UserFollowId followId = new UserFollowId(followerId, followingId);
        if (userFollowRepository.existsById(followId)) {
            log.debug("User {} already follows user {}", followerId, followingId);
            return;
        }

        User follower = userRepository.getReferenceById(followerId);
        User following = userRepository.getReferenceById(followingId);

        UserFollow userFollow = UserFollow.create(follower, following);
        userFollowRepository.save(userFollow);

        // Increment counts
        incrementFollowerCount(followingId);
        incrementFollowingCount(followerId);

        // Send notification to the followed user
        notificationService.notifyNewFollower(following, follower);

        log.info("User {} followed user {}", followerId, followingId);
    }

    /**
     * Unfollow a user
     */
    @Transactional
    public void unfollow(Long followerId, UUID targetUserPublicId) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long followingId = targetUser.getId();

        // Check if actually following
        if (!userFollowRepository.existsByFollowerIdAndFollowingId(followerId, followingId)) {
            log.debug("User {} does not follow user {}", followerId, followingId);
            return;
        }

        userFollowRepository.deleteByFollowerIdAndFollowingId(followerId, followingId);

        // Decrement counts
        decrementFollowerCount(followingId);
        decrementFollowingCount(followerId);

        log.info("User {} unfollowed user {}", followerId, followingId);
    }

    /**
     * Check if user follows another user
     */
    public FollowStatusResponse getFollowStatus(Long currentUserId, UUID targetUserPublicId) {
        if (currentUserId == null) {
            return new FollowStatusResponse(false);
        }

        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        boolean isFollowing = userFollowRepository.existsByFollowerIdAndFollowingId(
                currentUserId, targetUser.getId());

        return new FollowStatusResponse(isFollowing);
    }

    /**
     * Get followers of a user (people who follow them)
     */
    public FollowListResponse getFollowers(Long currentUserId, UUID targetUserPublicId, int page, int size) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Pageable pageable = PageRequest.of(page, size);
        Slice<UserFollow> follows = userFollowRepository.findFollowersByUserId(targetUser.getId(), pageable);

        // Get set of users that current user follows (for "follow back" indicator)
        Set<Long> currentUserFollowing = getCurrentUserFollowingIds(currentUserId);

        List<FollowerDto> followerDtos = follows.getContent().stream()
                .map(uf -> {
                    User follower = uf.getFollower();
                    boolean isFollowingBack = currentUserFollowing.contains(follower.getId());
                    return FollowerDto.from(follower, urlPrefix, isFollowingBack, uf.getCreatedAt());
                })
                .collect(Collectors.toList());

        return new FollowListResponse(followerDtos, follows.hasNext(), page, size);
    }

    /**
     * Get users that a user is following
     */
    public FollowListResponse getFollowing(Long currentUserId, UUID targetUserPublicId, int page, int size) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Pageable pageable = PageRequest.of(page, size);
        Slice<UserFollow> follows = userFollowRepository.findFollowingByUserId(targetUser.getId(), pageable);

        // Get set of users that current user follows (for follow button state)
        Set<Long> currentUserFollowing = getCurrentUserFollowingIds(currentUserId);

        List<FollowerDto> followingDtos = follows.getContent().stream()
                .map(uf -> {
                    User following = uf.getFollowing();
                    boolean isFollowing = currentUserFollowing.contains(following.getId());
                    return FollowerDto.from(following, urlPrefix, isFollowing, uf.getCreatedAt());
                })
                .collect(Collectors.toList());

        return new FollowListResponse(followingDtos, follows.hasNext(), page, size);
    }

    /**
     * Get IDs of users that the current user is following
     */
    private Set<Long> getCurrentUserFollowingIds(Long currentUserId) {
        if (currentUserId == null) {
            return Set.of();
        }

        // Get all users the current user follows (for small datasets this is ok)
        // For large datasets, consider batch fetching or a different approach
        return userFollowRepository.findFollowingByUserId(currentUserId, PageRequest.of(0, 1000))
                .getContent()
                .stream()
                .map(uf -> uf.getFollowing().getId())
                .collect(Collectors.toSet());
    }

    /**
     * Increment follower count for a user
     */
    @Transactional
    public void incrementFollowerCount(Long userId) {
        userRepository.findById(userId).ifPresent(user -> {
            user.setFollowerCount(user.getFollowerCount() + 1);
        });
    }

    /**
     * Decrement follower count for a user
     */
    @Transactional
    public void decrementFollowerCount(Long userId) {
        userRepository.findById(userId).ifPresent(user -> {
            int newCount = Math.max(0, user.getFollowerCount() - 1);
            user.setFollowerCount(newCount);
        });
    }

    /**
     * Increment following count for a user
     */
    @Transactional
    public void incrementFollowingCount(Long userId) {
        userRepository.findById(userId).ifPresent(user -> {
            user.setFollowingCount(user.getFollowingCount() + 1);
        });
    }

    /**
     * Decrement following count for a user
     */
    @Transactional
    public void decrementFollowingCount(Long userId) {
        userRepository.findById(userId).ifPresent(user -> {
            int newCount = Math.max(0, user.getFollowingCount() - 1);
            user.setFollowingCount(newCount);
        });
    }
}
