package com.pairingplanet.pairing_planet.domain.entity.recipe;

import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.MeasurementUnit;
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
     * Legacy amount field - stores free-text like "2 cups" or "a pinch".
     * Used for backward compatibility with existing recipes.
     * New recipes should use quantity + unit instead.
     */
    @Column(length = 50)
    private String amount;

    /**
     * Numeric quantity for structured measurements (e.g., 2.5).
     * Nullable for legacy recipes that only have the amount string.
     */
    @Column
    private Double quantity;

    /**
     * Standardized unit for structured measurements.
     * Nullable for legacy recipes that only have the amount string.
     */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private MeasurementUnit unit;

    @Enumerated(EnumType.STRING)
    private IngredientType type;

    @Column(name = "display_order")
    @Builder.Default
    private Integer displayOrder = 0;

    /**
     * Check if this ingredient uses structured measurements (quantity + unit).
     */
    public boolean hasStructuredMeasurement() {
        return quantity != null && unit != null;
    }
}