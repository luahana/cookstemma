package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeIngredient;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeStep;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.CookingTimeRange;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import com.pairingplanet.pairing_planet.dto.common.CursorPageResponse;
import com.pairingplanet.pairing_planet.dto.common.UnifiedPageResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.log_post.RecentActivityDto;
import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.util.CursorUtil;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.food.UserSuggestedFoodRepository;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.recipe.*;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
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

import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
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
    private final RecipeCategoryDetectionService categoryDetectionService;
    private final SavedRecipeRepository savedRecipeRepository;
    private final HashtagService hashtagService;
    private final NotificationService notificationService;

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
            throw new IllegalArgumentException("음식 정보(UUID 또는 새 이름)가 반드시 필요합니다.");
        }

        String finalLocale = (req.culinaryLocale() == null || req.culinaryLocale().isBlank())
                ? (parent != null ? parent.getCulinaryLocale() : "ko-KR")
                : req.culinaryLocale();

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
                .culinaryLocale(finalLocale)
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
                .build();

        recipeRepository.save(recipe);

        // Process hashtags
        if (req.hashtags() != null && !req.hashtags().isEmpty()) {
            Set<Hashtag> hashtags = hashtagService.getOrCreateHashtags(req.hashtags());
            recipe.setHashtags(hashtags);
        }
        saveIngredientsAndSteps(recipe, req);
        imageService.activateImages(req.imagePublicIds(), recipe);

        // Flush to ensure images are persisted before fetching recipe detail
        imageRepository.flush();

        // Notify parent recipe owner if this is a variation
        if (parent != null) {
            User sender = userRepository.findById(creatorId)
                    .orElseThrow(() -> new IllegalArgumentException("User not found"));
            notificationService.notifyRecipeVariation(parent, recipe, sender);
        }

        return getRecipeDetail(recipe.getPublicId());
    }

    /**
     * 레시피 상세 조회 (기획 원칙 1 반영: 상단 루트 고정)
     * 비로그인 사용자용 (isSavedByCurrentUser = null)
     */
    public RecipeDetailResponseDto getRecipeDetail(UUID publicId) {
        return getRecipeDetail(publicId, null);
    }

    /**
     * 레시피 상세 조회 (기획 원칙 1 반영: 상단 루트 고정)
     * 로그인 사용자용 (저장 여부 확인)
     */
    public RecipeDetailResponseDto getRecipeDetail(UUID publicId, Long userId) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        // [원칙 1] 어디서든 루트 레시피 정보 포함
        Recipe root = (recipe.getRootRecipe() != null) ? recipe.getRootRecipe() : recipe;

        // 변형 및 로그 리스트 조회 - 루트에 연결된 모든 변형을 가져옴
        List<RecipeSummaryDto> variants = recipeRepository.findByRootRecipeIdAndDeletedAtIsNull(root.getId())
                .stream()
                .filter(v -> !v.getId().equals(recipe.getId())) // Exclude current recipe
                .limit(6)  // Limit to 6 for "View All" detection (show 5, detect more if 6)
                .map(this::convertToSummary)
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
                    String foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCulinaryLocale());
                    Boolean isVariant = recipe.getRootRecipe() != null;

                    // Get hashtag names
                    List<String> logHashtags = logPost.getHashtags().stream()
                            .map(Hashtag::getName)
                            .toList();

                    return new LogPostSummaryDto(
                            logPost.getPublicId(),
                            logPost.getTitle(),
                            rl.getOutcome(),
                            thumbnailUrl,
                            logCreatorPublicId,
                            logCreatorName,
                            foodName,
                            logHashtags,
                            isVariant
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

        return RecipeDetailResponseDto.from(recipe, variants, logs, this.urlPrefix, isSavedByCurrentUser, creatorPublicId, userName, rootCreatorPublicId, rootCreatorName);
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
                        String locale = (req.culinaryLocale() != null) ? req.culinaryLocale() : "ko-KR";
                        return createSuggestedFoodEntity(trimmedName, userId, locale);
                    });
        }
        return null;
    }

    private FoodMaster createSuggestedFoodEntity(String foodName, Long userId, String locale) {
        String normalizedLocale = locale.replace("_", "-");

        // 1. foods_master에 비검증 상태로 등록
        FoodMaster newFood = FoodMaster.builder()
                .name(Map.of(normalizedLocale, foodName))
                .isVerified(false)
                .build();
        foodMasterRepository.save(newFood);

        // 2. user_suggested_foods 기록 생성
        UserSuggestedFood suggestion = UserSuggestedFood.builder()
                .suggestedName(foodName)
                .localeCode(normalizedLocale)
                .user(userRepository.getReferenceById(userId))
                .status(SuggestionStatus.PENDING)
                .masterFoodRef(newFood)
                .build();
        suggestedFoodRepository.save(suggestion);

        return newFood;
    }

    private void saveIngredientsAndSteps(Recipe recipe, CreateRecipeRequestDto req) {
        // 1. 재료 저장
        if (req.ingredients() != null) {
            List<RecipeIngredient> ingredients = req.ingredients().stream()
                    .map(dto -> RecipeIngredient.builder()
                            .recipe(recipe)
                            .name(dto.name())
                            .amount(dto.amount())
                            .quantity(dto.quantity())
                            .unit(dto.unit())
                            .type(dto.type())
                            .build())
                    .toList();
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

                    // Step images are linked ONLY via RecipeStep.image_id, NOT via recipe_id
                    // This keeps them separate from cover images in recipe.getImages()
                    stepImage.setStatus(com.pairingplanet.pairing_planet.domain.enums.ImageStatus.ACTIVE);
                    imageRepository.save(stepImage);
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

    private String getFoodName(Recipe recipe) {
        Map<String, String> nameMap = recipe.getFoodMaster().getName();
        String locale = recipe.getCulinaryLocale();

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

    private RecipeSummaryDto convertToSummary(Recipe recipe) {
        // 1. 작성자 정보 조회
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // 2. 음식 이름 추출 (JSONB 맵에서 현재 로케일에 맞는 이름 찾기)
        String foodName = getFoodName(recipe);

        // 3. 썸네일 URL 추출 (첫 번째 커버 이미지 사용, displayOrder로 정렬됨)
        String thumbnail = recipe.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 4. 변형 수 조회
        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());

        // 5. 로그 수 조회 (Activity count)
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // 6. 루트 레시피 제목 추출 (for lineage display in variants)
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;

        // 7. 해시태그 추출 (first 3)
        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
                recipe.getCulinaryLocale(),
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
                hashtags
        );
    }

    @Transactional(readOnly = true)
    public HomeFeedResponseDto getHomeFeed() {
        // 1. 최근 요리 활동 (로그) 조회 - "📍 최근 요리 활동" 섹션
        List<RecentActivityDto> recentActivity = logPostRepository
                .findAllOrderByCreatedAtDesc(PageRequest.of(0, 5))
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

                    return RecentActivityDto.builder()
                            .logPublicId(log.getPublicId())
                            .outcome(recipeLog.getOutcome())
                            .thumbnailUrl(thumbnailUrl)
                            .userName(userName)
                            .recipeTitle(recipe.getTitle())
                            .recipePublicId(recipe.getPublicId())
                            .foodName(getFoodName(recipe))
                            .createdAt(log.getCreatedAt())
                            .hashtags(log.getHashtags().stream().map(Hashtag::getName).toList())
                            .build();
                })
                .toList();

        // 2. 최근 레시피 조회
        List<RecipeSummaryDto> recentRecipes = recipeRepository.findTop5ByDeletedAtIsNullAndIsPrivateFalseOrderByCreatedAtDesc()
                .stream().map(this::convertToSummary).toList();

        // 3. 활발한 변형 트리 조회 (기획서: "🔥 이 레시피, 이렇게 바뀌고 있어요")
        List<TrendingTreeDto> trending = recipeRepository.findTrendingOriginals(PageRequest.of(0, 5))
                .stream().map(root -> {
                    long variants = recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(root.getId());
                    long logs = recipeLogRepository.countByRecipeId(root.getId());
                    String thumbnail = root.getImages().stream()
                            .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.COVER)
                            .findFirst()
                            .map(img -> urlPrefix + "/" + img.getStoredFilename())
                            .orElse(null);

                    // Get creator info (handle null creatorId)
                    var creatorOpt = Optional.ofNullable(root.getCreatorId())
                            .flatMap(userRepository::findById);
                    String userName = creatorOpt.map(user -> user.getUsername()).orElse("Unknown");
                    UUID creatorPublicId = creatorOpt.map(user -> user.getPublicId()).orElse(null);

                    return TrendingTreeDto.builder()
                            .rootRecipeId(root.getPublicId())
                            .title(root.getTitle())
                            .foodName(getFoodName(root))
                            .culinaryLocale(root.getCulinaryLocale())
                            .thumbnail(thumbnail)
                            .variantCount(variants)
                            .logCount(logs)
                            .latestChangeSummary(root.getDescription())
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
     */
    public Slice<RecipeSummaryDto> searchRecipes(String keyword, Pageable pageable) {
        if (keyword == null || keyword.trim().length() < 2) {
            return new org.springframework.data.domain.SliceImpl<>(
                    java.util.Collections.emptyList(), pageable, false);
        }
        // Use unsorted pageable - the native query handles ordering by relevance score
        Pageable unsortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize());
        return recipeRepository.searchRecipes(keyword.trim(), unsortedPageable)
                .map(this::convertToSummary);
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
        if (req.culinaryLocale() != null && !req.culinaryLocale().isBlank()) {
            recipe.setCulinaryLocale(req.culinaryLocale());
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

        // Update ingredients (clear and re-add)
        ingredientRepository.deleteAllByRecipeId(recipe.getId());
        if (req.ingredients() != null) {
            List<RecipeIngredient> newIngredients = req.ingredients().stream()
                    .map(dto -> RecipeIngredient.builder()
                            .recipe(recipe)
                            .name(dto.name())
                            .amount(dto.amount())
                            .quantity(dto.quantity())
                            .unit(dto.unit())
                            .type(dto.type())
                            .build())
                    .toList();
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
                    // Step images are linked ONLY via RecipeStep.image_id, NOT via recipe_id
                    stepImage.setStatus(com.pairingplanet.pairing_planet.domain.enums.ImageStatus.ACTIVE);
                    imageRepository.save(stepImage);
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
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<RecipeSummaryDto> findRecipesWithCursor(String locale, boolean onlyRoot, String typeFilter, String cursor, int size) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        boolean isOriginalFilter = "original".equalsIgnoreCase(typeFilter) || onlyRoot;
        boolean isVariantFilter = "variant".equalsIgnoreCase(typeFilter);

        Slice<Recipe> recipes;

        if (cursorData == null) {
            // Initial page (no cursor)
            if (locale == null || locale.isBlank()) {
                if (isVariantFilter) {
                    recipes = recipeRepository.findVariantRecipesWithCursorInitial(pageable);
                } else if (isOriginalFilter) {
                    recipes = recipeRepository.findOriginalRecipesWithCursorInitial(pageable);
                } else {
                    recipes = recipeRepository.findPublicRecipesWithCursorInitial(pageable);
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
                    recipes = recipeRepository.findVariantRecipesWithCursor(cursorData.createdAt(), cursorData.id(), pageable);
                } else if (isOriginalFilter) {
                    recipes = recipeRepository.findOriginalRecipesWithCursor(cursorData.createdAt(), cursorData.id(), pageable);
                } else {
                    recipes = recipeRepository.findPublicRecipesWithCursor(cursorData.createdAt(), cursorData.id(), pageable);
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

        return buildCursorResponse(recipes, size);
    }

    /**
     * Search recipes with cursor-based pagination
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<RecipeSummaryDto> searchRecipesWithCursor(String keyword, String cursor, int size) {
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
                .map(this::convertToSummary)
                .toList();

        String nextCursor = recipes.hasNext() ? String.valueOf(page + 1) : null;
        return new CursorPageResponse<>(content, nextCursor, recipes.hasNext(), size);
    }

    /**
     * Get my recipes with cursor-based pagination
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<RecipeSummaryDto> getMyRecipesWithCursor(Long userId, String typeFilter, String cursor, int size) {
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

        return buildCursorResponse(recipes, size);
    }

    /**
     * Helper to build cursor response from Slice
     */
    private CursorPageResponse<RecipeSummaryDto> buildCursorResponse(Slice<Recipe> recipes, int size) {
        List<RecipeSummaryDto> content = recipes.getContent().stream()
                .map(this::convertToSummary)
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
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> findRecipesUnified(
            String locale, String typeFilter, String sort, String cursor, Integer page, int size) {

        // For mostForked and trending, use offset pagination (complex sorting)
        boolean isComplexSort = "mostForked".equalsIgnoreCase(sort) || "trending".equalsIgnoreCase(sort);

        if (isComplexSort) {
            // Use offset pagination for complex sorts
            int pageNum = (page != null) ? page : 0;
            return findRecipesWithOffsetSorted(locale, typeFilter, sort, pageNum, size);
        }

        // Strategy selection for recent sort (default)
        if (cursor != null && !cursor.isEmpty()) {
            return findRecipesWithCursorUnified(locale, typeFilter, cursor, size);
        } else if (page != null) {
            return findRecipesWithOffset(locale, typeFilter, page, size);
        } else {
            // Default: initial cursor-based (first page)
            return findRecipesWithCursorUnified(locale, typeFilter, null, size);
        }
    }

    /**
     * Offset-based pagination for web clients.
     * Returns Page with totalElements, totalPages, currentPage.
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithOffset(
            String locale, String typeFilter, int page, int size) {

        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        boolean isOriginalFilter = "original".equalsIgnoreCase(typeFilter);
        boolean isVariantFilter = "variant".equalsIgnoreCase(typeFilter);

        Page<Recipe> recipes;

        if (locale == null || locale.isBlank()) {
            if (isVariantFilter) {
                recipes = recipeRepository.findVariantRecipesPage(pageable);
            } else if (isOriginalFilter) {
                recipes = recipeRepository.findOriginalRecipesPage(pageable);
            } else {
                recipes = recipeRepository.findPublicRecipesPage(pageable);
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

        Page<RecipeSummaryDto> mappedPage = recipes.map(this::convertToSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Offset-based pagination with complex sorting (mostForked, trending).
     * Uses native queries with subqueries for counting variants/activity.
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithOffsetSorted(
            String locale, String typeFilter, String sort, int page, int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<Recipe> recipes;

        if ("mostForked".equalsIgnoreCase(sort)) {
            // Order by variant count (most evolved)
            recipes = recipeRepository.findRecipesOrderByVariantCount(pageable);
        } else if ("trending".equalsIgnoreCase(sort)) {
            // Order by recent activity (variants + logs in last 7 days)
            recipes = recipeRepository.findRecipesOrderByTrending(pageable);
        } else {
            // Fallback to recent
            Sort sortBy = Sort.by(Sort.Direction.DESC, "createdAt");
            pageable = PageRequest.of(page, size, sortBy);
            recipes = recipeRepository.findPublicRecipesPage(pageable);
        }

        Page<RecipeSummaryDto> mappedPage = recipes.map(this::convertToSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based pagination wrapped in UnifiedPageResponse for mobile clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> findRecipesWithCursorUnified(
            String locale, String typeFilter, String cursor, int size) {

        CursorPageResponse<RecipeSummaryDto> cursorResponse =
                findRecipesWithCursor(locale, false, typeFilter, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }

    /**
     * Unified my recipes with strategy-based pagination.
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> getMyRecipesUnified(
            Long userId, String typeFilter, String cursor, Integer page, int size) {

        if (cursor != null && !cursor.isEmpty()) {
            return getMyRecipesWithCursorUnified(userId, typeFilter, cursor, size);
        } else if (page != null) {
            return getMyRecipesWithOffset(userId, typeFilter, page, size);
        } else {
            return getMyRecipesWithCursorUnified(userId, typeFilter, null, size);
        }
    }

    /**
     * Offset-based my recipes for web clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getMyRecipesWithOffset(
            Long userId, String typeFilter, int page, int size) {

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

        Page<RecipeSummaryDto> mappedPage = recipes.map(this::convertToSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based my recipes wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<RecipeSummaryDto> getMyRecipesWithCursorUnified(
            Long userId, String typeFilter, String cursor, int size) {

        CursorPageResponse<RecipeSummaryDto> cursorResponse =
                getMyRecipesWithCursor(userId, typeFilter, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }

    /**
     * Unified search with strategy-based pagination.
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<RecipeSummaryDto> searchRecipesUnified(
            String keyword, String cursor, Integer page, int size) {

        if (keyword == null || keyword.trim().length() < 2) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        if (cursor != null && !cursor.isEmpty()) {
            return searchRecipesWithCursorUnified(keyword, cursor, size);
        } else if (page != null) {
            return searchRecipesWithOffset(keyword, page, size);
        } else {
            return searchRecipesWithCursorUnified(keyword, null, size);
        }
    }

    /**
     * Offset-based search for web clients.
     */
    private UnifiedPageResponse<RecipeSummaryDto> searchRecipesWithOffset(
            String keyword, int page, int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<Recipe> recipes = recipeRepository.searchRecipesPage(keyword.trim(), pageable);

        Page<RecipeSummaryDto> mappedPage = recipes.map(this::convertToSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based search wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<RecipeSummaryDto> searchRecipesWithCursorUnified(
            String keyword, String cursor, int size) {

        CursorPageResponse<RecipeSummaryDto> cursorResponse =
                searchRecipesWithCursor(keyword, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}