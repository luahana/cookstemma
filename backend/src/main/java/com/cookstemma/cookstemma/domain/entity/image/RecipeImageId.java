package com.cookstemma.cookstemma.domain.entity.image;

import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;

/**
 * Composite primary key for the RecipeImage join table.
 * Enables many-to-many relationship between Recipe and Image
 * with recipe-specific display ordering.
 */
@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class RecipeImageId implements Serializable {
    private Long recipeId;
    private Long imageId;
}
