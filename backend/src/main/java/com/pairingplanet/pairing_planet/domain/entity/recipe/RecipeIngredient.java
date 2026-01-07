package com.pairingplanet.pairing_planet.domain.entity.recipe;

import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "recipe_ingredients")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecipeIngredient {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe; // [수정] Recipe와 직접 연결

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 50)
    private String amount;

    @Enumerated(EnumType.STRING)
    private IngredientType type;

    @Column(name = "display_order")
    private Integer displayOrder;
}