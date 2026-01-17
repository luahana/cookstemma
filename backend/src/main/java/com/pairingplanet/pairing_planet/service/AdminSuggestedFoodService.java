package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import com.pairingplanet.pairing_planet.dto.admin.SuggestedFoodFilterDto;
import com.pairingplanet.pairing_planet.dto.admin.UserSuggestedFoodDto;
import com.pairingplanet.pairing_planet.repository.food.UserSuggestedFoodRepository;
import com.pairingplanet.pairing_planet.repository.specification.UserSuggestedFoodSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminSuggestedFoodService {

    private final UserSuggestedFoodRepository repository;

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
        return UserSuggestedFoodDto.from(entity);
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
