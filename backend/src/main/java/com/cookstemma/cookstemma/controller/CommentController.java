package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.comment.CommentResponseDto;
import com.cookstemma.cookstemma.dto.comment.CommentWithRepliesDto;
import com.cookstemma.cookstemma.dto.comment.CreateCommentRequestDto;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.CommentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    // =========== Top-level Comments ===========

    /**
     * Get paginated top-level comments for a log post with preview replies
     * GET /api/v1/log_posts/{logId}/comments?page=0&size=20
     */
    @GetMapping("/api/v1/log_posts/{logId}/comments")
    public ResponseEntity<Page<CommentWithRepliesDto>> getComments(
            @PathVariable("logId") UUID logPublicId,
            @RequestHeader(value = "Accept-Language", defaultValue = "en") String locale,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long currentUserId = principal != null ? principal.getId() : null;
        PageRequest pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(commentService.getComments(logPublicId, locale, pageable, currentUserId));
    }

    /**
     * Create a top-level comment on a log post
     * POST /api/v1/log_posts/{logId}/comments
     */
    @PostMapping("/api/v1/log_posts/{logId}/comments")
    public ResponseEntity<CommentResponseDto> createComment(
            @PathVariable("logId") UUID logPublicId,
            @RequestHeader(value = "Accept-Language", defaultValue = "en") String locale,
            @Valid @RequestBody CreateCommentRequestDto request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(commentService.createComment(logPublicId, locale, request, principal));
    }

    // =========== Replies ===========

    /**
     * Get paginated replies to a comment
     * GET /api/v1/comments/{commentId}/replies?page=0&size=20
     */
    @GetMapping("/api/v1/comments/{commentId}/replies")
    public ResponseEntity<Page<CommentResponseDto>> getReplies(
            @PathVariable("commentId") UUID commentPublicId,
            @RequestHeader(value = "Accept-Language", defaultValue = "en") String locale,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long currentUserId = principal != null ? principal.getId() : null;
        PageRequest pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(commentService.getReplies(commentPublicId, locale, pageable, currentUserId));
    }

    /**
     * Create a reply to a comment
     * POST /api/v1/comments/{commentId}/replies
     */
    @PostMapping("/api/v1/comments/{commentId}/replies")
    public ResponseEntity<CommentResponseDto> createReply(
            @PathVariable("commentId") UUID commentPublicId,
            @RequestHeader(value = "Accept-Language", defaultValue = "en") String locale,
            @Valid @RequestBody CreateCommentRequestDto request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(commentService.createReply(commentPublicId, locale, request, principal));
    }

    // =========== Comment Actions ===========

    /**
     * Edit a comment (owner only)
     * PUT /api/v1/comments/{commentId}
     */
    @PutMapping("/api/v1/comments/{commentId}")
    public ResponseEntity<CommentResponseDto> editComment(
            @PathVariable("commentId") UUID commentPublicId,
            @RequestHeader(value = "Accept-Language", defaultValue = "en") String locale,
            @Valid @RequestBody CreateCommentRequestDto request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(commentService.editComment(commentPublicId, locale, request, principal.getId()));
    }

    /**
     * Delete a comment (owner only, soft delete)
     * DELETE /api/v1/comments/{commentId}
     */
    @DeleteMapping("/api/v1/comments/{commentId}")
    public ResponseEntity<Void> deleteComment(
            @PathVariable("commentId") UUID commentPublicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        commentService.deleteComment(commentPublicId, principal.getId());
        return ResponseEntity.noContent().build();
    }

    // =========== Likes ===========

    /**
     * Like a comment
     * POST /api/v1/comments/{commentId}/like
     */
    @PostMapping("/api/v1/comments/{commentId}/like")
    public ResponseEntity<Void> likeComment(
            @PathVariable("commentId") UUID commentPublicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        commentService.likeComment(commentPublicId, principal.getId());
        return ResponseEntity.ok().build();
    }

    /**
     * Unlike a comment
     * DELETE /api/v1/comments/{commentId}/like
     */
    @DeleteMapping("/api/v1/comments/{commentId}/like")
    public ResponseEntity<Void> unlikeComment(
            @PathVariable("commentId") UUID commentPublicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        commentService.unlikeComment(commentPublicId, principal.getId());
        return ResponseEntity.ok().build();
    }
}
