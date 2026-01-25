package com.cookstemma.cookstemma.repository.food;

import com.cookstemma.cookstemma.domain.entity.food.UserSuggestedFood;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.Optional;
import java.util.UUID;



public interface UserSuggestedFoodRepository extends JpaRepository<UserSuggestedFood, Long>, JpaSpecificationExecutor<UserSuggestedFood> {
    Optional<UserSuggestedFood> findByPublicId(UUID publicId);

    // 관리자용: 상태별 조회 (PENDING 인 것만 날짜순 정렬)
    Page<UserSuggestedFood> findByStatusOrderByCreatedAtDesc(SuggestionStatus status, Pageable pageable);
}