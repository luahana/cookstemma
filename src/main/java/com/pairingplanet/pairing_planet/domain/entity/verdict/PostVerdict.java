package com.pairingplanet.pairing_planet.domain.entity.verdict;

import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.Instant;

@Entity
@Table(name = "post_verdicts")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PostVerdict {

    @EmbeddedId
    private PostVerdictId id;

    @Enumerated(EnumType.STRING)
    private VerdictType verdictType;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

}