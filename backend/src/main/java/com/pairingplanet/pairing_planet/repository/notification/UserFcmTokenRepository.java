package com.pairingplanet.pairing_planet.repository.notification;

import com.pairingplanet.pairing_planet.domain.entity.notification.UserFcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserFcmTokenRepository extends JpaRepository<UserFcmToken, Long> {

    List<UserFcmToken> findByUserIdAndIsActiveTrue(Long userId);

    Optional<UserFcmToken> findByUserIdAndFcmToken(Long userId, String fcmToken);

    Optional<UserFcmToken> findByFcmToken(String fcmToken);

    @Modifying
    @Query("UPDATE UserFcmToken t SET t.isActive = false WHERE t.fcmToken = :token")
    void deactivateToken(String token);

    @Modifying
    @Query("DELETE FROM UserFcmToken t WHERE t.fcmToken = :token")
    void deleteByFcmToken(String token);
}
