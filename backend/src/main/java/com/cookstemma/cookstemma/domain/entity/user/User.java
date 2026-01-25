package com.cookstemma.cookstemma.domain.entity.user;

import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.entity.common.BaseEntity;
import com.cookstemma.cookstemma.domain.enums.AccountStatus;
import com.cookstemma.cookstemma.domain.enums.Gender;
import com.cookstemma.cookstemma.domain.enums.MeasurementPreference;
import com.cookstemma.cookstemma.domain.enums.Role;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;

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
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(nullable = false)
    private String locale;

    @Column(name = "default_cooking_style", length = 15)
    private String defaultCookingStyle; // ISO country code (e.g., "KR", "US", "JP") or "international"

    @Enumerated(EnumType.STRING)
    @Column(name = "measurement_preference", length = 20)
    @Builder.Default
    private MeasurementPreference measurementPreference = MeasurementPreference.ORIGINAL;

    @Column(name = "app_refresh_token")
    private String appRefreshToken;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private Role role;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private AccountStatus status;

    @Column(name = "marketing_agreed")
    @Builder.Default
    private Boolean marketingAgreed = false;

    // Legal acceptance tracking
    @Column(name = "terms_accepted_at")
    private Instant termsAcceptedAt;

    @Column(name = "terms_version", length = 20)
    private String termsVersion;

    @Column(name = "privacy_accepted_at")
    private Instant privacyAcceptedAt;

    @Column(name = "privacy_version", length = 20)
    private String privacyVersion;

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

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "delete_scheduled_at")
    private Instant deleteScheduledAt;

    @Column(name = "bio", length = 150)
    private String bio;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "bio_translations", columnDefinition = "jsonb")
    @Builder.Default
    private Map<String, String> bioTranslations = new HashMap<>();

    @Column(name = "youtube_url", length = 255)
    private String youtubeUrl;

    @Column(name = "instagram_handle", length = 30)
    private String instagramHandle;

    /**
     * Persona for bot users. Null for regular human users.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "persona_id")
    private BotPersona persona;
}