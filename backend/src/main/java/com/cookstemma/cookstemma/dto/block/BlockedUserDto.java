package com.cookstemma.cookstemma.dto.block;

import com.cookstemma.cookstemma.domain.entity.user.User;
import lombok.Builder;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.UUID;

@Builder
public record BlockedUserDto(
        UUID publicId,
        String username,
        String profileImageUrl,
        Instant blockedAt
) {
    public static BlockedUserDto from(User user, String urlPrefix, Instant blockedAt) {
        String profileUrl = user.getProfileImageUrl();

        if (profileUrl != null && !profileUrl.isEmpty()) {
            if (!profileUrl.startsWith("http") && urlPrefix != null) {
                profileUrl = urlPrefix + "/" + profileUrl;
            }
        } else {
            String encodedName = URLEncoder.encode(user.getUsername(), StandardCharsets.UTF_8);
            profileUrl = "https://ui-avatars.com/api/?name=" + encodedName + "&background=random&color=fff";
        }

        return BlockedUserDto.builder()
                .publicId(user.getPublicId())
                .username(user.getUsername())
                .profileImageUrl(profileUrl)
                .blockedAt(blockedAt)
                .build();
    }
}
