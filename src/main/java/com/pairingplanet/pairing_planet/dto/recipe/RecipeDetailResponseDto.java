package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.image.ImageResponseDto;
import lombok.Builder;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Builder
public record RecipeDetailResponseDto(
        UUID publicId,
        String title,
        String description,
        String culinaryLocale,
        String foodName,              // [추가] UI 상단 표시용
        UUID foodMasterPublicId,      // [추가] 음식 상세 이동용
        String changeCategory,
        RecipeSummaryDto rootInfo,    // 11개 필드 규격 적용 필요
        RecipeSummaryDto parentInfo,  // 11개 필드 규격 적용 필요
        List<IngredientDto> ingredients,
        List<StepDto> steps,
        List<ImageResponseDto> images,
        List<RecipeSummaryDto> variants,
        List<LogPostSummaryDto> logs
) {
    public static RecipeDetailResponseDto from(Recipe recipe, List<RecipeSummaryDto> variants, List<LogPostSummaryDto> logs, String urlPrefix) {
        Recipe root = recipe.getRootRecipe();
        Recipe parent = recipe.getParentRecipe();

        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String currentFoodName = nameMap.getOrDefault(recipe.getCulinaryLocale(),
                nameMap.getOrDefault("ko-KR",
                        nameMap.values().stream().findFirst().orElse("Unknown Food")));
        UUID currentFoodMasterPublicId = recipe.getFoodMaster().getPublicId();

        // 2. 루트 레시피 정보 생성 (11개 필드 생성자 대응)
        RecipeSummaryDto rootInfo = (root != null) ? new RecipeSummaryDto(
                root.getPublicId(), // 1. publicId (UUID)
                // 2. foodName (String): 현재 로케일 -> 한국어 -> 첫 번째 이름 순으로 시도
                root.getFoodMaster().getName().getOrDefault(root.getCulinaryLocale(),
                        root.getFoodMaster().getName().getOrDefault("ko-KR",
                                root.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"))),
                root.getFoodMaster().getPublicId(), // 3. foodMasterPublicId (UUID) - [수정됨]
                root.getTitle(),       // 4. title
                root.getDescription(), // 5. description
                root.getCulinaryLocale(), // 6. culinaryLocale
                null, // 7. creatorName (상세 카드 내 생략)
                null, // 8. thumbnail (상세 카드 내 생략)
                0,    // 9. variantCount (상세 카드 내 생략)
                null, // 10. parentPublicId
                null  // 11. rootPublicId
        ) : null;

        // 3. 부모 레시피 정보 생성 (11개 필드 생성자 대응)
        RecipeSummaryDto parentInfo = (parent != null) ? new RecipeSummaryDto(
                parent.getPublicId(),
                parent.getFoodMaster().getName().getOrDefault(parent.getCulinaryLocale(), "Unknown Food"),
                parent.getFoodMaster().getPublicId(),
                parent.getTitle(),
                parent.getDescription(),
                parent.getCulinaryLocale(),
                null,
                null,
                0,
                null,
                null
        ) : null;

        // 4. 이미지 리스트 변환
        List<ImageResponseDto> imageResponses = recipe.getImages().stream()
                .map(img -> new ImageResponseDto(
                        img.getPublicId(),
                        urlPrefix + "/" + img.getStoredFilename()
                ))
                .toList();

        return RecipeDetailResponseDto.builder()
                .publicId(recipe.getPublicId())
                .title(recipe.getTitle())
                .description(recipe.getDescription())
                .culinaryLocale(recipe.getCulinaryLocale())
                .foodName(currentFoodName) // [적용]
                .foodMasterPublicId(currentFoodMasterPublicId) // [적용]
                .changeCategory(recipe.getChangeCategory())
                .rootInfo(rootInfo)
                .parentInfo(parentInfo)
                .ingredients(recipe.getIngredients().stream()
                        .map(i -> new IngredientDto(i.getName(), i.getAmount(), i.getType()))
                        .toList())
                .steps(recipe.getSteps().stream()
                        .map(s -> {
                            UUID imgId = (s.getImage() != null) ? s.getImage().getPublicId() : null;
                            String imgUrl = (s.getImage() != null) ? urlPrefix + "/" + s.getImage().getStoredFilename() : null;
                            return new StepDto(s.getStepNumber(), s.getDescription(), imgId, imgUrl);
                        })
                        .toList())
                .images(imageResponses)
                .variants(variants)
                .logs(logs)
                .build();
    }
}