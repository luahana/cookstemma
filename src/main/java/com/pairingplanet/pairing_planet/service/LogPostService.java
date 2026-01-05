package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.image.ImageResponseDto;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostDetailResponseDto;
import com.pairingplanet.pairing_planet.dto.log_post.CreateLogRequestDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class LogPostService {
    private final LogPostRepository logPostRepository;
    private final RecipeRepository recipeRepository;
    private final ImageService imageService;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}") // [추가] URL 조합을 위해 필요
    private String urlPrefix;

    public LogPostDetailResponseDto createLog(CreateLogRequestDto req, UserPrincipal principal) {
        Long creatorId = principal.getId();

        // 2. 연결될 레시피를 찾습니다.
        Recipe recipe = recipeRepository.findByPublicId(req.recipePublicId())
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        LogPost logPost = LogPost.builder()
                .title(req.title())
                .content(req.content())
                .creatorId(creatorId) // 유저 ID 조회 생략
                .locale(recipe.getCulinaryLocale())
                .build();

        // 레시피-로그 연결 정보 생성
        RecipeLog recipeLog = RecipeLog.builder()
                .logPost(logPost)
                .recipe(recipe)
                .rating(req.rating())
                .build();

        logPost.setRecipeLog(recipeLog);
        logPostRepository.save(logPost);

        // 이미지 활성화 (LOG 타입)
        imageService.activateImages(req.imagePublicIds(), logPost);

        return getLogDetail(logPost.getPublicId());
    }

    @Transactional(readOnly = true)
    public LogPostDetailResponseDto getLogDetail(UUID publicId) {
        LogPost logPost = logPostRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Log not found"));

        RecipeLog recipeLog = logPost.getRecipeLog();
        Recipe linkedRecipe = recipeLog.getRecipe();

        // [수정] 로그 이미지 엔티티 리스트를 ImageResponseDto 리스트로 변환
        List<ImageResponseDto> imageResponses = logPost.getImages().stream()
                .map(img -> new ImageResponseDto(
                        img.getPublicId(),
                        urlPrefix + "/" + img.getStoredFilename()
                ))
                .toList();

        // [추가] 연결된 레시피의 요약 정보 생성 (9개 파라미터 대응)
        RecipeSummaryDto linkedRecipeSummary = convertToRecipeSummary(linkedRecipe);

        return new LogPostDetailResponseDto(
                logPost.getPublicId(),
                logPost.getTitle(),
                logPost.getContent(),
                recipeLog.getRating(),
                imageResponses,
                linkedRecipeSummary // [적용]
        );
    }

    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe) {
        // 1. 작성자 이름 조회
        String creatorName = userRepository.findById(recipe.getCreatorId())
                .map(User::getUsername)
                .orElse("Unknown");

        // 2. [추가] 음식 이름 추출 (JSONB 맵에서 현재 레시피 로케일 기준)
        String foodName = recipe.getFoodMaster().getName()
                .getOrDefault(recipe.getCulinaryLocale(), "Unknown Food");

        // 3. 썸네일 URL 추출 (첫 번째 THUMBNAIL 이미지)
        String thumbnail = recipe.getImages().stream()
                .filter(img -> img.getType() == com.pairingplanet.pairing_planet.domain.enums.ImageType.THUMBNAIL)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 4. 변형 수 조회
        int variantCount = (int) recipeRepository.countByRootRecipeIdAndIsDeletedFalse(recipe.getId());

        // 11개 인자 생성자 호출
        return new RecipeSummaryDto(
                recipe.getPublicId(),
                foodName,                             // [추가]
                recipe.getFoodMaster().getPublicId(), // [추가] foodMasterPublicId
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
}