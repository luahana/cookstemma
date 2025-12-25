package com.pairingplanet.pairing_planet.domain.entity.post;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.HashMap;
import java.util.Map;

@Entity
@DiscriminatorValue("RECIPE")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
public class RecipePost extends Post {

    @Column(columnDefinition = "TEXT") // 혹은 @JdbcTypeCode(SqlTypes.JSON)
    private String ingredients;

    @Column(name = "cooking_time")
    private int cookingTime; // 분 단위

    @Column(name = "difficulty")
    private int difficulty;

    @Column(name = "title")
    private String title;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "recipe_data", columnDefinition = "jsonb", nullable = false)
    @Builder.Default
    private Map<String, Object> recipeData = new HashMap<>();
}