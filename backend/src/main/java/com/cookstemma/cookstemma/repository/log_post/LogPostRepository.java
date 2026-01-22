package com.cookstemma.cookstemma.repository.log_post;

import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
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

public interface LogPostRepository extends JpaRepository<LogPost, Long> {
    // 1. 상세 조회
    @EntityGraph(attributePaths = {"hashtags", "recipeLog", "recipeLog.recipe"})
    Optional<LogPost> findByPublicId(UUID publicId);

    // 2. 내 로그 목록 (최신순)
    Slice<LogPost> findByCreatorIdAndDeletedAtIsNullOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // 2-0. 내 로그 목록 with visibility filter (최신순)
    Slice<LogPost> findByCreatorIdAndDeletedAtIsNullAndIsPrivateOrderByCreatedAtDesc(Long creatorId, Boolean isPrivate, Pageable pageable);

    // 2-1. 내 로그 목록 (rating 범위 필터링)
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :creatorId
        AND lp.deleted_at IS NULL
        AND rl.rating BETWEEN :minRating AND :maxRating
        ORDER BY lp.created_at DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findByCreatorIdAndRatingBetween(
            @Param("creatorId") Long creatorId,
            @Param("minRating") Integer minRating,
            @Param("maxRating") Integer maxRating,
            Pageable pageable);

    // 3. 특정 지역/언어 기반 최신 로그 피드
    Slice<LogPost> findByLocaleAndDeletedAtIsNullAndIsPrivateFalseOrderByCreatedAtDesc(String locale, Pageable pageable);

    @Query("SELECT l FROM LogPost l WHERE l.deletedAt IS NULL AND (l.isPrivate IS NULL OR l.isPrivate = false) ORDER BY l.createdAt DESC")
    Slice<LogPost> findAllOrderByCreatedAtDesc(Pageable pageable);

    // Filter by rating range
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.deleted_at IS NULL
        AND (lp.is_private IS NULL OR lp.is_private = false)
        AND rl.rating BETWEEN :minRating AND :maxRating
        ORDER BY lp.created_at DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findByRatingBetween(@Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, Pageable pageable);

    // 4. 사용자의 로그 개수 (삭제되지 않은 것만)
    long countByCreatorIdAndDeletedAtIsNull(Long creatorId);

