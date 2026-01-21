package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.food.UserSuggestedFood;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.dto.admin.UserSuggestedFoodDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.food.UserSuggestedFoodRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AdminSuggestedFoodServiceTest extends BaseIntegrationTest {

    @Autowired
    private AdminSuggestedFoodService adminSuggestedFoodService;

    @Autowired
    private UserSuggestedFoodRepository userSuggestedFoodRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private UserSuggestedFood pendingSuggestion;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        pendingSuggestion = UserSuggestedFood.builder()
                .suggestedName("김치찌개")
                .localeCode("ko")
                .user(testUser)
                .status(SuggestionStatus.PENDING)
                .build();
        userSuggestedFoodRepository.saveAndFlush(pendingSuggestion);
    }

    @Nested
    @DisplayName("Update Status - Approval Flow")
    class ApprovalFlowTests {

        @Test
        @DisplayName("Should create FoodMaster when suggestion is approved")
        void approveSuggestion_CreatesFoodMaster() {
            UserSuggestedFoodDto result = adminSuggestedFoodService.updateStatus(
                    pendingSuggestion.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            assertThat(result.status()).isEqualTo(SuggestionStatus.APPROVED);

            // Verify FoodMaster was created
            UserSuggestedFood updated = userSuggestedFoodRepository
                    .findByPublicId(pendingSuggestion.getPublicId())
                    .orElseThrow();

            assertThat(updated.getMasterFoodRef()).isNotNull();
            FoodMaster foodMaster = updated.getMasterFoodRef();
            assertThat(foodMaster.getName()).containsKey("ko-KR");
            assertThat(foodMaster.getName().get("ko-KR")).isEqualTo("김치찌개");
            assertThat(foodMaster.getIsVerified()).isTrue();
        }

        @Test
        @DisplayName("Should queue translation when suggestion is approved")
        void approveSuggestion_QueuesTranslation() {
            adminSuggestedFoodService.updateStatus(
                    pendingSuggestion.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            UserSuggestedFood updated = userSuggestedFoodRepository
                    .findByPublicId(pendingSuggestion.getPublicId())
                    .orElseThrow();

            FoodMaster foodMaster = updated.getMasterFoodRef();

            // Verify translation event was created
            Optional<TranslationEvent> translationEvent = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.FOOD_MASTER, foodMaster.getId());

            assertThat(translationEvent).isPresent();
            assertThat(translationEvent.get().getSourceLocale()).isEqualTo("ko-KR");  // BCP47 format
            assertThat(translationEvent.get().getStatus()).isEqualTo(TranslationStatus.PENDING);
            assertThat(translationEvent.get().getTargetLocales()).hasSize(19); // 20 - 1 (source)
            assertThat(translationEvent.get().getTargetLocales()).contains("en-US", "ja-JP", "zh-CN", "fr-FR");  // BCP47 format
        }

        @Test
        @DisplayName("Should handle BCP47 locale format correctly")
        void approveSuggestion_HandlesBcp47Locale() {
            UserSuggestedFood suggestionWithBcp47 = UserSuggestedFood.builder()
                    .suggestedName("Kimchi Stew")
                    .localeCode("en-US")
                    .user(testUser)
                    .status(SuggestionStatus.PENDING)
                    .build();
            userSuggestedFoodRepository.saveAndFlush(suggestionWithBcp47);

            adminSuggestedFoodService.updateStatus(
                    suggestionWithBcp47.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            UserSuggestedFood updated = userSuggestedFoodRepository
                    .findByPublicId(suggestionWithBcp47.getPublicId())
                    .orElseThrow();

            FoodMaster foodMaster = updated.getMasterFoodRef();
            assertThat(foodMaster.getName()).containsKey("en-US");
            assertThat(foodMaster.getName().get("en-US")).isEqualTo("Kimchi Stew");
        }

        @Test
        @DisplayName("Should not create FoodMaster when suggestion is rejected")
        void rejectSuggestion_DoesNotCreateFoodMaster() {
            UserSuggestedFoodDto result = adminSuggestedFoodService.updateStatus(
                    pendingSuggestion.getPublicId(),
                    SuggestionStatus.REJECTED
            );

            assertThat(result.status()).isEqualTo(SuggestionStatus.REJECTED);

            UserSuggestedFood updated = userSuggestedFoodRepository
                    .findByPublicId(pendingSuggestion.getPublicId())
                    .orElseThrow();

            assertThat(updated.getMasterFoodRef()).isNull();
        }

        @Test
        @DisplayName("Should throw exception when suggestion not found")
        void updateStatus_NotFound_ThrowsException() {
            assertThatThrownBy(() -> adminSuggestedFoodService.updateStatus(
                    java.util.UUID.randomUUID(),
                    SuggestionStatus.APPROVED
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not found");
        }
    }

    @Nested
    @DisplayName("Locale Conversion Tests")
    class LocaleConversionTests {

        @Test
        @DisplayName("Should convert short locale to BCP47 format")
        void shortLocale_ConvertedToBcp47() {
            String[] shortLocales = {"en", "ko", "ja", "zh", "fr", "de", "es", "it", "pt", "ru",
                                     "ar", "id", "vi", "hi", "th", "pl", "tr", "nl", "sv", "fa"};
            String[] expectedBcp47 = {"en-US", "ko-KR", "ja-JP", "zh-CN", "fr-FR", "de-DE",
                                      "es-ES", "it-IT", "pt-BR", "ru-RU", "ar-SA", "id-ID",
                                      "vi-VN", "hi-IN", "th-TH", "pl-PL", "tr-TR", "nl-NL",
                                      "sv-SE", "fa-IR"};

            for (int i = 0; i < shortLocales.length; i++) {
                UserSuggestedFood suggestion = UserSuggestedFood.builder()
                        .suggestedName("Test Food " + i)
                        .localeCode(shortLocales[i])
                        .user(testUser)
                        .status(SuggestionStatus.PENDING)
                        .build();
                userSuggestedFoodRepository.saveAndFlush(suggestion);

                adminSuggestedFoodService.updateStatus(
                        suggestion.getPublicId(),
                        SuggestionStatus.APPROVED
                );

                UserSuggestedFood updated = userSuggestedFoodRepository
                        .findByPublicId(suggestion.getPublicId())
                        .orElseThrow();

                FoodMaster foodMaster = updated.getMasterFoodRef();
                assertThat(foodMaster.getName()).containsKey(expectedBcp47[i]);
            }
        }
    }
}
