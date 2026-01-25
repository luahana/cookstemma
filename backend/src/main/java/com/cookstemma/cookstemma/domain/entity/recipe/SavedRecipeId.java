package com.cookstemma.cookstemma.domain.entity.recipe;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SavedRecipeId implements Serializable {
    private Long userId;
    private Long recipeId;
}
