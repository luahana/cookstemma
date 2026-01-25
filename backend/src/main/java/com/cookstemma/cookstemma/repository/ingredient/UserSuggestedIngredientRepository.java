package com.cookstemma.cookstemma.repository.ingredient;

import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.Optional;
import java.util.UUID;

public interface UserSuggestedIngredientRepository
        extends JpaRepository<UserSuggestedIngredient, Long>,
                JpaSpecificationExecutor<UserSuggestedIngredient> {

    Optional<UserSuggestedIngredient> findByPublicId(UUID publicId);

    Page<UserSuggestedIngredient> findByStatusOrderByCreatedAtDesc(
            SuggestionStatus status,
            Pageable pageable
    );

    Page<UserSuggestedIngredient> findByStatusAndIngredientTypeOrderByCreatedAtDesc(
            SuggestionStatus status,
            IngredientType ingredientType,
            Pageable pageable
    );

    boolean existsBySuggestedNameIgnoreCaseAndIngredientTypeAndLocaleCode(
            String suggestedName,
            IngredientType ingredientType,
            String localeCode
    );
}
