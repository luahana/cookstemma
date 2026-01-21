package com.cookstemma.cookstemma.repository.translation;

import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
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

    List<TranslationEvent> findByEntityTypeAndEntityIdAndStatusIn(
            TranslatableEntity entityType, Long entityId, List<TranslationStatus> statuses);

    /**
     * Find the most recent translation event for a specific entity.
     */
    Optional<TranslationEvent> findFirstByEntityTypeAndEntityIdOrderByCreatedAtDesc(
            TranslatableEntity entityType, Long entityId);

    /**
     * Find the most recent translation events for multiple entities of a specific type.
     */
    @Query("""
        SELECT te FROM TranslationEvent te
        WHERE te.entityType = :entityType AND te.entityId IN :entityIds
        AND te.createdAt = (
            SELECT MAX(te2.createdAt) FROM TranslationEvent te2
            WHERE te2.entityType = te.entityType AND te2.entityId = te.entityId
        )
        """)
    List<TranslationEvent> findLatestByEntityTypeAndEntityIds(
            @Param("entityType") TranslatableEntity entityType,
            @Param("entityIds") List<Long> entityIds);
}
