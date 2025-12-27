package com.pairingplanet.pairing_planet.repository.post;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, Long> {

    Optional<Post> findByPublicId(UUID publicId);

    // 1. 첫 페이지 (커서 없음)
    @Query("""
        SELECT p FROM Post p 
        JOIN FETCH p.pairing pm
        JOIN FETCH pm.food1
        LEFT JOIN FETCH pm.food2
        WHERE p.creator.id = :userId 
          AND p.isDeleted = false 
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findMyPostsFirstPage(@Param("userId") Long userId, Pageable pageable);

    // 2. 두 번째 페이지부터 (커서 있음)
    // 커서 조건: (createdAt < cursorTime) OR (createdAt = cursorTime AND id < cursorId)
    @Query("""
        SELECT p FROM Post p 
        JOIN FETCH p.pairing pm
        JOIN FETCH pm.food1
        LEFT JOIN FETCH pm.food2
        WHERE p.creator.id = :userId 
          AND p.isDeleted = false
          AND (p.createdAt < :cursorTime OR (p.createdAt = :cursorTime AND p.id < :cursorId))
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findMyPostsWithCursor(@Param("userId") Long userId,
                                      @Param("cursorTime") Instant cursorTime,
                                      @Param("cursorId") Long cursorId,
                                      Pageable pageable);

    // 1. 첫 페이지 (커서 없음)
    @Query("""
        SELECT p FROM Post p 
        JOIN FETCH p.pairing pm
        JOIN FETCH pm.food1
        LEFT JOIN FETCH pm.food2
        WHERE p.creator.id = :targetUserId 
          AND p.isDeleted = false 
          AND p.isPrivate = false  
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findPublicPostsByCreatorFirstPage(@Param("targetUserId") Long targetUserId, Pageable pageable);

    // 2. 두 번째 페이지부터 (커서 있음)
    @Query("""
        SELECT p FROM Post p 
        JOIN FETCH p.pairing pm
        JOIN FETCH pm.food1
        LEFT JOIN FETCH pm.food2
        WHERE p.creator.id = :targetUserId 
          AND p.isDeleted = false
          AND p.isPrivate = false  
          AND (p.createdAt < :cursorTime OR (p.createdAt = :cursorTime AND p.id < :cursorId))
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findPublicPostsByCreatorWithCursor(@Param("targetUserId") Long targetUserId,
                                                   @Param("cursorTime") Instant cursorTime,
                                                   @Param("cursorId") Long cursorId,
                                                   Pageable pageable);

    // 0. Fresh (최신글) - Cursor: createdAt, id
    @Query("""
        SELECT p FROM Post p 
        WHERE p.locale = :locale 
          AND p.isDeleted = false
          AND p.isPrivate = false
          AND (p.createdAt < :lastTime OR (p.createdAt = :lastTime AND p.id < :lastId))
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findFresh(@Param("locale") String locale,
                          @Param("lastId") Long lastId,
                          @Param("lastTime") Instant lastTime,
                          Pageable pageable);

    // 1. Popular Only - Cursor: popularityScore, id
    @Query("""
        SELECT p FROM Post p 
        WHERE p.locale = :locale 
          AND p.isDeleted = false
          AND p.isPrivate = false
          AND (p.popularityScore < :lastScore OR (p.popularityScore = :lastScore AND p.id < :lastId))
        ORDER BY p.popularityScore DESC, p.id DESC
    """)
    Slice<Post> findPopularOnly(@Param("locale") String locale,
                                @Param("lastId") Long lastId,
                                @Param("lastScore") Double lastScore,
                                Pageable pageable);

    // 2. Controversial Only - Cursor: controversyScore, id
    @Query("""
        SELECT p FROM Post p 
        WHERE p.locale = :locale 
          AND p.isDeleted = false
          AND p.isPrivate = false
          AND (p.controversyScore < :lastScore OR (p.controversyScore = :lastScore AND p.id < :lastId))
        ORDER BY p.controversyScore DESC, p.id DESC
    """)
    Slice<Post> findControversialOnly(@Param("locale") String locale,
                                      @Param("lastId") Long lastId,
                                      @Param("lastScore") Double lastScore,
                                      Pageable pageable);

    // 3. Trending Only - Cursor: CalculatedScore, createdAt (Secondary), id (Tertiary)
    // 정렬 기준: (comment*3 + saved*5) DESC, createdAt DESC
    @Query("""
        SELECT p FROM Post p 
        WHERE p.locale = :locale 
          AND p.isDeleted = false
          AND p.isPrivate = false
          AND p.popularityScore < :popThreshold 
          AND p.createdAt >= :afterTime
          AND (
              ((p.commentCount * 3.0 + p.savedCount * 5.0) < :lastScore)
              OR 
              ((p.commentCount * 3.0 + p.savedCount * 5.0) = :lastScore AND p.createdAt < :lastTime)
              OR
              ((p.commentCount * 3.0 + p.savedCount * 5.0) = :lastScore AND p.createdAt = :lastTime AND p.id < :lastId)
          )
        ORDER BY (p.commentCount * 3.0 + p.savedCount * 5.0) DESC, p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findTrendingOnly(
            @Param("locale") String locale,
            @Param("popThreshold") double popThreshold,
            @Param("afterTime") Instant afterTime,
            @Param("lastId") Long lastId,
            @Param("lastScore") Double lastScore,
            @Param("lastTime") Instant lastTime,
            Pageable pageable
    );

    // 4. Popular & Trending - Cursor: popularityScore, id
    @Query("""
        SELECT p FROM Post p 
        WHERE p.locale = :locale 
          AND p.isDeleted = false
          AND p.isPrivate = false
          AND p.popularityScore >= :popThreshold 
          AND p.createdAt >= :afterTime
          AND (p.popularityScore < :lastScore OR (p.popularityScore = :lastScore AND p.id < :lastId))
        ORDER BY p.popularityScore DESC, p.id DESC
    """)
    Slice<Post> findPopularAndTrending(
            @Param("locale") String locale,
            @Param("popThreshold") double popThreshold,
            @Param("afterTime") Instant afterTime,
            @Param("lastId") Long lastId,
            @Param("lastScore") Double lastScore,
            Pageable pageable
    );

    // 5. Trending & Controversial - Cursor: commentCount, id
    // 정렬 기준: commentCount DESC
    @Query("""
        SELECT p FROM Post p 
        WHERE p.locale = :locale 
          AND p.isDeleted = false
          AND p.isPrivate = false
          AND p.controversyScore >= :contThreshold 
          AND p.createdAt >= :afterTime
          AND (p.commentCount < :lastCount OR (p.commentCount = :lastCount AND p.id < :lastId))
        ORDER BY p.commentCount DESC, p.id DESC
    """)
    Slice<Post> findTrendingAndControversial(
            @Param("locale") String locale,
            @Param("contThreshold") double contThreshold,
            @Param("afterTime") Instant afterTime,
            @Param("lastId") Long lastId,
            @Param("lastCount") Integer lastCount,
            Pageable pageable
    );

    // Fallback (Native Query) - 여기는 간단히 id cursor로만 예시 처리 (필요시 수정)
    @Query(value = """
        SELECT * FROM posts p
        WHERE p.content ILIKE %:keyword%
        AND p.locale = :locale
        AND p.is_deleted = false
        AND p.is_private = false -- Fixed snake_case/camelCase mismatch if needed, check DB column name
        AND (
            p.popularity_score < :lastScore
            OR (p.popularity_score = :lastScore AND p.created_at <= :lastCreatedAt)
        )
        ORDER BY p.popularity_score DESC, p.created_at DESC
        LIMIT :limit
        """, nativeQuery = true)
    List<Post> searchByContentNative(@Param("keyword") String keyword,
                                     @Param("locale") String locale,
                                     @Param("lastScore") Double lastScore,
                                     @Param("lastCreatedAt") Instant lastCreatedAt, // Guaranteed safe by Service
                                     @Param("limit") int limit);

    @Query("SELECT p FROM Post p WHERE p.isDeleted = false AND p.isPrivate = false ORDER BY p.createdAt DESC")
    List<Post> findAllFallback(org.springframework.data.domain.Pageable pageable);

    @Query("""
        SELECT p FROM Post p 
        JOIN FETCH p.pairing pm
        WHERE p.creator.id = :userId 
          AND p.isDeleted = false 
          AND (:type IS NULL OR TYPE(p) = :type)
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findMyPostsByTypeFirstPage(@Param("userId") Long userId,
                                           @Param("type") Class<? extends Post> type,
                                           Pageable pageable);

    // [추가] 타입별 커서 기반 조회
    @Query("""
        SELECT p FROM Post p 
        JOIN FETCH p.pairing pm
        WHERE p.creator.id = :userId 
          AND p.isDeleted = false
          AND (:type IS NULL OR TYPE(p) = :type)
          AND (p.createdAt < :cursorTime OR (p.createdAt = :cursorTime AND p.id < :cursorId))
        ORDER BY p.createdAt DESC, p.id DESC
    """)
    Slice<Post> findMyPostsByTypeWithCursor(@Param("userId") Long userId,
                                            @Param("type") Class<? extends Post> type,
                                            @Param("cursorTime") Instant cursorTime,
                                            @Param("cursorId") Long cursorId,
                                            Pageable pageable);

    // [추가] 전체 개수 조회 (요구사항 반영)
    @Query("SELECT COUNT(p) FROM Post p WHERE p.creator.id = :userId AND p.isDeleted = false AND (:type IS NULL OR TYPE(p) = :type)")
    long countMyPostsByType(@Param("userId") Long userId, @Param("type") Class<? extends Post> type);
}