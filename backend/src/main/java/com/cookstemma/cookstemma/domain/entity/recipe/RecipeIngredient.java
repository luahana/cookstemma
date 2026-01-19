package com.cookstemma.cookstemma.domain.entity.recipe;

import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.MeasurementUnit;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@Table(name = "recipe_ingredients")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecipeIngredient {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe;

    @Column(nullable = false, length = 100)
    private String name;

    // Translation field for multilingual content
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "name_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> nameTranslations = new HashMap<>();

    /**
     * Numeric quantity for structured measurements (e.g., 2.5).
     */
    @Column
    private Double quantity;

    /**
     * Standardized unit for structured measurements.
     */
    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(length = 20)
    private MeasurementUnit unit;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private IngredientType type;

    @Column(name = "display_order")
    @Builder.Default
    private Integer displayOrder = 0;
}