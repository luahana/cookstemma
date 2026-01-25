package com.cookstemma.cookstemma.repository.specification;

import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientFilterDto;
import jakarta.persistence.criteria.Join;
import org.springframework.data.jpa.domain.Specification;

public class UserSuggestedIngredientSpecification {

    private UserSuggestedIngredientSpecification() {
        // Utility class
    }

    public static Specification<UserSuggestedIngredient> withFilters(SuggestedIngredientFilterDto filter) {
        return suggestedNameContains(filter.suggestedName())
                .and(ingredientTypeEquals(filter.ingredientType()))
                .and(localeCodeEquals(filter.localeCode()))
                .and(statusEquals(filter.status()))
                .and(usernameContains(filter.username()));
    }

    private static Specification<UserSuggestedIngredient> suggestedNameContains(String suggestedName) {
        return (root, query, cb) -> {
            if (suggestedName == null || suggestedName.isBlank()) {
                return null;
            }
            return cb.like(
                    cb.lower(root.get("suggestedName")),
                    "%" + suggestedName.toLowerCase() + "%"
            );
        };
    }

    private static Specification<UserSuggestedIngredient> ingredientTypeEquals(IngredientType ingredientType) {
        return (root, query, cb) -> {
            if (ingredientType == null) {
                return null;
            }
            return cb.equal(root.get("ingredientType"), ingredientType);
        };
    }

    private static Specification<UserSuggestedIngredient> localeCodeEquals(String localeCode) {
        return (root, query, cb) -> {
            if (localeCode == null || localeCode.isBlank()) {
                return null;
            }
            return cb.equal(root.get("localeCode"), localeCode);
        };
    }

    private static Specification<UserSuggestedIngredient> statusEquals(SuggestionStatus status) {
        return (root, query, cb) -> {
            if (status == null) {
                return null;
            }
            return cb.equal(root.get("status"), status);
        };
    }

    private static Specification<UserSuggestedIngredient> usernameContains(String username) {
        return (root, query, cb) -> {
            if (username == null || username.isBlank()) {
                return null;
            }
            Join<UserSuggestedIngredient, User> userJoin = root.join("user");
            return cb.like(
                    cb.lower(userJoin.get("username")),
                    "%" + username.toLowerCase() + "%"
            );
        };
    }
}
