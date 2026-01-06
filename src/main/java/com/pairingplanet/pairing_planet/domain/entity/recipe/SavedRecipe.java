package com.pairingplanet.pairing_planet.domain.entity.recipe;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "saved_recipes")
@IdClass(SavedRecipeId.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class SavedRecipe {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Id
    @Column(name = "recipe_id")
    private Long recipeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", insertable = false, updatable = false)
    private Recipe recipe;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;
}
