package com.pairingplanet.pairing_planet.domain.entity.log_post;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "saved_logs")
@IdClass(SavedLogId.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class SavedLog {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Id
    @Column(name = "log_post_id")
    private Long logPostId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "log_post_id", insertable = false, updatable = false)
    private LogPost logPost;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;
}
