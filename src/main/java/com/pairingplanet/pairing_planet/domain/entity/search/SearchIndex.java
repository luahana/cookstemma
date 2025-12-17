package com.pairingplanet.pairing_planet.domain.entity.search;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.enums.SearchTargetType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "search_index", uniqueConstraints = {
        @UniqueConstraint(
                name = "uq_search_target",
                columnNames = {"target_id", "target_type", "keyword", "locale_code"}
        )
})
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class SearchIndex extends BaseEntity {

    @Column(name = "target_id", nullable = false)
    private Long targetId;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_type", nullable = false, length = 20)
    private SearchTargetType targetType;

    @Column(nullable = false, length = 100)
    private String keyword;

    @Column(name = "locale_code", nullable = false, length = 10)
    private String localeCode;

    @Column(name = "icon_url", columnDefinition = "TEXT")
    private String iconUrl;
}