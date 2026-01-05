package com.pairingplanet.pairing_planet.domain.entity.recipe;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
// Recipe.java 수정 제안
@Entity
@Table(name = "recipes")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@SuperBuilder // BaseEntity 상속을 위해 SuperBuilder 사용
public class Recipe extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food1_master_id", nullable = false)
    private FoodMaster foodMaster;

    private String culinaryLocale;
    private String title;
    private String description;
    private Integer cookingTime;
    private String difficulty;

    @Builder.Default
    private Integer savedCount = 0;
    @Builder.Default
    private Boolean isPrivate = false;
    @Builder.Default
    private Boolean isDeleted = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "root_recipe_id")
    private Recipe rootRecipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_recipe_id")
    private Recipe parentRecipe;

    private String changeCategory;
    private Long creatorId;

    // [경고 해결] @Builder.Default 추가
    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    private List<RecipeIngredient> ingredients = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    @OrderBy("stepNumber ASC")
    private List<RecipeStep> steps = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    @OrderBy("displayOrder ASC")
    private List<Image> images = new ArrayList<>();

    @Builder.Default
    @ManyToMany
    @JoinTable(name = "recipe_hashtag_map",
            joinColumns = @JoinColumn(name = "recipe_id"),
            inverseJoinColumns = @JoinColumn(name = "hashtag_id"))
    private Set<Hashtag> hashtags = new HashSet<>();

    public boolean isOriginal() {
        return this.rootRecipe == null;
    }
}