package com.pairingplanet.pairing_planet.domain.entity.user;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.enums.Provider;
import com.pairingplanet.pairing_planet.util.EncryptionConverter;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "social_accounts", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"provider", "provider_user_id"})
})
@Setter
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor @Builder
public class SocialAccount extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private Provider provider;

    @Column(name = "provider_user_id", nullable = false)
    private String providerUserId;

    private String email;

    @Convert(converter = EncryptionConverter.class)
    @Column(name = "access_token", columnDefinition = "TEXT")
    private String accessToken;

    @Convert(converter = EncryptionConverter.class)
    @Column(name = "refresh_token", columnDefinition = "TEXT")
    private String refreshToken;
}