package com.pairingplanet.pairing_planet.domain.entity.pairing;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.Generated;
import org.hibernate.annotations.GenerationTime;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.Instant;

@Entity
@Table(
        name = "pairing_locale_stats",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_pairing_locale", columnNames = {"pairing_id", "locale"}),
                @UniqueConstraint(name = "uk_pairing_locale_public_id", columnNames = {"public_id"})
        },
        indexes = {
                @Index(name = "idx_stats_locale_trending", columnList = "locale, trending_score DESC"),
                @Index(name = "idx_stats_locale_popular", columnList = "locale, popularity_score DESC"),
                @Index(name = "idx_stats_locale_controversial", columnList = "locale, controversy_score DESC")
        }
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@DynamicInsert // null인 필드는 insert 쿼리에서 제외 (DB Default 값 적용을 위해)
@EntityListeners(AuditingEntityListener.class)
public class PairingLocaleStats extends BaseEntity {

    // FetchType.LAZY는 필수입니다.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pairing_id", nullable = false)
    private PairingMap pairingMap;

    @Column(nullable = false, length = 10)
    private String locale;

    // --- Counters (Default 0) ---
    @ColumnDefault("0")
    @Column(name = "genius_count")
    private Integer geniusCount;

    @ColumnDefault("0")
    @Column(name = "daring_count")
    private Integer daringCount;

    @Column(name = "picky_count")
    @ColumnDefault("0")
    private int pickyCount;

    @ColumnDefault("0")
    @Column(name = "saved_count")
    private Integer savedCount;

    @ColumnDefault("0")
    @Column(name = "comment_count")
    private Integer commentCount;

    // --- Computed Columns (Generated Always) ---
    // 중요: DB가 계산하는 컬럼이므로 Java에서 insert/update 하지 않도록 막아야 함
    // @Generated(GenerationTime.ALWAYS): 데이터가 변경될 때마다 DB에서 값을 다시 읽어옴(Refresh)
    // deprecated지만 사용하는걸 권장
    @Column(name = "popularity_score", insertable = false, updatable = false)
    @Generated(GenerationTime.ALWAYS)
    private Double popularityScore;

    @Column(name = "controversy_score", insertable = false, updatable = false)
    @Generated(GenerationTime.ALWAYS)
    private Double controversyScore;

    // --- Scheduler Updated Column ---
    @ColumnDefault("0.0")
    @Column(name = "trending_score")
    private Double trendingScore;

    @Column(name = "score_updated_at")
    private Instant scoreUpdatedAt;

}