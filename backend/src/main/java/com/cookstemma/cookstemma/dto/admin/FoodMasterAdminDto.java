package com.cookstemma.cookstemma.dto.admin;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/**
 * DTO for displaying FoodMaster data in the admin panel.
 */
public record FoodMasterAdminDto(
        UUID publicId,
        Map<String, String> name,
        Map<String, String> categoryName,
        Map<String, String> description,
        Map<String, String> searchKeywords,
        Double foodScore,
        Boolean isVerified,
        Instant createdAt,
        Instant updatedAt
) {
    public static FoodMasterAdminDto from(FoodMaster food) {
        return new FoodMasterAdminDto(
                food.getPublicId(),
                food.getName(),
                food.getCategory() != null ? food.getCategory().getName() : null,
                food.getDescription(),
                food.getSearchKeywords(),
                food.getFoodScore(),
                food.getIsVerified(),
                food.getCreatedAt(),
                food.getUpdatedAt()
        );
    }
}
