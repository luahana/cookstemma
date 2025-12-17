package com.pairingplanet.pairing_planet.domain.entity.post;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.user.User;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.GenerationTime;
import org.hibernate.annotations.Generated;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.util.List;

@Builder
@AllArgsConstructor
@Entity
@Table(name = "posts")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Post extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pairing_id", nullable = false)
    private PairingMap pairing;

    @Column(nullable = false)
    private String locale;

    @Column(columnDefinition = "TEXT")
    private String content;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "image_urls", columnDefinition = "text[]")
    private List<String> imageUrls;

    @Column(name = "genius_count")
    @ColumnDefault("0")
    private int geniusCount;

    @Column(name = "daring_count")
    @ColumnDefault("0")
    private int daringCount;

    @Column(name = "picky_count")
    @ColumnDefault("0")
    private int pickyCount;

    @Column(name = "saved_count")
    @ColumnDefault("0")
    private int savedCount;

    @Column(name = "comment_count")
    @ColumnDefault("0")
    private int commentCount;

    @Column(name = "popularity_score", insertable = false, updatable = false)
    @Generated(GenerationTime.ALWAYS)
    private Double popularityScore;

    @Column(name = "controversy_score", insertable = false, updatable = false)
    @Generated(GenerationTime.ALWAYS)
    private Double controversyScore;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    private User creator;

    @Column(name = "verdict_enabled")
    private boolean verdictEnabled;

    @Column(name = "comments_enabled")
    private boolean commentsEnabled;

    // [수정된 부분] 초기값(= false)을 넣어주어야 합니다.
    @Column(name = "is_deleted", nullable = false)
    @Builder.Default
    private boolean isDeleted = false;

    @Column(name = "is_private", nullable = false)
    @Builder.Default
    private boolean isPrivate = false;

    public void softDelete() {
        this.isDeleted = true;
    }

    public void setPrivate(boolean isPrivate) {
        this.isPrivate = isPrivate;
    }

    public void updateContent(String content) {
        this.content = content;
    }
}