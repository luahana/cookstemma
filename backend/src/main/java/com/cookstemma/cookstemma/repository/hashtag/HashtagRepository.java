package com.cookstemma.cookstemma.repository.hashtag;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface HashtagRepository extends JpaRepository<Hashtag, Long> {
    Optional<Hashtag> findByName(String name);

    // 이름 리스트로 한꺼번에 조회
    List<Hashtag> findByNameIn(List<String> names);

    // 자동완성용 검색 (대소문자 무시)
    List<Hashtag> findByNameContainingIgnoreCase(String name);

    // ==================== UNIFIED SEARCH QUERIES ====================

    /**
     * Search hashtags with fuzzy matching and relevance scoring.
     * Returns hashtags ordered by relevance (exact match > prefix > fuzzy).
     */
    @Query(value = """
        SELECT h.*,
            CASE
                WHEN LOWER(h.name) = LOWER(:keyword) THEN 1.0
                WHEN LOWER(h.name) LIKE LOWER(:keyword) || '%' THEN 0.9
                ELSE COALESCE(SIMILARITY(h.name, :keyword), 0) * 0.8
            END AS relevance_score
        FROM hashtags h
        WHERE h.name % :keyword
           OR LOWER(h.name) LIKE '%' || LOWER(:keyword) || '%'
        ORDER BY relevance_score DESC, h.name ASC
        """,
        countQuery = """
        SELECT COUNT(*) FROM hashtags h
        WHERE h.name % :keyword
           OR LOWER(h.name) LIKE '%' || LOWER(:keyword) || '%'
        """,
        nativeQuery = true)
    Page<Hashtag> searchHashtagsWithRelevance(@Param("keyword") String keyword, Pageable pageable);

    /**
     * Count hashtags matching search keyword.
     */
    @Query(value = """
        SELECT COUNT(*) FROM hashtags h
        WHERE h.name % :keyword
           OR LOWER(h.name) LIKE '%' || LOWER(:keyword) || '%'
        """,
        nativeQuery = true)
    long countSearchResults(@Param("keyword") String keyword);

    /**
     * Get recipe count for a specific hashtag.
     */
    @Query("SELECT COUNT(r) FROM Recipe r JOIN r.hashtags h " +
           "WHERE h.id = :hashtagId AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false)")
    int countRecipesByHashtagId(@Param("hashtagId") Long hashtagId);

    /**
     * Get log count for a specific hashtag.
     */
    @Query("SELECT COUNT(l) FROM LogPost l JOIN l.hashtags h " +
           "WHERE h.id = :hashtagId AND l.deletedAt IS NULL AND (l.isPrivate IS NULL OR l.isPrivate = false)")
    int countLogsByHashtagId(@Param("hashtagId") Long hashtagId);

    /**
     * Get sample thumbnail URLs from recipes using this hashtag (limit 4).
     */
    @Query(value = """
        SELECT DISTINCT img.stored_filename
        FROM recipe_hashtag_map rhm
        JOIN recipes r ON r.id = rhm.recipe_id
        JOIN images img ON img.recipe_id = r.id AND img.type = 'COVER'
        WHERE rhm.hashtag_id = :hashtagId
        AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        LIMIT 4
        """,
        nativeQuery = true)
    List<String> findSampleThumbnails(@Param("hashtagId") Long hashtagId);

    /**
     * Get top contributors (users with most content using this hashtag).
     * Returns Object[] with [publicId, username, profileImageUrl, contentCount].
     */
    @Query(value = """
        SELECT u.public_id, u.username, u.profile_image_url, COUNT(*) as content_count
        FROM (
            SELECT r.creator_id FROM recipes r
            JOIN recipe_hashtag_map rhm ON rhm.recipe_id = r.id
            WHERE rhm.hashtag_id = :hashtagId AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
            UNION ALL
            SELECT lp.creator_id FROM log_posts lp
            JOIN log_post_hashtag_map lphm ON lphm.log_post_id = lp.id
            WHERE lphm.hashtag_id = :hashtagId AND lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
        ) content
        JOIN users u ON u.id = content.creator_id
        GROUP BY u.id, u.public_id, u.username, u.profile_image_url
        ORDER BY content_count DESC
        LIMIT 3
        """,
        nativeQuery = true)
    List<Object[]> findTopContributors(@Param("hashtagId") Long hashtagId);

    // ==================== BATCH METHODS FOR SEARCH PERFORMANCE ====================

    /**
     * Get recipe counts for multiple hashtag IDs in a single query.
     * Returns List of [hashtagId, count] pairs.
     */
    @Query("SELECT h.id, COUNT(r) FROM Recipe r JOIN r.hashtags h " +
           "WHERE h.id IN :hashtagIds AND r.deletedAt IS NULL AND (r.isPrivate IS NULL OR r.isPrivate = false) " +
           "GROUP BY h.id")
    List<Object[]> countRecipesByHashtagIds(@Param("hashtagIds") List<Long> hashtagIds);

    /**
     * Get log counts for multiple hashtag IDs in a single query.
     * Returns List of [hashtagId, count] pairs.
     */
    @Query("SELECT h.id, COUNT(l) FROM LogPost l JOIN l.hashtags h " +
           "WHERE h.id IN :hashtagIds AND l.deletedAt IS NULL AND (l.isPrivate IS NULL OR l.isPrivate = false) " +
           "GROUP BY h.id")
    List<Object[]> countLogsByHashtagIds(@Param("hashtagIds") List<Long> hashtagIds);

    /**
     * Get sample thumbnails for multiple hashtag IDs in a single query.
     * Returns List of [hashtagId, storedFilename] pairs.
     * Note: Uses a subquery with row_number to limit to 4 per hashtag.
     */
    @Query(value = """
        SELECT ranked.hashtag_id, ranked.stored_filename
        FROM (
            SELECT rhm.hashtag_id, img.stored_filename,
                   ROW_NUMBER() OVER (PARTITION BY rhm.hashtag_id ORDER BY r.created_at DESC) as rn
            FROM recipe_hashtag_map rhm
            JOIN recipes r ON r.id = rhm.recipe_id
            JOIN images img ON img.recipe_id = r.id AND img.type = 'COVER'
            WHERE rhm.hashtag_id IN :hashtagIds
            AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
        ) ranked
        WHERE ranked.rn <= 4
        """,
        nativeQuery = true)
    List<Object[]> findSampleThumbnailsByHashtagIds(@Param("hashtagIds") List<Long> hashtagIds);

    /**
     * Get top contributors for multiple hashtag IDs in a single query.
     * Returns List of [hashtagId, publicId, username, profileImageUrl] (top 3 per hashtag).
     */
    @Query(value = """
        SELECT ranked.hashtag_id, ranked.public_id, ranked.username, ranked.profile_image_url
        FROM (
            SELECT content.hashtag_id, u.public_id, u.username, u.profile_image_url,
                   COUNT(*) as content_count,
                   ROW_NUMBER() OVER (PARTITION BY content.hashtag_id ORDER BY COUNT(*) DESC) as rn
            FROM (
                SELECT rhm.hashtag_id, r.creator_id FROM recipes r
                JOIN recipe_hashtag_map rhm ON rhm.recipe_id = r.id
                WHERE rhm.hashtag_id IN :hashtagIds AND r.deleted_at IS NULL AND (r.is_private IS NULL OR r.is_private = false)
                UNION ALL
                SELECT lphm.hashtag_id, lp.creator_id FROM log_posts lp
                JOIN log_post_hashtag_map lphm ON lphm.log_post_id = lp.id
                WHERE lphm.hashtag_id IN :hashtagIds AND lp.deleted_at IS NULL AND (lp.is_private IS NULL OR lp.is_private = false)
            ) content
            JOIN users u ON u.id = content.creator_id
            GROUP BY content.hashtag_id, u.id, u.public_id, u.username, u.profile_image_url
        ) ranked
        WHERE ranked.rn <= 3
        ORDER BY ranked.hashtag_id, ranked.rn
        """,
        nativeQuery = true)
    List<Object[]> findTopContributorsByHashtagIds(@Param("hashtagIds") List<Long> hashtagIds);


    // ==================== POPULAR HASHTAGS BY LANGUAGE ====================

    /**
     * Get popular hashtags based on recipe counts filtered by original language (cooking_style).
     * Only counts recipes that were originally created in the specified language.
     * This ensures hashtags are shown in the script/language users can read.
     * Returns List of [hashtag_id, recipe_count] pairs.
     */
    @Query(value = """
        SELECT h.id, COUNT(DISTINCT r.id) as recipe_count
        FROM hashtags h
        JOIN recipe_hashtag_map rhm ON h.id = rhm.hashtag_id
        JOIN recipes r ON rhm.recipe_id = r.id
        WHERE r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND r.cooking_style LIKE :langPattern
        GROUP BY h.id
        HAVING COUNT(DISTINCT r.id) >= :minCount
        ORDER BY COUNT(DISTINCT r.id) DESC
        LIMIT :limit
        """, nativeQuery = true)
    List<Object[]> findPopularHashtagsByRecipeLanguage(
            @Param("langPattern") String langPattern,
            @Param("minCount") int minCount,
            @Param("limit") int limit);

    /**
     * Get popular hashtags based on log post counts filtered by original language (locale).
     * Only counts log posts that were originally created in the specified language.
     * Returns List of [hashtag_id, log_count] pairs.
     */
    @Query(value = """
        SELECT h.id, COUNT(DISTINCT lp.id) as log_count
        FROM hashtags h
        JOIN log_post_hashtag_map lphm ON h.id = lphm.hashtag_id
        JOIN log_posts lp ON lphm.log_post_id = lp.id
        WHERE lp.deleted_at IS NULL
        AND (lp.is_private IS NULL OR lp.is_private = false)
        AND lp.locale LIKE :langPattern
        GROUP BY h.id
        HAVING COUNT(DISTINCT lp.id) >= 1
        """, nativeQuery = true)
    List<Object[]> findPopularHashtagsByLogLanguage(@Param("langPattern") String langPattern);

    /**
     * Get recipe counts for specific hashtag IDs filtered by original language (cooking_style).
     * Returns List of [hashtag_id, count] pairs.
     */
    @Query(value = """
        SELECT h.id, COUNT(DISTINCT r.id)
        FROM hashtags h
        JOIN recipe_hashtag_map rhm ON h.id = rhm.hashtag_id
        JOIN recipes r ON rhm.recipe_id = r.id
        WHERE h.id IN :hashtagIds
        AND r.deleted_at IS NULL
        AND (r.is_private IS NULL OR r.is_private = false)
        AND r.cooking_style LIKE :langPattern
        GROUP BY h.id
        """, nativeQuery = true)
    List<Object[]> countRecipesByHashtagIdsAndLanguage(
            @Param("hashtagIds") List<Long> hashtagIds,
            @Param("langPattern") String langPattern);

    /**
     * Get log counts for specific hashtag IDs filtered by original language (locale).
     * Returns List of [hashtag_id, count] pairs.
     */
    @Query(value = """
        SELECT h.id, COUNT(DISTINCT lp.id)
        FROM hashtags h
        JOIN log_post_hashtag_map lphm ON h.id = lphm.hashtag_id
        JOIN log_posts lp ON lphm.log_post_id = lp.id
        WHERE h.id IN :hashtagIds
        AND lp.deleted_at IS NULL
        AND (lp.is_private IS NULL OR lp.is_private = false)
        AND lp.locale LIKE :langPattern
        GROUP BY h.id
        """, nativeQuery = true)
    List<Object[]> countLogsByHashtagIdsAndLanguage(
            @Param("hashtagIds") List<Long> hashtagIds,
            @Param("langPattern") String langPattern);
}
