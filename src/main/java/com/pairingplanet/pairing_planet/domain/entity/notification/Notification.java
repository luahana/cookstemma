package com.pairingplanet.pairing_planet.domain.entity.notification;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.NotificationType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "notifications")
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Notification extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = true) // 시스템 알림일 경우 null 가능
    private User sender;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private NotificationType type;

    @Column(name = "reference_id")
    private Long referenceId; // 클릭 시 이동할 타겟 ID (Post ID 등)

    @Column(name = "is_read", nullable = false)
    private boolean isRead;

    // 알림 읽음 처리 메서드 (비즈니스 로직)
    public void markAsRead() {
        this.isRead = true;
    }
}