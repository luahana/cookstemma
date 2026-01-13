package com.pairingplanet.pairing_planet.domain.entity.recipe;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.enums.CookingTimeRange;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
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

    @Enumerated(EnumType.STRING)
    @Column(name = "cooking_time_range")
    @Builder.Default
    private CookingTimeRange cookingTimeRange = CookingTimeRange.MIN_30_TO_60;

    @Builder.Default
    private Integer servings = 2;

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

    // Phase 7-2: Change tracking fields for automatic change detection
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "change_diff", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, Object> changeDiff = new HashMap<>();

    @Column(name = "change_reason", length = 200)
    private String changeReason;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "change_categories", columnDefinition = "jsonb")
    @Builder.Default
    private List<String> changeCategories = new ArrayList<>();

    // [경고 해결] @Builder.Default 추가
    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    private List<RecipeIngredient> ingredients = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    @OrderBy("stepNumber ASC")
    private List<RecipeStep> steps = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @OrderBy("displayOrder ASC")
    private List<Image> images = new ArrayList<>();

    @Builder.Default
    @ManyToMany
    @JoinTable(name = "recipe_hashtag_map",
            joinColumns = @JoinColumn(name = "recipe_id"),
            inverseJoinColumns = @JoinColumn(name = "hashtag_id"))
    private Set<Hashtag> hashtags = new HashSet<>();

    public void incrementSavedCount() {
        this.savedCount = (this.savedCount == null ? 0 : this.savedCount) + 1;
    }

    public void decrementSavedCount() {
        this.savedCount = Math.max(0, (this.savedCount == null ? 0 : this.savedCount) - 1);
    }

    public boolean isOriginal() {
        return this.rootRecipe == null;
    }
}
