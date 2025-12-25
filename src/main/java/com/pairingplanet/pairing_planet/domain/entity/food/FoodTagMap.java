package com.pairingplanet.pairing_planet.domain.entity.food;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import org.hibernate.annotations.UpdateTimestamp;

import java.io.Serializable;
import java.time.Instant;

@Entity
@Table(name = "food_tag_map")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FoodTagMap {

    @EmbeddedId
    private FoodTagMapId id;

    @MapsId("foodId") // FoodTagMapId의 foodId와 매핑
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE) // DDL 수준 반영
    private FoodMaster food;

    @MapsId("tagId") // FoodTagMapId의 tagId와 매핑
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tag_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private FoodTag tag;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    // 생성자 패턴
    @Builder
    public FoodTagMap(FoodMaster food, FoodTag tag) {
        this.food = food;
        this.tag = tag;
        this.id = new FoodTagMapId(food.getId(), tag.getId());
    }

    // 복합키 클래스 (EmbeddedId)
    @Embeddable
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class FoodTagMapId implements Serializable {
        @Column(name = "food_id")
        private Long foodId;

        @Column(name = "tag_id")
        private Long tagId;
    }
}