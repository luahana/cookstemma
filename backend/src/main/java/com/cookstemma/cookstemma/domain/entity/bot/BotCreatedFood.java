package com.cookstemma.cookstemma.domain.entity.bot;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * Tracks which foods each bot persona has created recipes for.
 * Used to prevent bots from creating duplicate recipes for the same food.
 */
@Entity
@Table(
    name = "bot_created_foods",
    uniqueConstraints = @UniqueConstraint(columnNames = {"persona_name", "food_name"})
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BotCreatedFood {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "persona_name", nullable = false, length = 100)
    private String personaName;

    @Column(name = "food_name", nullable = false, length = 200)
    private String foodName;

    @Column(name = "recipe_public_id")
    private UUID recipePublicId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
