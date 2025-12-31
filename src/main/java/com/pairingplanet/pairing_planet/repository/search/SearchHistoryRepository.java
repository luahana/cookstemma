package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.domain.entity.search.SearchHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SearchHistoryRepository extends JpaRepository<SearchHistory, Long> {
    // 특정 유저의 최근 검색 기록 10개 조회
    List<SearchHistory> findTop10ByUserIdOrderByUpdatedAtDesc(Long userId);

    // 중복 확인용
    Optional<SearchHistory> findByUserIdAndPairingId(Long userId, Long pairingId);

    // 기록 삭제
    void deleteByPublicIdAndUserId(UUID publicId, Long userId);

    // 전체 삭제
    void deleteAllByUserId(Long userId);
}