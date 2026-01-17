package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import com.pairingplanet.pairing_planet.dto.admin.SuggestedFoodFilterDto;
import com.pairingplanet.pairing_planet.dto.admin.UserSuggestedFoodDto;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.food.UserSuggestedFoodRepository;
import com.pairingplanet.pairing_planet.repository.specification.UserSuggestedFoodSpecification;
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
