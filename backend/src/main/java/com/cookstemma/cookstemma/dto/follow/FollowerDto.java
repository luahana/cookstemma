package com.cookstemma.cookstemma.dto.follow;

import com.cookstemma.cookstemma.domain.entity.user.User;
import lombok.Builder;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.UUID;

@Builder
public record FollowerDto(
        UUID publicId,
        String username,
        String profileImageUrl,
        Boolean isFollowingBack,  // Does the current user follow this person back?
        Instant followedAt        // When the follow relationship was created
) {
    public static FollowerDto from(User user, String urlPrefix, Boolean isFollowingBack, Instant followedAt) {
        String profileUrl = user.getProfileImageUrl();

        if (profileUrl != null && !profileUrl.isEmpty()) {
            if (!profileUrl.startsWith("http") && urlPrefix != null) {
                profileUrl = urlPrefix + "/" + profileUrl;
            }
        } else {
            String encodedName = URLEncoder.encode(user.getUsername(), StandardCharsets.UTF_8);
            profileUrl = "https://ui-avatars.com/api/?name=" + encodedName + "&background=random&color=fff";
        }

        return FollowerDto.builder()
                .publicId(user.getPublicId())
                .username(user.getUsername())
                .profileImageUrl(profileUrl)
                .isFollowingBack(isFollowingBack)
                .followedAt(followedAt)
                .build();
    }
}
