package com.cookstemma.cookstemma.domain.entity.food;

import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

@Entity
@Table(name = "user_suggested_foods")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
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

    @Column(name = "rejection_reason", length = 500)
    private String rejectionReason;

    public void updateStatus(SuggestionStatus status) {
        this.status = status;
    }

    public void reject(String reason) {
        this.status = SuggestionStatus.REJECTED;
        this.rejectionReason = reason;
    }

    public void linkToFoodMaster(FoodMaster foodMaster) {
        this.masterFoodRef = foodMaster;
    }
}