package com.pairingplanet.pairing_planet.dto.user;

import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.Gender;
import lombok.Builder;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.UUID;

@Builder
public record UserDto(
        UUID id,                 // 유저 고유 ID
        String username,
        UUID profileImageId,     // [추가] 프로필 이미지의 UUID
        String profileImageUrl,  // [유지] 화면 표시용 전체 URL
        Gender gender,
        LocalDate birthDate
) {
    public static UserDto from(User user, String urlPrefix) {
        if (user == null) return null;

        String profileUrl = user.getProfileImageUrl();
        // [추가] 실제 이미지 엔티티의 UUID 정보는 필요시 DB에서 가져오거나
        // User 엔티티가 Image 엔티티를 참조하게 설계했다면 바로 매핑 가능합니다.
        // 현재는 파일명 기반이므로 URL 처리 로직을 유지합니다.

        if (profileUrl != null && !profileUrl.isEmpty()) {
            if (!profileUrl.startsWith("http") && urlPrefix != null) {
                profileUrl = urlPrefix + "/" + profileUrl;
            }
        } else {
            String encodedName = URLEncoder.encode(user.getUsername(), StandardCharsets.UTF_8);
            profileUrl = "https://ui-avatars.com/api/?name=" + encodedName + "&background=random&color=fff";
        }

        return UserDto.builder()
                .id(user.getPublicId())
                .username(user.getUsername())
                .profileImageUrl(profileUrl)
                .gender(user.getGender())
                .birthDate(user.getBirthDate())
                .build();
    }
}