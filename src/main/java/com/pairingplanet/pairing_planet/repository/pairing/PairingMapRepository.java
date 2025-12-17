package com.pairingplanet.pairing_planet.repository.pairing;

import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.UUID;

public interface PairingMapRepository extends JpaRepository<PairingMap, Long> {
    Optional<PairingMap> findByPublicId(UUID publicId);

    // [중복 방지] 동일한 조합이 이미 있는지 확인
    @Query("SELECT p FROM PairingMap p WHERE " +
            "p.food1.id = :food1Id AND " +
            "((:food2Id IS NULL AND p.food2 IS NULL) OR p.food2.id = :food2Id) AND " +
            "((:whenId IS NULL AND p.whenContext IS NULL) OR p.whenContext.id = :whenId) AND " +
            "((:dietaryId IS NULL AND p.dietaryContext IS NULL) OR p.dietaryContext.id = :dietaryId)")
    Optional<PairingMap> findExistingPairing(
            @Param("food1Id") Long food1Id,
            @Param("food2Id") Long food2Id,
            @Param("whenId") Long whenId,
            @Param("dietaryId") Long dietaryId
    );
}