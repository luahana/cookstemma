package com.pairingplanet.pairing_planet.repository.image;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ImageRepository extends JpaRepository<Image, Long> {

    // [확인] 아래처럼 필드명 'StoredFilename'을 정확히 사용해야 합니다.
    Optional<Image> findByStoredFilename(String storedFilename);

    // [확인] findByUrlIn이 남아있다면 반드시 아래로 변경해야 합니다.
    List<Image> findByStoredFilenameIn(List<String> storedFilenames);

    List<Image> findByStatusAndCreatedAtBefore(ImageStatus status, Instant cutoffTime);
}