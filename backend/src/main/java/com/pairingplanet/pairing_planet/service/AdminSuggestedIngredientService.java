package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.autocomplete.AutocompleteItem;
import com.pairingplanet.pairing_planet.domain.entity.ingredient.UserSuggestedIngredient;
import com.pairingplanet.pairing_planet.domain.enums.AutocompleteType;
import com.pairingplanet.pairing_planet.domain.enums.IngredientType;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import com.pairingplanet.pairing_planet.dto.admin.SuggestedIngredientAdminDto;
import com.pairingplanet.pairing_planet.dto.admin.SuggestedIngredientFilterDto;
import com.pairingplanet.pairing_planet.repository.autocomplete.AutocompleteItemRepository;
import com.pairingplanet.pairing_planet.repository.ingredient.UserSuggestedIngredientRepository;
import com.pairingplanet.pairing_planet.repository.specification.UserSuggestedIngredientSpecification;
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
            Map.entry("ko", "ko-KR"),
            Map.entry("en", "en-US"),
            Map.entry("ja", "ja-JP"),
            Map.entry("zh", "zh-CN"),
            Map.entry("fr", "fr-FR"),
            Map.entry("es", "es-ES"),
            Map.entry("it", "it-IT"),
            Map.entry("de", "de-DE"),
            Map.entry("ru", "ru-RU"),
            Map.entry("pt", "pt-BR"),
            Map.entry("el", "el-GR"),
            Map.entry("ar", "ar-SA")
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
