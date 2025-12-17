package com.pairingplanet.pairing_planet.domain.entity.food;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "food_categories")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class FoodCategory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private FoodCategory parent;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(columnDefinition = "int default 1")
    @Builder.Default
    private Integer depth = 1;

    // JSONB 매핑: {"ko": "면", "en": "Noodle"}
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, String> name = new HashMap<>();
}