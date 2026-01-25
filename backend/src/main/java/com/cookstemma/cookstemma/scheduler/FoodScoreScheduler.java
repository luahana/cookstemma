package com.cookstemma.cookstemma.scheduler;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Component
@RequiredArgsConstructor
public class FoodScoreScheduler {

    private final JdbcTemplate jdbcTemplate;

    /**
     * 매일 UTC 03:00에 실행
     * (한국 시간으로는 낮 12:00, 미국 NY 시간으로는 밤 22:00/23:00)
     * 글로벌 서비스는 보통 UTC 00:00 ~ 04:00 사이를 배치 시간으로 잡습니다.
     */
    @Scheduled(cron = "0 0 3 * * *", zone = "UTC")
    @Transactional
    public void updateFoodPopularity() {
        log.info("Starting Daily Food Score Update (UTC 03:00)...");
        long start = System.currentTimeMillis();

        // 1. 점수 계산 알고리즘 (SQL)
        // JPA로 하나씩 가져와서 계산하면 느리므로, DB 차원에서 집계하여 한 번에 Update 합니다.
        // 알고리즘: (PairingMap 등장 횟수 * 10) + (추가 로직 가능)
        String sql = """
            UPDATE foods_master f 
            SET food_score = COALESCE(stats.usage_count, 0) * 10.0
            FROM (
                SELECT food_id, COUNT(*) as usage_count
                FROM (
                    SELECT food1_master_id as food_id FROM pairing_map
                ) combined_foods
                GROUP BY food_id
            ) stats
            WHERE f.id = stats.food_id
        """;

        // 2. 실행
        int updatedRows = jdbcTemplate.update(sql);

        long end = System.currentTimeMillis();
        log.info("Food Score Update Completed. Updated {} rows in {} ms.", updatedRows, (end - start));
    }
}