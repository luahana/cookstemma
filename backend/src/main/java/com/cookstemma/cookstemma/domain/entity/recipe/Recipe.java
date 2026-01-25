package com.cookstemma.cookstemma.domain.entity.recipe;

import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.image.RecipeImage;
import com.cookstemma.cookstemma.domain.enums.CookingTimeRange;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Entity
@Table(name = "recipes")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@SuperBuilder
public class Recipe extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_master_id", nullable = false)
    private FoodMaster foodMaster;

    @Column(name = "cooking_style", length = 15)
    private String cookingStyle;

    @Column(name = "original_language", length = 15)
    private String originalLanguage;
    @Column(length = 200)
    private String title;
    @Column(length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "cooking_time_range")
    @Builder.Default
    private CookingTimeRange cookingTimeRange = CookingTimeRange.MIN_30_TO_60;

    @Builder.Default
    private Integer servings = 2;

    @Builder.Default
    private Integer savedCount = 0;
    @Builder.Default
    @Column(name = "view_count")
    private Integer viewCount = 0;
    @Builder.Default
    private Boolean isPrivate = false;

    // Soft delete (standardized pattern - NULL means active, timestamp means deleted)
    @Column(name = "deleted_at")
    private Instant deletedAt;

    // Audit: who last updated this recipe
    @Column(name = "updated_by_id")
    private Long updatedById;

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

    @Column(name = "change_reason", length = 2000)
    private String changeReason;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "change_reason_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> changeReasonTranslations = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "change_categories", columnDefinition = "jsonb")
    @Builder.Default
    private List<String> changeCategories = new ArrayList<>();

    // Translation fields for multilingual content
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "title_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> titleTranslations = new HashMap<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "description_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> descriptionTranslations = new HashMap<>();

    // [경고 해결] @Builder.Default 추가
    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    private List<RecipeIngredient> ingredients = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL)
    @OrderBy("stepNumber ASC")
    private List<RecipeStep> steps = new ArrayList<>();

    // Legacy: Direct image relationship (used for step images and backward compatibility)
    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @OrderBy("displayOrder ASC")
    private List<Image> images = new ArrayList<>();

    // New: Many-to-many relationship for cover images (allows sharing across variants)
    @Builder.Default
    @OneToMany(mappedBy = "recipe", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("displayOrder ASC")
    private List<RecipeImage> recipeImages = new ArrayList<>();

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

    public void incrementViewCount() {
        this.viewCount = (this.viewCount == null ? 0 : this.viewCount) + 1;
    }

    public boolean isOriginal() {
        return this.rootRecipe == null;
    }

    public boolean isDeleted() {
        return deletedAt != null;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }

    /**
     * Gets cover images via the many-to-many join table.
     * Falls back to the legacy images collection if recipeImages is empty
     * (for backward compatibility during migration period).
     * Images are ordered by their recipe-specific display order.
     *
     * @return List of cover images for this recipe
     */
    public List<Image> getCoverImages() {
        // If recipeImages collection is populated (loaded from DB), use it
        if (recipeImages != null && !recipeImages.isEmpty()) {
            return recipeImages.stream()
                    .sorted((a, b) -> Integer.compare(
                            a.getDisplayOrder() != null ? a.getDisplayOrder() : 0,
                            b.getDisplayOrder() != null ? b.getDisplayOrder() : 0))
                    .map(RecipeImage::getImage)
                    .toList();
        }
        // Fall back to legacy images collection
        // This handles:
        // 1. Same-transaction access before recipeImages is loaded
        // 2. Existing data not yet migrated
        return images.stream()
                .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                .sorted((a, b) -> Integer.compare(
                        a.getDisplayOrder() != null ? a.getDisplayOrder() : 0,
                        b.getDisplayOrder() != null ? b.getDisplayOrder() : 0))
                .toList();
    }
}
