package com.cookstemma.cookstemma.domain.entity.translation;

import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "translation_events")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TranslationEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "public_id", nullable = false, unique = true)
    @Builder.Default
    private UUID publicId = UUID.randomUUID();

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false)
    private TranslatableEntity entityType;

    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    @Column(name = "source_locale", nullable = false, length = 5)
    private String sourceLocale;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private TranslationStatus status = TranslationStatus.PENDING;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "target_locales", nullable = false, columnDefinition = "jsonb")
    @Builder.Default
    private List<String> targetLocales = new ArrayList<>();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "completed_locales", columnDefinition = "jsonb")
    @Builder.Default
    private List<String> completedLocales = new ArrayList<>();

    @Column(name = "retry_count", nullable = false)
    @Builder.Default
    private Integer retryCount = 0;

    @Column(name = "last_error", columnDefinition = "TEXT")
    private String lastError;

    @Column(name = "created_at", nullable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    public void markProcessing() {
        this.status = TranslationStatus.PROCESSING;
        this.startedAt = Instant.now();
    }

    public void markCompleted() {
        this.status = TranslationStatus.COMPLETED;
        this.completedAt = Instant.now();
    }

    public void markFailed(String error) {
        this.status = TranslationStatus.FAILED;
        this.lastError = error;
        this.retryCount++;
    }

    public void addCompletedLocale(String locale) {
        if (!this.completedLocales.contains(locale)) {
            this.completedLocales.add(locale);
        }
    }

    public boolean isAllLocalesCompleted() {
        return this.completedLocales.containsAll(this.targetLocales);
    }
}
