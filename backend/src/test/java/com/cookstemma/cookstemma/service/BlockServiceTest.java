package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.block.BlockStatusResponse;
import com.cookstemma.cookstemma.dto.block.BlockedUsersListResponse;
import com.cookstemma.cookstemma.repository.user.UserBlockRepository;
import com.cookstemma.cookstemma.repository.user.UserFollowRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BlockServiceTest extends BaseIntegrationTest {

    @Autowired
    private BlockService blockService;

    @Autowired
    private FollowService followService;

    @Autowired
    private UserBlockRepository userBlockRepository;

    @Autowired
    private UserFollowRepository userFollowRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User user1;
    private User user2;

    @BeforeEach
    void setUp() {
        user1 = testUserFactory.createTestUser("user1_" + System.currentTimeMillis());
        user2 = testUserFactory.createTestUser("user2_" + System.currentTimeMillis());
    }

    @Nested
    @DisplayName("Block User")
    class BlockUserTests {

        @Test
        @DisplayName("Should block user successfully")
        void blockUser_Success() {
            blockService.blockUser(user1.getId(), user2.getPublicId());

            assertThat(userBlockRepository.existsByBlockerIdAndBlockedId(user1.getId(), user2.getId()))
                    .isTrue();
        }

        @Test
        @DisplayName("Should remove follow relationships when blocking")
        void blockUser_RemovesFollowRelationships() {
            // Setup: user1 follows user2 and vice versa
            followService.follow(user1.getId(), user2.getPublicId());
            followService.follow(user2.getId(), user1.getPublicId());

            // Verify follows exist
            assertThat(userFollowRepository.existsByFollowerIdAndFollowingId(user1.getId(), user2.getId())).isTrue();
            assertThat(userFollowRepository.existsByFollowerIdAndFollowingId(user2.getId(), user1.getId())).isTrue();

            // Block
            blockService.blockUser(user1.getId(), user2.getPublicId());

            // Verify follows removed
            assertThat(userFollowRepository.existsByFollowerIdAndFollowingId(user1.getId(), user2.getId())).isFalse();
            assertThat(userFollowRepository.existsByFollowerIdAndFollowingId(user2.getId(), user1.getId())).isFalse();
        }

        @Test
        @DisplayName("Should throw when blocking yourself")
        void blockUser_Self_ThrowsException() {
            assertThatThrownBy(() -> blockService.blockUser(user1.getId(), user1.getPublicId()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Cannot block yourself");
        }

        @Test
        @DisplayName("Should not duplicate block")
        void blockUser_AlreadyBlocked_NoChange() {
            blockService.blockUser(user1.getId(), user2.getPublicId());
            blockService.blockUser(user1.getId(), user2.getPublicId()); // Duplicate

            // Should still only have one block record
            assertThat(userBlockRepository.existsByBlockerIdAndBlockedId(user1.getId(), user2.getId()))
                    .isTrue();
        }
    }

    @Nested
    @DisplayName("Unblock User")
    class UnblockUserTests {

        @Test
        @DisplayName("Should unblock user successfully")
        void unblockUser_Success() {
            blockService.blockUser(user1.getId(), user2.getPublicId());
            blockService.unblockUser(user1.getId(), user2.getPublicId());

            assertThat(userBlockRepository.existsByBlockerIdAndBlockedId(user1.getId(), user2.getId()))
                    .isFalse();
        }

        @Test
        @DisplayName("Should handle unblock of not-blocked user gracefully")
        void unblockUser_NotBlocked_NoError() {
            // Should not throw
            blockService.unblockUser(user1.getId(), user2.getPublicId());

            assertThat(userBlockRepository.existsByBlockerIdAndBlockedId(user1.getId(), user2.getId()))
                    .isFalse();
        }
    }

    @Nested
    @DisplayName("Block Status")
    class BlockStatusTests {

        @Test
        @DisplayName("Should return correct status when blocked")
        void getBlockStatus_Blocked_ReturnsTrue() {
            blockService.blockUser(user1.getId(), user2.getPublicId());

            BlockStatusResponse response = blockService.getBlockStatus(user1.getId(), user2.getPublicId());

            assertThat(response.isBlocked()).isTrue();
            assertThat(response.amBlocked()).isFalse();
        }

        @Test
        @DisplayName("Should return correct status when blocked by target")
        void getBlockStatus_AmBlocked_ReturnsTrue() {
            blockService.blockUser(user2.getId(), user1.getPublicId()); // user2 blocks user1

            BlockStatusResponse response = blockService.getBlockStatus(user1.getId(), user2.getPublicId());

            assertThat(response.isBlocked()).isFalse();
            assertThat(response.amBlocked()).isTrue();
        }

        @Test
        @DisplayName("Should return false for no block")
        void getBlockStatus_NoBlock_ReturnsFalse() {
            BlockStatusResponse response = blockService.getBlockStatus(user1.getId(), user2.getPublicId());

            assertThat(response.isBlocked()).isFalse();
            assertThat(response.amBlocked()).isFalse();
        }
    }

    @Nested
    @DisplayName("Blocked Users List")
    class BlockedUsersListTests {

        @Test
        @DisplayName("Should return blocked users list")
        void getBlockedUsers_HasBlocked_ReturnsList() {
            blockService.blockUser(user1.getId(), user2.getPublicId());

            BlockedUsersListResponse response = blockService.getBlockedUsers(user1.getId(), 0, 20);

            assertThat(response.content()).hasSize(1);
            assertThat(response.content().get(0).publicId()).isEqualTo(user2.getPublicId());
        }

        @Test
        @DisplayName("Should return empty list when no blocked users")
        void getBlockedUsers_NoBlocked_ReturnsEmpty() {
            BlockedUsersListResponse response = blockService.getBlockedUsers(user1.getId(), 0, 20);

            assertThat(response.content()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Follow Prevention")
    class FollowPreventionTests {

        @Test
        @DisplayName("Should prevent follow when blocked")
        void follow_WhenBlocked_ThrowsException() {
            blockService.blockUser(user1.getId(), user2.getPublicId());

            assertThatThrownBy(() -> followService.follow(user1.getId(), user2.getPublicId()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Cannot follow a blocked user");
        }

        @Test
        @DisplayName("Should prevent follow when blocker")
        void follow_WhenBlocker_ThrowsException() {
            blockService.blockUser(user2.getId(), user1.getPublicId()); // user2 blocks user1

            assertThatThrownBy(() -> followService.follow(user1.getId(), user2.getPublicId()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Cannot follow a blocked user");
        }
    }
}
