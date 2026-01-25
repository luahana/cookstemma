package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.autocomplete.AutocompleteItem;
import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.enums.AutocompleteType;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientAdminDto;
import com.cookstemma.cookstemma.dto.admin.SuggestedIngredientFilterDto;
import com.cookstemma.cookstemma.repository.autocomplete.AutocompleteItemRepository;
import com.cookstemma.cookstemma.repository.ingredient.UserSuggestedIngredientRepository;
import com.cookstemma.cookstemma.repository.specification.UserSuggestedIngredientSpecification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminSuggestedIngredientService {

    private final UserSuggestedIngredientRepository repository;
    private final AutocompleteItemRepository autocompleteItemRepository;
    private final TranslationEventService translationEventService;

    private static final Map<String, String> LOCALE_TO_BCP47 = Map.ofEntries(
            Map.entry("en", "en-US"),
            Map.entry("ko", "ko-KR"),
            Map.entry("ja", "ja-JP"),
            Map.entry("zh", "zh-CN"),
            Map.entry("fr", "fr-FR"),
            Map.entry("de", "de-DE"),
            Map.entry("es", "es-ES"),
            Map.entry("it", "it-IT"),
            Map.entry("pt", "pt-BR"),
            Map.entry("ru", "ru-RU"),
            Map.entry("ar", "ar-SA"),
            Map.entry("id", "id-ID"),
            Map.entry("vi", "vi-VN"),
            Map.entry("hi", "hi-IN"),
            Map.entry("th", "th-TH"),
            Map.entry("pl", "pl-PL"),
            Map.entry("tr", "tr-TR"),
            Map.entry("nl", "nl-NL"),
            Map.entry("sv", "sv-SE"),
            Map.entry("fa", "fa-IR")
    );

    @Transactional(readOnly = true)
    public Page<SuggestedIngredientAdminDto> getSuggestedIngredients(
            SuggestedIngredientFilterDto filter,
            int page,
            int size
    ) {
        Sort sort = buildSort(filter.sortBy(), filter.sortOrder());
        Pageable pageable = PageRequest.of(page, size, sort);

        return repository
                .findAll(UserSuggestedIngredientSpecification.withFilters(filter), pageable)
                .map(SuggestedIngredientAdminDto::from);
    }

    @Transactional
    public SuggestedIngredientAdminDto updateStatus(UUID publicId, SuggestionStatus status) {
        UserSuggestedIngredient entity = repository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Suggested ingredient not found: " + publicId));

        entity.updateStatus(status);

        if (status == SuggestionStatus.APPROVED) {
            AutocompleteItem autocompleteItem = createAutocompleteItemFromSuggestion(entity);
            entity.linkToAutocompleteItem(autocompleteItem);
            translationEventService.queueAutocompleteItemTranslation(
                    autocompleteItem, entity.getLocaleCode());
            log.info("Created AutocompleteItem {} from approved ingredient suggestion {} and queued translation",
                    autocompleteItem.getId(), publicId);
        }

        return SuggestedIngredientAdminDto.from(entity);
    }

    private AutocompleteItem createAutocompleteItemFromSuggestion(UserSuggestedIngredient suggestion) {
        String localeCode = suggestion.getLocaleCode();
        String bcp47Locale = toBcp47Locale(localeCode);
        AutocompleteType autocompleteType = mapIngredientTypeToAutocompleteType(
                suggestion.getIngredientType());

        Map<String, String> nameMap = new HashMap<>();
        nameMap.put(bcp47Locale, suggestion.getSuggestedName());

        AutocompleteItem autocompleteItem = AutocompleteItem.builder()
                .type(autocompleteType)
                .name(nameMap)
                .score(50.0)
                .build();

        return autocompleteItemRepository.save(autocompleteItem);
    }

    private AutocompleteType mapIngredientTypeToAutocompleteType(IngredientType ingredientType) {
        return switch (ingredientType) {
            case MAIN -> AutocompleteType.MAIN_INGREDIENT;
            case SECONDARY -> AutocompleteType.SECONDARY_INGREDIENT;
            case SEASONING -> AutocompleteType.SEASONING;
        };
    }

    private String toBcp47Locale(String localeCode) {
        if (localeCode == null || localeCode.isBlank()) {
            return "ko-KR";
        }
        if (localeCode.contains("-")) {
            return localeCode;
        }
        String shortCode = localeCode.toLowerCase();
        return LOCALE_TO_BCP47.getOrDefault(shortCode, "ko-KR");
    }

    private Sort buildSort(String sortBy, String sortOrder) {
        Sort.Direction direction = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        String field = switch (sortBy) {
            case "username" -> "user.username";
            default -> sortBy;
        };

        return Sort.by(direction, field);
    }
}
