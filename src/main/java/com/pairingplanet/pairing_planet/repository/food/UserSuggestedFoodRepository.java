package com.pairingplanet.pairing_planet.repository.food;

import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.Optional;
import java.util.UUID;



public interface UserSuggestedFoodRepository extends JpaRepository<UserSuggestedFood, Long> {
    Optional<UserSuggestedFood> findByPublicId(UUID publicId);

    // 관리자용: 상태별 조회 (PENDING 인 것만 날짜순 정렬)
    Page<UserSuggestedFood> findByStatusOrderByCreatedAtDesc(SuggestionStatus status, Pageable pageable);
}