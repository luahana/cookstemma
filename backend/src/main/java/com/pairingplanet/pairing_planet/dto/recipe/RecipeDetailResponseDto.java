package com.pairingplanet.pairing_planet.dto.recipe;

import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.hashtag.HashtagDto;
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
        UUID creatorPublicId,         // Creator's publicId for profile navigation
        String userName,           // [추가] 레시피 작성자 이름
        String changeCategory,
        RecipeSummaryDto rootInfo,    // 11개 필드 규격 적용 필요
        RecipeSummaryDto parentInfo,  // 11개 필드 규격 적용 필요
        List<IngredientDto> ingredients,
        List<StepDto> steps,
        List<ImageResponseDto> images,
        List<RecipeSummaryDto> variants,
        List<LogPostSummaryDto> logs,
        List<HashtagDto> hashtags,    // Hashtags for this recipe
        Boolean isSavedByCurrentUser, // P1: 북마크 저장 여부
        // Living Blueprint: Diff fields for variation tracking
        Map<String, Object> changeDiff,      // Ingredient/step changes from parent
        List<String> changeCategories,       // Auto-detected: INGREDIENT, TECHNIQUE, AMOUNT, SEASONING
        String changeReason,                 // User-provided reason for changes
        // Servings and cooking time
        Integer servings,                    // Number of servings (default: 2)
        String cookingTimeRange              // Cooking time range enum (e.g., "MIN_30_TO_60")
) {
    public static RecipeDetailResponseDto from(Recipe recipe, List<RecipeSummaryDto> variants, List<LogPostSummaryDto> logs, String urlPrefix, Boolean isSavedByCurrentUser, UUID creatorPublicId, String userName, UUID rootCreatorPublicId, String rootCreatorName) {
        Recipe root = recipe.getRootRecipe();
        Recipe parent = recipe.getParentRecipe();

        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String currentFoodName = nameMap.getOrDefault(recipe.getCulinaryLocale(),
                nameMap.getOrDefault("ko-KR",
                        nameMap.values().stream().findFirst().orElse("Unknown Food")));
        UUID currentFoodMasterPublicId = recipe.getFoodMaster().getPublicId();

        // 2. 루트 레시피 정보 생성 (17개 필드 생성자 대응)
        // Get root recipe thumbnail
        String rootThumbnail = (root != null) ? root.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null) : null;

        RecipeSummaryDto rootInfo = (root != null) ? new RecipeSummaryDto(
                root.getPublicId(), // 1. publicId (UUID)
                // 2. foodName (String): 현재 로케일 -> 한국어 -> 첫 번째 이름 순으로 시도
                root.getFoodMaster().getName().getOrDefault(root.getCulinaryLocale(),
                        root.getFoodMaster().getName().getOrDefault("ko-KR",
                                root.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"))),
                root.getFoodMaster().getPublicId(), // 3. foodMasterPublicId (UUID)
                root.getTitle(),       // 4. title
                root.getDescription(), // 5. description
                root.getCulinaryLocale(), // 6. culinaryLocale
                rootCreatorPublicId, // 7. creatorPublicId
                rootCreatorName, // 8. userName
                rootThumbnail, // 9. thumbnail
                0,    // 10. variantCount (상세 카드 내 생략)
                0,    // 11. logCount (상세 카드 내 생략)
                null, // 12. parentPublicId
                null, // 13. rootPublicId
                null, // 14. rootTitle (root itself has no root)
                root.getServings() != null ? root.getServings() : 2, // 15. servings
                root.getCookingTimeRange() != null ? root.getCookingTimeRange().name() : "MIN_30_TO_60", // 16. cookingTimeRange
                List.of() // 17. hashtags (상세 카드 내 생략)
        ) : null;

        // 3. 부모 레시피 정보 생성 (17개 필드 생성자 대응)
        RecipeSummaryDto parentInfo = (parent != null) ? new RecipeSummaryDto(
                parent.getPublicId(),
                parent.getFoodMaster().getName().getOrDefault(parent.getCulinaryLocale(), "Unknown Food"),
                parent.getFoodMaster().getPublicId(),
                parent.getTitle(),
                parent.getDescription(),
                parent.getCulinaryLocale(),
                null, // creatorPublicId
                null, // userName
                null, // thumbnail
                0,    // variantCount
                0,    // logCount
                null, // parentPublicId
                null, // rootPublicId
                null, // rootTitle
                parent.getServings() != null ? parent.getServings() : 2, // servings
                parent.getCookingTimeRange() != null ? parent.getCookingTimeRange().name() : "MIN_30_TO_60", // cookingTimeRange
                List.of() // hashtags (상세 카드 내 생략)
        ) : null;

        // 4. 이미지 리스트 변환 (COVER 타입만 반환, STEP 이미지는 steps[].imageUrl로 반환됨)
        // Note: distinct() is needed because EntityGraph with multiple *ToMany relations causes Cartesian product
        List<ImageResponseDto> imageResponses = recipe.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.COVER)
                .distinct()
                .map(img -> new ImageResponseDto(
                        img.getPublicId(),
                        urlPrefix + "/" + img.getStoredFilename()
                ))
                .toList();

        // 5. 해시태그 리스트 변환
        List<HashtagDto> hashtagDtos = recipe.getHashtags().stream()
                .map(HashtagDto::from)
                .toList();

        return RecipeDetailResponseDto.builder()
                .publicId(recipe.getPublicId())
                .title(recipe.getTitle())
                .description(recipe.getDescription())
                .culinaryLocale(recipe.getCulinaryLocale())
                .foodName(currentFoodName) // [적용]
                .foodMasterPublicId(currentFoodMasterPublicId) // [적용]
                .creatorPublicId(creatorPublicId) // Creator's publicId for profile navigation
                .userName(userName) // [적용]
                .changeCategory(recipe.getChangeCategory())
                .rootInfo(rootInfo)
                .parentInfo(parentInfo)
                .ingredients(recipe.getIngredients().stream()
                        .map(i -> new IngredientDto(i.getName(), i.getAmount(), i.getQuantity(), i.getUnit(), i.getType()))
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
                .hashtags(hashtagDtos)
                .isSavedByCurrentUser(isSavedByCurrentUser)
                .changeDiff(recipe.getChangeDiff())
                .changeCategories(recipe.getChangeCategories())
                .changeReason(recipe.getChangeReason())
                .servings(recipe.getServings() != null ? recipe.getServings() : 2)
                .cookingTimeRange(recipe.getCookingTimeRange() != null ? recipe.getCookingTimeRange().name() : "MIN_30_TO_60")
                .build();
    }
}
