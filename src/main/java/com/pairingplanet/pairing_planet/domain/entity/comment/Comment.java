package com.pairingplanet.pairing_planet.domain.entity.comment;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "comments")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Comment extends BaseEntity {
    private Long postId;
    private Long userId;
    private Long parentId; // null if root comment

    @Column(columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    private VerdictType initialVerdict; // 작성 당시

    @Setter
    @Enumerated(EnumType.STRING)
    private VerdictType currentVerdict; // 현재 상태 (업데이트 됨)

    @Builder.Default
    private int likeCount = 0;

    @Builder.Default
    private boolean isDeleted = false;


    // 비즈니스 메서드: 좋아요 수 조정
    public void increaseLike() { this.likeCount++; }
    public void decreaseLike() { this.likeCount--; }

    // 비즈니스 메서드: Verdict 변경 반영
    public void syncVerdict(VerdictType newVerdict) {
        this.currentVerdict = newVerdict;
    }
}