package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.food.UserSuggestedFood;
import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeIngredient;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeStep;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.SuggestionStatus;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import com.pairingplanet.pairing_planet.repository.food.UserSuggestedFoodRepository;
import com.pairingplanet.pairing_planet.repository.image.ImageRepository;
import com.pairingplanet.pairing_planet.repository.recipe.*;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RecipeService {
    private final RecipeRepository recipeRepository;
    private final RecipeIngredientRepository ingredientRepository;
    private final RecipeStepRepository stepRepository;
    private final RecipeLogRepository recipeLogRepository; // [수정] 누락된 주입 추가
    private final ImageService imageService;
    private final ImageRepository imageRepository;
    private final UserRepository userRepository;

    private final FoodMasterRepository foodMasterRepository;
    private final UserSuggestedFoodRepository suggestedFoodRepository;

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

        Recipe recipe = Recipe.builder()
                .title(req.title())
                .description(req.description())
                .culinaryLocale(finalLocale)
                .foodMaster(foodMaster)
                .creatorId(creatorId)
                .parentRecipe(parent) // 바로 위 부모
                .rootRecipe(root)     // 최상위 뿌리
                .changeCategory(req.changeCategory())
                .build();

        recipeRepository.save(recipe);
        saveIngredientsAndSteps(recipe, req);
        imageService.activateImages(req.imagePublicIds(), recipe);

        return getRecipeDetail(recipe.getPublicId());
    }

    /**
     * 레시피 상세 조회 (기획 원칙 1 반영: 상단 루트 고정)
     */
    public RecipeDetailResponseDto getRecipeDetail(UUID publicId) {
        Recipe recipe = recipeRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        // [원칙 1] 어디서든 루트 레시피 정보 포함
        Recipe root = (recipe.getRootRecipe() != null) ? recipe.getRootRecipe() : recipe;

        // 변형 및 로그 리스트 조회
        List<RecipeSummaryDto> variants = recipeRepository.findByParentRecipeIdAndIsDeletedFalse(recipe.getId())
                .stream().map(this::convertToSummary).toList();

        List<LogPostSummaryDto> logs = recipeLogRepository.findAllByRecipeId(recipe.getId())
                .stream().map(rl -> new LogPostSummaryDto(
                        rl.getLogPost().getPublicId(),
                        rl.getLogPost().getTitle(),
                        rl.getRating(),
                        null, // 대표이미지 생략
                        null  // 작성자 생략
                )).toList();

        return RecipeDetailResponseDto.from(recipe, variants, logs, this.urlPrefix);
    }

    @Transactional(readOnly = true)
    public Slice<RecipeSummaryDto> findRecipes(String locale, boolean onlyRoot, Pageable pageable) {
        Slice<Recipe> recipes;

        if (locale == null || locale.isBlank()) {
            // 로케일이 없을 때 (전체 글로벌 조회)
            recipes = onlyRoot
                    ? recipeRepository.findAllRootRecipes(pageable)
                    : recipeRepository.findPublicRecipes(pageable);
        } else {
            // 특정 로케일 필터링 시
            recipes = onlyRoot
                    ? recipeRepository.findRootRecipesByLocale(locale, pageable)
                    : recipeRepository.findPublicRecipesByLocale(locale, pageable);
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
                            .type(dto.type())
                            .build())
                    .toList();
            ingredientRepository.saveAll(ingredients);
        }

        // 2. 단계 저장 및 단계 이미지 연결
        if (req.steps() != null) {
            for (StepDto stepDto : req.steps()) {
                Image stepImage = null;
                if (stepDto.imagePublicId() != null) {
                    stepImage = imageRepository.findByPublicId(stepDto.imagePublicId())
                            .orElseThrow(() -> new IllegalArgumentException("Step image not found"));

                    // [해결] Image 엔티티에 Recipe를 연결하여 DB 제약 조건(chk_image_target) 충돌 방지
                    stepImage.setRecipe(recipe);
                    stepImage.setStatus(com.pairingplanet.pairing_planet.domain.enums.ImageStatus.ACTIVE);
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
        // 1. 작성자 이름 조회
        String creatorName = userRepository.findById(recipe.getCreatorId())
                .map(User::getUsername)
                .orElse("Unknown");

        // 2. 음식 이름 추출 (JSONB 맵에서 현재 로케일에 맞는 이름 찾기)
        String foodName = getFoodName(recipe);

        // 3. 썸네일 URL 추출
        String thumbnail = recipe.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.THUMBNAIL)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 4. 변형 수 조회
        int variantCount = (int) recipeRepository.countByRootRecipeIdAndIsDeletedFalse(recipe.getId());

        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,
                recipe.getFoodMaster().getPublicId(),
                recipe.getTitle(),
                recipe.getDescription(),
                recipe.getCulinaryLocale(),
                creatorName,
                thumbnail,
                variantCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null
        );
    }

    @Transactional(readOnly = true)
    public HomeFeedResponseDto getHomeFeed() {
        // 1. 최근 레시피 조회
        List<RecipeSummaryDto> recent = recipeRepository.findTop5ByIsDeletedFalseAndIsPrivateFalseOrderByCreatedAtDesc()
                .stream().map(this::convertToSummary).toList();

        // 2. 활발한 변형 트리 조회 (기획서: "이 레시피, 이렇게 바뀌고 있어요")
        List<TrendingTreeDto> trending = recipeRepository.findTrendingOriginals(PageRequest.of(0, 3))
                .stream().map(root -> {
                    long variants = recipeRepository.countByRootRecipeIdAndIsDeletedFalse(root.getId());
                    long logs = recipeLogRepository.countByRecipeId(root.getId()); // 혹은 계보 전체 로그 합산

                    return TrendingTreeDto.builder()
                            .rootRecipeId(root.getPublicId())
                            .title(root.getTitle())
                            .culinaryLocale(root.getCulinaryLocale())
                            .variantCount(variants)
                            .logCount(logs)
                            .latestChangeSummary(root.getDescription()) // 예시 데이터
                            .build();
                }).toList();

        return new HomeFeedResponseDto(recent, trending);
    }

    private Long findUserId(UUID publicId) {
        return userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found")).getId();
    }

    public Slice<RecipeSummaryDto> findAllRootRecipes(Pageable pageable) {
        return recipeRepository.findAllRootRecipes(pageable)
                .map(this::convertToSummary);
    }

}