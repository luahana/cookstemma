package com.pairingplanet.pairing_planet.dto.bot;

import com.pairingplanet.pairing_planet.domain.entity.bot.BotPersona;
import com.pairingplanet.pairing_planet.domain.enums.BotDietaryFocus;
import com.pairingplanet.pairing_planet.domain.enums.BotSkillLevel;
import com.pairingplanet.pairing_planet.domain.enums.BotTone;
import com.pairingplanet.pairing_planet.domain.enums.BotVocabularyStyle;
import lombok.Builder;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * DTO for bot persona information.
 */
@Builder
public record BotPersonaDto(
        UUID publicId,
        String name,
        Map<String, String> displayName,
        BotTone tone,
        BotSkillLevel skillLevel,
        BotDietaryFocus dietaryFocus,
        BotVocabularyStyle vocabularyStyle,
        String locale,
        String culinaryLocale,
        String kitchenStylePrompt,
        boolean isActive,
        Instant createdAt
) {
    public static BotPersonaDto from(BotPersona persona) {
        return BotPersonaDto.builder()
                .publicId(persona.getPublicId())
                .name(persona.getName())
                .displayName(persona.getDisplayName())
                .tone(persona.getTone())
                .skillLevel(persona.getSkillLevel())
                .dietaryFocus(persona.getDietaryFocus())
                .vocabularyStyle(persona.getVocabularyStyle())
                .locale(persona.getLocale())
                .culinaryLocale(persona.getCulinaryLocale())
                .kitchenStylePrompt(persona.getKitchenStylePrompt())
                .isActive(persona.isActive())
                .createdAt(persona.getCreatedAt())
                .build();
    }
}
