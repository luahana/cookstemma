package com.pairingplanet.pairing_planet.scheduler;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class TrendingScoreService {

    private final JdbcTemplate jdbcTemplate;

    // 1시간마다 실행 (cron = "0 0 * * * *")
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void updateTrendingScores() {
        // 1. 트렌딩 스코어 계산 및 업데이트
        // 공식: (Genius 증가분 * 1) + (Picky 증가분 * 1) + (Comment 증가분 * 3) + (Save 증가분 * 5)
        // Picky도 유저의 적극적인 투표 행위이므로 Genius와 동일한 가중치(1.0)를 부여하여 '화제성'에 기여하게 함

        String updateSql = """
            UPDATE pairing_locale_stats ps
            SET 
                trending_score = (
                    (ps.genius_count - COALESCE(sn.last_genius_count, ps.genius_count)) * 1.0 +
                    (ps.picky_count - COALESCE(sn.last_picky_count, ps.picky_count)) * 1.0 +  
                    (ps.comment_count - COALESCE(sn.last_comment_count, ps.comment_count)) * 3.0 +
                    (ps.saved_count - COALESCE(sn.last_saved_count, ps.saved_count)) * 5.0
                ),
                score_updated_at = NOW()
            FROM pairing_stats_snapshot sn
            WHERE ps.pairing_id = sn.pairing_id 
              AND ps.locale = sn.locale
            -- 변화가 있는 것만 업데이트 (성능 최적화)
            AND (ps.genius_count != sn.last_genius_count OR 
                 ps.picky_count != sn.last_picky_count OR   
                 ps.comment_count != sn.last_comment_count OR 
                 ps.saved_count != sn.last_saved_count);
        """;

        jdbcTemplate.update(updateSql);

        // 2. 스냅샷 테이블을 현재 값으로 갱신 (다음 턴을 위해)
        // last_picky_count 컬럼 추가 반영
        String snapshotSql = """
            INSERT INTO pairing_stats_snapshot (
                pairing_id, locale, 
                last_genius_count, last_picky_count, 
                last_comment_count, last_saved_count, 
                updated_at
            )
            SELECT 
                pairing_id, locale, 
                genius_count, picky_count, 
                comment_count, saved_count, 
                NOW()
            FROM pairing_locale_stats
            ON CONFLICT (pairing_id, locale) 
            DO UPDATE SET
                last_genius_count = EXCLUDED.last_genius_count,
                last_picky_count = EXCLUDED.last_picky_count, 
                last_comment_count = EXCLUDED.last_comment_count,
                last_saved_count = EXCLUDED.last_saved_count,
                updated_at = NOW();
        """;

        jdbcTemplate.update(snapshotSql);

        System.out.println("Trending scores updated successfully (with Picky metric).");
    }
}