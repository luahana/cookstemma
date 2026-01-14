package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.hashtag.Hashtag;
import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.log_post.SavedLog;
import com.pairingplanet.pairing_planet.domain.entity.recipe.Recipe;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.common.CursorPageResponse;
import com.pairingplanet.pairing_planet.dto.common.UnifiedPageResponse;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.log_post.SavedLogRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.util.CursorUtil;
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

    public Slice<LogPostSummaryDto> getSavedLogs(Long userId, Pageable pageable) {
        return savedLogRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(sl -> convertToSummary(sl.getLogPost()));
    }

    /**
     * Get saved logs with cursor-based pagination
     */
    public CursorPageResponse<LogPostSummaryDto> getSavedLogsWithCursor(Long userId, String cursor, int size) {
        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<SavedLog> savedLogs;
        if (cursorData == null) {
            savedLogs = savedLogRepository.findSavedLogsWithCursorInitial(userId, pageable);
        } else {
            savedLogs = savedLogRepository.findSavedLogsWithCursor(userId, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<LogPostSummaryDto> content = savedLogs.getContent().stream()
                .map(sl -> convertToSummary(sl.getLogPost()))
                .toList();

        String nextCursor = null;
        if (savedLogs.hasNext() && !savedLogs.getContent().isEmpty()) {
            SavedLog lastItem = savedLogs.getContent().get(savedLogs.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getLogPostId());
        }

        return CursorPageResponse.of(content, nextCursor, size);
    }

    private LogPostSummaryDto convertToSummary(LogPost log) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String creatorName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // Get food name and variant status from linked recipe
        String foodName = null;
        Boolean isVariant = null;
        if (log.getRecipeLog() != null && log.getRecipeLog().getRecipe() != null) {
            Recipe recipe = log.getRecipeLog().getRecipe();
            foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCulinaryLocale());
            isVariant = recipe.getRootRecipe() != null;
        }

        // Get hashtag names
        List<String> hashtags = log.getHashtags().stream()
                .map(Hashtag::getName)
                .toList();

        return new LogPostSummaryDto(
                log.getPublicId(),
                log.getTitle(),
                log.getRecipeLog() != null ? log.getRecipeLog().getOutcome() : null,
                thumbnailUrl,
                creatorPublicId,
                creatorName,
                foodName,
                hashtags,
                isVariant
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
     */
    public UnifiedPageResponse<LogPostSummaryDto> getSavedLogsUnified(Long userId, String cursor, Integer page, int size) {
        if (cursor != null && !cursor.isEmpty()) {
            return getSavedLogsWithCursorUnified(userId, cursor, size);
        } else if (page != null) {
            return getSavedLogsWithOffset(userId, page, size);
        } else {
            return getSavedLogsWithCursorUnified(userId, null, size);
        }
    }

    /**
     * Offset-based saved logs for web clients.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getSavedLogsWithOffset(Long userId, int page, int size) {
        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<SavedLog> savedLogs = savedLogRepository.findSavedLogsPage(userId, pageable);
        Page<LogPostSummaryDto> mappedPage = savedLogs.map(sl -> convertToSummary(sl.getLogPost()));

        return UnifiedPageResponse.fromPage(mappedPage, size);
    }

    /**
     * Cursor-based saved logs wrapped in UnifiedPageResponse.
     */
    private UnifiedPageResponse<LogPostSummaryDto> getSavedLogsWithCursorUnified(Long userId, String cursor, int size) {
        CursorPageResponse<LogPostSummaryDto> cursorResponse = getSavedLogsWithCursor(userId, cursor, size);

        return UnifiedPageResponse.fromCursor(
                cursorResponse.content(),
                cursorResponse.nextCursor(),
                size
        );
    }
}
