package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.translation.TranslationEvent;
import com.pairingplanet.pairing_planet.domain.enums.TranslatableEntity;
import com.pairingplanet.pairing_planet.domain.enums.TranslationStatus;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.translation.TranslationEventRepository;
import com.pairingplanet.pairing_planet.support.BaseIntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

class TranslationEventServiceTest extends BaseIntegrationTest {

    @Autowired
    private TranslationEventService translationEventService;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    private FoodMaster testFoodMaster;

    @BeforeEach
    void setUp() {
        testFoodMaster = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.saveAndFlush(testFoodMaster);
    }

    @Nested
    @DisplayName("Queue Food Master Translation")
    class QueueFoodMasterTranslationTests {

        @Test
        @DisplayName("Should create translation event with correct entity type")
        void queueFoodMasterTranslation_CreatesEvent() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            Optional<TranslationEvent> event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId());

            assertThat(event).isPresent();
            assertThat(event.get().getEntityType()).isEqualTo(TranslatableEntity.FOOD_MASTER);
            assertThat(event.get().getEntityId()).isEqualTo(testFoodMaster.getId());
        }

        @Test
        @DisplayName("Should set source locale correctly")
        void queueFoodMasterTranslation_SetsSourceLocale() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should set all target locales except source")
        void queueFoodMasterTranslation_SetsTargetLocales() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getTargetLocales()).hasSize(11);
            assertThat(event.getTargetLocales()).contains("en", "ja", "zh", "fr", "es", "it", "de", "ru", "pt", "el", "ar");
            assertThat(event.getTargetLocales()).doesNotContain("ko");
        }

        @Test
        @DisplayName("Should set status to PENDING")
        void queueFoodMasterTranslation_StatusIsPending() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getStatus()).isEqualTo(TranslationStatus.PENDING);
        }

        @Test
        @DisplayName("Should normalize BCP47 locale to short format")
        void queueFoodMasterTranslation_NormalizesLocale() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko-KR");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should not create duplicate event if one is pending")
        void queueFoodMasterTranslation_NoDuplicateWhenPending() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "ko");

            long count = translationEventRepository.findAll().stream()
                    .filter(e -> e.getEntityType() == TranslatableEntity.FOOD_MASTER)
                    .filter(e -> e.getEntityId().equals(testFoodMaster.getId()))
                    .count();

            assertThat(count).isEqualTo(1);
        }

        @Test
        @DisplayName("Should handle English as source locale")
        void queueFoodMasterTranslation_EnglishSource() {
            FoodMaster englishFood = FoodMaster.builder()
                    .name(Map.of("en-US", "Test Food"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.saveAndFlush(englishFood);

            translationEventService.queueFoodMasterTranslation(englishFood, "en");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, englishFood.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("en");
            assertThat(event.getTargetLocales()).contains("ko");
            assertThat(event.getTargetLocales()).doesNotContain("en");
        }

        @Test
        @DisplayName("Should default to ko for unknown locale")
        void queueFoodMasterTranslation_DefaultsToKorean() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, "xx-XX");

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }

        @Test
        @DisplayName("Should handle null locale gracefully")
        void queueFoodMasterTranslation_NullLocale() {
            translationEventService.queueFoodMasterTranslation(testFoodMaster, null);

            TranslationEvent event = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, testFoodMaster.getId())
                    .orElseThrow();

            assertThat(event.getSourceLocale()).isEqualTo("ko");
        }
    }
}
