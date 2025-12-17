package com.pairingplanet.pairing_planet.domain.entity.food;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_suggested_foods")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class UserSuggestedFood extends BaseEntity {

    @Column(name = "suggested_name", nullable = false, length = 100)
    private String suggestedName;

    @Column(name = "locale_code", nullable = false, length = 5)
    private String localeCode;

    // User 엔티티가 있다고 가정
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private SuggestionStatus status = SuggestionStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "master_food_id_ref")
    private FoodMaster masterFoodRef;

    // Status Enum 정의
    public enum SuggestionStatus {
        PENDING, APPROVED, REJECTED
    }
}