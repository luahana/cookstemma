package com.pairingplanet.pairing_planet.repository.log_post;

import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface LogPostRepository extends JpaRepository<LogPost, Long> {
    // 1. 상세 조회
    @EntityGraph(attributePaths = {"hashtags", "recipeLog", "recipeLog.recipe"})
    Optional<LogPost> findByPublicId(UUID publicId);

    // 2. 내 로그 목록 (최신순)
    Slice<LogPost> findByCreatorIdAndIsDeletedFalseOrderByCreatedAtDesc(Long creatorId, Pageable pageable);

    // 2-1. 내 로그 목록 (outcome 필터링)
    @Query(value = """
        SELECT lp.* FROM log_posts lp
        JOIN recipe_logs rl ON rl.log_post_id = lp.id
        WHERE lp.creator_id = :creatorId
        AND lp.is_deleted = false
        AND rl.outcome = :outcome
        ORDER BY lp.created_at DESC
        """,
        nativeQuery = true)
    Slice<LogPost> findByCreatorIdAndOutcome(
            @Param("creatorId") Long creatorId,
            @Param("outcome") String outcome,
            Pageable pageable);

    // 3. 특정 지역/언어 기반 최신 로그 피드
    Slice<LogPost> findByLocaleAndIsDeletedFalseAndIsPrivateFalseOrderByCreatedAtDesc(String locale, Pageable pageable);

    @Query("SELECT l FROM LogPost l ORDER BY l.createdAt DESC")
    Slice<LogPost> findAllOrderByCreatedAtDesc(Pageable pageable);

    // 4. 사용자의 로그 개수 (삭제되지 않은 것만)
    long countByCreatorIdAndIsDeletedFalse(Long creatorId);

    // [검색] pg_trgm 기반 로그 검색 (제목, 내용, 연결된 레시피명)
    @Query(value = """
        SELECT DISTINCT lp.* FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.is_deleted = false AND lp.is_private = false
        AND (
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            OR r.title ILIKE '%' || :keyword || '%'
        )
        ORDER BY lp.created_at DESC
        """,
        countQuery = """
        SELECT COUNT(DISTINCT lp.id) FROM log_posts lp
        LEFT JOIN recipe_logs rl ON rl.log_post_id = lp.id
        LEFT JOIN recipes r ON r.id = rl.recipe_id
        WHERE lp.is_deleted = false AND lp.is_private = false
        AND (
            lp.title ILIKE '%' || :keyword || '%'
            OR lp.content ILIKE '%' || :keyword || '%'
            OR r.title ILIKE '%' || :keyword || '%'
        )
        """,
        nativeQuery = true)
    Slice<LogPost> searchLogPosts(@Param("keyword") String keyword, Pageable pageable);
}