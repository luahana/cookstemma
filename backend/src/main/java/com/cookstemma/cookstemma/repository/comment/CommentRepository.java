package com.cookstemma.cookstemma.repository.comment;

import com.cookstemma.cookstemma.domain.entity.comment.Comment;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    @EntityGraph(attributePaths = {"creator", "logPost"})
    Optional<Comment> findByPublicId(UUID publicId);

    @EntityGraph(attributePaths = {"creator"})
    Optional<Comment> findByPublicIdAndDeletedAtIsNull(UUID publicId);

    // Top-level comments for a log post (parent_id IS NULL)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.logPost.id = :logPostId AND c.parent IS NULL AND c.deletedAt IS NULL " +
           "ORDER BY c.createdAt DESC")
    Page<Comment> findTopLevelCommentsByLogPostId(@Param("logPostId") Long logPostId, Pageable pageable);

    // Top-level comments with cursor-based pagination (initial)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.logPost.id = :logPostId AND c.parent IS NULL AND c.deletedAt IS NULL " +
           "ORDER BY c.createdAt DESC, c.id DESC")
    Slice<Comment> findTopLevelCommentsWithCursorInitial(@Param("logPostId") Long logPostId, Pageable pageable);

    // Top-level comments with cursor-based pagination (with cursor)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.logPost.id = :logPostId AND c.parent IS NULL AND c.deletedAt IS NULL " +
           "AND (c.createdAt < :cursorTime OR (c.createdAt = :cursorTime AND c.id < :cursorId)) " +
           "ORDER BY c.createdAt DESC, c.id DESC")
    Slice<Comment> findTopLevelCommentsWithCursor(
        @Param("logPostId") Long logPostId,
        @Param("cursorTime") Instant cursorTime,
        @Param("cursorId") Long cursorId,
        Pageable pageable
    );

    // Replies to a comment (ASC order for replies)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.parent.id = :parentId AND c.deletedAt IS NULL " +
           "ORDER BY c.createdAt ASC")
    Page<Comment> findRepliesByParentId(@Param("parentId") Long parentId, Pageable pageable);

    // Replies with cursor-based pagination (initial, ASC order)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.parent.id = :parentId AND c.deletedAt IS NULL " +
           "ORDER BY c.createdAt ASC, c.id ASC")
    Slice<Comment> findRepliesWithCursorInitial(@Param("parentId") Long parentId, Pageable pageable);

    // Replies with cursor-based pagination (with cursor, ASC order)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.parent.id = :parentId AND c.deletedAt IS NULL " +
           "AND (c.createdAt > :cursorTime OR (c.createdAt = :cursorTime AND c.id > :cursorId)) " +
           "ORDER BY c.createdAt ASC, c.id ASC")
    Slice<Comment> findRepliesWithCursor(
        @Param("parentId") Long parentId,
        @Param("cursorTime") Instant cursorTime,
        @Param("cursorId") Long cursorId,
        Pageable pageable
    );

    // First N replies for each top-level comment (for preview)
    @Query("SELECT c FROM Comment c " +
           "JOIN FETCH c.creator " +
           "WHERE c.parent.id IN :parentIds AND c.deletedAt IS NULL " +
           "ORDER BY c.createdAt ASC")
    List<Comment> findPreviewRepliesByParentIds(@Param("parentIds") List<Long> parentIds);

    // Count active comments for a log post
    long countByLogPostIdAndDeletedAtIsNull(Long logPostId);

    // Count replies for a comment
    long countByParentIdAndDeletedAtIsNull(Long parentId);

    // Check if user has commented on a log post
    boolean existsByLogPostIdAndCreatorIdAndDeletedAtIsNull(Long logPostId, Long creatorId);
}
