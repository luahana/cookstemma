package com.pairingplanet.pairing_planet.domain.entity.ingredient;

import com.pairingplanet.pairing_planet.domain.entity.autocomplete.AutocompleteItem;
import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

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

    public void updateStatus(SuggestionStatus status) {
        this.status = status;
    }

    public void linkToAutocompleteItem(AutocompleteItem autocompleteItem) {
        this.autocompleteItemRef = autocompleteItem;
    }
}
