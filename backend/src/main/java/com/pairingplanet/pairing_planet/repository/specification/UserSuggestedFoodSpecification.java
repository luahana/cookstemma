package com.pairingplanet.pairing_planet.repository.specification;

import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import com.pairingplanet.pairing_planet.dto.admin.SuggestedFoodFilterDto;
import jakarta.persistence.criteria.Join;
import org.springframework.data.jpa.domain.Specification;

public class UserSuggestedFoodSpecification {

    private UserSuggestedFoodSpecification() {
        // Utility class
    }

    public static Specification<UserSuggestedFood> withFilters(SuggestedFoodFilterDto filter) {
        return Specification
                .where(suggestedNameContains(filter.suggestedName()))
                .and(localeCodeEquals(filter.localeCode()))
                .and(statusEquals(filter.status()))
                .and(usernameContains(filter.username()));
    }

    private static Specification<UserSuggestedFood> suggestedNameContains(String suggestedName) {
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

    private static Specification<UserSuggestedFood> localeCodeEquals(String localeCode) {
        return (root, query, cb) -> {
            if (localeCode == null || localeCode.isBlank()) {
                return null;
            }
            return cb.equal(root.get("localeCode"), localeCode);
        };
    }

    private static Specification<UserSuggestedFood> statusEquals(SuggestionStatus status) {
        return (root, query, cb) -> {
            if (status == null) {
                return null;
            }
            return cb.equal(root.get("status"), status);
        };
    }

    private static Specification<UserSuggestedFood> usernameContains(String username) {
        return (root, query, cb) -> {
            if (username == null || username.isBlank()) {
                return null;
            }
            Join<UserSuggestedFood, User> userJoin = root.join("user");
            return cb.like(
                    cb.lower(userJoin.get("username")),
                    "%" + username.toLowerCase() + "%"
            );
        };
    }
}
