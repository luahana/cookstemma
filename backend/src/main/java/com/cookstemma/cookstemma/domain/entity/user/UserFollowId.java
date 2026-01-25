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
public class UserFollowId implements Serializable {

    @Column(name = "follower_id")
    private Long followerId;

    @Column(name = "following_id")
    private Long followingId;
}
