package com.pairingplanet.pairing_planet.domain.entity.notification;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.DeviceType;
import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.SuperBuilder;

import java.time.Instant;

@Entity
@Table(name = "user_fcm_tokens")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@SuperBuilder
public class UserFcmToken extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "fcm_token", nullable = false, length = 512)
    private String fcmToken;

    @Enumerated(EnumType.STRING)
    @Column(name = "device_type", nullable = false, length = 20)
    private DeviceType deviceType;

    @Column(name = "device_id")
    private String deviceId;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "last_used_at")
    private Instant lastUsedAt;
}
