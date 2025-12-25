package com.pairingplanet.pairing_planet.dto.user;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import lombok.Builder;

import java.util.UUID;


@Builder
public record UserDto(
        UUID id,
        String username
) {
    public static UserDto from(User user, String tag) {
        return UserDto.builder()
                .id(user.getPublicId())
                .username(user.getUsername())
                .build();
    }
}