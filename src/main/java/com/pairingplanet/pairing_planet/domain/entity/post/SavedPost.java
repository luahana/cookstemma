package com.pairingplanet.pairing_planet.domain.entity.post;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.io.Serializable;
import java.time.Instant;

@Entity
@Table(name = "saved_posts")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SavedPost {

    @EmbeddedId
    private SavedPostId id;

    @MapsId("userId")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @MapsId("postId")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id")
    private Post post;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    // updated_at은 생성 시점과 동일하거나 필요 시 추가

    @Builder
    public SavedPost(User user, Post post) {
        this.user = user;
        this.post = post;
        this.id = new SavedPostId(user.getId(), post.getId());
    }

    // 복합키 클래스
    @Embeddable
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class SavedPostId implements Serializable {
        private Long userId;
        private Long postId;
    }
}