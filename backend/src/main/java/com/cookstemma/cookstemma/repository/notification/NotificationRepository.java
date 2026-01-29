package com.cookstemma.cookstemma.repository.notification;

import com.cookstemma.cookstemma.domain.entity.notification.Notification;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    Slice<Notification> findByRecipientIdOrderByCreatedAtDesc(Long recipientId, Pageable pageable);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.recipient.id = :userId AND n.isRead = false")
    long countUnreadByRecipientId(Long userId);

    Optional<Notification> findByPublicId(UUID publicId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.recipient.id = :userId AND n.isRead = false")
    void markAllAsReadByRecipientId(Long userId);

    @Modifying(clearAutomatically = true)
    @Query(value = "DELETE FROM notifications WHERE recipient_id = :userId", nativeQuery = true)
    void deleteAllByRecipientId(@Param("userId") Long userId);
}
