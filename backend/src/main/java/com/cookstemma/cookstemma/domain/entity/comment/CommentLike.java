package com.cookstemma.cookstemma.domain.entity.comment;

import com.cookstemma.cookstemma.domain.entity.user.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "comment_likes")
@IdClass(CommentLikeId.class)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class CommentLike {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Id
    @Column(name = "comment_id")
    private Long commentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comment_id", insertable = false, updatable = false)
    private Comment comment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @CreationTimestamp
    @Column(name = "created_at")
    private Instant createdAt;
}
