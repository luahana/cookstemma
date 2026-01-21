package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.comment.Comment;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.comment.CommentRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.service.CommentService;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CommentControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private CommentService commentService;

    private User logAuthor;
    private User commenter;
    private User anotherUser;
    private LogPost testLogPost;
    private String commenterToken;
    private String anotherUserToken;

    @BeforeEach
    void setUp() {
        logAuthor = testUserFactory.createTestUser("logauthor_" + System.currentTimeMillis());
        commenter = testUserFactory.createTestUser("commenter_" + System.currentTimeMillis());
        anotherUser = testUserFactory.createTestUser("another_" + System.currentTimeMillis());

        testLogPost = LogPost.builder()
                .title("Test Log Post")
                .content("Test content")
                .locale("ko-KR")
                .creatorId(logAuthor.getId())
                .build();
        logPostRepository.saveAndFlush(testLogPost);

        commenterToken = testJwtTokenProvider.createAccessToken(commenter.getPublicId(), "USER");
        anotherUserToken = testJwtTokenProvider.createAccessToken(anotherUser.getPublicId(), "USER");
    }

    @Nested
    @DisplayName("GET /api/v1/log_posts/{logId}/comments - Get Comments")
    class GetComments {

        @Test
        @DisplayName("Should return empty page when no comments")
        void getComments_NoComments_ReturnsEmptyPage() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").isArray())
                    .andExpect(jsonPath("$.content.length()").value(0))
                    .andExpect(jsonPath("$.totalElements").value(0));
        }

        @Test
        @DisplayName("Should return comments with replies")
        void getComments_HasComments_ReturnsCommentsWithReplies() throws Exception {
            // Create a comment
            Comment comment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("Test comment")
                    .build();
            commentRepository.saveAndFlush(comment);

            // Create a reply
            Comment reply = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .parent(comment)
                    .content("Test reply")
                    .build();
            commentRepository.saveAndFlush(reply);
            comment.incrementReplyCount();
            commentRepository.saveAndFlush(comment);

            mockMvc.perform(get("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content.length()").value(1))
                    .andExpect(jsonPath("$.content[0].comment.content").value("Test comment"))
                    .andExpect(jsonPath("$.content[0].replies.length()").value(1))
                    .andExpect(jsonPath("$.content[0].replies[0].content").value("Test reply"));
        }

        @Test
        @DisplayName("Should mark liked comments for authenticated user")
        void getComments_Authenticated_MarksLikedComments() throws Exception {
            Comment comment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .content("Likeable comment")
                    .build();
            commentRepository.saveAndFlush(comment);

            commentService.likeComment(comment.getPublicId(), commenter.getId());

            mockMvc.perform(get("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content[0].comment.isLikedByCurrentUser").value(true));
        }

        @Test
        @DisplayName("Should support pagination")
        void getComments_Pagination_ReturnsCorrectPage() throws Exception {
            // Create 5 comments
            for (int i = 0; i < 5; i++) {
                Comment comment = Comment.builder()
                        .logPost(testLogPost)
                        .creator(commenter)
                        .content("Comment " + i)
                        .build();
                commentRepository.saveAndFlush(comment);
            }

            mockMvc.perform(get("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId())
                            .param("page", "0")
                            .param("size", "2"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content.length()").value(2))
                    .andExpect(jsonPath("$.totalElements").value(5))
                    .andExpect(jsonPath("$.totalPages").value(3));
        }

        @Test
        @DisplayName("Should return 400 for non-existent log post")
        void getComments_NonExistentLog_Returns400() throws Exception {
            mockMvc.perform(get("/api/v1/log_posts/{logId}/comments", UUID.randomUUID()))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/log_posts/{logId}/comments - Create Comment")
    class CreateComment {

        @Test
        @DisplayName("Should create comment with valid token")
        void createComment_ValidToken_Returns200() throws Exception {
            mockMvc.perform(post("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "New comment"))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").value("New comment"))
                    .andExpect(jsonPath("$.creatorPublicId").value(commenter.getPublicId().toString()));
        }

        @Test
        @DisplayName("Should return 401 without token")
        void createComment_NoToken_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "New comment"))))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 400 for empty content")
        void createComment_EmptyContent_Returns400() throws Exception {
            mockMvc.perform(post("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", ""))))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 400 for content exceeding max length")
        void createComment_ContentTooLong_Returns400() throws Exception {
            String longContent = "a".repeat(1001);
            mockMvc.perform(post("/api/v1/log_posts/{logId}/comments", testLogPost.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", longContent))))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("GET /api/v1/comments/{commentId}/replies - Get Replies")
    class GetReplies {

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
        @DisplayName("Should return replies for comment")
        void getReplies_HasReplies_ReturnsReplies() throws Exception {
            Comment reply = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .parent(parentComment)
                    .content("Test reply")
                    .build();
            commentRepository.saveAndFlush(reply);

            mockMvc.perform(get("/api/v1/comments/{commentId}/replies", parentComment.getPublicId()))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content.length()").value(1))
                    .andExpect(jsonPath("$.content[0].content").value("Test reply"));
        }

        @Test
        @DisplayName("Should return 400 for non-existent comment")
        void getReplies_NonExistentComment_Returns400() throws Exception {
            mockMvc.perform(get("/api/v1/comments/{commentId}/replies", UUID.randomUUID()))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/comments/{commentId}/replies - Create Reply")
    class CreateReply {

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
        @DisplayName("Should create reply with valid token")
        void createReply_ValidToken_Returns200() throws Exception {
            mockMvc.perform(post("/api/v1/comments/{commentId}/replies", parentComment.getPublicId())
                            .header("Authorization", "Bearer " + anotherUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "New reply"))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").value("New reply"));
        }

        @Test
        @DisplayName("Should return 401 without token")
        void createReply_NoToken_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/comments/{commentId}/replies", parentComment.getPublicId())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "New reply"))))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 400 when replying to a reply")
        void createReply_ToReply_Returns400() throws Exception {
            // Create a reply first
            Comment reply = Comment.builder()
                    .logPost(testLogPost)
                    .creator(anotherUser)
                    .parent(parentComment)
                    .content("First reply")
                    .build();
            commentRepository.saveAndFlush(reply);

            // Try to reply to the reply
            mockMvc.perform(post("/api/v1/comments/{commentId}/replies", reply.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "Reply to reply"))))
                    .andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("PUT /api/v1/comments/{commentId} - Edit Comment")
    class EditComment {

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
        @DisplayName("Should edit own comment")
        void editComment_Owner_Returns200() throws Exception {
            mockMvc.perform(put("/api/v1/comments/{commentId}", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "Updated content"))))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.content").value("Updated content"))
                    .andExpect(jsonPath("$.isEdited").value(true));
        }

        @Test
        @DisplayName("Should return 403 when editing other's comment")
        void editComment_NotOwner_Returns403() throws Exception {
            mockMvc.perform(put("/api/v1/comments/{commentId}", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + anotherUserToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "Hacked content"))))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void editComment_NoToken_Returns401() throws Exception {
            mockMvc.perform(put("/api/v1/comments/{commentId}", existingComment.getPublicId())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(Map.of("content", "Updated"))))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("DELETE /api/v1/comments/{commentId} - Delete Comment")
    class DeleteComment {

        private Comment existingComment;

        @BeforeEach
        void setUpComment() {
            existingComment = Comment.builder()
                    .logPost(testLogPost)
                    .creator(commenter)
                    .content("To be deleted")
                    .build();
            commentRepository.saveAndFlush(existingComment);
        }

        @Test
        @DisplayName("Should delete own comment")
        void deleteComment_Owner_Returns204() throws Exception {
            mockMvc.perform(delete("/api/v1/comments/{commentId}", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken))
                    .andExpect(status().isNoContent());

            // Verify soft delete
            Comment deleted = commentRepository.findById(existingComment.getId()).orElseThrow();
            assert deleted.isDeleted();
        }

        @Test
        @DisplayName("Should return 403 when deleting other's comment")
        void deleteComment_NotOwner_Returns403() throws Exception {
            mockMvc.perform(delete("/api/v1/comments/{commentId}", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + anotherUserToken))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void deleteComment_NoToken_Returns401() throws Exception {
            mockMvc.perform(delete("/api/v1/comments/{commentId}", existingComment.getPublicId()))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("POST /api/v1/comments/{commentId}/like - Like Comment")
    class LikeComment {

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
        @DisplayName("Should like comment with valid token")
        void likeComment_ValidToken_Returns200() throws Exception {
            mockMvc.perform(post("/api/v1/comments/{commentId}/like", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken))
                    .andExpect(status().isOk());

            Comment liked = commentRepository.findById(existingComment.getId()).orElseThrow();
            assert liked.getLikeCount() == 1;
        }

        @Test
        @DisplayName("Should return 401 without token")
        void likeComment_NoToken_Returns401() throws Exception {
            mockMvc.perform(post("/api/v1/comments/{commentId}/like", existingComment.getPublicId()))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should handle duplicate like gracefully")
        void likeComment_AlreadyLiked_Returns200() throws Exception {
            commentService.likeComment(existingComment.getPublicId(), commenter.getId());

            mockMvc.perform(post("/api/v1/comments/{commentId}/like", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken))
                    .andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("DELETE /api/v1/comments/{commentId}/like - Unlike Comment")
    class UnlikeComment {

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
        @DisplayName("Should unlike comment with valid token")
        void unlikeComment_ValidToken_Returns200() throws Exception {
            mockMvc.perform(delete("/api/v1/comments/{commentId}/like", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void unlikeComment_NoToken_Returns401() throws Exception {
            mockMvc.perform(delete("/api/v1/comments/{commentId}/like", existingComment.getPublicId()))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should handle unlike when not liked gracefully")
        void unlikeComment_NotLiked_Returns200() throws Exception {
            // Unlike first
            commentService.unlikeComment(existingComment.getPublicId(), commenter.getId());

            // Try again
            mockMvc.perform(delete("/api/v1/comments/{commentId}/like", existingComment.getPublicId())
                            .header("Authorization", "Bearer " + commenterToken))
                    .andExpect(status().isOk());
        }
    }
}
