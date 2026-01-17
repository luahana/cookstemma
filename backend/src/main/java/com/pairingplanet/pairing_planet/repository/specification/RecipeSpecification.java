package com.pairingplanet.pairing_planet.repository.specification;

import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.enums.CookingTimeRange;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

public class RecipeSpecification {

    private RecipeSpecification() {
        // Utility class
    }

    /**
     * Build a specification with all filters combined.
     */
    public static Specification<Recipe> withFilters(
            String locale,
            String typeFilter,
            List<CookingTimeRange> cookingTimeRanges,
            Integer minServings,
            Integer maxServings) {
        return isPublic()
                .and(isNotDeleted())
                .and(localeEquals(locale))
                .and(typeFilterMatches(typeFilter))
                .and(cookingTimeIn(cookingTimeRanges))
                .and(servingsInRange(minServings, maxServings));
    }

    /**
     * Base filter: only public recipes
     */
    public static Specification<Recipe> isPublic() {
        return (root, query, cb) -> cb.equal(root.get("isPrivate"), false);
    }

    /**
     * Base filter: not soft deleted
     */
    public static Specification<Recipe> isNotDeleted() {
        return (root, query, cb) -> cb.isNull(root.get("deletedAt"));
    }

    /**
     * Filter by culinary locale
     */
    public static Specification<Recipe> localeEquals(String locale) {
        return (root, query, cb) -> {
            if (locale == null || locale.isBlank()) {
                return null;
            }
            return cb.equal(root.get("culinaryLocale"), locale);
        };
    }

    /**
     * Filter by recipe type (original or variant)
     */
    public static Specification<Recipe> typeFilterMatches(String typeFilter) {
        return (root, query, cb) -> {
            if (typeFilter == null || typeFilter.isBlank()) {
                return null;
            }
            if ("original".equalsIgnoreCase(typeFilter)) {
                return cb.isNull(root.get("rootRecipe"));
            } else if ("variant".equalsIgnoreCase(typeFilter)) {
                return cb.isNotNull(root.get("rootRecipe"));
            }
            return null;
        };
    }

    /**
     * Filter by cooking time ranges (multiple values allowed)
     */
    public static Specification<Recipe> cookingTimeIn(List<CookingTimeRange> cookingTimeRanges) {
        return (root, query, cb) -> {
            if (cookingTimeRanges == null || cookingTimeRanges.isEmpty()) {
                return null;
            }
            return root.get("cookingTimeRange").in(cookingTimeRanges);
        };
    }

    /**
     * Filter by servings range
     */
    public static Specification<Recipe> servingsInRange(Integer minServings, Integer maxServings) {
        return (root, query, cb) -> {
            if (minServings == null && maxServings == null) {
                return null;
            }
            if (minServings != null && maxServings != null) {
                return cb.between(root.get("servings"), minServings, maxServings);
            } else if (minServings != null) {
                return cb.greaterThanOrEqualTo(root.get("servings"), minServings);
            } else {
                return cb.lessThanOrEqualTo(root.get("servings"), maxServings);
            }
        };
    }
}
