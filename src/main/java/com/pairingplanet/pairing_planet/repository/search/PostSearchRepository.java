package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.dto.search.PairingSearchRequestDto;
import com.pairingplanet.pairing_planet.dto.search.PostSearchResultDto;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Repository
public class PostSearchRepository {

    @PersistenceContext
    private EntityManager em;

    public List<PostSearchResultDto> searchPosts(PairingSearchRequestDto request, boolean ignoreWhenTag) {
        StringBuilder sql = new StringBuilder("""
            SELECT 
                -- [0~4] Post Info
                p.id, p.public_id, p.content, p.image_urls, p.created_at,
                
                -- [5~6] Creator Info
                u.username, u.public_id as u_pid,
                
                -- [7~8] Food1 Info (Required)
                f1.name ->> :locale as f1_name, f1.public_id as f1_pid,
                
                -- [9~10] Food2 Info (Optional - LEFT JOIN)
                f2.name ->> :locale as f2_name, f2.public_id as f2_pid,
                
                -- [11~12] Tags Display Name
                ctx_when.display_name as when_name,
                ctx_diet.display_name as diet_name,
                
                -- [13~18] Metrics
                p.genius_count, p.daring_count, p.picky_count,
                p.comment_count, p.saved_count, p.popularity_score
            
            FROM posts p
            JOIN pairing_map pm ON p.pairing_id = pm.id
            JOIN users u ON p.creator_id = u.id
            JOIN foods_master f1 ON pm.food1_master_id = f1.id
            LEFT JOIN foods_master f2 ON pm.food2_master_id = f2.id
            LEFT JOIN context_tags ctx_when ON pm.when_context_id = ctx_when.id
            LEFT JOIN context_tags ctx_diet ON pm.dietary_context_id = ctx_diet.id
            
            WHERE 1=1
            AND p.is_deleted = false
        """);

        // --- 필터링 로직 ---

        // FR-80: Food Tags Search
        if (request.foodIds() != null && !request.foodIds().isEmpty()) {
            if (request.foodIds().size() == 1) {
                // Food1만 입력했어도, 그게 Food1 자리에 있든 Food2 자리에 있든 검색
                sql.append(" AND (pm.food1_master_id = :foodId1 OR pm.food2_master_id = :foodId1)");
            } else if (request.foodIds().size() >= 2) {
                // 두 개 입력 시: 순서 무관 교차 검증
                sql.append(" AND (");
                sql.append("   (pm.food1_master_id = :foodId1 AND pm.food2_master_id = :foodId2)");
                sql.append("   OR (pm.food1_master_id = :foodId2 AND pm.food2_master_id = :foodId1)");
                sql.append(" )");
            }
        }

        // FR-83: Dietary Tag (Hard Filter)
        if (request.dietaryContextId() != null) {
            sql.append(" AND pm.dietary_context_id = :dietaryId");
        }

        // FR-84: When Tag (Soft Filter - Service에서 제어)
        if (!ignoreWhenTag && request.whenContextId() != null) {
            sql.append(" AND pm.when_context_id = :whenId");
        }

        // FR-88: Ranking Algorithm
        // 1. Locality 일치 여부 (내 지역 포스트 우선)
        // 2. Popularity Score (DB에서 계산된 인기 점수)
        // 3. 최신순
        sql.append("""
            ORDER BY 
                CASE WHEN p.locale = :locale THEN 1 ELSE 0 END DESC,
                p.popularity_score DESC NULLS LAST,
                p.created_at DESC
        """);

        // --- 쿼리 실행 및 파라미터 바인딩 ---
        Query query = em.createNativeQuery(sql.toString());

        query.setParameter("locale", request.locale());

        if (request.foodIds() != null && !request.foodIds().isEmpty()) {
            query.setParameter("foodId1", request.foodIds().get(0));
            if (request.foodIds().size() >= 2) {
                query.setParameter("foodId2", request.foodIds().get(1));
            }
        }
        if (request.dietaryContextId() != null) {
            query.setParameter("dietaryId", request.dietaryContextId());
        }
        if (!ignoreWhenTag && request.whenContextId() != null) {
            query.setParameter("whenId", request.whenContextId());
        }

        query.setMaxResults(20);

        // --- 결과 매핑 (Object[] -> DTO) ---
        List<Object[]> rows = query.getResultList();

        return rows.stream().map(row -> {
            String[] imgArr = row[3] != null ? (String[]) row[3] : new String[0];

            return new PostSearchResultDto(
                    ((Number) row[0]).longValue(),      // id
                    (UUID) row[1],                      // public_id
                    (String) row[2],                    // content
                    Arrays.asList(imgArr),              // imageUrls
                    ((Instant) row[4]), // createdAt

                    (String) row[5],                    // creatorName
                    (UUID) row[6],                      // creatorPid

                    (String) row[7],                    // food1Name
                    (UUID) row[8],                      // food1Pid
                    (String) row[9],                    // food2Name (Nullable)
                    (UUID) row[10],                     // food2Pid (Nullable)

                    (String) row[11],                   // whenName
                    (String) row[12],                   // dietName

                    ((Number) row[13]).intValue(),      // genius
                    ((Number) row[14]).intValue(),      // daring
                    ((Number) row[15]).intValue(),      // picky
                    ((Number) row[16]).intValue(),      // comment
                    ((Number) row[17]).intValue(),      // saved
                    ((Number) row[18]).doubleValue(),   // popularity

                    ignoreWhenTag                       // isWhenFallback flag
            );
        }).collect(Collectors.toList());
    }
}