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
@Table(name = "food_tags")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
public class FoodTag extends BaseEntity {

    @Column(name = "tag_group", nullable = false, length = 20)
    private String tagGroup; // ENUM으로 변경 가능 (INGREDIENT, STYLE 등)

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, String> name = new HashMap<>();
}