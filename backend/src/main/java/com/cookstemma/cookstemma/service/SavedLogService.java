package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.log_post.SavedLog;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.common.CursorPageResponse;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.log_post.SavedLogRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
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
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SavedLogService {

    private final SavedLogRepository savedLogRepository;
    private final LogPostRepository logPostRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    @Transactional
    public void saveLog(UUID logPublicId, Long userId) {
        LogPost logPost = logPostRepository.findByPublicId(logPublicId)
                .orElseThrow(() -> new IllegalArgumentException("Log post not found"));

        if (!savedLogRepository.existsByUserIdAndLogPostId(userId, logPost.getId())) {
            savedLogRepository.save(SavedLog.builder()
                    .userId(userId)
                    .logPostId(logPost.getId())
                    .build());
            logPost.incrementSavedCount();
        }
    }

    @Transactional
    public void unsaveLog(UUID logPublicId, Long userId) {
        LogPost logPost = logPostRepository.findByPublicId(logPublicId)
                .orElseThrow(() -> new IllegalArgumentException("Log post not found"));

        if (savedLogRepository.existsByUserIdAndLogPostId(userId, logPost.getId())) {
            savedLogRepository.deleteByUserIdAndLogPostId(userId, logPost.getId());
            logPost.decrementSavedCount();
        }
    }

    public boolean isSavedByUser(Long logPostId, Long userId) {
        if (userId == null) return false;
        return savedLogRepository.existsByUserIdAndLogPostId(userId, logPostId);
    }

    public boolean isSavedByUserPublicId(UUID logPublicId, Long userId) {
        if (userId == null) return false;
        return logPostRepository.findByPublicId(logPublicId)
                .map(logPost -> savedLogRepository.existsByUserIdAndLogPostId(userId, logPost.getId()))
                .orElse(false);
    }

    public Slice<LogPostSummaryDto> getSavedLogs(Long userId, Pageable pageable) {
        return savedLogRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(sl -> convertToSummary(sl.getLogPost()));
    }

    /**
     * Get saved logs with cursor-based pagination
     */
    public CursorPageResponse<LogPostSummaryDto> getSavedLogsWithCursor(Long userId, String cursor, int size, String locale) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<SavedLog> savedLogs;
        if (cursorData == null) {
            savedLogs = savedLogRepository.findSavedLogsWithCursorInitial(userId, pageable);
        } else {
            savedLogs = savedLogRepository.findSavedLogsWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<LogPostSummaryDto> content = savedLogs.getContent().stream()
                .map(sl -> convertToSummary(sl.getLogPost(), locale))
                .toList();

        String nextCursor = null;
        if (savedLogs.hasNext() && !savedLogs.getContent().isEmpty()) {
            SavedLog lastItem = savedLogs.getContent().get(savedLogs.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getLogPostId());
        }

        return CursorPageResponse.of(content, nextCursor, size);
    }

    private LogPostSummaryDto convertToSummary(LogPost log) {
        return convertToSummary(log, LocaleUtils.DEFAULT_LOCALE);
    }

    private LogPostSummaryDto convertToSummary(LogPost log, String locale) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // Normalize locale for consistent usage
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);

        // Get localized title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
                log.getTitleTranslations(), normalizedLocale, log.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
                log.getContentTranslations(), normalizedLocale, log.getContent());

        // Get food name, recipe title, and variant status from linked recipe
        String foodName = null;
        String recipeTitle = null;
        Boolean isVariant = null;
        if (log.getRecipeLog() != null && log.getRecipeLog().getRecipe() != null) {
            Recipe recipe = log.getRecipeLog().getRecipe();
            // Use locale-aware food name
            foodName = LocaleUtils.getLocalizedValue(
                    recipe.getFoodMaster().getName(),
                    normalizedLocale,
                    recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
            // Use locale-aware recipe title
            recipeTitle = LocaleUtils.getLocalizedValue(
                    recipe.getTitleTranslations(), normalizedLocale, recipe.getTitle());
            isVariant = recipe.getRootRecipe() != null;
        }

        // Get hashtag names
        List<String> hashtags = log.getHashtags().stream()
                .map(Hashtag::getName)
                .toList();

        return new LogPostSummaryDto(
                log.getPublicId(),
                localizedTitle,
                localizedContent,
                log.getRecipeLog() != null ? log.getRecipeLog().getRating() : null,
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                recipeTitle,
                hashtags,
                isVariant,
                log.getIsPrivate() != null ? log.getIsPrivate() : false
        );
    }

    // ================================================================
    // Unified Dual Pagination Methods (Strategy Pattern)
    // ================================================================

    /**
     * Unified saved logs with strategy-based pagination.
     * - If cursor is provided → cursor-based pagination (mobile)
     * - If page is provided → offset-based pagination (web)
     * - Default → cursor-based initial page
     * @param locale Content locale from Accept-Language header for translation
     */
    public UnifiedPageResponse<LogPostSummaryDto> getSavedLogsUnified(Long userId, String cursor, Integer page, int size, String locale) {
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);

        if (cursor != null && !cursor.isEmpty()) {
            return getSavedLogsWithCursorUnified(userId, cursor, size, normalizedLocale);
        } else if (page != null) {
            return getSavedLogsWithOffset(userId, page, size, normalizedLocale);
        } else {
            return getSavedLogsWithCursorUnified(userId, null, size, normalizedLocale);
        }
    }

    /**
     * Offset-based saved logs for web clients.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getSavedLogsWithOffset(Long userId, int page, int size, String locale) {
        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<SavedLog> savedLogs = savedLogRepository.findSavedLogsPage(userId, pageable);
        Page<LogPostSummaryDto> mappedPage = savedLogs.map(sl -> convertToSummary(sl.getLogPost(), locale));

        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based saved logs wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getSavedLogsWithCursorUnified(Long userId, String cursor, int size, String locale) {
        CursorPageResponse<LogPostSummaryDto> cursorResponse = getSavedLogsWithCursor(userId, cursor, size, locale);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}
