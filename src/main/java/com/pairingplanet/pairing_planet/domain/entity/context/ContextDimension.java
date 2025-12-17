package com.pairingplanet.pairing_planet.domain.entity.context;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "context_dimensions")
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ContextDimension extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String name;
}