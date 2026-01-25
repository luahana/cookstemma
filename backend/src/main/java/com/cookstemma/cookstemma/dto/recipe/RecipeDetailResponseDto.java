package com.cookstemma.cookstemma.dto.recipe;

import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.hashtag.HashtagDto;
import com.cookstemma.cookstemma.dto.image.ImageResponseDto;
import lombok.Builder;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Recipe detail DTO with pre-localized title/description.
 * All translatable string fields contain values for the requested locale,
 * resolved server-side from the translations maps.
 */
@Builder
public record RecipeDetailResponseDto(
        UUID publicId,
        String title,                 // Localized title
        String description,           // Localized description
        String cookingStyle,
        String foodName,              // Localized food name
        UUID foodMasterPublicId,      // Food detail navigation
        UUID creatorPublicId,         // Creator's publicId for profile navigation
        String userName,              // Recipe creator name
        String changeCategory,
        RecipeSummaryDto rootInfo,    // Root recipe info
        RecipeSummaryDto parentInfo,  // Parent recipe info
        List<IngredientDto> ingredients,
        List<StepDto> steps,
        List<ImageResponseDto> images,
        List<RecipeSummaryDto> variants,
        List<LogPostSummaryDto> logs,
        List<HashtagDto> hashtags,    // Hashtags for this recipe
        Boolean isSavedByCurrentUser, // P1: bookmark status
        // Living Blueprint: Diff fields for variation tracking
        Map<String, Object> changeDiff,      // Ingredient/step changes from parent
        List<String> changeCategories,       // Auto-detected: INGREDIENT, TECHNIQUE, AMOUNT, SEASONING
        String changeReason,                 // User-provided reason for changes
        // Servings and cooking time
        Integer servings,                    // Number of servings (default: 2)
        String cookingTimeRange,             // Cooking time range enum (e.g., "MIN_30_TO_60")
        // Privacy setting
        Boolean isPrivate                    // Whether this recipe is private (only visible to creator)
) {
    /**
     * Build RecipeDetailResponseDto with locale-aware field resolution.
     *
     * @param recipe                The recipe entity
     * @param variants              List of variant recipes
     * @param logs                  List of cooking logs
     * @param urlPrefix             URL prefix for images
     * @param isSavedByCurrentUser  Whether the current user has saved this recipe
     * @param creatorPublicId       Recipe creator's public ID
     * @param userName              Recipe creator's username
     * @param rootCreatorPublicId   Root recipe creator's public ID
     * @param rootCreatorName       Root recipe creator's username
     * @param locale                Requested locale for translations (e.g., "ko-KR", "en-US")
     */
    public static RecipeDetailResponseDto from(
            Recipe recipe,
            List<RecipeSummaryDto> variants,
            List<LogPostSummaryDto> logs,
            String urlPrefix,
            Boolean isSavedByCurrentUser,
            UUID creatorPublicId,
            String userName,
            UUID rootCreatorPublicId,
            String rootCreatorName,
            String locale
    ) {
        Recipe root = recipe.getRootRecipe();
        Recipe parent = recipe.getParentRecipe();

        // Get localized food name
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String currentFoodName = com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                nameMap, locale, nameMap.values().stream().findFirst().orElse("Unknown Food"));
        UUID currentFoodMasterPublicId = recipe.getFoodMaster().getPublicId();

        // Get localized title and description for main recipe
        String localizedTitle = com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                recipe.getTitleTranslations(), locale, recipe.getTitle());
        String localizedDescription = com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                recipe.getDescriptionTranslations(), locale, recipe.getDescription());

        // Build root recipe info with localized fields
        String rootThumbnail = (root != null) ? root.getCoverImages().stream()
                .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null) : null;

        RecipeSummaryDto rootInfo = (root != null) ? new RecipeSummaryDto(
                root.getPublicId(),
                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        root.getFoodMaster().getName(), locale,
                        root.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food")),
                root.getFoodMaster().getPublicId(),
                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        root.getTitleTranslations(), locale, root.getTitle()),
                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        root.getDescriptionTranslations(), locale, root.getDescription()),
                root.getCookingStyle(),
                rootCreatorPublicId,
                rootCreatorName,
                rootThumbnail,
                0, 0, null, null, null,
                root.getServings() != null ? root.getServings() : 2,
                root.getCookingTimeRange() != null ? root.getCookingTimeRange().name() : "MIN_30_TO_60",
                List.of(),
                root.getIsPrivate() != null ? root.getIsPrivate() : false
        ) : null;

        // Build parent recipe info with localized fields
        RecipeSummaryDto parentInfo = (parent != null) ? new RecipeSummaryDto(
                parent.getPublicId(),
                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        parent.getFoodMaster().getName(), locale, "Unknown Food"),
                parent.getFoodMaster().getPublicId(),
                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        parent.getTitleTranslations(), locale, parent.getTitle()),
                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        parent.getDescriptionTranslations(), locale, parent.getDescription()),
                parent.getCookingStyle(),
                null, null, null, 0, 0, null, null, null,
                parent.getServings() != null ? parent.getServings() : 2,
                parent.getCookingTimeRange() != null ? parent.getCookingTimeRange().name() : "MIN_30_TO_60",
                List.of(),
                parent.getIsPrivate() != null ? parent.getIsPrivate() : false
        ) : null;

        // Build image responses (COVER type only)
        List<ImageResponseDto> imageResponses = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                .distinct()
                .map(img -> new ImageResponseDto(
                        img.getPublicId(),
                        urlPrefix + "/" + img.getStoredFilename()
                ))
                .toList();

        // Build hashtag DTOs
        List<HashtagDto> hashtagDtos = recipe.getHashtags().stream()
                .map(HashtagDto::from)
                .toList();

        return RecipeDetailResponseDto.builder()
                .publicId(recipe.getPublicId())
                .title(localizedTitle)
                .description(localizedDescription)
                .cookingStyle(recipe.getCookingStyle())
                .foodName(currentFoodName)
                .foodMasterPublicId(currentFoodMasterPublicId)
                .creatorPublicId(creatorPublicId)
                .userName(userName)
                .changeCategory(recipe.getChangeCategory())
                .rootInfo(rootInfo)
                .parentInfo(parentInfo)
                .ingredients(recipe.getIngredients().stream()
                        .map(i -> new IngredientDto(
                                com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                                        i.getNameTranslations(), locale, i.getName()),
                                i.getQuantity(),
                                i.getUnit(),
                                i.getType()))
                        .toList())
                .steps(recipe.getSteps().stream()
                        .map(s -> {
                            UUID imgId = (s.getImage() != null) ? s.getImage().getPublicId() : null;
                            String imgUrl = (s.getImage() != null) ? urlPrefix + "/" + s.getImage().getStoredFilename() : null;
                            return new StepDto(
                                    s.getStepNumber(),
                                    com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                                            s.getDescriptionTranslations(), locale, s.getDescription()),
                                    imgId,
                                    imgUrl);
                        })
                        .toList())
                .images(imageResponses)
                .variants(variants)
                .logs(logs)
                .hashtags(hashtagDtos)
                .isSavedByCurrentUser(isSavedByCurrentUser)
                .changeDiff(recipe.getChangeDiff())
                .changeCategories(recipe.getChangeCategories())
                .changeReason(com.cookstemma.cookstemma.util.LocaleUtils.getLocalizedValue(
                        recipe.getChangeReasonTranslations(), locale, recipe.getChangeReason()))
                .servings(recipe.getServings() != null ? recipe.getServings() : 2)
                .cookingTimeRange(recipe.getCookingTimeRange() != null ? recipe.getCookingTimeRange().name() : "MIN_30_TO_60")
                .isPrivate(recipe.getIsPrivate() != null ? recipe.getIsPrivate() : false)
                .build();
    }
}
