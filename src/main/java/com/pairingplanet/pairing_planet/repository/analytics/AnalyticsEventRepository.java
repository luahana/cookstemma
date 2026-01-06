package com.pairingplanet.pairing_planet.repository.analytics;

import com.pairingplanet.pairing_planet.domain.entity.analytics.AnalyticsEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface AnalyticsEventRepository extends JpaRepository<AnalyticsEvent, Long> {

    // 1. 서비스 로직용 메서드
    boolean existsByEventId(UUID eventId); // 중복 수집 방지용

    void deleteByUserId(UUID userId); // GDPR: 유저 데이터 삭제용

    // 2. 제품 분석용 쿼리 (Product Analytics)

    /**
     * 가장 많이 조회된 레시피 TOP 10
     */
    @Query(value = """
        SELECT recipe_id, COUNT(*) as views 
        FROM analytics_events 
        WHERE event_type = 'recipeViewed' AND recipe_id IS NOT NULL
        GROUP BY recipe_id 
        ORDER BY views DESC 
        LIMIT :limit
        """, nativeQuery = true)
    List<Object[]> findTopViewedRecipes(@Param("limit") int limit);

    /**
     * 특정 기간 내 활동 중인 요리사(로그 작성 유저) 수 조회
     */
    @Query("SELECT COUNT(DISTINCT e.userId) FROM AnalyticsEvent e " +
            "WHERE e.eventType = 'logCreated' AND e.timestamp > :since")
    long countActiveCooks(@Param("since") Instant since);

    /**
     * 조회 대비 요리 전환율(Conversion Rate) 계산
     * $$ \text{Conversion Rate} = \frac{\text{Unique Cooks}}{\text{Unique Viewers}} \times 100 $$
     */
    @Query(value = """
        SELECT 
          (COUNT(DISTINCT CASE WHEN event_type = 'logCreated' THEN user_id END) * 100.0 / 
           NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'recipeViewed' THEN user_id END), 0)) 
        FROM analytics_events
        """, nativeQuery = true)
    Double getRecipeToLogConversionRate();

    // 3. A/B 테스트 및 속성 분석 (JSONB 활용)

    /**
     * 실험 그룹별 레시피 생성률 비교
     */
    @Query(value = """
        SELECT 
          properties->>'experiment_group' as group_name,
          COUNT(DISTINCT user_id) as user_count,
          COUNT(CASE WHEN event_type = 'recipeCreated' THEN 1 END) as creation_count
        FROM analytics_events 
        WHERE properties->>'experiment_id' = :experimentId
        GROUP BY group_name
        """, nativeQuery = true)
    List<Object[]> compareExperimentGroups(@Param("experimentId") String experimentId);
}