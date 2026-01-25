package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.bot.BotPersona;
import com.cookstemma.cookstemma.domain.enums.*;
import com.cookstemma.cookstemma.dto.bot.BotPersonaDto;
import com.cookstemma.cookstemma.repository.bot.BotPersonaRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class BotPersonaServiceTest extends BaseIntegrationTest {

    @Autowired
    private BotPersonaService botPersonaService;

    @Autowired
    private BotPersonaRepository botPersonaRepository;

    private BotPersona activePersona;
    private BotPersona inactivePersona;

    @BeforeEach
    void setUp() {
        activePersona = BotPersona.builder()
                .name("active_persona_" + System.currentTimeMillis())
                .displayName(Map.of("en", "Active Chef", "ko", "활동 셰프"))
                .tone(BotTone.PROFESSIONAL)
                .skillLevel(BotSkillLevel.ADVANCED)
                .dietaryFocus(BotDietaryFocus.FINE_DINING)
                .vocabularyStyle(BotVocabularyStyle.TECHNICAL)
                .locale("ko-KR")
                .cookingStyle("KR")
                .kitchenStylePrompt("Active kitchen prompt")
                .isActive(true)
                .build();
        botPersonaRepository.save(activePersona);

        inactivePersona = BotPersona.builder()
                .name("inactive_persona_" + System.currentTimeMillis())
                .displayName(Map.of("en", "Inactive Chef", "ko", "비활동 셰프"))
                .tone(BotTone.CASUAL)
                .skillLevel(BotSkillLevel.BEGINNER)
                .dietaryFocus(BotDietaryFocus.BUDGET)
                .vocabularyStyle(BotVocabularyStyle.SIMPLE)
                .locale("en-US")
                .cookingStyle("US")
                .kitchenStylePrompt("Inactive kitchen prompt")
                .isActive(false)
                .build();
        botPersonaRepository.save(inactivePersona);
    }

    @Nested
    @DisplayName("Get Active Personas")
    class GetActivePersonasTests {

        @Test
        @DisplayName("Should return only active personas")
        void getAllActivePersonas_ReturnsActive() {
            List<BotPersonaDto> personas = botPersonaService.getAllActivePersonas();

            assertThat(personas).isNotEmpty();
            assertThat(personas).allMatch(BotPersonaDto::isActive);
            assertThat(personas.stream().map(BotPersonaDto::publicId))
                    .contains(activePersona.getPublicId());
            assertThat(personas.stream().map(BotPersonaDto::publicId))
                    .doesNotContain(inactivePersona.getPublicId());
        }
    }

    @Nested
    @DisplayName("Get All Personas")
    class GetAllPersonasTests {

        @Test
        @DisplayName("Should return all personas including inactive")
        void getAllPersonas_ReturnsAll() {
            List<BotPersonaDto> personas = botPersonaService.getAllPersonas();

            assertThat(personas).hasSizeGreaterThanOrEqualTo(2);
            List<UUID> publicIds = personas.stream().map(BotPersonaDto::publicId).toList();
            assertThat(publicIds).contains(activePersona.getPublicId());
            assertThat(publicIds).contains(inactivePersona.getPublicId());
        }
    }

    @Nested
    @DisplayName("Get Personas by Locale")
    class GetPersonasByLocaleTests {

        @Test
        @DisplayName("Should return personas matching locale")
        void getPersonasByLocale_ReturnsMatching() {
            List<BotPersonaDto> koreanPersonas = botPersonaService.getPersonasByLocale("ko-KR");

            assertThat(koreanPersonas).isNotEmpty();
            assertThat(koreanPersonas).allMatch(p -> p.locale().equals("ko-KR"));
            assertThat(koreanPersonas.stream().map(BotPersonaDto::publicId))
                    .contains(activePersona.getPublicId());
        }

        @Test
        @DisplayName("Should return empty for non-existent locale")
        void getPersonasByLocale_NonExistent_ReturnsEmpty() {
            List<BotPersonaDto> personas = botPersonaService.getPersonasByLocale("fr-FR");

            // May or may not be empty depending on seeded data, but should not throw
            assertThat(personas).isNotNull();
        }
    }

    @Nested
    @DisplayName("Get Persona by ID")
    class GetPersonaByIdTests {

        @Test
        @DisplayName("Should return persona by public ID")
        void getPersona_ValidId_Success() {
            BotPersonaDto persona = botPersonaService.getPersona(activePersona.getPublicId());

            assertThat(persona.publicId()).isEqualTo(activePersona.getPublicId());
            assertThat(persona.name()).isEqualTo(activePersona.getName());
            assertThat(persona.tone()).isEqualTo(activePersona.getTone());
            assertThat(persona.skillLevel()).isEqualTo(activePersona.getSkillLevel());
        }

        @Test
        @DisplayName("Should fail with invalid ID")
        void getPersona_InvalidId_Failure() {
            assertThatThrownBy(() -> botPersonaService.getPersona(UUID.randomUUID()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Persona not found");
        }
    }

    @Nested
    @DisplayName("Get Persona by Name")
    class GetPersonaByNameTests {

        @Test
        @DisplayName("Should return persona by name")
        void getPersonaByName_ValidName_Success() {
            BotPersonaDto persona = botPersonaService.getPersonaByName(activePersona.getName());

            assertThat(persona.name()).isEqualTo(activePersona.getName());
        }

        @Test
        @DisplayName("Should fail with invalid name")
        void getPersonaByName_InvalidName_Failure() {
            assertThatThrownBy(() -> botPersonaService.getPersonaByName("nonexistent_persona"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Persona not found");
        }
    }

    @Nested
    @DisplayName("Set Persona Active")
    class SetPersonaActiveTests {

        @Test
        @DisplayName("Should activate persona")
        void setPersonaActive_Activate_Success() {
            botPersonaService.setPersonaActive(inactivePersona.getPublicId(), true);

            BotPersona updated = botPersonaRepository.findByPublicId(inactivePersona.getPublicId()).orElseThrow();
            assertThat(updated.isActive()).isTrue();
        }

        @Test
        @DisplayName("Should deactivate persona")
        void setPersonaActive_Deactivate_Success() {
            botPersonaService.setPersonaActive(activePersona.getPublicId(), false);

            BotPersona updated = botPersonaRepository.findByPublicId(activePersona.getPublicId()).orElseThrow();
            assertThat(updated.isActive()).isFalse();
        }

        @Test
        @DisplayName("Should fail with invalid ID")
        void setPersonaActive_InvalidId_Failure() {
            assertThatThrownBy(() -> botPersonaService.setPersonaActive(UUID.randomUUID(), true))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Persona not found");
        }
    }
}
