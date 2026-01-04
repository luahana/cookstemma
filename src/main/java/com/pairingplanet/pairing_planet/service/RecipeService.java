package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.image.Image;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeIngredient;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeStep;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.*;
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

        // 변형(Variant) 생성인 경우 계보 설정
        if (req.parentPublicId() != null) {
            parent = recipeRepository.findByPublicId(req.parentPublicId())
                    .orElseThrow(() -> new IllegalArgumentException("Parent recipe not found"));
            root = (parent.getRootRecipe() != null) ? parent.getRootRecipe() : parent;
        }

        Long foodId = req.food1MasterId();
        if (foodId == null && parent != null) {
            foodId = parent.getFood1MasterId();
        }

        if (foodId == null) {
            throw new IllegalArgumentException("음식 카테고리(food1MasterId)는 필수입니다.");
        }

        Recipe recipe = Recipe.builder()
                .title(req.title())
                .description(req.description())
                .culinaryLocale(req.culinaryLocale() != null ? req.culinaryLocale() : (parent != null ? parent.getCulinaryLocale() : "ko-KR"))
                .food1MasterId(req.food1MasterId())
                .creatorId(creatorId)
                .parentRecipe(parent)
                .rootRecipe(root)
                .changeCategory(req.changeCategory())
                .build();

        recipeRepository.save(recipe);

        // 하위 요소 저장 (재료, 단계)
        saveIngredientsAndSteps(recipe, req);

        // 이미지 활성화 (대표 이미지들)
        imageService.activateImages(req.imageUrls(), recipe);

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

        return RecipeDetailResponseDto.builder()
                .publicId(recipe.getPublicId())
                .title(recipe.getTitle())
                .description(recipe.getDescription())
                .culinaryLocale(recipe.getCulinaryLocale())
                .changeCategory(recipe.getChangeCategory())
                .rootInfo(convertToSummary(root))
                .ingredients(convertToIngredientDtos(recipe.getIngredients()))
                .steps(convertToStepDtos(recipe.getSteps()))
                .variants(variants)
                .logs(logs)
                .build();
    }

    // --- 내부 헬퍼 메서드 (에러 해결 핵심) ---

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
                if (stepDto.imageUrl() != null) {
                    String filename = stepDto.imageUrl().replace(urlPrefix + "/", "");
                    stepImage = imageRepository.findByStoredFilename(filename).orElse(null);
                }

                RecipeStep step = RecipeStep.builder()
                        .recipe(recipe)
                        .stepNumber(stepDto.stepNumber())
                        .description(stepDto.description())
                        .image(stepImage)
                        .build();
                stepRepository.save(step);

                // 단계 이미지 상태도 ACTIVE로 변경
                if (stepImage != null) {
                    stepImage.setStatus(com.pairingplanet.pairing_planet.domain.enums.ImageStatus.ACTIVE);
                }
            }
        }
    }

    private RecipeSummaryDto convertToSummary(Recipe recipe) {
        return new RecipeSummaryDto(
                recipe.getPublicId(),
                recipe.getTitle(),
                recipe.getCulinaryLocale(),
                null, // 작성자명은 필요시 조회
                null  // 썸네일 경로
        );
    }

    private List<IngredientDto> convertToIngredientDtos(List<RecipeIngredient> ingredients) {
        return ingredients.stream()
                .map(i -> new IngredientDto(i.getName(), i.getAmount(), i.getType()))
                .collect(Collectors.toList());
    }

    private List<StepDto> convertToStepDtos(List<RecipeStep> steps) {
        return steps.stream()
                .map(s -> new StepDto(
                        s.getStepNumber(),
                        s.getDescription(),
                        s.getImage() != null ? urlPrefix + "/" + s.getImage().getStoredFilename() : null
                ))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public HomeFeedResponseDto getHomeFeed() {
        // 1. 최근 레시피 조회
        List<RecipeSummaryDto> recent = recipeRepository.findTop5ByIsDeletedFalseOrderByCreatedAtDesc()
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

    /**
     * [해결] Cannot resolve method 'findRootRecipes'
     * Recipes 탭의 기본 뷰: 오리지널 레시피 카드 리스트
     */
    @Transactional(readOnly = true)
    public Slice<RecipeSummaryDto> findRootRecipes(String locale, Pageable pageable) {
        return recipeRepository.findRootRecipesByLocale(locale, pageable)
                .map(this::convertToSummary);
    }

    private Long findUserId(UUID publicId) {
        return userRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found")).getId();
    }
}