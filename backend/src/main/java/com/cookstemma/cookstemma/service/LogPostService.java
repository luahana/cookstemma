package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.common.CursorPageResponse;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.hashtag.HashtagDto;
import com.cookstemma.cookstemma.dto.image.ImageResponseDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostDetailResponseDto;
import com.cookstemma.cookstemma.dto.log_post.CreateLogRequestDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.log_post.UpdateLogRequestDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.log_post.SavedLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.util.CursorUtil;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.domain.Sort;
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
    private final SavedLogRepository savedLogRepository;
    private final TranslationEventService translationEventService;

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
                .locale(recipe.getCookingStyle())
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

        // 해시태그 처리
        if (req.hashtags() != null && !req.hashtags().isEmpty()) {
            Set<Hashtag> hashtags = hashtagService.getOrCreateHashtags(req.hashtags());
            logPost.setHashtags(hashtags);
        }

        // Notify recipe owner that someone cooked their recipe
        User sender = userRepository.findById(creatorId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        notificationService.notifyRecipeCooked(recipe, logPost, sender);

        // Queue async translation for all languages
        translationEventService.queueLogPostTranslation(logPost);

        return getLogDetail(logPost.getPublicId());
    }

    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> getAllLogs(Pageable pageable) {
        return logPostRepository.findAllOrderByCreatedAtDesc(pageable)
                .map(this::convertToLogSummary);
    }

    /**
     * 로그 목록 조회 (rating 범위 필터링)
     * @param minRating Minimum rating (1-5)
     * @param maxRating Maximum rating (1-5)
     */
    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> getAllLogsByRating(Integer minRating, Integer maxRating, Pageable pageable) {
        return logPostRepository.findByRatingBetween(minRating, maxRating, pageable)
                .map(this::convertToLogSummary);
    }

    /**
     * 내가 작성한 로그 목록 조회
     * @param minRating null=all, or minimum rating (1-5)
     * @param maxRating null=all, or maximum rating (1-5)
     */
    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> getMyLogs(Long userId, Integer minRating, Integer maxRating, Pageable pageable) {
        Slice<LogPost> logs;

        if (minRating != null && maxRating != null) {
            logs = logPostRepository.findByCreatorIdAndRatingBetween(userId, minRating, maxRating, pageable);
        } else {
            logs = logPostRepository.findByCreatorIdAndDeletedAtIsNullOrderByCreatedAtDesc(userId, pageable);
        }

        return logs.map(this::convertToLogSummary);
    }

    /**
     * 특정 레시피에 달린 로그 목록 조회 (페이지네이션)
     * @param recipePublicId Recipe public ID
     * @param pageable Pagination info
     */
    @Transactional(readOnly = true)
    public Slice<LogPostSummaryDto> getLogsByRecipe(UUID recipePublicId, Pageable pageable) {
        Recipe recipe = recipeRepository.findByPublicId(recipePublicId)
                .orElseThrow(() -> new IllegalArgumentException("Recipe not found"));

        return recipeLogRepository.findByRecipeIdOrderByCreatedAtDesc(recipe.getId(), pageable)
                .map(rl -> convertToLogSummary(rl.getLogPost()));
    }

    @Transactional(readOnly = true)
    public LogPostDetailResponseDto getLogDetail(UUID publicId) {
        return getLogDetail(publicId, null, LocaleUtils.DEFAULT_LOCALE);
    }

    @Transactional
    public LogPostDetailResponseDto getLogDetail(UUID publicId, Long userId) {
        return getLogDetail(publicId, userId, LocaleUtils.DEFAULT_LOCALE);
    }

    @Transactional
    public LogPostDetailResponseDto getLogDetail(UUID publicId, Long userId, String locale) {
        LogPost logPost = logPostRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Log not found"));

        // Increment view count for analytics
        logPost.incrementViewCount();
        logPostRepository.save(logPost);

        // Normalize locale
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);

        RecipeLog recipeLog = logPost.getRecipeLog();
        Recipe linkedRecipe = recipeLog.getRecipe();

        // 1. 이미지 리스트 변환
        List<ImageResponseDto> imageResponses = logPost.getImages().stream()
                .map(img -> new ImageResponseDto(
                        img.getPublicId(),
                        urlPrefix + "/" + img.getStoredFilename()
                ))
                .toList();

        // 2. 연결된 레시피 요약 정보 생성 (locale-aware)
        RecipeSummaryDto linkedRecipeSummary = convertToRecipeSummary(linkedRecipe, normalizedLocale);

        // 3. 해시태그 리스트 변환
        List<HashtagDto> hashtagDtos = logPost.getHashtags().stream()
                .map(HashtagDto::from)
                .toList();

        // 4. 저장 상태 확인 (로그인한 경우만)
        Boolean isSavedByCurrentUser = null;
        if (userId != null) {
            isSavedByCurrentUser = savedLogRepository.existsByUserIdAndLogPostId(userId, logPost.getId());
        }

        // 5. 소유자 정보 조회 (edit/delete 권한 확인 및 프로필 링크용)
        User creator = userRepository.findById(logPost.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // 6. Get localized title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
                logPost.getTitleTranslations(), normalizedLocale, logPost.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
                logPost.getContentTranslations(), normalizedLocale, logPost.getContent());

        // 7. 최종 DTO 생성
        return new LogPostDetailResponseDto(
                logPost.getPublicId(),
                localizedTitle,
                localizedContent,
                recipeLog.getRating(),
                imageResponses,
                linkedRecipeSummary,
                logPost.getCreatedAt(),
                hashtagDtos,
                isSavedByCurrentUser,
                creatorPublicId,
                userName
        );
    }

    private LogPostSummaryDto convertToLogSummary(LogPost log) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
                .findFirst() // 로그의 첫 번째 이미지를 썸네일로 사용
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // Get food name, recipe title, and variant status from linked recipe
        RecipeLog recipeLog = log.getRecipeLog();
        String foodName = null;
        String recipeTitle = null;
        Boolean isVariant = null;
        if (recipeLog != null && recipeLog.getRecipe() != null) {
            Recipe recipe = recipeLog.getRecipe();
            foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCookingStyle());
            recipeTitle = recipe.getTitle();
            isVariant = recipe.getRootRecipe() != null;
        }

        // Get hashtag names
        List<String> hashtags = log.getHashtags().stream()
                .map(Hashtag::getName)
                .toList();

        return new LogPostSummaryDto(
                log.getPublicId(),
                log.getTitle(),
                log.getContent(),
                log.getRecipeLog().getRating(),
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                recipeTitle,
                hashtags,
                isVariant
        );
    }

    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe, String locale) {
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
                hashtags
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

    // ==================== CURSOR-BASED PAGINATION ====================

    /**
     * 모든 로그 조회 (Cursor-based pagination)
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<LogPostSummaryDto> getAllLogsWithCursor(String cursor, int size) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<LogPost> logs;
        if (cursorData == null) {
            logs = logPostRepository.findAllLogsWithCursorInitial(pageable);
        } else {
            logs = logPostRepository.findAllLogsWithCursor(cursorData.createdAt(), cursorData.id(), pageable);
        }

        return buildCursorResponse(logs, size);
    }

    /**
     * 로그 목록 조회 with rating filter (Cursor-based pagination)
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<LogPostSummaryDto> getAllLogsByRatingWithCursor(Integer minRating, Integer maxRating, String cursor, int size) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<LogPost> logs;
        if (cursorData == null) {
            logs = logPostRepository.findByRatingWithCursorInitial(minRating, maxRating, pageable);
        } else {
            logs = logPostRepository.findByRatingWithCursor(minRating, maxRating, cursorData.createdAt(), cursorData.id(), pageable);
        }

        return buildCursorResponse(logs, size);
    }

    /**
     * 내 로그 조회 (Cursor-based pagination)
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<LogPostSummaryDto> getMyLogsWithCursor(Long userId, Integer minRating, Integer maxRating, String cursor, int size) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<LogPost> logs;
        if (minRating != null && maxRating != null) {
            if (cursorData == null) {
                logs = logPostRepository.findMyLogsByRatingWithCursorInitial(userId, minRating, maxRating, pageable);
            } else {
                logs = logPostRepository.findMyLogsByRatingWithCursor(userId, minRating, maxRating, cursorData.createdAt(), cursorData.id(), pageable);
            }
        } else {
            if (cursorData == null) {
                logs = logPostRepository.findMyLogsWithCursorInitial(userId, pageable);
            } else {
                logs = logPostRepository.findMyLogsWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
            }
        }

        return buildCursorResponse(logs, size);
    }

    /**
     * 로그 검색 (Cursor-based pagination)
     * Note: Search still uses page-based internally for complex ordering, but returns cursor response
     */
    @Transactional(readOnly = true)
    public CursorPageResponse<LogPostSummaryDto> searchLogPostsWithCursor(String keyword, String cursor, int size) {
        if (keyword == null || keyword.trim().length() < 2) {
            return CursorPageResponse.empty(size);
        }
        // Search uses page-based due to complex ordering, cursor decodes to page number for simplicity
        Pageable pageable = PageRequest.of(0, size);
        Slice<LogPost> logs = logPostRepository.searchLogPosts(keyword.trim(), pageable);
        return buildCursorResponse(logs, size);
    }

    private CursorPageResponse<LogPostSummaryDto> buildCursorResponse(Slice<LogPost> logs, int size) {
        List<LogPostSummaryDto> content = logs.getContent().stream()
                .map(this::convertToLogSummary)
                .toList();

        String nextCursor = null;
        if (logs.hasNext() && !logs.getContent().isEmpty()) {
            LogPost lastItem = logs.getContent().get(logs.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getId());
        }

        return CursorPageResponse.of(content, nextCursor, size);
    }

    /**
     * 로그 수정
     */
    public LogPostDetailResponseDto updateLog(UUID publicId, UpdateLogRequestDto request, Long userId) {
        LogPost logPost = logPostRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Log not found"));

        // Verify ownership
        if (!logPost.getCreatorId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("You are not the owner of this log");
        }

        // Update fields
        if (request.title() != null) {
            logPost.setTitle(request.title());
        }
        logPost.setContent(request.content());

        // Update rating via RecipeLog
        RecipeLog recipeLog = logPost.getRecipeLog();
        recipeLog.setRating(request.rating());

        // Update hashtags
        if (request.hashtags() != null) {
            Set<Hashtag> hashtags = hashtagService.getOrCreateHashtags(request.hashtags());
            logPost.setHashtags(hashtags);
        } else {
            logPost.getHashtags().clear();
        }

        // Update images if provided
        if (request.imagePublicIds() != null) {
            imageService.updateLogPostImages(logPost, request.imagePublicIds());
        }

        logPostRepository.save(logPost);

        return getLogDetail(publicId, userId);
    }

    /**
     * 로그 삭제 (소프트 삭제)
     */
    public void deleteLog(UUID publicId, Long userId) {
        LogPost logPost = logPostRepository.findByPublicId(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Log not found"));

        // Verify ownership
        if (!logPost.getCreatorId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("You are not the owner of this log");
        }

        // Soft delete
        logPost.softDelete();
        logPostRepository.save(logPost);
    }

    // ================================================================
    // Unified Dual Pagination Methods (Strategy Pattern)
    // ================================================================

    /**
     * Unified log list with strategy-based pagination.
     * - If cursor is provided → cursor-based pagination (mobile)
     * - If page is provided → offset-based pagination (web)
     * - Default → cursor-based initial page
     *
     * Sort options:
     * - recent (default): order by createdAt DESC
     * - popular: order by popularity score (viewCount + savedCount * 5)
     * - trending: order by engagement with time decay
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<LogPostSummaryDto> getAllLogsUnified(
            Integer minRating, Integer maxRating, String sort, String cursor, Integer page, int size) {

        // For popular and trending sorts, use offset-based pagination (complex sorting)
        boolean isComplexSort = "popular".equalsIgnoreCase(sort) || "trending".equalsIgnoreCase(sort);

        if (isComplexSort) {
            int pageNum = (page != null) ? page : 0;
            return getAllLogsWithOffsetSorted(minRating, maxRating, sort, pageNum, size);
        }

        if (cursor != null && !cursor.isEmpty()) {
            return getAllLogsWithCursorUnified(minRating, maxRating, cursor, size);
        } else if (page != null) {
            return getAllLogsWithOffset(minRating, maxRating, page, size);
        } else {
            return getAllLogsWithCursorUnified(minRating, maxRating, null, size);
        }
    }

    /**
     * Offset-based log list for web clients.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getAllLogsWithOffset(
            Integer minRating, Integer maxRating, int page, int size) {

        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<LogPost> logs;
        if (minRating != null && maxRating != null) {
            logs = logPostRepository.findByRatingPage(minRating, maxRating, pageable);
        } else {
            logs = logPostRepository.findAllLogsPage(pageable);
        }

        Page<LogPostSummaryDto> mappedPage = logs.map(this::convertToLogSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Offset-based log list with complex sorting (popular, trending).
     * Note: rating filters are not combined with complex sorting for simplicity.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getAllLogsWithOffsetSorted(
            Integer minRating, Integer maxRating, String sort, int page, int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<LogPost> logs;

        if ("popular".equalsIgnoreCase(sort)) {
            logs = logPostRepository.findAllLogsOrderByPopular(pageable);
        } else if ("trending".equalsIgnoreCase(sort)) {
            logs = logPostRepository.findAllLogsOrderByTrending(pageable);
        } else {
            // Fallback to recent
            Sort sortBy = Sort.by(Sort.Direction.DESC, "createdAt");
            pageable = PageRequest.of(page, size, sortBy);
            logs = logPostRepository.findAllLogsPage(pageable);
        }

        Page<LogPostSummaryDto> mappedPage = logs.map(this::convertToLogSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based log list wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getAllLogsWithCursorUnified(
            Integer minRating, Integer maxRating, String cursor, int size) {

        CursorPageResponse<LogPostSummaryDto> cursorResponse;
        if (minRating != null && maxRating != null) {
            cursorResponse = getAllLogsByRatingWithCursor(minRating, maxRating, cursor, size);
        } else {
            cursorResponse = getAllLogsWithCursor(cursor, size);
        }

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }

    /**
     * Unified my logs with strategy-based pagination.
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<LogPostSummaryDto> getMyLogsUnified(
            Long userId, Integer minRating, Integer maxRating, String cursor, Integer page, int size) {

        if (cursor != null && !cursor.isEmpty()) {
            return getMyLogsWithCursorUnified(userId, minRating, maxRating, cursor, size);
        } else if (page != null) {
            return getMyLogsWithOffset(userId, minRating, maxRating, page, size);
        } else {
            return getMyLogsWithCursorUnified(userId, minRating, maxRating, null, size);
        }
    }

    /**
     * Offset-based my logs for web clients.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getMyLogsWithOffset(
            Long userId, Integer minRating, Integer maxRating, int page, int size) {

        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<LogPost> logs;
        if (minRating != null && maxRating != null) {
            logs = logPostRepository.findMyLogsByRatingPage(userId, minRating, maxRating, pageable);
        } else {
            logs = logPostRepository.findMyLogsPage(userId, pageable);
        }

        Page<LogPostSummaryDto> mappedPage = logs.map(this::convertToLogSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based my logs wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getMyLogsWithCursorUnified(
            Long userId, Integer minRating, Integer maxRating, String cursor, int size) {

        CursorPageResponse<LogPostSummaryDto> cursorResponse =
                getMyLogsWithCursor(userId, minRating, maxRating, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }

    /**
     * Unified search logs with strategy-based pagination.
     */
    @Transactional(readOnly = true)
    public UnifiedPageResponse<LogPostSummaryDto> searchLogPostsUnified(
            String keyword, String cursor, Integer page, int size) {

        if (keyword == null || keyword.trim().length() < 2) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        if (cursor != null && !cursor.isEmpty()) {
            return searchLogPostsWithCursorUnified(keyword, cursor, size);
        } else if (page != null) {
            return searchLogPostsWithOffset(keyword, page, size);
        } else {
            return searchLogPostsWithCursorUnified(keyword, null, size);
        }
    }

    /**
     * Offset-based search logs for web clients.
     */
    private UnifiedPageResponse<LogPostSummaryDto> searchLogPostsWithOffset(
            String keyword, int page, int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<LogPost> logs = logPostRepository.searchLogPostsPage(keyword.trim(), pageable);

        Page<LogPostSummaryDto> mappedPage = logs.map(this::convertToLogSummary);
        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based search logs wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<LogPostSummaryDto> searchLogPostsWithCursorUnified(
            String keyword, String cursor, int size) {

        CursorPageResponse<LogPostSummaryDto> cursorResponse =
                searchLogPostsWithCursor(keyword, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}