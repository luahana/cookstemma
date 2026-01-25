package com.cookstemma.cookstemma.domain.entity.user;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.io.Serializable;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class UserBlockId implements Serializable {

    @Column(name = "blocker_id")
    private Long blockerId;

    @Column(name = "blocked_id")
    private Long blockedId;
}
