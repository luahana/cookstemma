package com.cookstemma.cookstemma.dto.image;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import lombok.Builder;

import java.util.UUID;

@Builder
public record PostImageDto(
        UUID imageId,   // 수정/삭제 시 식별용 (필요하다면 publicId UUID 사용)
        String url,     // <Image.network>에 넣을 주소
        int order       // (옵션) 사진 순서
) {
    public static PostImageDto from(Image image, String urlPrefix) {
        return PostImageDto.builder()
                .imageId(image.getPublicId()) // 또는 image.getPublicId()
                .url(urlPrefix + "/" + image.getStoredFilename())
                .build();
    }
}