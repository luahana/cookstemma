package com.cookstemma.cookstemma.domain.entity.analytics;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "analytics_events")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AnalyticsEvent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private UUID eventId;

    @Column(nullable = false)
    private String eventType;

    private UUID userId;
    private UUID recipeId;
    private UUID logId;

    @Column(nullable = false)
    private Instant timestamp;

    @JdbcTypeCode(SqlTypes.JSON) // Hibernate 6의 JSONB 매핑 방식
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> properties;
}