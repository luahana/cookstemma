package com.pairingplanet.pairing_planet.repository.specification;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.Role;
import org.springframework.data.jpa.domain.Specification;

public class UserSpecification {

    private UserSpecification() {
        // Utility class
    }

    public static Specification<User> withFilters(String username, String email, Role role) {
        return Specification
                .where(usernameContains(username))
                .and(emailContains(email))
                .and(roleEquals(role));
    }

    private static Specification<User> usernameContains(String username) {
        return (root, query, cb) -> {
            if (username == null || username.isBlank()) {
                return null;
            }
            return cb.like(
                    cb.lower(root.get("username")),
                    "%" + username.toLowerCase() + "%"
            );
        };
    }

    private static Specification<User> emailContains(String email) {
        return (root, query, cb) -> {
            if (email == null || email.isBlank()) {
                return null;
            }
            return cb.like(
                    cb.lower(root.get("email")),
                    "%" + email.toLowerCase() + "%"
            );
        };
    }

    private static Specification<User> roleEquals(Role role) {
        return (root, query, cb) -> {
            if (role == null) {
                return null;
            }
            return cb.equal(root.get("role"), role);
        };
    }
}
