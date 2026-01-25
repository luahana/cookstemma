package com.cookstemma.cookstemma.repository.user;

import com.cookstemma.cookstemma.domain.entity.user.UserReport;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserReportRepository extends JpaRepository<UserReport, Long> {

    /**
     * Check if user has already reported another user
     */
    boolean existsByReporterIdAndReportedId(Long reporterId, Long reportedId);

    /**
     * Count reports against a user (for admin review)
     */
    long countByReportedId(Long reportedId);
}
