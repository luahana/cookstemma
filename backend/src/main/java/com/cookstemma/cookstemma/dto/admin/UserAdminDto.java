package com.cookstemma.cookstemma.dto.admin;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import com.cookstemma.cookstemma.domain.enums.Role;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record UserAdminDto(
        UUID publicId,
        String username,
        String email,
        Role role,
        AccountStatus status,
        Instant createdAt,
        Instant lastLoginAt
) {
    public static UserAdminDto from(User user) {
        return UserAdminDto.builder()
                .publicId(user.getPublicId())
                .username(user.getUsername())
                .email(user.getEmail())
                .role(user.getRole())
                .status(user.getStatus())
                .createdAt(user.getCreatedAt())
                .lastLoginAt(user.getLastLoginAt())
                .build();
    }
}
