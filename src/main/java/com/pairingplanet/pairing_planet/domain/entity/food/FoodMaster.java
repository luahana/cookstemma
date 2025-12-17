package com.pairingplanet.pairing_planet.domain.entity.food;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "foods_master")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class FoodMaster extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private FoodCategory category;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, String> name = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> description = new HashMap<>();

    @Column(name = "food_score")
    private Double foodScore;

    @Column(name = "search_keywords", columnDefinition = "TEXT")
    private String searchKeywords;

    @Column(name = "is_verified", nullable = false)
    @Builder.Default
    private Boolean isVerified = true;
}