package com.pairingplanet.pairing_planet.dto.user;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import lombok.Builder;

import java.util.UUID;

@Builder
public record UserDto(
        UUID id,
        String username,
        String profileImageUrl
) {
    /**
     * User 엔티티를 UserDto로 변환합니다.
     * @param user 변환할 유저 엔티티
     * @param urlPrefix 프로필 이미지 경로 구성을 위한 프리픽스 (선택 사항)
     */
    public static UserDto from(User user, String urlPrefix) {
        if (user == null) return null;

        // 프로필 이미지 URL 처리: 저장된 값이 파일명 형태일 경우 프리픽스를 결합합니다.
        String profileUrl = user.getProfileImageUrl();
        if (profileUrl != null && !profileUrl.startsWith("http") && urlPrefix != null) {
            profileUrl = urlPrefix + "/" + profileUrl;
        }

        return UserDto.builder()
                .id(user.getPublicId()) // UUID
                .username(user.getUsername())
                .profileImageUrl(profileUrl)
                .build();
    }
}