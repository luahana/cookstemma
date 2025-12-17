package com.pairingplanet.pairing_planet.domain.entity.pairing;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "pairing_map")
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor // Builder용 (추가)
@Builder // 테스트 및 생성용 (추가)
public class PairingMap extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food1_master_id", nullable = false)
    private FoodMaster food1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food2_master_id")
    private FoodMaster food2;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "when_context_id")
    private ContextTag whenContext;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "dietary_context_id")
    private ContextTag dietaryContext;

}