package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.domain.entity.log_post.LogPost;
import com.pairingplanet.pairing_planet.domain.entity.log_post.SavedLog;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.log_post.SavedLogRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    private LogPostSummaryDto convertToSummary(LogPost log) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String creatorName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        return new LogPostSummaryDto(
                log.getPublicId(),
                log.getTitle(),
                log.getRecipeLog() != null ? log.getRecipeLog().getOutcome() : null,
                thumbnailUrl,
                creatorPublicId,
                creatorName
        );
    }
}
