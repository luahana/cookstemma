package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.entity.user.UserBlock;
import com.cookstemma.cookstemma.domain.entity.user.UserBlockId;
import com.cookstemma.cookstemma.dto.block.BlockStatusResponse;
import com.cookstemma.cookstemma.dto.block.BlockedUserDto;
import com.cookstemma.cookstemma.dto.block.BlockedUsersListResponse;
import com.cookstemma.cookstemma.repository.user.UserBlockRepository;
import com.cookstemma.cookstemma.repository.user.UserFollowRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
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
public class BlockService {

    private final UserBlockRepository userBlockRepository;
    private final UserFollowRepository userFollowRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * Block a user. Auto-unfollows both directions.
     */
    @Transactional
    public void blockUser(Long blockerId, UUID targetUserPublicId) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long blockedId = targetUser.getId();

        // Cannot block yourself
        if (blockerId.equals(blockedId)) {
            throw new IllegalArgumentException("Cannot block yourself");
        }

        // Check if already blocked
        UserBlockId blockId = new UserBlockId(blockerId, blockedId);
        if (userBlockRepository.existsById(blockId)) {
            log.debug("User {} already blocked user {}", blockerId, blockedId);
            return;
        }

        User blocker = userRepository.getReferenceById(blockerId);
        User blocked = userRepository.getReferenceById(blockedId);

        // Remove any existing follow relationships in both directions
        removeFollowRelationships(blockerId, blockedId);

        // Create block record
        UserBlock userBlock = UserBlock.create(blocker, blocked);
        userBlockRepository.save(userBlock);

        log.info("User {} blocked user {}", blockerId, blockedId);
    }

    /**
     * Unblock a user
     */
    @Transactional
    public void unblockUser(Long blockerId, UUID targetUserPublicId) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long blockedId = targetUser.getId();

        // Check if actually blocked
        if (!userBlockRepository.existsByBlockerIdAndBlockedId(blockerId, blockedId)) {
            log.debug("User {} has not blocked user {}", blockerId, blockedId);
            return;
        }

        userBlockRepository.deleteByBlockerIdAndBlockedId(blockerId, blockedId);

        log.info("User {} unblocked user {}", blockerId, blockedId);
    }

    /**
     * Get block status between two users
     */
    public BlockStatusResponse getBlockStatus(Long currentUserId, UUID targetUserPublicId) {
        if (currentUserId == null) {
            return new BlockStatusResponse(false, false);
        }

        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long targetId = targetUser.getId();

        boolean isBlocked = userBlockRepository.existsByBlockerIdAndBlockedId(currentUserId, targetId);
        boolean amBlocked = userBlockRepository.existsByBlockerIdAndBlockedId(targetId, currentUserId);

        return new BlockStatusResponse(isBlocked, amBlocked);
    }

    /**
     * Get list of blocked users (paginated)
     */
    public BlockedUsersListResponse getBlockedUsers(Long blockerId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<UserBlock> blockedPage = userBlockRepository.findBlockedUsersByBlockerId(blockerId, pageable);

        List<BlockedUserDto> blockedUsers = blockedPage.getContent().stream()
                .map(ub -> BlockedUserDto.from(ub.getBlocked(), urlPrefix, ub.getCreatedAt()))
                .collect(Collectors.toList());

        return new BlockedUsersListResponse(
                blockedUsers,
                blockedPage.hasNext(),
                page,
                size,
                blockedPage.getTotalElements()
        );
    }

    /**
     * Get IDs of users blocked by the given user
     */
    public Set<Long> getBlockedUserIds(Long userId) {
        if (userId == null) {
            return Set.of();
        }
        return userBlockRepository.findBlockedUserIdsByBlockerId(userId);
    }

    /**
     * Get IDs of users who have blocked the given user
     */
    public Set<Long> getBlockerIds(Long userId) {
        if (userId == null) {
            return Set.of();
        }
        return userBlockRepository.findBlockerIdsByBlockedId(userId);
    }

    /**
     * Check if there's a block relationship between two users (either direction)
     */
    public boolean isBlockedBetweenUsers(Long userId1, Long userId2) {
        if (userId1 == null || userId2 == null) {
            return false;
        }
        return userBlockRepository.existsBlockBetweenUsers(userId1, userId2);
    }

    /**
     * Remove follow relationships in both directions when blocking
     */
    private void removeFollowRelationships(Long blockerId, Long blockedId) {
        // Remove blocker following blocked
        if (userFollowRepository.existsByFollowerIdAndFollowingId(blockerId, blockedId)) {
            userFollowRepository.deleteByFollowerIdAndFollowingId(blockerId, blockedId);
            decrementFollowCounts(blockerId, blockedId);
            log.debug("Removed follow: {} -> {}", blockerId, blockedId);
        }

        // Remove blocked following blocker
        if (userFollowRepository.existsByFollowerIdAndFollowingId(blockedId, blockerId)) {
            userFollowRepository.deleteByFollowerIdAndFollowingId(blockedId, blockerId);
            decrementFollowCounts(blockedId, blockerId);
            log.debug("Removed follow: {} -> {}", blockedId, blockerId);
        }
    }

    /**
     * Decrement follow counts for both users
     */
    private void decrementFollowCounts(Long followerId, Long followingId) {
        userRepository.findById(followerId).ifPresent(user -> {
            int newCount = Math.max(0, user.getFollowingCount() - 1);
            user.setFollowingCount(newCount);
        });

        userRepository.findById(followingId).ifPresent(user -> {
            int newCount = Math.max(0, user.getFollowerCount() - 1);
            user.setFollowerCount(newCount);
        });
    }
}
