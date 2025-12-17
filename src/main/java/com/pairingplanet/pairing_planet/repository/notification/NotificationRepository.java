package com.pairingplanet.pairing_planet.repository.notification;

import com.pairingplanet.pairing_planet.domain.entity.notification.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    // 내 알림 목록 (최신순)
    List<Notification> findByRecipientIdOrderByIdDesc(Long recipientId, Pageable pageable);

    // 읽지 않은 알림 개수 (뱃지 표시용)
    long countByRecipientIdAndIsReadFalse(Long recipientId);

    // 읽지 않은 알림만 조회
    List<Notification> findByRecipientIdAndIsReadFalseOrderByIdDesc(Long recipientId);
}