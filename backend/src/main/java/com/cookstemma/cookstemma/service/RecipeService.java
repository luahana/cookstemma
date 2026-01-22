package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.food.UserSuggestedFood;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.ingredient.UserSuggestedIngredient;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeIngredient;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeStep;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.AutocompleteType;
import com.cookstemma.cookstemma.domain.enums.CookingTimeRange;
import com.cookstemma.cookstemma.domain.enums.IngredientType;
import com.cookstemma.cookstemma.domain.enums.SuggestionStatus;
import com.cookstemma.cookstemma.dto.common.CursorPageResponse;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.log_post.RecentActivityDto;
import com.cookstemma.cookstemma.dto.recipe.*;
import com.cookstemma.cookstemma.util.CursorUtil;
import com.cookstemma.cookstemma.util.LocaleUtils;
import com.cookstemma.cookstemma.repository.autocomplete.AutocompleteItemRepository;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.food.UserSuggestedFoodRepository;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.ingredient.UserSuggestedIngredientRepository;
import com.cookstemma.cookstemma.repository.recipe.*;
import com.cookstemma.cookstemma.repository.specification.RecipeSpecification;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecipeService {
    private final RecipeRepository recipeRepository;
    private final RecipeIngredientRepository ingredientRepository;
    private final RecipeStepRepository stepRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final LogPostRepository logPostRepository;  // For home feed activity
    private final ImageService imageService;
    private final ImageRepository imageRepository;
    private final UserRepository userRepository;

    private final FoodMasterRepository foodMasterRepository;
    private final UserSuggestedFoodRepository suggestedFoodRepository;
    private final AutocompleteItemRepository autocompleteItemRepository;
    private final UserSuggestedIngredientRepository suggestedIngredientRepository;
    private final RecipeCategoryDetectionService categoryDetectionService;
    private final SavedRecipeRepository savedRecipeRepository;
    private final HashtagService hashtagService;
    private final NotificationService notificationService;
    private final TranslationEventService translationEventService;
    private final ImageProcessingService imageProcessingService;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * 새 레시피 생성 및 이미지/재료/단계 활성화
     */
    @Transactional
    public RecipeDetailResponseDto createRecipe(CreateRecipeRequestDto req, UserPrincipal principal) {
        Long creatorId = principal.getId();
        Recipe parent = null;
        Recipe root = null;

        // [계보 로직 수정]
        if (req.parentPublicId() != null) {
            parent = recipeRepository.findByPublicId(req.parentPublicId())
                    .orElseThrow(() -> new IllegalArgumentException("Parent recipe not found"));
            root = (parent.getRootRecipe() != null) ? parent.getRootRecipe() : parent;
        }

        // 2. 음식 엔티티 결정 로직 호출
        FoodMaster foodMaster = resolveFoodMaster(req, creatorId);

        // 부모로부터 음식 정보 상속 (요청에 없을 경우)
        if (foodMaster == null && parent != null) {
            foodMaster = parent.getFoodMaster();
        }

        if (foodMaster == null) {
            throw new IllegalArgumentException("Food information (UUID or new name) is required.");
        }

        String finalLocale = (req.cookingStyle() == null || req.cookingStyle().isBlank())
                ? (parent != null ? parent.getCookingStyle() : "ko-KR")
                : req.cookingStyle();

        // Phase 7-3: Process change diff and auto-detect categories
        Map<String, Object> changeDiff = req.changeDiff() != null ? req.changeDiff() : new HashMap<>();
        List<String> changeCategories = categoryDetectionService.detectCategories(changeDiff);

        // Parse cooking time range from request
        CookingTimeRange cookingTimeRange = CookingTimeRange.MIN_30_TO_60; // Default
        if (req.cookingTimeRange() != null && !req.cookingTimeRange().isBlank()) {
            try {
                cookingTimeRange = CookingTimeRange.valueOf(req.cookingTimeRange());
            } catch (IllegalArgumentException ignored) {
                // Use default if invalid
            }
        }

        Recipe recipe = Recipe.builder()
                .title(req.title())
                .description(req.description())
                .cookingStyle(finalLocale)
                .foodMaster(foodMaster)
                .creatorId(creatorId)
                .parentRecipe(parent) // 바로 위 부모
                .rootRecipe(root)     // 최상위 뿌리
                .changeCategory(req.changeCategory())
                .changeDiff(changeDiff)
                .changeReason(req.changeReason())
                .changeCategories(changeCategories)
                .servings(req.servings() != null ? req.servings() : 2)
                .cookingTimeRange(cookingTimeRange)
                .isPrivate(req.isPrivate() != null ? req.isPrivate() : false)
                .build();

        recipeRepository.save(recipe);

        // Process hashtags
        if (req.hashtags() != null && !req.hashtags().isEmpty()) {
            Set<Hashtag> hashtags = hashtagService.getOrCreateHashtags(req.hashtags());
            recipe.setHashtags(hashtags);
        }
        saveIngredientsAndSteps(recipe, req, creatorId, finalLocale);
        imageService.activateImages(req.imagePublicIds(), recipe);

        // Flush to ensure images are persisted before fetching recipe detail
        imageRepository.flush();

        // Notify parent recipe owner if this is a variation
        if (parent != null) {
            User sender = userRepository.findById(creatorId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));
            notificationService.notifyRecipeVariation(parent, recipe, sender);
        }

        // Queue async translation for all languages
        translationEventService.queueRecipeTranslation(recipe);

        return getRecipeDetail(recipe.getPublicId());
    }

    /**
     * 레시피 상세 조회 (기획 원칙 1 반영: 상단 루트 고정)
     * 비로그인 사용자용 (isSavedByCurrentUser = null)
     */
    public RecipeDetailResponseDto getRecipeDetail(UUID publicId) {
        return getRecipeDetail(publicId, null, LocaleUtils.DEFAULT_LOCALE);
    }

    /**
     * 레시피 상세 조회 (기획 원칙 1 반영: 상단 루트 고정)
     * 로그인 사용자용, default locale
     */
    @Transactional
    public RecipeDetailResponseDto getRecipeDetail(UUID publicId, Long userId) {
        return getRecipeDetail(publicId, userId, LocaleUtils.DEFAULT_LOCALE);
    }

    /**
     * 레시피 상세 조회 (기획 원칙 1 반영: 상단 루트 고정)
     * 로그인 사용자용, with locale
     * Increments view count for analytics.
     */
    @Transactional
    public RecipeDetailResponseDto getRecipeDetail(UUID publicId, Long userId, String locale) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        // Access control for private recipes - only owner can view
        if (Boolean.TRUE.equals(recipe.getIsPrivate())) {
            if (userId == null || !recipe.getCreatorId().equals(userId)) {
                throw new org.springframework.security.access.AccessDeniedException("This recipe is private");
            }
        }

        // Increment view count for analytics
        recipe.incrementViewCount();
        recipeRepository.save(recipe);

        // [원칙 1] 어디서든 루트 레시피 정보 포함
        Recipe root = (recipe.getRootRecipe() != null) ? recipe.getRootRecipe() : recipe;

        // Normalize locale for consistent usage
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);

        // 변형 및 로그 리스트 조회 - 루트에 연결된 모든 변형을 가져옴
        List<RecipeSummaryDto> variants = recipeRepository.findByRootRecipeIdAndDeletedAtIsNull(root.getId())
                .stream()
                .filter(v -> !v.getId().equals(recipe.getId())) // Exclude current recipe
                .limit(6)  // Limit to 6 for "View All" detection (show 5, detect more if 6)
                .map(v -> convertToSummary(v, normalizedLocale))
                .toList();

        List<LogPostSummaryDto> logs = recipeLogRepository.findAllByRecipeId(recipe.getId())
                .stream()
                .limit(6)  // Limit to 6 for "See More" detection (show 5, detect more if 6)
                .map(rl -> {
                    var logPost = rl.getLogPost();
                    // Get first image URL as thumbnail (images ordered by displayOrder ASC)
                    String thumbnailUrl = logPost.getImages().isEmpty()
                            ? null
                            : urlPrefix + "/" + logPost.getImages().get(0).getStoredFilename();
                    // Get creator info
                    User logCreator = userRepository.findById(logPost.getCreatorId()).orElse(null);
                    UUID logCreatorPublicId = logCreator != null ? logCreator.getPublicId() : null;
                    String logCreatorName = logCreator != null ? logCreator.getUsername() : null;
                    // Get food name and variant status from linked recipe
                    String foodName = recipe.getFoodMaster().getNameByLocale(normalizedLocale);
                    Boolean isVariant = recipe.getRootRecipe() != null;

                    // Get hashtag names
                    List<String> logHashtags = logPost.getHashtags().stream()
                            .map(Hashtag::getName)
                            .toList();

                    return new LogPostSummaryDto(
                            logPost.getPublicId(),
                            LocaleUtils.getLocalizedValue(logPost.getTitleTranslations(), normalizedLocale, logPost.getTitle()),
                            LocaleUtils.getLocalizedValue(logPost.getContentTranslations(), normalizedLocale, logPost.getContent()),
                            rl.getRating(),
                            thumbnailUrl,
                            logCreatorPublicId,
                            logCreatorName,
                            foodName,
                            LocaleUtils.getLocalizedValue(recipe.getTitleTranslations(), normalizedLocale, recipe.getTitle()),
                            logHashtags,
                            isVariant,
                            logPost.getIsPrivate() != null ? logPost.getIsPrivate() : false,
                            logPost.getCommentCount() != null ? logPost.getCommentCount() : 0
                    );
                }).toList();

        // P1: 저장 여부 확인
        Boolean isSavedByCurrentUser = (userId != null)
                ? savedRecipeRepository.existsByUserIdAndRecipeId(userId, recipe.getId())
                : null;

        // 작성자 정보 조회
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // 루트 레시피 작성자 정보 조회
        Recipe rootRecipe = recipe.getRootRecipe();
        UUID rootCreatorPublicId = null;
        String rootCreatorName = null;
        if (rootRecipe != null) {
            User rootCreator = userRepository.findById(rootRecipe.getCreatorId()).orElse(null);
            rootCreatorPublicId = rootCreator != null ? rootCreator.getPublicId() : null;
            rootCreatorName = rootCreator != null ? rootCreator.getUsername() : "Unknown";
        }

        return RecipeDetailResponseDto.from(recipe, variants, logs, this.urlPrefix, isSavedByCurrentUser, creatorPublicId, userName, rootCreatorPublicId, rootCreatorName, normalizedLocale);
    }

    @Transactional(readOnly = true)
    public Slice<RecipeSummaryDto> findRecipes(String locale, boolean onlyRoot, String typeFilter, Pageable pageable) {
        Slice<Recipe> recipes;

        // typeFilter takes precedence over onlyRoot for clarity
        // "original" = only root recipes, "variant" = only variant recipes
        boolean isOriginalFilter = "original".equalsIgnoreCase(typeFilter) || onlyRoot;
        boolean isVariantFilter = "variant".equalsIgnoreCase(typeFilter);

        if (locale == null || locale.isBlank()) {
            // 로케일이 없을 때 (전체 글로벌 조회)
            if (isVariantFilter) {
                recipes = recipeRepository.findOnlyVariantsPublic(pageable);
            } else if (isOriginalFilter) {
                recipes = recipeRepository.findAllRootRecipes(pageable);
            } else {
                recipes = recipeRepository.findPublicRecipes(pageable);
            }
        } else {
            // 특정 로케일 필터링 시
            if (isVariantFilter) {
                recipes = recipeRepository.findOnlyVariantsByLocale(locale, pageable);
            } else if (isOriginalFilter) {
                recipes = recipeRepository.findRootRecipesByLocale(locale, pageable);
            } else {
                recipes = recipeRepository.findPublicRecipesByLocale(locale, pageable);
            }
        }

        return recipes.map(this::convertToSummary);
    }


    private FoodMaster resolveFoodMaster(CreateRecipeRequestDto req, Long userId) {
        // 상황 A: UUID 기반 기존 음식 조회
        if (req.food1MasterPublicId() != null) {
            return foodMasterRepository.findByPublicId(req.food1MasterPublicId())
                    .orElseThrow(() -> new IllegalArgumentException("Invalid Food Public ID"));
        }

        // 상황 B: 이름 기반 신규 제안 또는 중복 체크
        if (req.newFoodName() != null && !req.newFoodName().isBlank()) {
            String trimmedName = req.newFoodName().trim();

            // 모든 언어 통합 중복 체크
            return foodMasterRepository.findByNameInAnyLocale(trimmedName)
                    .orElseGet(() -> {
                        String locale = (req.cookingStyle() != null) ? req.cookingStyle() : "ko-KR";
                        return createSuggestedFoodEntity(trimmedName, userId, locale);
                    });
        }
        return null;
    }

    private FoodMaster createSuggestedFoodEntity(String foodName, Long userId, String locale) {
        // Convert locale to BCP47 format for consistent FoodMaster keys
        String bcp47Locale = LocaleUtils.toBcp47(locale);

        // 1. foods_master에 비검증 상태로 등록
        FoodMaster newFood = FoodMaster.builder()
                .name(Map.of(bcp47Locale, foodName))
                .isVerified(false)
                .build();
        foodMasterRepository.save(newFood);

        // Queue translation for the new food name to all supported locales
        translationEventService.queueFoodMasterTranslation(newFood, bcp47Locale);

        // 2. user_suggested_foods 기록 생성
        UserSuggestedFood suggestion = UserSuggestedFood.builder()
                .suggestedName(foodName)
                .localeCode(bcp47Locale)
                .user(userRepository.getReferenceById(userId))
                .status(SuggestionStatus.PENDING)
                .masterFoodRef(newFood)
                .build();
        suggestedFoodRepository.save(suggestion);

        return newFood;
    }

    private void saveIngredientsAndSteps(
            Recipe recipe,
            CreateRecipeRequestDto req,
            Long userId,
            String locale
    ) {
        // 1. 재료 저장
        if (req.ingredients() != null) {
            var ingredientList = req.ingredients();
            List<RecipeIngredient> ingredients = new java.util.ArrayList<>();
            for (int i = 0; i < ingredientList.size(); i++) {
                var dto = ingredientList.get(i);
                ingredients.add(RecipeIngredient.builder()
                        .recipe(recipe)
                        .name(dto.name())
                        .quantity(dto.quantity())
                        .unit(dto.unit())
                        .type(dto.type())
                        .displayOrder(i + 1)
                        .build());

                // Capture suggested ingredient if not in autocomplete
                if (dto.name() != null && dto.type() != null) {
                    captureSuggestedIngredientIfNotExists(dto.name(), dto.type(), locale, userId);
                }
            }
            ingredientRepository.saveAll(ingredients);
            // Maintain bidirectional relationship for proper lazy loading in same transaction
            recipe.getIngredients().addAll(ingredients);
        }

        // 2. 단계 저장 및 단계 이미지 연결
        if (req.steps() != null) {
            for (StepDto stepDto : req.steps()) {
                Image stepImage = null;
                if (stepDto.imagePublicId() != null) {
                    stepImage = imageRepository.findByPublicId(stepDto.imagePublicId())
                            .orElseThrow(() -> new IllegalArgumentException("Step image not found"));

                    // Set recipe_id to satisfy chk_images_has_parent constraint
                    // Also set type to STEP to distinguish from cover images
                    stepImage.setRecipe(recipe);
                    stepImage.setType(com.cookstemma.cookstemma.domain.enums.ImageType.STEP);
                    stepImage.setStatus(com.cookstemma.cookstemma.domain.enums.ImageStatus.ACTIVE);
                    imageRepository.save(stepImage);

                    // Trigger async variant generation for step images
                    imageProcessingService.generateVariantsAsync(stepImage.getId());
                }

                RecipeStep step = RecipeStep.builder()
                        .recipe(recipe)
                        .stepNumber(stepDto.stepNumber())
                        .description(stepDto.description())
                        .image(stepImage)
                        .build();
                stepRepository.save(step);
                // Maintain bidirectional relationship for proper lazy loading in same transaction
                recipe.getSteps().add(step);
            }
        }
    }

    /**
     * Captures ingredient name as a suggestion if it doesn't exist in AutocompleteItem.
     * This allows admins to review and approve new ingredients.
     */
    private void captureSuggestedIngredientIfNotExists(
            String ingredientName,
            IngredientType ingredientType,
            String localeCode,
            Long userId
    ) {
        if (ingredientName == null || ingredientName.isBlank()) {
            return;
        }

        String normalizedLocale = localeCode != null ? localeCode.replace("_", "-") : "ko-KR";
        AutocompleteType autocompleteType = mapIngredientTypeToAutocompleteType(ingredientType);

        // Check if ingredient exists in AutocompleteItem
        boolean existsInAutocomplete = autocompleteItemRepository.existsByNameIgnoreCaseAndTypeAndLocale(
                ingredientName.trim(),
                autocompleteType.name(),
                normalizedLocale
        );

        if (existsInAutocomplete) {
            return;
        }

        // Check if already suggested
        boolean alreadySuggested = suggestedIngredientRepository
                .existsBySuggestedNameIgnoreCaseAndIngredientTypeAndLocaleCode(
                        ingredientName.trim(),
                        ingredientType,
                        normalizedLocale
                );

        if (alreadySuggested) {
            return;
        }

        // Create suggestion record for admin review
        UserSuggestedIngredient suggestion = UserSuggestedIngredient.builder()
                .suggestedName(ingredientName.trim())
                .ingredientType(ingredientType)
                .localeCode(normalizedLocale)
                .user(userRepository.getReferenceById(userId))
                .status(SuggestionStatus.PENDING)
                .build();
        suggestedIngredientRepository.save(suggestion);

        log.debug("Created suggested ingredient: {} ({}) for locale {}",
                ingredientName, ingredientType, normalizedLocale);
    }

    private AutocompleteType mapIngredientTypeToAutocompleteType(IngredientType ingredientType) {
        return switch (ingredientType) {
            case MAIN -> AutocompleteType.MAIN_INGREDIENT;
            case SECONDARY -> AutocompleteType.SECONDARY_INGREDIENT;
            case SEASONING -> AutocompleteType.SEASONING;
        };
    }

    private String getFoodName(Recipe recipe) {
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String locale = recipe.getCookingStyle();

        // 1. 레시피의 로케일과 일치하는 이름이 있는지 확인
        if (locale != null && nameMap.containsKey(locale)) {
            return nameMap.get(locale);
        }

        // 2. 없으면 한국어(ko-KR) 이름을 우선적으로 시도
        if (nameMap.containsKey("ko-KR")) {
            return nameMap.get("ko-KR");
        }

        // 3. 그것도 없으면 맵에 들어있는 첫 번째 이름을 반환
        return nameMap.values().stream().findFirst().orElse("Unknown Food");
    }

    /**
     * Convert recipe to summary DTO without locale (uses default locale).
     * For backward compatibility with methods that don't have locale context.
     */
    private RecipeSummaryDto convertToSummary(Recipe recipe) {
        return convertToSummary(recipe, LocaleUtils.DEFAULT_LOCALE);
    }

    /**
     * Convert recipe to summary DTO with locale-aware field resolution.
     */
    private RecipeSummaryDto convertToSummary(Recipe recipe, String locale) {
        // 1. 작성자 정보 조회
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // 2. 음식 이름 추출 (locale 기반)
        String foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        // 3. 제목/설명 locale 기반 추출
        String localizedTitle = LocaleUtils.getLocalizedValue(
                recipe.getTitleTranslations(), locale, recipe.getTitle());
        String localizedDescription = LocaleUtils.getLocalizedValue(
                recipe.getDescriptionTranslations(), locale, recipe.getDescription());

        // 4. 썸네일 URL 추출 (첫 번째 커버 이미지 사용)
        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 5. 변형 수 조회
        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());

        // 6. 로그 수 조회 (Activity count)
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // 7. 루트 레시피 제목 추출 (locale 기반)
        String rootTitle = null;
        if (recipe.getRootRecipe() != null) {
            rootTitle = LocaleUtils.getLocalizedValue(
                    recipe.getRootRecipe().getTitleTranslations(),
                    locale,
                    recipe.getRootRecipe().getTitle());
        }

        // 8. 해시태그 추출 (first 3)
        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                localizedTitle,
                localizedDescription,
                recipe.getCookingStyle(),
                creatorPublicId,
                userName,
                thumbnail,
                variantCount,
                logCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
                rootTitle,
                recipe.getServings() != null ? recipe.getServings() : 2,
                recipe.getCookingTimeRange() != null ? recipe.getCookingTimeRange().name() : "MIN_30_TO_60",
                hashtags,
                recipe.getIsPrivate() != null ? recipe.getIsPrivate() : false
        );
    }

    @Transactional(readOnly = true)
    public HomeFeedResponseDto getHomeFeed(String locale) {
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        // Use BCP47 format for translation filtering (matches how Lambda translator stores keys)
        String langCode = LocaleUtils.toBcp47(normalizedLocale);

        // 1. 최근 요리 활동 (로그) 조회 - "📍 최근 요리 활동" 섹션
        // Use translation-aware query to only show logs available in user's locale
        List<RecentActivityDto> recentActivity = logPostRepository
                .findAllLogsPage(langCode, PageRequest.of(0, 5))
                .stream()
                .map(log -> {
                    var recipeLog = log.getRecipeLog();
                    var recipe = recipeLog.getRecipe();
                    String userName = userRepository.findById(log.getCreatorId())
                            .map(User::getUsername)
                            .orElse("익명");
                    String thumbnailUrl = log.getImages().stream()
                            .findFirst()
                            .map(img -> urlPrefix + "/" + img.getStoredFilename())
                            .orElse(null);

                    // Get localized recipe title
                    String recipeTitle = LocaleUtils.getLocalizedValue(
                            recipe.getTitleTranslations(), normalizedLocale, recipe.getTitle());
                    // Get localized food name
                    String foodName = LocaleUtils.getLocalizedValue(
                            recipe.getFoodMaster().getName(), normalizedLocale,
                            recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

                    return RecentActivityDto.builder()
                            .logPublicId(log.getPublicId())
                            .rating(recipeLog.getRating())
                            .thumbnailUrl(thumbnailUrl)
                            .userName(userName)
                            .recipeTitle(recipeTitle)
                            .recipePublicId(recipe.getPublicId())
                            .foodName(foodName)
                            .createdAt(log.getCreatedAt())
                            .hashtags(log.getHashtags().stream().map(Hashtag::getName).toList())
                            .commentCount(log.getCommentCount())
                            .build();
                })
                .toList();

        // 2. 최근 레시피 조회 - Use translation-aware query to only show recipes available in user's locale
        List<RecipeSummaryDto> recentRecipes = recipeRepository
                .findPublicRecipesPage(langCode, PageRequest.of(0, 5))
                .stream()
                .map(r -> convertToSummary(r, normalizedLocale))
                .toList();

        // 3. 활발한 변형 트리 조회 (기획서: "🔥 이 레시피, 이렇게 바뀌고 있어요")
        // Use translation-aware query to only show recipes available in user's locale
        List<TrendingTreeDto> trending = recipeRepository
                .findRecipesOrderByTrending(langCode, PageRequest.of(0, 5))
                .stream()
                .map(root -> {
                    long variants = recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(root.getId());
                    long logs = recipeLogRepository.countByRecipeId(root.getId());
                    String thumbnail = root.getCoverImages().stream()
                            .filter(img -> img.getType() == com.cookstemma.cookstemma.domain.enums.ImageType.COVER)
                            .findFirst()
                            .map(img -> urlPrefix + "/" + img.getStoredFilename())
                            .orElse(null);

                    // Get creator info (handle null creatorId)
                    var creatorOpt = Optional.ofNullable(root.getCreatorId())
                            .flatMap(userRepository::findById);
                    String userName = creatorOpt.map(user -> user.getUsername()).orElse("Unknown");
                    UUID creatorPublicId = creatorOpt.map(user -> user.getPublicId()).orElse(null);

                    // Get localized title and food name
                    String title = LocaleUtils.getLocalizedValue(
                            root.getTitleTranslations(), normalizedLocale, root.getTitle());
                    String foodName = LocaleUtils.getLocalizedValue(
                            root.getFoodMaster().getName(), normalizedLocale,
                            root.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
                    String description = LocaleUtils.getLocalizedValue(
                            root.getDescriptionTranslations(), normalizedLocale, root.getDescription());

                    return TrendingTreeDto.builder()
                            .rootRecipeId(root.getPublicId())
                            .title(title)
                            .foodName(foodName)
                            .cookingStyle(root.getCookingStyle())
                            .thumbnail(thumbnail)
                            .variantCount(variants)
                            .logCount(logs)
                            .latestChangeSummary(description)
                            .userName(userName)
                            .creatorPublicId(creatorPublicId)
                            .build();
                }).toList();

        return new HomeFeedResponseDto(recentActivity, recentRecipes, trending);
    }

    private Long findUserId(UUID publicId) {
        return userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found")).getId();
    }

    public Slice<RecipeSummaryDto> findAllRootRecipes(Pageable pageable) {
        return recipeRepository.findAllRootRecipes(pageable)
                .map(this::convertToSummary);
    }

    /**
     * 내가 만든 레시피 목록 조회
     * @param typeFilter null=all, "original"=only originals, "variants"=only variants
     */
    public Slice<RecipeSummaryDto> getMyRecipes(Long userId, String typeFilter, Pageable pageable) {
        Slice<Recipe> recipes;

        if ("original".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNullOrderByCreatedAtDesc(userId, pageable);
        } else if ("variants".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNotNullOrderByCreatedAtDesc(userId, pageable);
        } else {
            recipes = recipeRepository.findByCreatorIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId, pageable);
        }

        return recipes.map(this::convertToSummary);
    }

    /**
     * 레시피 검색 (제목, 설명, 재료명)
     * Filters by translation availability based on locale
     */
    public Slice<RecipeSummaryDto> searchRecipes(String keyword, Pageable pageable, String locale) {
        if (keyword == null || keyword.trim().length() < 2) {
            return new org.springframework.data.domain.SliceImpl<>(
                    java.util.Collections.emptyList(), pageable, false);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);

        // Use unsorted pageable - the native query handles ordering by relevance score
        Pageable unsortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize());
        return recipeRepository.searchRecipes(keyword.trim(), unsortedPageable)
                .map(r -> convertToSummary(r, normalizedLocale));
    }

    // ================================================================
    // Recipe Modification (Edit/Delete) Methods
    // ================================================================

    /**
     * Check if a recipe can be modified (edited or deleted) by the current user.
     * A recipe can only be modified if:
     * 1. The user is the creator
     * 2. The recipe has no child variants (recipes that use this as parent)
     * 3. The recipe has no associated cooking logs
     */
    public RecipeModifiableResponseDto checkRecipeModifiable(UUID publicId, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        boolean isOwner = recipe.getCreatorId().equals(userId);
        long variantCount = recipeRepository.countByParentRecipeIdAndDeletedAtIsNull(recipe.getId());
        long logCount = recipeLogRepository.countByRecipeId(recipe.getId());

        boolean hasVariants = variantCount > 0;
        boolean hasLogs = logCount > 0;
        boolean canModify = isOwner && !hasVariants && !hasLogs;

        String reason = null;
        if (!isOwner) {
            reason = "You can only modify recipes you created";
        } else if (hasVariants) {
            reason = "Cannot modify: this recipe has " + variantCount + " variant(s)";
        } else if (hasLogs) {
            reason = "Cannot modify: this recipe has " + logCount + " cooking log(s)";
        }

        return RecipeModifiableResponseDto.builder()
                .canModify(canModify)
                .isOwner(isOwner)
                .hasVariants(hasVariants)
                .hasLogs(hasLogs)
                .variantCount(variantCount)
                .logCount(logCount)
                .reason(reason)
                .build();
    }

    /**
     * Update recipe in-place.
     * Only allowed if the user is the creator and there are no variants or logs.
     */
    @Transactional
    public RecipeDetailResponseDto updateRecipe(UUID publicId, UpdateRecipeRequestDto req, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        // Validate ownership
        if (!recipe.getCreatorId().equals(userId)) {
            throw new IllegalArgumentException("You can only edit recipes you created");
        }

        // Validate no variants
        long variantCount = recipeRepository.countByParentRecipeIdAndDeletedAtIsNull(recipe.getId());
        if (variantCount > 0) {
            throw new IllegalArgumentException("Cannot edit: recipe has " + variantCount + " variant(s)");
        }

        // Validate no logs
        long logCount = recipeLogRepository.countByRecipeId(recipe.getId());
        if (logCount > 0) {
            throw new IllegalArgumentException("Cannot edit: recipe has " + logCount + " cooking log(s)");
        }

        // Update basic fields
        recipe.setTitle(req.title());
        recipe.setDescription(req.description());
        if (req.cookingStyle() != null && !req.cookingStyle().isBlank()) {
            recipe.setCookingStyle(req.cookingStyle());
        }

        // Update servings and cooking time
        if (req.servings() != null) {
            recipe.setServings(req.servings());
        }
        if (req.cookingTimeRange() != null && !req.cookingTimeRange().isBlank()) {
            try {
                recipe.setCookingTimeRange(CookingTimeRange.valueOf(req.cookingTimeRange()));
            } catch (IllegalArgumentException ignored) {
                // Keep existing value if invalid
            }
        }

        // Update privacy setting
        if (req.isPrivate() != null) {
            recipe.setIsPrivate(req.isPrivate());
        }

        // Update ingredients (clear and re-add)
        ingredientRepository.deleteAllByRecipeId(recipe.getId());
        if (req.ingredients() != null) {
            var ingredientList = req.ingredients();
            List<RecipeIngredient> newIngredients = new java.util.ArrayList<>();
            for (int i = 0; i < ingredientList.size(); i++) {
                var dto = ingredientList.get(i);
                newIngredients.add(RecipeIngredient.builder()
                        .recipe(recipe)
                        .name(dto.name())
                        .quantity(dto.quantity())
                        .unit(dto.unit())
                        .type(dto.type())
                        .displayOrder(i + 1)
                        .build());
            }
            ingredientRepository.saveAll(newIngredients);
        }

        // Update steps (clear and re-add)
        stepRepository.deleteAllByRecipeId(recipe.getId());
        if (req.steps() != null) {
            for (StepDto stepDto : req.steps()) {
                Image stepImage = null;
                if (stepDto.imagePublicId() != null) {
                    stepImage = imageRepository.findByPublicId(stepDto.imagePublicId())
                            .orElseThrow(() -> new IllegalArgumentException("Step image not found"));
                    // Set recipe_id to satisfy chk_images_has_parent constraint
                    // Also set type to STEP to distinguish from cover images
                    stepImage.setRecipe(recipe);
                    stepImage.setType(com.cookstemma.cookstemma.domain.enums.ImageType.STEP);
                    stepImage.setStatus(com.cookstemma.cookstemma.domain.enums.ImageStatus.ACTIVE);
                    imageRepository.save(stepImage);

                    // Trigger async variant generation for step images
                    imageProcessingService.generateVariantsAsync(stepImage.getId());
                }

                RecipeStep step = RecipeStep.builder()
                        .recipe(recipe)
                        .stepNumber(stepDto.stepNumber())
                        .description(stepDto.description())
                        .image(stepImage)
                        .build();
                stepRepository.save(step);
            }
        }

        // Update images - deactivate old ones and activate new ones
        imageService.updateRecipeImages(recipe, req.imagePublicIds());

        // Update hashtags
        if (req.hashtags() != null) {
            Set<Hashtag> hashtags = hashtagService.getOrCreateHashtags(req.hashtags());
            recipe.setHashtags(hashtags);
        } else {
            recipe.getHashtags().clear();
        }

        recipeRepository.save(recipe);

        // Queue translation for updated content (hybrid SQS push)
        translationEventService.queueRecipeTranslation(recipe);

        return getRecipeDetail(recipe.getPublicId(), userId);
    }

    /**
     * Soft delete a recipe.
     * Only allowed if the user is the creator and there are no variants or logs.
     */
    @Transactional
    public void deleteRecipe(UUID publicId, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        // Validate ownership
        if (!recipe.getCreatorId().equals(userId)) {
            throw new IllegalArgumentException("You can only delete recipes you created");
        }

        // Validate no variants
        long variantCount = recipeRepository.countByParentRecipeIdAndDeletedAtIsNull(recipe.getId());
        if (variantCount > 0) {
            throw new IllegalArgumentException("Cannot delete: recipe has " + variantCount + " variant(s)");
        }

        // Validate no logs
        long logCount = recipeLogRepository.countByRecipeId(recipe.getId());
        if (logCount > 0) {
            throw new IllegalArgumentException("Cannot delete: recipe has " + logCount + " cooking log(s)");
        }

        // Soft delete (images remain, just hidden with recipe)
        recipe.softDelete();
        recipeRepository.save(recipe);
    }

    // ================================================================
    // Cursor-Based Pagination Methods
    // ================================================================

    /**
     * Find recipes with cursor-based pagination
     * Filters by translation availability based on contentLocale
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<RecipeSummaryDto> findRecipesWithCursor(String locale, boolean onlyRoot, String typeFilter, String cursor, int size, String contentLocale) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        boolean isOriginalFilter = "original".equalsIgnoreCase(typeFilter) || onlyRoot;
        boolean isVariantFilter = "variant".equalsIgnoreCase(typeFilter);

        // Use BCP47 format for translation filtering (matches how Lambda translator stores keys)
        String langCode = LocaleUtils.toBcp47(contentLocale);

        Slice<Recipe> recipes;

        if (cursorData == null) {
            // Initial page (no cursor)
            if (locale == null || locale.isBlank()) {
                if (isVariantFilter) {
                    recipes = recipeRepository.findVariantRecipesWithCursorInitial(langCode, pageable);
                } else if (isOriginalFilter) {
                    recipes = recipeRepository.findOriginalRecipesWithCursorInitial(langCode, pageable);
                } else {
                    recipes = recipeRepository.findPublicRecipesWithCursorInitial(langCode, pageable);
                }
            } else {
                if (isVariantFilter) {
                    recipes = recipeRepository.findVariantRecipesByLocaleWithCursorInitial(locale, pageable);
                } else if (isOriginalFilter) {
                    recipes = recipeRepository.findOriginalRecipesByLocaleWithCursorInitial(locale, pageable);
                } else {
                    recipes = recipeRepository.findPublicRecipesByLocaleWithCursorInitial(locale, pageable);
                }
            }
        } else {
            // With cursor
            if (locale == null || locale.isBlank()) {
                if (isVariantFilter) {
                    recipes = recipeRepository.findVariantRecipesWithCursor(langCode, cursorData.createdAt(), cursorData.id(), pageable);
                } else if (isOriginalFilter) {
                    recipes = recipeRepository.findOriginalRecipesWithCursor(langCode, cursorData.createdAt(), cursorData.id(), pageable);
                } else {
                    recipes = recipeRepository.findPublicRecipesWithCursor(langCode, cursorData.createdAt(), cursorData.id(), pageable);
                }
            } else {
                if (isVariantFilter) {
                    recipes = recipeRepository.findVariantRecipesByLocaleWithCursor(locale, cursorData.createdAt(), cursorData.id(), pageable);
                } else if (isOriginalFilter) {
                    recipes = recipeRepository.findOriginalRecipesByLocaleWithCursor(locale, cursorData.createdAt(), cursorData.id(), pageable);
                } else {
                    recipes = recipeRepository.findPublicRecipesByLocaleWithCursor(locale, cursorData.createdAt(), cursorData.id(), pageable);
                }
            }
        }

        return buildCursorResponse(recipes, size, contentLocale);
    }

    /**
     * Search recipes with cursor-based pagination
     * Filters by translation availability based on contentLocale
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<RecipeSummaryDto> searchRecipesWithCursor(String keyword, String cursor, int size, String contentLocale) {
        if (keyword == null || keyword.trim().length() < 2) {
            return CursorPageResponse.empty(size);
        }

        // Note: Search uses relevance ordering, so we fall back to simple offset pagination
        // decoded from cursor as page number for simplicity
        int page = 0;
        if (cursor != null && !cursor.isBlank()) {
            try {
                page = Integer.parseInt(cursor);
            } catch (NumberFormatException ignored) {}
        }

        Pageable pageable = PageRequest.of(page, size);
        Slice<Recipe> recipes = recipeRepository.searchRecipes(keyword.trim(), pageable);
        List<RecipeSummaryDto> content = recipes.getContent().stream()
                .map(r -> convertToSummary(r, contentLocale))
                .toList();

        String nextCursor = recipes.hasNext() ? String.valueOf(page + 1) : null;
        return new CursorPageResponse<>(content, nextCursor, recipes.hasNext(), size);
    }

    /**
     * Get my recipes with cursor-based pagination
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<RecipeSummaryDto> getMyRecipesWithCursor(Long userId, String typeFilter, String cursor, int size, String locale) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<Recipe> recipes;

        if (cursorData == null) {
            // Initial page
            if ("original".equalsIgnoreCase(typeFilter)) {
                recipes = recipeRepository.findMyOriginalRecipesWithCursorInitial(userId, pageable);
            } else if ("variants".equalsIgnoreCase(typeFilter)) {
                recipes = recipeRepository.findMyVariantRecipesWithCursorInitial(userId, pageable);
            } else {
                recipes = recipeRepository.findMyRecipesWithCursorInitial(userId, pageable);
            }
        } else {
            // With cursor
            if ("original".equalsIgnoreCase(typeFilter)) {
                recipes = recipeRepository.findMyOriginalRecipesWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
            } else if ("variants".equalsIgnoreCase(typeFilter)) {
                recipes = recipeRepository.findMyVariantRecipesWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
            } else {
                recipes = recipeRepository.findMyRecipesWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
            }
        }

        return buildCursorResponse(recipes, size, locale);
    }

    /**
     * Helper to build cursor response from Slice (uses default locale)
     */
    private CursorPageResponse<RecipeSummaryDto> buildCursorResponse(Slice<Recipe> recipes, int size) {
        return buildCursorResponse(recipes, size, LocaleUtils.DEFAULT_LOCALE);
    }

    /**
     * Helper to build cursor response from Slice
     */
    private CursorPageResponse<RecipeSummaryDto> buildCursorResponse(Slice<Recipe> recipes, int size, String contentLocale) {
        List<RecipeSummaryDto> content = recipes.getContent().stream()
                .map(r -> convertToSummary(r, contentLocale))
                .toList();

        String nextCursor = null;
        if (recipes.hasNext() && !recipes.getContent().isEmpty()) {
            Recipe lastItem = recipes.getContent().get(recipes.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getId());
        }

        return CursorPageResponse.of(content, nextCursor, size);
    }

    // ================================================================
    // Unified Dual Pagination Methods (Strategy Pattern)
    // ================================================================

    /**
     * Unified recipe list with strategy-based pagination.
     * - If cursor is provided → cursor-based pagination (mobile)
     * - If page is provided → offset-based pagination (web)
     * - Default → cursor-based initial page
     *
     * Sort options:
     * - recent (default): order by createdAt DESC
     * - mostForked: order by variant count DESC
     * - trending: order by recent activity (variants + logs in last 7 days)
     *
     * Filter options:
     * - cookingTimeRanges: List of acceptable cooking time ranges
     * - minServings/maxServings: Servings range filter
     *
     * @param contentLocale Locale from Accept-Language header for content translation
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> findRecipesUnified(
            String locale, String typeFilter, String sort,
            List<CookingTimeRange> cookingTimeRanges, Integer minServings, Integer maxServings,
            String cursor, Integer page, int size, String contentLocale) {

        String normalizedLocale = LocaleUtils.normalizeLocale(contentLocale);

        // Check if any advanced filters are applied
        boolean hasAdvancedFilters = (cookingTimeRanges != null && !cookingTimeRanges.isEmpty())
                || minServings != null || maxServings != null;

        // For mostForked, trending, and popular, use offset pagination (complex sorting)
        boolean isComplexSort = "mostForked".equalsIgnoreCase(sort) || "trending".equalsIgnoreCase(sort) || "popular".equalsIgnoreCase(sort);

        // For advanced filters, use specification-based pagination
        if (hasAdvancedFilters || isComplexSort) {
            int pageNum = (page != null) ? page : 0;
            if (isComplexSort && !hasAdvancedFilters) {
                return findRecipesWithOffsetSorted(locale, typeFilter, sort, pageNum, size, normalizedLocale);
            }
            return findRecipesWithSpecification(locale, typeFilter, sort, cookingTimeRanges, minServings, maxServings, pageNum, size, normalizedLocale);
        }

        // Strategy selection for recent sort (default) without advanced filters
        if (cursor != null && !cursor.isEmpty()) {
            return findRecipesWithCursorUnified(locale, typeFilter, cursor, size, normalizedLocale);
        } else if (page != null) {
            return findRecipesWithOffset(locale, typeFilter, page, size, normalizedLocale);
        } else {
            // Default: initial cursor-based (first page)
            return findRecipesWithCursorUnified(locale, typeFilter, null, size, normalizedLocale);
        }
    }

    /**
     * Specification-based pagination for advanced filtering.
     * Supports cooking time ranges and servings filters.
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithSpecification(
            String locale, String typeFilter, String sort,
            List<CookingTimeRange> cookingTimeRanges, Integer minServings, Integer maxServings,
            int page, int size, String contentLocale) {

        Sort sortBy;
        if ("mostForked".equalsIgnoreCase(sort)) {
            sortBy = Sort.by(Sort.Direction.DESC, "createdAt"); // TODO: Implement variant count sorting with Spec
        } else if ("trending".equalsIgnoreCase(sort)) {
            sortBy = Sort.by(Sort.Direction.DESC, "createdAt"); // TODO: Implement trending with Spec
        } else {
            sortBy = Sort.by(Sort.Direction.DESC, "createdAt");
        }

        Pageable pageable = PageRequest.of(page, size, sortBy);
        var spec = RecipeSpecification.withFilters(locale, typeFilter, cookingTimeRanges, minServings, maxServings);

        Page<Recipe> recipes = recipeRepository.findAll(spec, pageable);
        Page<RecipeSummaryDto> mappedPage = recipes.map(r -> convertToSummary(r, contentLocale));
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Offset-based pagination for web clients.
     * Returns Page with totalElements, totalPages, currentPage.
     * Filters by translation availability based on contentLocale
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithOffset(
            String locale, String typeFilter, int page, int size, String contentLocale) {

        Pageable pageable = PageRequest.of(page, size);

        boolean isOriginalFilter = "original".equalsIgnoreCase(typeFilter);
        boolean isVariantFilter = "variant".equalsIgnoreCase(typeFilter);

        // Use BCP47 format for translation filtering (matches how Lambda translator stores keys)
        String langCode = LocaleUtils.toBcp47(contentLocale);

        Page<Recipe> recipes;

        if (locale == null || locale.isBlank()) {
            if (isVariantFilter) {
                recipes = recipeRepository.findVariantRecipesPage(langCode, pageable);
            } else if (isOriginalFilter) {
                recipes = recipeRepository.findOriginalRecipesPage(langCode, pageable);
            } else {
                recipes = recipeRepository.findPublicRecipesPage(langCode, pageable);
            }
        } else {
            if (isVariantFilter) {
                recipes = recipeRepository.findVariantRecipesByLocalePage(locale, pageable);
            } else if (isOriginalFilter) {
                recipes = recipeRepository.findOriginalRecipesByLocalePage(locale, pageable);
            } else {
                recipes = recipeRepository.findPublicRecipesByLocalePage(locale, pageable);
            }
        }

        Page<RecipeSummaryDto> mappedPage = recipes.map(r -> convertToSummary(r, contentLocale));
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Offset-based pagination with complex sorting (mostForked, trending).
     * Uses native queries with subqueries for counting variants/activity.
     * Filters by translation availability based on contentLocale
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithOffsetSorted(
            String locale, String typeFilter, String sort, int page, int size, String contentLocale) {

        Pageable pageable = PageRequest.of(page, size);

        // Use BCP47 format for translation filtering (matches how Lambda translator stores keys)
        String langCode = LocaleUtils.toBcp47(contentLocale);

        Page<Recipe> recipes;

        if ("mostForked".equalsIgnoreCase(sort)) {
            // Order by variant count (most evolved)
            recipes = recipeRepository.findRecipesOrderByVariantCount(langCode, pageable);
        } else if ("trending".equalsIgnoreCase(sort)) {
            // Order by recent activity (variants + logs in last 7 days)
            recipes = recipeRepository.findRecipesOrderByTrending(langCode, pageable);
        } else if ("popular".equalsIgnoreCase(sort)) {
            // Order by popularity score (weighted engagement metrics)
            recipes = recipeRepository.findRecipesOrderByPopular(langCode, pageable);
        } else {
            // Fallback to recent
            recipes = recipeRepository.findPublicRecipesPage(langCode, pageable);
        }

        Page<RecipeSummaryDto> mappedPage = recipes.map(r -> convertToSummary(r, contentLocale));
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based pagination wrapped in UnifiedPageResponse for mobile clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithCursorUnified(
            String locale, String typeFilter, String cursor, int size, String contentLocale) {

        CursorPageResponse<RecipeSummaryDto> cursorResponse =
                findRecipesWithCursor(locale, false, typeFilter, cursor, size, contentLocale);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }

    /**
     * Unified my recipes with strategy-based pagination.
     * @param contentLocale Content locale from Accept-Language header for translation
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> getMyRecipesUnified(
            Long userId, String typeFilter, String cursor, Integer page, int size, String contentLocale) {

        String normalizedLocale = LocaleUtils.normalizeLocale(contentLocale);

        if (cursor != null && !cursor.isEmpty()) {
            return getMyRecipesWithCursorUnified(userId, typeFilter, cursor, size, normalizedLocale);
        } else if (page != null) {
            return getMyRecipesWithOffset(userId, typeFilter, page, size, normalizedLocale);
        } else {
            return getMyRecipesWithCursorUnified(userId, typeFilter, null, size, normalizedLocale);
        }
    }

    /**
     * Offset-based my recipes for web clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getMyRecipesWithOffset(
            Long userId, String typeFilter, int page, int size, String locale) {

        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<Recipe> recipes;

        if ("original".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findMyOriginalRecipesPage(userId, pageable);
        } else if ("variants".equalsIgnoreCase(typeFilter)) {
            recipes = recipeRepository.findMyVariantRecipesPage(userId, pageable);
        } else {
            recipes = recipeRepository.findMyRecipesPage(userId, pageable);
        }

        Page<RecipeSummaryDto> mappedPage = recipes.map(r -> convertToSummary(r, locale));
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based my recipes wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getMyRecipesWithCursorUnified(
            Long userId, String typeFilter, String cursor, int size, String locale) {

        CursorPageResponse<RecipeSummaryDto> cursorResponse =
                getMyRecipesWithCursor(userId, typeFilter, cursor, size, locale);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }

    /**
     * Unified search with strategy-based pagination.
     *
     * @param contentLocale Locale from Accept-Language header for content translation
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> searchRecipesUnified(
            String keyword, String cursor, Integer page, int size, String contentLocale) {

        String normalizedLocale = LocaleUtils.normalizeLocale(contentLocale);

        if (keyword == null || keyword.trim().length() < 2) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        if (cursor != null && !cursor.isEmpty()) {
            return searchRecipesWithCursorUnified(keyword, cursor, size, normalizedLocale);
        } else if (page != null) {
            return searchRecipesWithOffset(keyword, page, size, normalizedLocale);
        } else {
            return searchRecipesWithCursorUnified(keyword, null, size, normalizedLocale);
        }
    }

    /**
     * Offset-based search for web clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> searchRecipesWithOffset(
            String keyword, int page, int size, String contentLocale) {

        Pageable pageable = PageRequest.of(page, size);
        Page<Recipe> recipes = recipeRepository.searchRecipesPage(keyword.trim(), pageable);

        Page<RecipeSummaryDto> mappedPage = recipes.map(r -> convertToSummary(r, contentLocale));
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based search wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<RecipeSummaryDto> searchRecipesWithCursorUnified(
            String keyword, String cursor, int size, String contentLocale) {

        CursorPageResponse<RecipeSummaryDto> cursorResponse =
                searchRecipesWithCursor(keyword, cursor, size, contentLocale);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}