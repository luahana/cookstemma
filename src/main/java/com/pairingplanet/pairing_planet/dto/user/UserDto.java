package com.pairingplanet.pairing_planet.dto.user;

import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import lombok.Builder;


@Builder
public record UserDto(
        Long id,
        String username
) {
    public static UserDto from(User user, String tag) {
        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .build();
    }
}