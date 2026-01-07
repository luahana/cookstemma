package com.pairingplanet.pairing_planet.domain.entity.recipe;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import jakarta.persistence.*;
import lombok.*;

// RecipeStep.java 수정 제안
@Entity
@Table(name = "recipe_steps")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecipeStep {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id")
    private Recipe recipe; // [수정] Recipe와 직접 연결

    @Column(name = "step_number", nullable = false)
    private Integer stepNumber;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "image_id")
    private Image image;
}