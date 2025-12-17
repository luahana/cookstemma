package com.pairingplanet.pairing_planet.repository.context;

import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ContextTagRepository extends JpaRepository<ContextTag, Long> {
    Optional<ContextTag> findByPublicId(UUID publicId);

    // 특정 차원(Dimension)과 언어(Locale)에 맞는 태그 목록 조회 (ex: 한국어 'When' 태그들)
    List<ContextTag> findByDimensionIdAndLocale(Integer dimensionId, String locale);
}