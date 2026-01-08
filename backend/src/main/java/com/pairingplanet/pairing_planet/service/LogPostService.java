package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.recipe.RecipeLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.hashtag.HashtagDto;
import com.pairingplanet.pairing_planet.dto.image.ImageResponseDto;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostDetailResponseDto;
import com.pairingplanet.pairing_planet.dto.log_post.CreateLogRequestDto;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeLogRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class LogPostService {
    private final LogPostRepository logPostRepository;
    private final RecipeRepository recipeRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final ImageService imageService;
    private final UserRepository userRepository;
    private final HashtagService hashtagService;
    private final NotificationService notificationService;

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
                .outcome(req.outcome())
                .build();

        logPost.setRecipeLog(recipeLog);
        logPostRepository.save(logPost);

        // 이미지 활성화 (LOG 타입)
        imageService.activateImages(req.imagePublicIds(), logPost);

        // 해시태그 처리
        if (req.hashtags() != null && !req.hashtags().isEmpty()) {
            Set<Hashtag> hashtags = hashtagService.getOrCreateHashtags(req.hashtags());
            logPost.setHashtags(hashtags);
        }

        // Notify recipe owner that someone cooked their recipe
        User sender = userRepository.findById(creatorId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        notificationService.notifyRecipeCooked(recipe, logPost, sender);

        return getLogDetail(logPost.getPublicId());
    }

    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> getAllLogs(Pageable pageable) {
        return logPostRepository.findAllOrderByCreatedAtDesc(pageable)
                .map(this::convertToLogSummary);
    }

    /**
     * 내가 작성한 로그 목록 조회
     */
    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> getMyLogs(Long userId, Pageable pageable) {
        return logPostRepository.findByCreatorIdAndIsDeletedFalseOrderByCreatedAtDesc(userId, pageable)
                .map(this::convertToLogSummary);
    }

    @Transactional(readOnly = true)
    public LogPostDetailResponseDto getLogDetail(UUID publicId) {
        LogPost logPost = logPostRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Log not found"));

        RecipeLog recipeLog = logPost.getRecipeLog();
        Recipe linkedRecipe = recipeLog.getRecipe();

        // 1. 이미지 리스트 변환
        List<ImageResponseDto> imageResponses = logPost.getImages().stream()
                .map(img -> new ImageResponseDto(
                        img.getPublicId(),
                        urlPrefix + "/" + img.getStoredFilename()
                ))
                .toList();

        // 2. 연결된 레시피 요약 정보 생성 (11개 필드 대응)
        RecipeSummaryDto linkedRecipeSummary = convertToRecipeSummary(linkedRecipe);

        // 3. 해시태그 리스트 변환
        List<HashtagDto> hashtagDtos = logPost.getHashtags().stream()
                .map(HashtagDto::from)
                .toList();

        // 4. 최종 DTO 생성 시 createdAt 추가
        return new LogPostDetailResponseDto(
                logPost.getPublicId(),
                logPost.getTitle(),
                logPost.getContent(),
                recipeLog.getOutcome(),
                imageResponses,
                linkedRecipeSummary,
                logPost.getCreatedAt(),
                hashtagDtos
        );
    }

    private LogPostSummaryDto convertToLogSummary(LogPost log) {
        String creatorName = userRepository.findById(log.getCreatorId())
                .map(User::getUsername)
                .orElse("Unknown");

        String thumbnailUrl = log.getImages().stream()
                .findFirst() // 로그의 첫 번째 이미지를 썸네일로 사용
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        return new LogPostSummaryDto(
                log.getPublicId(),
                log.getTitle(),
                log.getRecipeLog().getOutcome(),
                thumbnailUrl,
                creatorName
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

        // 5. 로그 수 조회 (Activity count)
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // 6. 루트 레시피 제목 추출 (for lineage display in variants)
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;

        // 13개 인자 생성자 호출
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
                logCount,
                recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
                recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
                rootTitle
        );
    }

    /**
     * 로그 검색 (제목, 내용, 연결된 레시피 제목)
     */
    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> searchLogPosts(String keyword, Pageable pageable) {
        if (keyword == null || keyword.trim().length() < 2) {
            return new org.springframework.data.domain.SliceImpl<>(
                    java.util.Collections.emptyList(), pageable, false);
        }
        return logPostRepository.searchLogPosts(keyword.trim(), pageable)
                .map(this::convertToLogSummary);
    }
}