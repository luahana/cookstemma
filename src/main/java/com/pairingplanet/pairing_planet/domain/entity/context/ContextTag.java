package com.pairingplanet.pairing_planet.domain.entity.context;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "context_tags")
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ContextTag extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "dimension_id", nullable = false)
    private ContextDimension dimension;

    @Column(name = "tag_name", nullable = false)
    private String tagName;

    @Column(name = "display_name", nullable = false)
    private String displayName;

    @Column(name = "locale", nullable = false)
    private String locale;
}