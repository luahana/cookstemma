package com.pairingplanet.pairing_planet.dto.image;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import lombok.Builder;

@Builder
public record PostImageDto(
        Long imageId,   // 수정/삭제 시 식별용 (필요하다면 publicId UUID 사용)
        String url,     // <Image.network>에 넣을 주소
        int order       // (옵션) 사진 순서
) {
    public static PostImageDto from(Image image) {
        return PostImageDto.builder()
                .imageId(image.getId()) // 또는 image.getPublicId()
                .url(image.getUrl())
                .build();
    }
}