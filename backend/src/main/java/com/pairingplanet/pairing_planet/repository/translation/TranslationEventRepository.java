package com.pairingplanet.pairing_planet.repository.translation;

import com.pairingplanet.pairing_planet.domain.entity.translation.TranslationEvent;
import com.pairingplanet.pairing_planet.domain.enums.TranslatableEntity;
import com.pairingplanet.pairing_planet.domain.enums.TranslationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TranslationEventRepository extends JpaRepository<TranslationEvent, Long> {

    Optional<TranslationEvent> findByPublicId(UUID publicId);

    Optional<TranslationEvent> findByEntityTypeAndEntityId(TranslatableEntity entityType, Long entityId);

    List<TranslationEvent> findByStatus(TranslationStatus status);

    @Query("SELECT te FROM TranslationEvent te WHERE te.status IN :statuses ORDER BY te.createdAt ASC")
    List<TranslationEvent> findPendingOrFailed(@Param("statuses") List<TranslationStatus> statuses);

    @Query("SELECT te FROM TranslationEvent te WHERE te.status = 'PENDING' OR (te.status = 'FAILED' AND te.retryCount < 3) ORDER BY te.createdAt ASC")
    List<TranslationEvent> findRetryable();

    boolean existsByEntityTypeAndEntityIdAndStatusIn(
            TranslatableEntity entityType, Long entityId, List<TranslationStatus> statuses);
}
