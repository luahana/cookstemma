package com.cookstemma.cookstemma.dto.user;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.Gender;
import com.cookstemma.cookstemma.domain.enums.MeasurementPreference;
import com.cookstemma.cookstemma.domain.enums.Role;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.Builder;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Builder
public record UserDto(
        UUID id,                 // 유저 고유 ID
        String username,
        Role role,               // User role (USER, ADMIN, CREATOR, BOT)
        UUID profileImageId,     // [추가] 프로필 이미지의 UUID
        String profileImageUrl,  // [유지] 화면 표시용 전체 URL
        Gender gender,
        LocalDate birthDate,
        String locale,           // 언어 설정: ko-KR, en-US
        String defaultCookingStyle, // 기본 요리 스타일: ISO country code (e.g., "KR", "US") or "international"
        MeasurementPreference measurementPreference, // 측정 단위 선호: METRIC, US, ORIGINAL
        int followerCount,
        int followingCount,
        long recipeCount,        // Number of recipes created by user
        long logCount,           // Number of logs created by user
        int level,               // Gamification level (1-100)
        String levelName,        // Level title (beginner, homeCook, etc.)
        // XP Progress fields for profile display
        Integer totalXp,         // Total XP accumulated
        Integer xpForCurrentLevel,  // XP threshold for current level
        Integer xpForNextLevel,     // XP threshold for next level
        Double levelProgress,    // Progress percentage (0.0-1.0) within current level
        String bio,              // User bio/description (max 150 chars)
        String youtubeUrl,       // YouTube channel URL
        String instagramHandle,  // Instagram handle (without @)
        // Legal acceptance fields
        Instant termsAcceptedAt,
        String termsVersion,
        Instant privacyAcceptedAt,
        String privacyVersion,
        Boolean marketingAgreed
) {
    public static UserDto from(User user, String urlPrefix) {
        return from(user, urlPrefix, 0, 0, 1, "beginner", null, null, null, null);
    }

    public static UserDto from(User user, String urlPrefix, String locale) {
        return from(user, urlPrefix, 0, 0, 1, "beginner", locale, null, null, null);
    }

    public static UserDto from(User user, String urlPrefix, long recipeCount, long logCount) {
        return from(user, urlPrefix, recipeCount, logCount, 1, "beginner", null, null, null, null);
    }

    public static UserDto from(User user, String urlPrefix, long recipeCount, long logCount, int level, String levelName) {
        return from(user, urlPrefix, recipeCount, logCount, level, levelName, null, null, null, null);
    }

    public static UserDto from(User user, String urlPrefix, long recipeCount, long logCount, int level, String levelName, String locale) {
        return from(user, urlPrefix, recipeCount, logCount, level, levelName, locale, null, null, null);
    }

    /**
     * Full factory method with XP progress information
     */
    public static UserDto from(User user, String urlPrefix, long recipeCount, long logCount,
                               int level, String levelName, String locale,
                               Integer totalXp, Integer xpForCurrentLevel, Integer xpForNextLevel) {
        if (user == null) return null;

        // Build profile image URL - clients handle fallback UI for missing images
        String profileUrl = user.getProfileImageUrl();
        if (profileUrl != null && !profileUrl.isEmpty() && !profileUrl.startsWith("http") && urlPrefix != null) {
            profileUrl = urlPrefix + "/" + profileUrl;
        } else if (profileUrl != null && profileUrl.isEmpty()) {
            profileUrl = null; // Normalize empty string to null
        }

        // Get localized bio using translations or fallback to original
        String localizedBio = LocaleUtils.getLocalizedValue(
                user.getBioTranslations(),
                locale,
                user.getBio()
        );

        // Calculate level progress if XP values are provided
        Double levelProgress = null;
        if (totalXp != null && xpForCurrentLevel != null && xpForNextLevel != null) {
            if (xpForNextLevel > xpForCurrentLevel) {
                levelProgress = Math.min(1.0, (double) (totalXp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel));
            } else {
                levelProgress = 1.0; // Max level reached
            }
        }

        return UserDto.builder()
                .id(user.getPublicId())
                .username(user.getUsername())
                .role(user.getRole())
                .profileImageUrl(profileUrl)
                .gender(user.getGender())
                .birthDate(user.getBirthDate())
                .locale(user.getLocale())
                .defaultCookingStyle(user.getDefaultCookingStyle())
                .measurementPreference(user.getMeasurementPreference())
                .followerCount(user.getFollowerCount())
                .followingCount(user.getFollowingCount())
                .recipeCount(recipeCount)
                .logCount(logCount)
                .level(level)
                .levelName(levelName)
                .totalXp(totalXp)
                .xpForCurrentLevel(xpForCurrentLevel)
                .xpForNextLevel(xpForNextLevel)
                .levelProgress(levelProgress)
                .bio(localizedBio)
                .youtubeUrl(user.getYoutubeUrl())
                .instagramHandle(user.getInstagramHandle())
                .termsAcceptedAt(user.getTermsAcceptedAt())
                .termsVersion(user.getTermsVersion())
                .privacyAcceptedAt(user.getPrivacyAcceptedAt())
                .privacyVersion(user.getPrivacyVersion())
                .marketingAgreed(user.getMarketingAgreed())
                .build();
    }
}