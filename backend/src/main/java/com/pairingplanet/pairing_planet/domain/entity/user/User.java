package com.pairingplanet.pairing_planet.domain.entity.user;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.enums.AccountStatus;
import com.pairingplanet.pairing_planet.domain.enums.Gender;
import com.pairingplanet.pairing_planet.domain.enums.Role;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor @Builder
public class User extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(name = "profile_image_url", columnDefinition = "TEXT")
    private String profileImageUrl;

    private String email;

    @Enumerated(EnumType.STRING)
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(nullable = false)
    private String locale;

    @Column(name = "app_refresh_token")
    private String appRefreshToken;

    @Enumerated(EnumType.STRING)
    private Role role;

    @Enumerated(EnumType.STRING)
    private AccountStatus status;

    @Column(name = "marketing_agreed")
    private boolean marketingAgreed;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    @Column(name = "preferred_dietary_id")
    private Long preferredDietaryId;

    @Column(name = "is_bot", nullable = false)
    @Builder.Default
    private boolean isBot = false; // 기본값은 일반 유저

    @Column(name = "follower_count", nullable = false)
    @Builder.Default
    private int followerCount = 0;

    @Column(name = "following_count", nullable = false)
    @Builder.Default
    private int followingCount = 0;
}