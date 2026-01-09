package com.pairingplanet.pairing_planet.domain.entity.log_post;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SavedLogId implements Serializable {
    private Long userId;
    private Long logPostId;
}
