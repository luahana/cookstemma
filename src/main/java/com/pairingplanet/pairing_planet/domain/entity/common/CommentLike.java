package com.pairingplanet.pairing_planet.domain.entity.common;

import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.io.Serializable;
import java.time.ZonedDateTime;

@Entity
@Table(name = "comment_likes")
@Getter @NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CommentLike {

    @EmbeddedId
    private CommentLikeId id;

    @MapsId("userId") // CommentLikeId의 userId 필드와 매핑
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @MapsId("commentId") // CommentLikeId의 commentId 필드와 매핑
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comment_id")
    private Comment comment;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private ZonedDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private ZonedDateTime updatedAt;

    // 복합키 식별자 클래스
    @Embeddable
    @Getter @NoArgsConstructor @AllArgsConstructor @EqualsAndHashCode
    public static class CommentLikeId implements Serializable {
        private Long userId;
        private Long commentId;
    }
}