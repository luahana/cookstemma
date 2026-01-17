package com.pairingplanet.pairing_planet.domain.entity.bot;

import com.pairingplanet.pairing_planet.domain.entity.common.BaseEntity;
import com.pairingplanet.pairing_planet.domain.enums.BotDietaryFocus;
import com.pairingplanet.pairing_planet.domain.enums.BotSkillLevel;
import com.pairingplanet.pairing_planet.domain.enums.BotTone;
import com.pairingplanet.pairing_planet.domain.enums.BotVocabularyStyle;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.Map;

/**
 * Bot persona defining the personality and content generation style.
 * Each persona has a unique voice, skill level, and kitchen aesthetic.
 */
@Entity
@Table(name = "bot_personas")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class BotPersona extends BaseEntity {

    @Column(nullable = false, unique = true, length = 50)
    private String name;

    /**
     * Localized display names: {"en": "Chef Park", "ko": "박수진 셰프"}
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "display_name", nullable = false, columnDefinition = "jsonb")
    private Map<String, String> displayName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private BotTone tone;

    @Enumerated(EnumType.STRING)
    @Column(name = "skill_level", nullable = false, length = 20)
    private BotSkillLevel skillLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "dietary_focus", length = 50)
    private BotDietaryFocus dietaryFocus;

    @Enumerated(EnumType.STRING)
    @Column(name = "vocabulary_style", nullable = false, length = 30)
    private BotVocabularyStyle vocabularyStyle;

    @Column(nullable = false, length = 10)
    private String locale;

    @Column(name = "culinary_locale", nullable = false, length = 10)
    private String culinaryLocale;

    /**
     * Detailed prompt for AI image generation describing the kitchen aesthetic.
     */
    @Column(name = "kitchen_style_prompt", nullable = false, columnDefinition = "TEXT")
    private String kitchenStylePrompt;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean isActive = true;

    /**
     * Gets the display name for the given locale, falling back to English if not found.
     */
    public String getDisplayNameForLocale(String requestedLocale) {
        if (displayName == null) {
            return name;
        }
        String localeName = displayName.get(requestedLocale);
        if (localeName != null) {
            return localeName;
        }
        // Try language code only (e.g., "ko" from "ko-KR")
        String langCode = requestedLocale.split("-")[0];
        localeName = displayName.get(langCode);
        if (localeName != null) {
            return localeName;
        }
        // Fallback to English
        return displayName.getOrDefault("en", name);
    }
}
