package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.food.UserSuggestedFood;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.dto.admin.SuggestedFoodFilterDto;
import com.cookstemma.cookstemma.dto.admin.UserSuggestedFoodDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.food.UserSuggestedFoodRepository;
import com.cookstemma.cookstemma.repository.specification.UserSuggestedFoodSpecification;
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
public class AdminSuggestedFoodService {

    private final UserSuggestedFoodRepository repository;
    private final FoodMasterRepository foodMasterRepository;
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
    public Page<UserSuggestedFoodDto> getSuggestedFoods(SuggestedFoodFilterDto filter, int page, int size) {
        Sort sort = buildSort(filter.sortBy(), filter.sortOrder());
        Pageable pageable = PageRequest.of(page, size, sort);

        return repository
                .findAll(UserSuggestedFoodSpecification.withFilters(filter), pageable)
                .map(UserSuggestedFoodDto::from);
    }

    @Transactional
    public UserSuggestedFoodDto updateStatus(UUID publicId, SuggestionStatus status) {
        UserSuggestedFood entity = repository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Suggested food not found: " + publicId));

        entity.updateStatus(status);

        if (status == SuggestionStatus.APPROVED) {
            FoodMaster foodMaster = createFoodMasterFromSuggestion(entity);
            entity.linkToFoodMaster(foodMaster);
            translationEventService.queueFoodMasterTranslation(foodMaster, entity.getLocaleCode());
            log.info("Created FoodMaster {} from approved suggestion {} and queued translation",
                    foodMaster.getId(), publicId);
        }

        return UserSuggestedFoodDto.from(entity);
    }

    private FoodMaster createFoodMasterFromSuggestion(UserSuggestedFood suggestion) {
        String localeCode = suggestion.getLocaleCode();
        String bcp47Locale = toBcp47Locale(localeCode);

        Map<String, String> nameMap = new HashMap<>();
        nameMap.put(bcp47Locale, suggestion.getSuggestedName());

        FoodMaster foodMaster = FoodMaster.builder()
                .name(nameMap)
                .isVerified(true)
                .build();

        return foodMasterRepository.save(foodMaster);
    }

    private String toBcp47Locale(String localeCode) {
        if (localeCode == null || localeCode.isBlank()) {
            return "ko-KR";
        }
        // If already in BCP47 format (contains hyphen), return as-is
        if (localeCode.contains("-")) {
            return localeCode;
        }
        // Convert short code to BCP47
        String shortCode = localeCode.toLowerCase();
        return LOCALE_TO_BCP47.getOrDefault(shortCode, "ko-KR");
    }

    private Sort buildSort(String sortBy, String sortOrder) {
        Sort.Direction direction = "asc".equalsIgnoreCase(sortOrder)
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        // Map frontend field names to entity field names if needed
        String field = switch (sortBy) {
            case "username" -> "user.username";
            default -> sortBy;
        };

        return Sort.by(direction, field);
    }
}
