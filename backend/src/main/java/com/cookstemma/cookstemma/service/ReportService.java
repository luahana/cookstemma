package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.entity.user.UserReport;
import com.cookstemma.cookstemma.dto.report.CreateReportRequest;
import com.cookstemma.cookstemma.repository.user.UserReportRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    private final UserReportRepository userReportRepository;
    private final UserRepository userRepository;

    /**
     * Report a user for violation
     */
    @Transactional
    public void reportUser(Long reporterId, UUID targetUserPublicId, CreateReportRequest request) {
        User targetUser = userRepository.findByPublicId(targetUserPublicId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Long reportedId = targetUser.getId();

        // Cannot report yourself
        if (reporterId.equals(reportedId)) {
            throw new IllegalArgumentException("Cannot report yourself");
        }

        // Check if already reported (optional: allow multiple reports or not)
        if (userReportRepository.existsByReporterIdAndReportedId(reporterId, reportedId)) {
            log.debug("User {} has already reported user {}", reporterId, reportedId);
            throw new IllegalArgumentException("You have already reported this user");
        }

        UserReport report = UserReport.create(
                reporterId,
                reportedId,
                request.reason(),
                request.description()
        );

        userReportRepository.save(report);

        log.info("User {} reported user {} for reason: {}", reporterId, reportedId, request.reason());
    }

    /**
     * Get total reports against a user (for admin review)
     */
    public long getReportCount(Long userId) {
        return userReportRepository.countByReportedId(userId);
    }
}
