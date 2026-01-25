package com.cookstemma.cookstemma.domain.entity.image;

import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Join entity for Recipe-Image many-to-many relationship.
 * Stores recipe-specific display order for each image,
 * allowing the same image to be shared across multiple recipes
 * (e.g., variant recipes inheriting parent's photos).
 */
@Entity
@Table(name = "recipe_image_map")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecipeImage {

    @EmbeddedId
    @Builder.Default
    private RecipeImageId id = new RecipeImageId();

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("recipeId")
    @JoinColumn(name = "recipe_id")
    private Recipe recipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("imageId")
    @JoinColumn(name = "image_id")
    private Image image;

    @Builder.Default
    private Integer displayOrder = 0;

    /**
     * Convenience constructor for creating recipe-image links.
     */
    public static RecipeImage of(Recipe recipe, Image image, int displayOrder) {
        RecipeImage ri = new RecipeImage();
        ri.setRecipe(recipe);
        ri.setImage(image);
        ri.setDisplayOrder(displayOrder);
        return ri;
    }
}
