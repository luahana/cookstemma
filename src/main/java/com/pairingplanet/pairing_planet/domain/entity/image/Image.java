package com.pairingplanet.pairing_planet.domain.entity.image;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.enums.ImageStatus;
import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "images")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Image extends BaseEntity {

    @Column(nullable = false, unique = true)
    private String url; // 전체 URL (조회용)

    @Column(nullable = false)
    private String storedFilename; // S3 Key (삭제용, 예: posts/daily/uuid.jpg)

    private String originalFilename;

    @Enumerated(EnumType.STRING)
    private ImageStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ImageType type;

    private Long uploaderId; // 업로더 ID (보안/추적용)

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id") // DB 컬럼명
    private Post post;


    @Builder
    public Image(String url, String storedFilename, String originalFilename, ImageType type, Long uploaderId) {
        this.url = url;
        this.storedFilename = storedFilename;
        this.originalFilename = originalFilename;
        this.type = type; // DB에 저장
        this.uploaderId = uploaderId;
        this.status = ImageStatus.TEMP;
    }

    public void activate() {
        this.status = ImageStatus.ACTIVE;
    }

    public void setPost(Post post) {
        this.post = post;
        this.status = ImageStatus.ACTIVE; // 포스트와 연결되면 ACTIVE로 변경
    }

    // 포스트 삭제/수정 시 연결 끊기용
    public void unsetPost() {
        this.post = null;
        // 정책에 따라 status를 TEMP로 돌릴지, 그대로 둘지 결정
        // 보통 연결이 끊기면 다시 TEMP로 돌려서 GC 대상이 되게 하거나, 즉시 삭제합니다.
    }
}