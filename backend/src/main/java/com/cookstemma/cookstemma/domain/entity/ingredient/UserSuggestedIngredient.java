package com.cookstemma.cookstemma.domain.entity.ingredient;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "user_suggested_ingredients")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
public class UserSuggestedIngredient extends BaseEntity {

    @Column(name = "suggested_name", nullable = false, length = 255)
    private String suggestedName;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "ingredient_type", nullable = false, length = 20)
    private IngredientType ingredientType;

    @Column(name = "locale_code", nullable = false, length = 10)
    @Builder.Default
    private String localeCode = "en-US";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private SuggestionStatus status = SuggestionStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "autocomplete_item_id")
    private AutocompleteItem autocompleteItemRef;

    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    public void updateStatus(SuggestionStatus status) {
        this.status = status;
    }

    public void reject(String reason) {
        this.status = SuggestionStatus.REJECTED;
        this.rejectionReason = reason;
    }

    public void linkToAutocompleteItem(AutocompleteItem autocompleteItem) {
        this.autocompleteItemRef = autocompleteItem;
    }
}
