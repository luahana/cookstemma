package com.pairingplanet.pairing_planet.repository.pairing;

import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingLocaleStats;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;


public interface PairingLocaleStatsRepository extends JpaRepository<PairingLocaleStats, Long> {

    // 1. Popular Only (스테디셀러)
    // - 단순히 인기 점수 순으로 정렬
    // - 인덱스: idx_stats_locale_popular 사용
    @Query("SELECT p FROM PairingLocaleStats p WHERE p.locale = :locale ORDER BY p.popularityScore DESC")
    Slice<PairingLocaleStats> findPopularOnly(@Param("locale") String locale, Pageable pageable);

    // 2. Controversial Only (전통의 논쟁)
    // - 논쟁 점수 순으로 정렬
    // - 인덱스: idx_stats_locale_controversial 사용
    @Query("SELECT p FROM PairingLocaleStats p WHERE p.locale = :locale ORDER BY p.controversyScore DESC")
    Slice<PairingLocaleStats> findControversialOnly(@Param("locale") String locale, Pageable pageable);

    // 3. Trending Only (급상승 신예)
    // - 트렌딩 점수는 높은데, 아직 누적 인기는 낮은 것 (숨겨진 라이징 스타)
    // - 예: popularityScore가 50 미만인 것들 중에서 trendingScore 순
    @Query("SELECT p FROM PairingLocaleStats p " +
            "WHERE p.locale = :locale AND p.popularityScore < :popThreshold " +
            "ORDER BY p.trendingScore DESC")
    Slice<PairingLocaleStats> findTrendingOnly(
            @Param("locale") String locale,
            @Param("popThreshold") double popThreshold, // 예: 50.0
            Pageable pageable
    );

    // 4. Popular & Trending (대세)
    // - 이미 인기도 많고(검증됨), 지금 트렌드 점수도 높은 것
    // - 전략: 인기 점수가 일정 수준 이상인 것들 중에서 트렌드 순 정렬
    @Query("SELECT p FROM PairingLocaleStats p " +
            "WHERE p.locale = :locale AND p.popularityScore >= :popThreshold " +
            "ORDER BY p.trendingScore DESC")
    Slice<PairingLocaleStats> findPopularAndTrending(
            @Param("locale") String locale,
            @Param("popThreshold") double popThreshold, // 예: 100.0
            Pageable pageable
    );

    // 5. Trending & Controversial (화제의 중심/괴식)
    // - 논란 점수가 높은 것들 중에서 트렌드 순 정렬
    // - 인덱스: idx_trending_controversial_filtered (Partial Index) 최적화
    @Query("SELECT p FROM PairingLocaleStats p " +
            "WHERE p.locale = :locale AND p.controversyScore >= :contThreshold " +
            "ORDER BY p.trendingScore DESC")
    Slice<PairingLocaleStats> findTrendingAndControversial(
            @Param("locale") String locale,
            @Param("contThreshold") double contThreshold, // 예: 2.0
            Pageable pageable
    );
}