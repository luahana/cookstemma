package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.entity.translation.TranslationEvent;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AutocompleteType;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.domain.enums.TranslatableEntity;
import com.cookstemma.cookstemma.domain.enums.TranslationStatus;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientAdminDto;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientFilterDto;
import com.cookstemma.cookstemma.repository.autocomplete.AutocompleteItemRepository;
import com.cookstemma.cookstemma.repository.ingredient.UserSuggestedIngredientRepository;
import com.cookstemma.cookstemma.repository.translation.TranslationEventRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AdminSuggestedIngredientServiceTest extends BaseIntegrationTest {

    @Autowired
    private AdminSuggestedIngredientService adminSuggestedIngredientService;

    @Autowired
    private UserSuggestedIngredientRepository suggestedIngredientRepository;

    @Autowired
    private AutocompleteItemRepository autocompleteItemRepository;

    @Autowired
    private TranslationEventRepository translationEventRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private UserSuggestedIngredient pendingSuggestion;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        pendingSuggestion = UserSuggestedIngredient.builder()
                .suggestedName("고춧가루")
                .ingredientType(IngredientType.SEASONING)
                .localeCode("ko-KR")
                .user(testUser)
                .status(SuggestionStatus.PENDING)
                .build();
        suggestedIngredientRepository.saveAndFlush(pendingSuggestion);
    }

    @Nested
    @DisplayName("Get Suggested Ingredients")
    class GetSuggestedIngredientsTests {

        @Test
        @DisplayName("Should return all suggested ingredients with pagination")
        void getSuggestedIngredients_ReturnsPaginatedResults() {
            SuggestedIngredientFilterDto filter = new SuggestedIngredientFilterDto(
                    null, null, null, null, null, "createdAt", "desc"
            );

            Page<SuggestedIngredientAdminDto> result = adminSuggestedIngredientService
                    .getSuggestedIngredients(filter, 0, 20);

            assertThat(result.getContent()).isNotEmpty();
            assertThat(result.getContent().get(0).suggestedName()).isEqualTo("고춧가루");
        }

        @Test
        @DisplayName("Should filter by ingredient type")
        void getSuggestedIngredients_FiltersByIngredientType() {
            // Add a MAIN ingredient suggestion
            UserSuggestedIngredient mainIngredient = UserSuggestedIngredient.builder()
                    .suggestedName("소고기")
                    .ingredientType(IngredientType.MAIN)
                    .localeCode("ko-KR")
                    .user(testUser)
                    .status(SuggestionStatus.PENDING)
                    .build();
            suggestedIngredientRepository.saveAndFlush(mainIngredient);

            SuggestedIngredientFilterDto filter = new SuggestedIngredientFilterDto(
                    null, IngredientType.MAIN, null, null, null, "createdAt", "desc"
            );

            Page<SuggestedIngredientAdminDto> result = adminSuggestedIngredientService
                    .getSuggestedIngredients(filter, 0, 20);

            assertThat(result.getContent()).allMatch(dto -> dto.ingredientType() == IngredientType.MAIN);
        }

        @Test
        @DisplayName("Should filter by status")
        void getSuggestedIngredients_FiltersByStatus() {
            SuggestedIngredientFilterDto filter = new SuggestedIngredientFilterDto(
                    null, null, null, SuggestionStatus.PENDING, null, "createdAt", "desc"
            );

            Page<SuggestedIngredientAdminDto> result = adminSuggestedIngredientService
                    .getSuggestedIngredients(filter, 0, 20);

            assertThat(result.getContent()).allMatch(dto -> dto.status() == SuggestionStatus.PENDING);
        }

        @Test
        @DisplayName("Should filter by suggested name")
        void getSuggestedIngredients_FiltersBySuggestedName() {
            SuggestedIngredientFilterDto filter = new SuggestedIngredientFilterDto(
                    "고춧", null, null, null, null, "createdAt", "desc"
            );

            Page<SuggestedIngredientAdminDto> result = adminSuggestedIngredientService
                    .getSuggestedIngredients(filter, 0, 20);

            assertThat(result.getContent()).isNotEmpty();
            assertThat(result.getContent()).allMatch(dto ->
                    dto.suggestedName().toLowerCase().contains("고춧"));
        }
    }

    @Nested
    @DisplayName("Update Status - Approval Flow")
    class ApprovalFlowTests {

        @Test
        @DisplayName("Should create AutocompleteItem and queue translation when suggestion is approved")
        void approveSuggestion_CreatesAutocompleteItemAndQueuesTranslation() {
            SuggestedIngredientAdminDto result = adminSuggestedIngredientService.updateStatus(
                    pendingSuggestion.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            assertThat(result.status()).isEqualTo(SuggestionStatus.APPROVED);

            // Verify AutocompleteItem was created
            UserSuggestedIngredient updated = suggestedIngredientRepository
                    .findByPublicId(pendingSuggestion.getPublicId())
                    .orElseThrow();

            assertThat(updated.getAutocompleteItemRef()).isNotNull();
            AutocompleteItem autocompleteItem = updated.getAutocompleteItemRef();
            assertThat(autocompleteItem.getType()).isEqualTo(AutocompleteType.SEASONING);
            assertThat(autocompleteItem.getName()).containsKey("ko-KR");
            assertThat(autocompleteItem.getName().get("ko-KR")).isEqualTo("고춧가루");

            // Verify translation event was queued
            TranslationEvent translationEvent = translationEventRepository
                    .findByEntityTypeAndEntityId(TranslatableEntity.AUTOCOMPLETE_ITEM, autocompleteItem.getId())
                    .orElseThrow(() -> new AssertionError("Translation event should be created"));

            assertThat(translationEvent.getStatus()).isEqualTo(TranslationStatus.PENDING);
            assertThat(translationEvent.getSourceLocale()).isEqualTo("ko-KR");  // BCP47 format
            assertThat(translationEvent.getTargetLocales()).hasSize(19); // All locales except source
            assertThat(translationEvent.getTargetLocales()).doesNotContain("ko-KR");  // BCP47 format
        }

        @Test
        @DisplayName("Should map MAIN ingredient type to MAIN_INGREDIENT autocomplete type")
        void approveSuggestion_MapsMainIngredientType() {
            UserSuggestedIngredient mainSuggestion = UserSuggestedIngredient.builder()
                    .suggestedName("Beef")
                    .ingredientType(IngredientType.MAIN)
                    .localeCode("en-US")
                    .user(testUser)
                    .status(SuggestionStatus.PENDING)
                    .build();
            suggestedIngredientRepository.saveAndFlush(mainSuggestion);

            adminSuggestedIngredientService.updateStatus(
                    mainSuggestion.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            UserSuggestedIngredient updated = suggestedIngredientRepository
                    .findByPublicId(mainSuggestion.getPublicId())
                    .orElseThrow();

            assertThat(updated.getAutocompleteItemRef().getType())
                    .isEqualTo(AutocompleteType.MAIN_INGREDIENT);
        }

        @Test
        @DisplayName("Should map SECONDARY ingredient type to SECONDARY_INGREDIENT autocomplete type")
        void approveSuggestion_MapsSecondaryIngredientType() {
            UserSuggestedIngredient secondarySuggestion = UserSuggestedIngredient.builder()
                    .suggestedName("Onion")
                    .ingredientType(IngredientType.SECONDARY)
                    .localeCode("en-US")
                    .user(testUser)
                    .status(SuggestionStatus.PENDING)
                    .build();
            suggestedIngredientRepository.saveAndFlush(secondarySuggestion);

            adminSuggestedIngredientService.updateStatus(
                    secondarySuggestion.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            UserSuggestedIngredient updated = suggestedIngredientRepository
                    .findByPublicId(secondarySuggestion.getPublicId())
                    .orElseThrow();

            assertThat(updated.getAutocompleteItemRef().getType())
                    .isEqualTo(AutocompleteType.SECONDARY_INGREDIENT);
        }

        @Test
        @DisplayName("Should not create AutocompleteItem when suggestion is rejected")
        void rejectSuggestion_DoesNotCreateAutocompleteItem() {
            SuggestedIngredientAdminDto result = adminSuggestedIngredientService.updateStatus(
                    pendingSuggestion.getPublicId(),
                    SuggestionStatus.REJECTED
            );

            assertThat(result.status()).isEqualTo(SuggestionStatus.REJECTED);

            UserSuggestedIngredient updated = suggestedIngredientRepository
                    .findByPublicId(pendingSuggestion.getPublicId())
                    .orElseThrow();

            assertThat(updated.getAutocompleteItemRef()).isNull();
        }

        @Test
        @DisplayName("Should throw exception when suggestion not found")
        void updateStatus_NotFound_ThrowsException() {
            assertThatThrownBy(() -> adminSuggestedIngredientService.updateStatus(
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
            UserSuggestedIngredient suggestionWithShortLocale = UserSuggestedIngredient.builder()
                    .suggestedName("Salt")
                    .ingredientType(IngredientType.SEASONING)
                    .localeCode("en")
                    .user(testUser)
                    .status(SuggestionStatus.PENDING)
                    .build();
            suggestedIngredientRepository.saveAndFlush(suggestionWithShortLocale);

            adminSuggestedIngredientService.updateStatus(
                    suggestionWithShortLocale.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            UserSuggestedIngredient updated = suggestedIngredientRepository
                    .findByPublicId(suggestionWithShortLocale.getPublicId())
                    .orElseThrow();

            AutocompleteItem autocompleteItem = updated.getAutocompleteItemRef();
            assertThat(autocompleteItem.getName()).containsKey("en-US");
            assertThat(autocompleteItem.getName().get("en-US")).isEqualTo("Salt");
        }

        @Test
        @DisplayName("Should handle BCP47 locale format correctly")
        void bcp47Locale_UsedAsIs() {
            UserSuggestedIngredient suggestionWithBcp47 = UserSuggestedIngredient.builder()
                    .suggestedName("Pepper")
                    .ingredientType(IngredientType.SEASONING)
                    .localeCode("en-US")
                    .user(testUser)
                    .status(SuggestionStatus.PENDING)
                    .build();
            suggestedIngredientRepository.saveAndFlush(suggestionWithBcp47);

            adminSuggestedIngredientService.updateStatus(
                    suggestionWithBcp47.getPublicId(),
                    SuggestionStatus.APPROVED
            );

            UserSuggestedIngredient updated = suggestedIngredientRepository
                    .findByPublicId(suggestionWithBcp47.getPublicId())
                    .orElseThrow();

            AutocompleteItem autocompleteItem = updated.getAutocompleteItemRef();
            assertThat(autocompleteItem.getName()).containsKey("en-US");
        }
    }
}
