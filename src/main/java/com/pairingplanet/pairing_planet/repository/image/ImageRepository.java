package com.pairingplanet.pairing_planet.repository.image;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ImageRepository extends JpaRepository<Image, Long> {
    Optional<Image> findByUrl(String url);

    // 여러 URL로 한 번에 조회 (포스트 등록 시 사용)
    List<Image> findByUrlIn(List<String> imageUrls);

    // 24시간 지난 TEMP 이미지 조회 (Garbage Collection 용)
    // BaseEntity의 createdAt은 Instant 타입이라 가정
    List<Image> findByStatusAndCreatedAtBefore(ImageStatus status, Instant cutoffTime);
}