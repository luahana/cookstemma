package com.pairingplanet.pairing_planet.domain.entity.verdict;

import jakarta.persistence.*;
import lombok.*;

@Embeddable
@Data
@AllArgsConstructor
@NoArgsConstructor
public class PostVerdictId implements java.io.Serializable {
    private Long userId;
    private Long postId;
}