    // [검색] pg_trgm 기반 로그 검색 (제목, 내용, 연결된 레시피명, 번역 필드 포함)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT DISTINCT lp.* FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND (
            -- Base fields
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            -- Title translations
            OR jsonb_values_text(lp.title_translations) ILIKE '%' || :keyword || '%'
            -- Content translations
            OR jsonb_values_text(lp.content_translations) ILIKE '%' || :keyword || '%'
            -- Linked recipe title (base + translations)
            OR r.title ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
        )
        ORDER BY lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(DISTINCT lp.id) FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND (
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(lp.title_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(lp.content_translations) ILIKE '%' || :keyword || '%'
            OR r.title ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    Slice<LogPost> searchLogPosts(@Param("keyword") String keyword, @Param("langCode") String langCode, Pageable pageable);

    // ==================== CURSOR-BASED PAGINATION ====================

    // [Cursor] All logs - initial page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        ORDER BY lp.created_at DESC, lp.id DESC
        """, nativeQuery = true)
    Slice<LogPost> findAllLogsWithCursorInitial(@Param("langCode") String langCode, Pageable pageable);

    // [Cursor] All logs - with cursor
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND (lp.created_at < :cursorTime OR (lp.created_at = :cursorTime AND lp.id < :cursorId))
        ORDER BY lp.created_at DESC, lp.id DESC
        """, nativeQuery = true)
    Slice<LogPost> findAllLogsWithCursor(@Param("langCode") String langCode, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] Logs by rating range - initial page (native query for JOIN)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND rl.rating BETWEEN :minRating AND :maxRating
        ORDER BY lp.created_at DESC, lp.id DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findByRatingWithCursorInitial(@Param("langCode") String langCode, @Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, Pageable pageable);

    // [Cursor] Logs by rating range - with cursor (native query for JOIN)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND rl.rating BETWEEN :minRating AND :maxRating
        AND (lp.created_at < :cursorTime OR (lp.created_at = :cursorTime AND lp.id < :cursorId))
        ORDER BY lp.created_at DESC, lp.id DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findByRatingWithCursor(@Param("langCode") String langCode, @Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] My logs - initial page
    @Query("SELECT l FROM LogPost l WHERE l.creatorId = :creatorId AND l.deletedAt IS NULL ORDER BY l.createdAt DESC, l.id DESC")
    Slice<LogPost> findMyLogsWithCursorInitial(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Cursor] My logs - with cursor
    @Query("SELECT l FROM LogPost l WHERE l.creatorId = :creatorId AND l.deletedAt IS NULL " +
           "AND (l.createdAt < :cursorTime OR (l.createdAt = :cursorTime AND l.id < :cursorId)) " +
           "ORDER BY l.createdAt DESC, l.id DESC")
    Slice<LogPost> findMyLogsWithCursor(@Param("creatorId") Long creatorId, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // [Cursor] My logs by rating - initial page (native query for JOIN)
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :creatorId
        AND lp.deleted_at IS NULL
        AND rl.rating BETWEEN :minRating AND :maxRating
        ORDER BY lp.created_at DESC, lp.id DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findMyLogsByRatingWithCursorInitial(@Param("creatorId") Long creatorId, @Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, Pageable pageable);

    // [Cursor] My logs by rating - with cursor (native query for JOIN)
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :creatorId
        AND lp.deleted_at IS NULL
        AND rl.rating BETWEEN :minRating AND :maxRating
        AND (lp.created_at < :cursorTime OR (lp.created_at = :cursorTime AND lp.id < :cursorId))
        ORDER BY lp.created_at DESC, lp.id DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findMyLogsByRatingWithCursor(@Param("creatorId") Long creatorId, @Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, @Param("cursorTime") Instant cursorTime, @Param("cursorId") Long cursorId, Pageable pageable);

    // ==================== OFFSET-BASED PAGINATION (for Web) ====================

    // [Offset] All logs - page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        ORDER BY lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        """,
        nativeQuery = true)
    Page<LogPost> findAllLogsPage(@Param("langCode") String langCode, Pageable pageable);

    // [Offset] All logs ordered by popularity score
    // Score = viewCount + savedCount * 5
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        ORDER BY (COALESCE(lp.view_count, 0) + COALESCE(lp.saved_count, 0) * 5) DESC, lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        """,
        nativeQuery = true)
    Page<LogPost> findAllLogsOrderByPopular(@Param("langCode") String langCode, Pageable pageable);

    // [Offset] All logs ordered by trending (engagement with time decay)
    // Score = (viewCount + savedCount * 5) / (1 + days_since_creation / 7)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        ORDER BY ((COALESCE(lp.view_count, 0) + COALESCE(lp.saved_count, 0) * 5)::float / (1.0 + EXTRACT(EPOCH FROM (NOW() - lp.created_at)) / 604800.0)) DESC,
                 lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM log_posts lp
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        """,
        nativeQuery = true)
    Page<LogPost> findAllLogsOrderByTrending(@Param("langCode") String langCode, Pageable pageable);

    // [Offset] Logs by rating range - page (native query for JOIN)
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND rl.rating BETWEEN :minRating AND :maxRating
        """,
        countQuery = """
        SELECT COUNT(lp.id) FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND rl.rating BETWEEN :minRating AND :maxRating
        """,
        nativeQuery = true)
    Page<LogPost> findByRatingPage(@Param("langCode") String langCode, @Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, Pageable pageable);

    // [Offset] My logs - page
    @Query("SELECT l FROM LogPost l WHERE l.creatorId = :creatorId AND l.deletedAt IS NULL")
    Page<LogPost> findMyLogsPage(@Param("creatorId") Long creatorId, Pageable pageable);

    // [Offset] My logs by rating - page (native query for JOIN)
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :creatorId
        AND lp.deleted_at IS NULL
        AND rl.rating BETWEEN :minRating AND :maxRating
        """,
        countQuery = """
        SELECT COUNT(lp.id) FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :creatorId
        AND lp.deleted_at IS NULL
        AND rl.rating BETWEEN :minRating AND :maxRating
        """,
        nativeQuery = true)
    Page<LogPost> findMyLogsByRatingPage(@Param("creatorId") Long creatorId, @Param("minRating") Integer minRating, @Param("maxRating") Integer maxRating, Pageable pageable);

    // [Offset] Search logs - page (multi-language)
    // Filters by translation availability
    @Query(value = """
        SELECT DISTINCT lp.* FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND jsonb_exists(lp.title_translations, :langCode)
        AND (
            -- Base fields
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            -- Title translations
            OR jsonb_values_text(lp.title_translations) ILIKE '%' || :keyword || '%'
            -- Content translations
            OR jsonb_values_text(lp.content_translations) ILIKE '%' || :keyword || '%'
            -- Linked recipe title (base + translations)
            OR r.title ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
        )
        ORDER BY lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(DISTINCT lp.id) FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND jsonb_exists(lp.title_translations, :langCode)
        AND (
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(lp.title_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(lp.content_translations) ILIKE '%' || :keyword || '%'
            OR r.title ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    Page<LogPost> searchLogPostsPage(@Param("keyword") String keyword, @Param("langCode") String langCode, Pageable pageable);

    // ==================== HASHTAG-BASED QUERIES ====================

    // [Cursor] LogPosts by hashtag - initial page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN log_post_hashtags lph ON lph.log_post_id = lp.id
        JOIN hashtags h ON h.id = lph.hashtag_id
        WHERE h.name = :hashtagName AND lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        ORDER BY lp.created_at DESC, lp.id DESC
        """, nativeQuery = true)
    Slice<LogPost> findByHashtagWithCursorInitial(
            @Param("hashtagName") String hashtagName,
            @Param("langCode") String langCode,
            Pageable pageable);

    // [Cursor] LogPosts by hashtag - with cursor
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN log_post_hashtags lph ON lph.log_post_id = lp.id
        JOIN hashtags h ON h.id = lph.hashtag_id
        WHERE h.name = :hashtagName AND lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        AND (lp.created_at < :cursorTime OR (lp.created_at = :cursorTime AND lp.id < :cursorId))
        ORDER BY lp.created_at DESC, lp.id DESC
        """, nativeQuery = true)
    Slice<LogPost> findByHashtagWithCursor(
            @Param("hashtagName") String hashtagName,
            @Param("langCode") String langCode,
            @Param("cursorTime") Instant cursorTime,
            @Param("cursorId") Long cursorId,
            Pageable pageable);

    // [Offset] LogPosts by hashtag - page
    // Filters by translation availability: source locale matches OR translation exists
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN log_post_hashtags lph ON lph.log_post_id = lp.id
        JOIN hashtags h ON h.id = lph.hashtag_id
        WHERE h.name = :hashtagName AND lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        """,
        countQuery = """
        SELECT COUNT(lp.id) FROM log_posts lp
        JOIN log_post_hashtags lph ON lph.log_post_id = lp.id
        JOIN hashtags h ON h.id = lph.hashtag_id
        WHERE h.name = :hashtagName AND lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND (SUBSTRING(lp.locale FROM 1 FOR 2) = :langCode
             OR jsonb_exists(lp.title_translations, :langCode))
        """,
        nativeQuery = true)
    Page<LogPost> findByHashtagPage(
            @Param("hashtagName") String hashtagName,
            @Param("langCode") String langCode,
            Pageable pageable);

    // Count log posts by hashtag (unfiltered - for hashtag display purposes)
    @Query("SELECT COUNT(l) FROM LogPost l JOIN l.hashtags h " +
           "WHERE h.name = :hashtagName AND l.deletedAt IS NULL AND (l.isPrivate IS NULL OR l.isPrivate = false)")
    long countByHashtag(@Param("hashtagName") String hashtagName);

    // ==================== UNIFIED SEARCH COUNT ====================

    /**
     * Count log posts matching search keyword (for unified search chips, multi-language).
     * Filters by translation availability to match actual search results.
     */
    @Query(value = """
        SELECT COUNT(DISTINCT lp.id) FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        AND jsonb_exists(lp.title_translations, :langCode)
        AND (
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(lp.title_translations) ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(lp.content_translations) ILIKE '%' || :keyword || '%'
            OR r.title ILIKE '%' || :keyword || '%'
            OR jsonb_values_text(r.title_translations) ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    long countSearchResults(@Param("keyword") String keyword, @Param("langCode") String langCode);

    // ==================== ADMIN: UNTRANSLATED CONTENT ====================

    /**
     * Find log posts with incomplete translations (fewer than 19 locales in title_translations).
     * Returns log posts ordered by creation date descending.
     */
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL
        AND (lp.title_translations IS NULL
             OR jsonb_typeof(lp.title_translations) != 'object'
             OR (SELECT COUNT(*) FROM jsonb_object_keys(COALESCE(lp.title_translations, '{}'::jsonb))) < 19)
        ORDER BY lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM log_posts lp
        WHERE lp.deleted_at IS NULL
        AND (lp.title_translations IS NULL
             OR jsonb_typeof(lp.title_translations) != 'object'
             OR (SELECT COUNT(*) FROM jsonb_object_keys(COALESCE(lp.title_translations, '{}'::jsonb))) < 19)
        """,
        nativeQuery = true)
    Page<LogPost> findUntranslatedLogPosts(Pageable pageable);

    /**
     * Find log posts with incomplete translations filtered by content.
     */
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        WHERE lp.deleted_at IS NULL
        AND (lp.title_translations IS NULL
             OR jsonb_typeof(lp.title_translations) != 'object'
             OR (SELECT COUNT(*) FROM jsonb_object_keys(COALESCE(lp.title_translations, '{}'::jsonb))) < 19)
        AND (lp.content ILIKE '%' || :content || '%' OR lp.title ILIKE '%' || :content || '%')
        ORDER BY lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(*) FROM log_posts lp
        WHERE lp.deleted_at IS NULL
        AND (lp.title_translations IS NULL
             OR jsonb_typeof(lp.title_translations) != 'object'
             OR (SELECT COUNT(*) FROM jsonb_object_keys(COALESCE(lp.title_translations, '{}'::jsonb))) < 19)
        AND (lp.content ILIKE '%' || :content || '%' OR lp.title ILIKE '%' || :content || '%')
        """,
        nativeQuery = true)
    Page<LogPost> findUntranslatedLogPostsByContent(@Param("content") String content, Pageable pageable);
}