package com.cookstemma.cookstemma.domain.entity.food;

import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "food_categories")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
public class FoodCategory extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private FoodCategory parent;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(columnDefinition = "int default 1")
    @Builder.Default
    private Integer depth = 1;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, String> name = new HashMap<>();
}