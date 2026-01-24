package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.comment.Comment;
import com.cookstemma.cookstemma.domain.entity.comment.CommentLike;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.notification.Notification;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.NotificationType;
import com.cookstemma.cookstemma.dto.comment.CommentResponseDto;
import com.cookstemma.cookstemma.dto.comment.CommentWithRepliesDto;
import com.cookstemma.cookstemma.dto.comment.CreateCommentRequestDto;
import com.cookstemma.cookstemma.repository.comment.CommentLikeRepository;
import com.cookstemma.cookstemma.repository.comment.CommentRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.notification.NotificationRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class CommentService {

    private final CommentRepository commentRepository;
    private final CommentLikeRepository commentLikeRepository;
    private final LogPostRepository logPostRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;
    private final PushNotificationService pushNotificationService;
    private final TranslationEventService translationEventService;

    private static final int MAX_PREVIEW_REPLIES = 3;

    /**
     * Create a top-level comment on a log post
     */
    public CommentResponseDto createComment(UUID logPublicId, String locale, CreateCommentRequestDto dto, UserPrincipal principal) {
        LogPost logPost = logPostRepository.findByPublicId(logPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Log post not found"));

        if (logPost.isDeleted()) {
            throw new IllegalArgumentException("Cannot comment on a deleted log post");
        }

        User creator = userRepository.getReferenceById(principal.getId());

        Comment comment = Comment.builder()
            .logPost(logPost)
            .creator(creator)
            .content(dto.content())
            .build();

        commentRepository.save(comment);

        // Increment comment count on log post
        logPost.setCommentCount((logPost.getCommentCount() == null ? 0 : logPost.getCommentCount()) + 1);
        logPostRepository.save(logPost);

        // Send notification to log author (if not self)
        notifyCommentOnLog(logPost, comment, creator);

        // Queue translation (with content moderation in Lambda)
        translationEventService.queueCommentTranslation(comment);

        log.info("Comment created on log {} by user {}", logPublicId, principal.getId());
        return toCommentResponse(comment, locale, principal.getId());
    }

    /**
     * Create a reply to a comment
     */
    public CommentResponseDto createReply(UUID parentCommentPublicId, String locale, CreateCommentRequestDto dto, UserPrincipal principal) {
        Comment parentComment = commentRepository.findByPublicIdAndDeletedAtIsNull(parentCommentPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Parent comment not found"));

        // Only allow replies to top-level comments (single-level replies)
        if (!parentComment.isTopLevel()) {
            throw new IllegalArgumentException("Cannot reply to a reply. Only single-level replies are allowed.");
        }

        User creator = userRepository.getReferenceById(principal.getId());

        Comment reply = Comment.builder()
            .logPost(parentComment.getLogPost())
            .creator(creator)
            .parent(parentComment)
            .content(dto.content())
            .build();

        commentRepository.save(reply);

        // Increment reply count on parent comment
        parentComment.incrementReplyCount();
        commentRepository.save(parentComment);

        // Increment comment count on log post
        LogPost logPost = parentComment.getLogPost();
        logPost.setCommentCount((logPost.getCommentCount() == null ? 0 : logPost.getCommentCount()) + 1);
        logPostRepository.save(logPost);

        // Send notification to parent comment author (if not self)
        notifyCommentReply(parentComment, reply, creator);

        // Queue translation (with content moderation in Lambda)
        translationEventService.queueCommentTranslation(reply);

        log.info("Reply created to comment {} by user {}", parentCommentPublicId, principal.getId());
        return toCommentResponse(reply, locale, principal.getId());
    }

    /**
     * Get paginated top-level comments for a log post with preview replies
     */
    @Transactional(readOnly = true)
    public Page<CommentWithRepliesDto> getComments(UUID logPublicId, String locale, Pageable pageable, Long currentUserId) {
        LogPost logPost = logPostRepository.findByPublicId(logPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Log post not found"));

        Page<Comment> commentsPage = commentRepository.findTopLevelCommentsByLogPostId(logPost.getId(), pageable);

        // Get preview replies for all comments
        List<Long> commentIds = commentsPage.getContent().stream()
            .map(Comment::getId)
            .toList();

        Map<Long, List<Comment>> repliesMap = getPreviewRepliesMap(commentIds);

        // Get liked comment IDs for current user
        Set<Long> likedCommentIds = getLikedCommentIds(currentUserId, commentIds, repliesMap);

        return commentsPage.map(comment -> {
            List<Comment> replies = repliesMap.getOrDefault(comment.getId(), Collections.emptyList());
            boolean hasMoreReplies = comment.getReplyCount() > MAX_PREVIEW_REPLIES;

            List<CommentResponseDto> replyDtos = replies.stream()
                .limit(MAX_PREVIEW_REPLIES)
                .map(r -> toCommentResponse(r, locale, currentUserId, likedCommentIds))
                .toList();

            return new CommentWithRepliesDto(
                toCommentResponse(comment, locale, currentUserId, likedCommentIds),
                replyDtos,
                hasMoreReplies
            );
        });
    }

    /**
     * Get paginated replies for a comment
     */
    @Transactional(readOnly = true)
    public Page<CommentResponseDto> getReplies(UUID commentPublicId, String locale, Pageable pageable, Long currentUserId) {
        Comment parentComment = commentRepository.findByPublicIdAndDeletedAtIsNull(commentPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

        Page<Comment> repliesPage = commentRepository.findRepliesByParentId(parentComment.getId(), pageable);

        // Get liked comment IDs for current user
        List<Long> replyIds = repliesPage.getContent().stream()
            .map(Comment::getId)
            .toList();
        Set<Long> likedCommentIds = currentUserId != null
            ? commentLikeRepository.findLikedCommentIdsByUserIdAndCommentIds(currentUserId, replyIds)
            : Collections.emptySet();

        return repliesPage.map(reply -> toCommentResponse(reply, locale, currentUserId, likedCommentIds));
    }

    /**
     * Edit a comment (owner only)
     */
    public CommentResponseDto editComment(UUID commentPublicId, String locale, CreateCommentRequestDto dto, Long userId) {
        Comment comment = commentRepository.findByPublicIdAndDeletedAtIsNull(commentPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

        if (!comment.getCreator().getId().equals(userId)) {
            throw new AccessDeniedException("You can only edit your own comments");
        }

        comment.setContent(dto.content());
        comment.markAsEdited();
        commentRepository.save(comment);

        // Queue translation for updated content (hybrid SQS push)
        translationEventService.queueCommentTranslation(comment);

        log.info("Comment {} edited by user {}", commentPublicId, userId);
        return toCommentResponse(comment, locale, userId);
    }

    /**
     * Soft delete a comment (owner only)
     */
    public void deleteComment(UUID commentPublicId, Long userId) {
        Comment comment = commentRepository.findByPublicIdAndDeletedAtIsNull(commentPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

        if (!comment.getCreator().getId().equals(userId)) {
            throw new AccessDeniedException("You can only delete your own comments");
        }

        comment.softDelete();
        commentRepository.save(comment);

        // Decrement parent reply count if this is a reply
        if (!comment.isTopLevel()) {
            Comment parent = comment.getParent();
            parent.decrementReplyCount();
            commentRepository.save(parent);
        }

        // Decrement comment count on log post
        LogPost logPost = comment.getLogPost();
        logPost.setCommentCount(Math.max(0, (logPost.getCommentCount() == null ? 0 : logPost.getCommentCount()) - 1));
        logPostRepository.save(logPost);

        log.info("Comment {} deleted by user {}", commentPublicId, userId);
    }

    /**
     * Like a comment
     */
    public void likeComment(UUID commentPublicId, Long userId) {
        Comment comment = commentRepository.findByPublicIdAndDeletedAtIsNull(commentPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

        if (commentLikeRepository.existsByUserIdAndCommentId(userId, comment.getId())) {
            log.debug("User {} already liked comment {}", userId, commentPublicId);
            return;
        }

        CommentLike like = CommentLike.builder()
            .userId(userId)
            .commentId(comment.getId())
            .build();

        commentLikeRepository.save(like);

        comment.incrementLikeCount();
        commentRepository.save(comment);

        log.info("Comment {} liked by user {}", commentPublicId, userId);
    }

    /**
     * Unlike a comment
     */
    public void unlikeComment(UUID commentPublicId, Long userId) {
        Comment comment = commentRepository.findByPublicIdAndDeletedAtIsNull(commentPublicId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

        if (!commentLikeRepository.existsByUserIdAndCommentId(userId, comment.getId())) {
            log.debug("User {} has not liked comment {}", userId, commentPublicId);
            return;
        }

        commentLikeRepository.deleteByUserIdAndCommentId(userId, comment.getId());

        comment.decrementLikeCount();
        commentRepository.save(comment);

        log.info("Comment {} unliked by user {}", commentPublicId, userId);
    }

    // =========== Notification Helpers ===========

    private void notifyCommentOnLog(LogPost logPost, Comment comment, User sender) {
        Long logOwnerId = logPost.getCreatorId();

        // Don't notify yourself
        if (logOwnerId.equals(sender.getId())) {
            log.debug("Skipping self-notification for COMMENT_ON_LOG");
            return;
        }

        User recipient = userRepository.getReferenceById(logOwnerId);

        String title = "새 댓글이 달렸어요!";
        String body = String.format("%s님이 회원님의 요리 일지에 댓글을 남겼습니다.", sender.getUsername());

        Notification notification = Notification.builder()
            .recipient(recipient)
            .sender(sender)
            .type(NotificationType.COMMENT_ON_LOG)
            .logPost(logPost)
            .title(title)
            .body(body)
            .data(Map.of(
                "commentContent", truncate(comment.getContent(), 50),
                "senderName", sender.getUsername(),
                "commentPublicId", comment.getPublicId().toString()
            ))
            .build();

        notificationRepository.save(notification);
        pushNotificationService.sendToUser(logOwnerId, notification);
        log.info("Sent COMMENT_ON_LOG notification to user {} from user {}", logOwnerId, sender.getId());
    }

    private void notifyCommentReply(Comment parentComment, Comment reply, User sender) {
        Long parentAuthorId = parentComment.getCreator().getId();

        // Don't notify yourself
        if (parentAuthorId.equals(sender.getId())) {
            log.debug("Skipping self-notification for COMMENT_REPLY");
            return;
        }

        User recipient = parentComment.getCreator();

        String title = "댓글에 답글이 달렸어요!";
        String body = String.format("%s님이 회원님의 댓글에 답글을 남겼습니다.", sender.getUsername());

        Notification notification = Notification.builder()
            .recipient(recipient)
            .sender(sender)
            .type(NotificationType.COMMENT_REPLY)
            .logPost(parentComment.getLogPost())
            .title(title)
            .body(body)
            .data(Map.of(
                "replyContent", truncate(reply.getContent(), 50),
                "senderName", sender.getUsername(),
                "commentPublicId", reply.getPublicId().toString(),
                "parentCommentPublicId", parentComment.getPublicId().toString()
            ))
            .build();

        notificationRepository.save(notification);
        pushNotificationService.sendToUser(parentAuthorId, notification);
        log.info("Sent COMMENT_REPLY notification to user {} from user {}", parentAuthorId, sender.getId());
    }

    // =========== Conversion Helpers ===========

    private Map<Long, List<Comment>> getPreviewRepliesMap(List<Long> parentIds) {
        if (parentIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Comment> allReplies = commentRepository.findPreviewRepliesByParentIds(parentIds);
        return allReplies.stream()
            .collect(Collectors.groupingBy(r -> r.getParent().getId()));
    }

    private Set<Long> getLikedCommentIds(Long currentUserId, List<Long> commentIds, Map<Long, List<Comment>> repliesMap) {
        if (currentUserId == null) {
            return Collections.emptySet();
        }

        List<Long> allCommentIds = new ArrayList<>(commentIds);
        repliesMap.values().forEach(replies ->
            allCommentIds.addAll(replies.stream().map(Comment::getId).toList())
        );

        if (allCommentIds.isEmpty()) {
            return Collections.emptySet();
        }

        return commentLikeRepository.findLikedCommentIdsByUserIdAndCommentIds(currentUserId, allCommentIds);
    }

    private CommentResponseDto toCommentResponse(Comment comment, String locale, Long currentUserId) {
        boolean isLiked = currentUserId != null &&
            commentLikeRepository.existsByUserIdAndCommentId(currentUserId, comment.getId());
        return toCommentResponseInternal(comment, locale, currentUserId, currentUserId != null ? isLiked : null);
    }

    private CommentResponseDto toCommentResponse(Comment comment, String locale, Long currentUserId, Set<Long> likedCommentIds) {
        Boolean isLiked = currentUserId != null ? likedCommentIds.contains(comment.getId()) : null;
        return toCommentResponseInternal(comment, locale, currentUserId, isLiked);
    }

    private CommentResponseDto toCommentResponseInternal(Comment comment, String locale, Long currentUserId, Boolean isLiked) {
        User creator = comment.getCreator();

        // For deleted comments, always hide content
        // For hidden comments, show content only to the creator
        boolean isCreator = currentUserId != null && currentUserId.equals(creator.getId());
        String content;
        if (comment.isDeleted()) {
            content = null;
        } else if (comment.isHidden() && !isCreator) {
            content = null;
        } else {
            content = LocaleUtils.getLocalizedValue(
                comment.getContentTranslations(), locale, comment.getContent());
        }

        return new CommentResponseDto(
            comment.getPublicId(),
            content,
            creator.getPublicId(),
            creator.getUsername(),
            creator.getProfileImageUrl(),
            comment.getReplyCount(),
            comment.getLikeCount(),
            isLiked,
            comment.isEdited(),
            comment.isDeleted(),
            comment.isHidden(),
            comment.getCreatedAt()
        );
    }

    private String truncate(String text, int maxLength) {
        if (text == null) return "";
        if (text.length() <= maxLength) return text;
        return text.substring(0, maxLength - 3) + "...";
    }
}
