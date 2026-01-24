package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.comment.Comment;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.NotificationType;
import com.cookstemma.cookstemma.dto.comment.CommentResponseDto;
import com.cookstemma.cookstemma.dto.comment.CommentWithRepliesDto;
import com.cookstemma.cookstemma.dto.comment.CreateCommentRequestDto;
import com.cookstemma.cookstemma.repository.comment.CommentLikeRepository;
import com.cookstemma.cookstemma.repository.comment.CommentRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.notification.NotificationRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CommentServiceTest extends BaseIntegrationTest {

    @Autowired
    private CommentService commentService;

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private CommentLikeRepository commentLikeRepository;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User logAuthor;
    private User commenter;
    private User anotherUser;
    private LogPost testLogPost;
    private UserPrincipal commenterPrincipal;
    private UserPrincipal anotherUserPrincipal;

    @BeforeEach
    void setUp() {
        logAuthor = testUserFactory.createTestUser("logauthor_" + System.currentTimeMillis());
        commenter = testUserFactory.createTestUser("commenter_" + System.currentTimeMillis());
        anotherUser = testUserFactory.createTestUser("another_" + System.currentTimeMillis());

        testLogPost = LogPost.builder()
                .title("Test Log Post")
                .content("Test content for the log post")
                .locale("ko-KR")
                .creatorId(logAuthor.getId())
                .build();
        logPostRepository.saveAndFlush(testLogPost);

        commenterPrincipal = new UserPrincipal(commenter);
        anotherUserPrincipal = new UserPrincipal(anotherUser);
    }

    @Nested
    @DisplayName("Create Comment")
    class CreateCommentTests {

        @Test
        @DisplayName("Should create comment successfully")
        void createComment_Success() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("This is a test comment");

            CommentResponseDto response = commentService.createComment(testLogPost.getPublicId(), "en", dto, commenterPrincipal);

            assertThat(response).isNotNull();
            assertThat(response.content()).isEqualTo("This is a test comment");
            assertThat(response.creatorPublicId()).isEqualTo(commenter.getPublicId());
            assertThat(response.replyCount()).isZero();
            assertThat(response.likeCount()).isZero();
            assertThat(response.isEdited()).isFalse();
            assertThat(response.isDeleted()).isFalse();
        }

        @Test
        @DisplayName("Should increment comment count on log post")
        void createComment_IncrementsCommentCount() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Comment 1");
            commentService.createComment(testLogPost.getPublicId(), "en", dto, commenterPrincipal);

            LogPost refreshed = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(refreshed.getCommentCount()).isEqualTo(1);

            dto = new CreateCommentRequestDto("Comment 2");
            commentService.createComment(testLogPost.getPublicId(), "en", dto, anotherUserPrincipal);

            refreshed = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(refreshed.getCommentCount()).isEqualTo(2);
        }

        @Test
        @DisplayName("Should throw when log post not found")
        void createComment_LogPostNotFound_ThrowsException() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Test comment");

            assertThatThrownBy(() -> commentService.createComment(java.util.UUID.randomUUID(), "en", dto, commenterPrincipal))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Log post not found");
        }

        @Test
        @DisplayName("Should throw when log post is deleted")
        void createComment_DeletedLogPost_ThrowsException() {
            testLogPost.softDelete();
            logPostRepository.saveAndFlush(testLogPost);

            CreateCommentRequestDto dto = new CreateCommentRequestDto("Test comment");

            assertThatThrownBy(() -> commentService.createComment(testLogPost.getPublicId(), "en", dto, commenterPrincipal))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Cannot comment on a deleted log post");
        }

        @Test
        @DisplayName("Should send notification to log author")
        void createComment_SendsNotificationToLogAuthor() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Nice log!");
            commentService.createComment(testLogPost.getPublicId(), "en", dto, commenterPrincipal);

            var notifications = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(
                    logAuthor.getId(), PageRequest.of(0, 10));

            assertThat(notifications.getContent()).hasSize(1);
            assertThat(notifications.getContent().get(0).getType()).isEqualTo(NotificationType.COMMENT_ON_LOG);
            assertThat(notifications.getContent().get(0).getSender().getId()).isEqualTo(commenter.getId());
        }

        @Test
        @DisplayName("Should not send notification when commenting on own log")
        void createComment_OwnLog_NoNotification() {
            UserPrincipal authorPrincipal = new UserPrincipal(logAuthor);

            CreateCommentRequestDto dto = new CreateCommentRequestDto("My own comment");
            commentService.createComment(testLogPost.getPublicId(), "en", dto, authorPrincipal);

            var notifications = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(
                    logAuthor.getId(), PageRequest.of(0, 10));

            assertThat(notifications.getContent()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Create Reply")
    class CreateReplyTests {

        private Comment parentComment;

        @BeforeEach
        void setUpParentComment() {
            parentComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Parent comment")
                    .build();
            commentRepository.saveAndFlush(parentComment);
        }

        @Test
        @DisplayName("Should create reply successfully")
        void createReply_Success() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("This is a reply");

            CommentResponseDto response = commentService.createReply(parentComment.getPublicId(), "en", dto, anotherUserPrincipal);

            assertThat(response).isNotNull();
            assertThat(response.content()).isEqualTo("This is a reply");
            assertThat(response.creatorPublicId()).isEqualTo(anotherUser.getPublicId());
        }

        @Test
        @DisplayName("Should increment reply count on parent comment")
        void createReply_IncrementsReplyCount() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Reply 1");
            commentService.createReply(parentComment.getPublicId(), "en", dto, anotherUserPrincipal);

            Comment refreshedParent = commentRepository.findById(parentComment.getId()).orElseThrow();
            assertThat(refreshedParent.getReplyCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should increment comment count on log post")
        void createReply_IncrementsLogPostCommentCount() {
            int initialCount = testLogPost.getCommentCount() != null ? testLogPost.getCommentCount() : 0;

            CreateCommentRequestDto dto = new CreateCommentRequestDto("Reply");
            commentService.createReply(parentComment.getPublicId(), "en", dto, anotherUserPrincipal);

            LogPost refreshed = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(refreshed.getCommentCount()).isEqualTo(initialCount + 1);
        }

        @Test
        @DisplayName("Should throw when parent comment not found")
        void createReply_ParentNotFound_ThrowsException() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Reply");

            assertThatThrownBy(() -> commentService.createReply(java.util.UUID.randomUUID(), "en", dto, anotherUserPrincipal))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Parent comment not found");
        }

        @Test
        @DisplayName("Should not allow reply to a reply (single-level only)")
        void createReply_ToReply_ThrowsException() {
            // Create a reply first
            Comment reply = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .parent(parentComment)
                    .content("First reply")
                    .build();
            commentRepository.saveAndFlush(reply);

            // Try to reply to the reply
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Reply to reply");

            assertThatThrownBy(() -> commentService.createReply(reply.getPublicId(), "en", dto, commenterPrincipal))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Cannot reply to a reply");
        }

        @Test
        @DisplayName("Should send notification to parent comment author")
        void createReply_SendsNotification() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Nice comment!");
            commentService.createReply(parentComment.getPublicId(), "en", dto, anotherUserPrincipal);

            var notifications = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(
                    commenter.getId(), PageRequest.of(0, 10));

            assertThat(notifications.getContent()).hasSize(1);
            assertThat(notifications.getContent().get(0).getType()).isEqualTo(NotificationType.COMMENT_REPLY);
        }

        @Test
        @DisplayName("Should not send notification when replying to own comment")
        void createReply_OwnComment_NoNotification() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Self reply");
            commentService.createReply(parentComment.getPublicId(), "en", dto, commenterPrincipal);

            var notifications = notificationRepository.findByRecipientIdOrderByCreatedAtDesc(
                    commenter.getId(), PageRequest.of(0, 10));

            assertThat(notifications.getContent()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Get Comments")
    class GetCommentsTests {

        @Test
        @DisplayName("Should return paginated comments with preview replies")
        void getComments_ReturnsWithReplies() {
            // Create comments with replies
            Comment comment1 = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Comment 1")
                    .build();
            commentRepository.saveAndFlush(comment1);

            Comment reply1 = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .parent(comment1)
                    .content("Reply to comment 1")
                    .build();
            commentRepository.saveAndFlush(reply1);
            comment1.incrementReplyCount();
            commentRepository.saveAndFlush(comment1);

            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), commenter.getId());

            assertThat(result.getContent()).hasSize(1);
            CommentWithRepliesDto commentWithReplies = result.getContent().get(0);
            assertThat(commentWithReplies.comment().content()).isEqualTo("Comment 1");
            assertThat(commentWithReplies.replies()).hasSize(1);
            assertThat(commentWithReplies.replies().get(0).content()).isEqualTo("Reply to comment 1");
        }

        @Test
        @DisplayName("Should return empty page when no comments")
        void getComments_NoComments_ReturnsEmpty() {
            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), null);

            assertThat(result.getContent()).isEmpty();
        }

        @Test
        @DisplayName("Should mark liked comments correctly")
        void getComments_MarksLikedComments() {
            Comment comment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .content("Likeable comment")
                    .build();
            commentRepository.saveAndFlush(comment);

            commentService.likeComment(comment.getPublicId(), commenter.getId());

            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), commenter.getId());

            assertThat(result.getContent().get(0).comment().isLikedByCurrentUser()).isTrue();
        }
    }

    @Nested
    @DisplayName("Get Replies")
    class GetRepliesTests {

        @Test
        @DisplayName("Should return paginated replies")
        void getReplies_ReturnsPaginated() {
            Comment parentComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Parent")
                    .build();
            commentRepository.saveAndFlush(parentComment);

            for (int i = 0; i < 5; i++) {
                Comment reply = Comment.builder()
                        .logPost(testLogPost)
                        .creator(anotherUser)
                        .parent(parentComment)
                        .content("Reply " + i)
                        .build();
                commentRepository.saveAndFlush(reply);
            }

            Page<CommentResponseDto> result = commentService.getReplies(parentComment.getPublicId(), "en", PageRequest.of(0, 3), null);

            assertThat(result.getContent()).hasSize(3);
            assertThat(result.getTotalElements()).isEqualTo(5);
        }
    }

    @Nested
    @DisplayName("Edit Comment")
    class EditCommentTests {

        private Comment existingComment;

        @BeforeEach
        void setUpComment() {
            existingComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Original content")
                    .build();
            commentRepository.saveAndFlush(existingComment);
        }

        @Test
        @DisplayName("Should edit comment successfully")
        void editComment_Success() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Updated content");

            CommentResponseDto response = commentService.editComment(existingComment.getPublicId(), "en", dto, commenter.getId());

            assertThat(response.content()).isEqualTo("Updated content");
            assertThat(response.isEdited()).isTrue();
        }

        @Test
        @DisplayName("Should throw when comment not found")
        void editComment_NotFound_ThrowsException() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Updated");

            assertThatThrownBy(() -> commentService.editComment(java.util.UUID.randomUUID(), "en", dto, commenter.getId()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Comment not found");
        }

        @Test
        @DisplayName("Should throw when not owner")
        void editComment_NotOwner_ThrowsException() {
            CreateCommentRequestDto dto = new CreateCommentRequestDto("Hacked content");

            assertThatThrownBy(() -> commentService.editComment(existingComment.getPublicId(), "en", dto, anotherUser.getId()))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("only edit your own");
        }
    }

    @Nested
    @DisplayName("Delete Comment")
    class DeleteCommentTests {

        private Comment existingComment;

        @BeforeEach
        void setUpComment() {
            existingComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("To be deleted")
                    .build();
            commentRepository.saveAndFlush(existingComment);

            testLogPost.setCommentCount(1);
            logPostRepository.saveAndFlush(testLogPost);
        }

        @Test
        @DisplayName("Should soft delete comment successfully")
        void deleteComment_Success() {
            commentService.deleteComment(existingComment.getPublicId(), commenter.getId());

            Comment refreshed = commentRepository.findById(existingComment.getId()).orElseThrow();
            assertThat(refreshed.isDeleted()).isTrue();
            assertThat(refreshed.getDeletedAt()).isNotNull();
        }

        @Test
        @DisplayName("Should decrement comment count on log post")
        void deleteComment_DecrementsLogPostCommentCount() {
            commentService.deleteComment(existingComment.getPublicId(), commenter.getId());

            LogPost refreshed = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(refreshed.getCommentCount()).isZero();
        }

        @Test
        @DisplayName("Should decrement parent reply count when deleting reply")
        void deleteReply_DecrementsParentReplyCount() {
            Comment reply = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .parent(existingComment)
                    .content("Reply to delete")
                    .build();
            commentRepository.saveAndFlush(reply);

            existingComment.incrementReplyCount();
            commentRepository.saveAndFlush(existingComment);

            commentService.deleteComment(reply.getPublicId(), anotherUser.getId());

            Comment refreshedParent = commentRepository.findById(existingComment.getId()).orElseThrow();
            assertThat(refreshedParent.getReplyCount()).isZero();
        }

        @Test
        @DisplayName("Should throw when not owner")
        void deleteComment_NotOwner_ThrowsException() {
            assertThatThrownBy(() -> commentService.deleteComment(
                    existingComment.getPublicId(), anotherUser.getId()))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("only delete your own");
        }
    }

    @Nested
    @DisplayName("Like Comment")
    class LikeCommentTests {

        private Comment existingComment;

        @BeforeEach
        void setUpComment() {
            existingComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .content("Likeable")
                    .build();
            commentRepository.saveAndFlush(existingComment);
        }

        @Test
        @DisplayName("Should like comment successfully")
        void likeComment_Success() {
            commentService.likeComment(existingComment.getPublicId(), commenter.getId());

            assertThat(commentLikeRepository.existsByUserIdAndCommentId(
                    commenter.getId(), existingComment.getId())).isTrue();

            Comment refreshed = commentRepository.findById(existingComment.getId()).orElseThrow();
            assertThat(refreshed.getLikeCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should not duplicate like")
        void likeComment_AlreadyLiked_NoDuplicate() {
            commentService.likeComment(existingComment.getPublicId(), commenter.getId());
            commentService.likeComment(existingComment.getPublicId(), commenter.getId());

            Comment refreshed = commentRepository.findById(existingComment.getId()).orElseThrow();
            assertThat(refreshed.getLikeCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should throw when comment not found")
        void likeComment_NotFound_ThrowsException() {
            assertThatThrownBy(() -> commentService.likeComment(
                    java.util.UUID.randomUUID(), commenter.getId()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Comment not found");
        }
    }

    @Nested
    @DisplayName("Hidden Comments")
    class HiddenCommentTests {

        private Comment hiddenComment;

        @BeforeEach
        void setUpHiddenComment() {
            hiddenComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Hidden content")
                    .build();
            hiddenComment.hide("Content moderation failure");
            commentRepository.saveAndFlush(hiddenComment);
        }

        @Test
        @DisplayName("Hidden comment should show content to creator")
        void hiddenComment_ShowsContentToCreator() {
            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), commenter.getId());

            assertThat(result.getContent()).hasSize(1);
            CommentResponseDto dto = result.getContent().get(0).comment();
            assertThat(dto.isHidden()).isTrue();
            assertThat(dto.content()).isEqualTo("Hidden content");
        }

        @Test
        @DisplayName("Hidden comment should hide content from others")
        void hiddenComment_HidesContentFromOthers() {
            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), anotherUser.getId());

            assertThat(result.getContent()).hasSize(1);
            CommentResponseDto dto = result.getContent().get(0).comment();
            assertThat(dto.isHidden()).isTrue();
            assertThat(dto.content()).isNull();
        }

        @Test
        @DisplayName("Hidden comment should hide content from anonymous users")
        void hiddenComment_HidesContentFromAnonymous() {
            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), null);

            assertThat(result.getContent()).hasSize(1);
            CommentResponseDto dto = result.getContent().get(0).comment();
            assertThat(dto.isHidden()).isTrue();
            assertThat(dto.content()).isNull();
        }

        @Test
        @DisplayName("isHidden flag should be correctly set in response")
        void hiddenComment_IsHiddenFlagSet() {
            // Create a normal comment for comparison
            Comment normalComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .content("Normal content")
                    .build();
            commentRepository.saveAndFlush(normalComment);

            Page<CommentWithRepliesDto> result = commentService.getComments(testLogPost.getPublicId(), "en", PageRequest.of(0, 10), anotherUser.getId());

            assertThat(result.getContent()).hasSize(2);

            // Find normal and hidden comments
            CommentResponseDto normalDto = result.getContent().stream()
                    .map(CommentWithRepliesDto::comment)
                    .filter(c -> !c.isHidden())
                    .findFirst()
                    .orElseThrow();
            CommentResponseDto hiddenDto = result.getContent().stream()
                    .map(CommentWithRepliesDto::comment)
                    .filter(CommentResponseDto::isHidden)
                    .findFirst()
                    .orElseThrow();

            assertThat(normalDto.isHidden()).isFalse();
            assertThat(normalDto.content()).isEqualTo("Normal content");

            assertThat(hiddenDto.isHidden()).isTrue();
            assertThat(hiddenDto.content()).isNull();
        }

        @Test
        @DisplayName("Comment entity hide method should set fields correctly")
        void hideMethod_SetsFieldsCorrectly() {
            Comment comment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Test content")
                    .build();

            assertThat(comment.isHidden()).isFalse();

            comment.hide("Test reason");

            assertThat(comment.isHidden()).isTrue();
            assertThat(comment.getHiddenReason()).isEqualTo("Test reason");
        }
    }

    @Nested
    @DisplayName("Unlike Comment")
    class UnlikeCommentTests {

        private Comment existingComment;

        @BeforeEach
        void setUpComment() {
            existingComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .content("Unlikeable")
                    .build();
            existingComment.incrementLikeCount();
            commentRepository.saveAndFlush(existingComment);

            commentService.likeComment(existingComment.getPublicId(), commenter.getId());
        }

        @Test
        @DisplayName("Should unlike comment successfully")
        void unlikeComment_Success() {
            commentService.unlikeComment(existingComment.getPublicId(), commenter.getId());

            assertThat(commentLikeRepository.existsByUserIdAndCommentId(
                    commenter.getId(), existingComment.getId())).isFalse();

            Comment refreshed = commentRepository.findById(existingComment.getId()).orElseThrow();
            assertThat(refreshed.getLikeCount()).isEqualTo(1); // Was incremented twice (once in setUp, once in likeComment)
        }

        @Test
        @DisplayName("Should handle unlike when not liked")
        void unlikeComment_NotLiked_NoError() {
            // Unlike first
            commentService.unlikeComment(existingComment.getPublicId(), commenter.getId());
            // Try again - should not throw
            commentService.unlikeComment(existingComment.getPublicId(), commenter.getId());

            assertThat(commentLikeRepository.existsByUserIdAndCommentId(
                    commenter.getId(), existingComment.getId())).isFalse();
        }
    }
}
