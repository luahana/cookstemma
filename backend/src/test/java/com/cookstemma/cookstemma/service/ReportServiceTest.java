package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ReportReason;
import com.cookstemma.cookstemma.dto.report.CreateReportRequest;
import com.cookstemma.cookstemma.repository.user.UserReportRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ReportServiceTest extends BaseIntegrationTest {

    @Autowired
    private ReportService reportService;

    @Autowired
    private UserReportRepository userReportRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User reporter;
    private User reported;

    @BeforeEach
    void setUp() {
        reporter = testUserFactory.createTestUser("reporter_" + System.currentTimeMillis());
        reported = testUserFactory.createTestUser("reported_" + System.currentTimeMillis());
    }

    @Nested
    @DisplayName("Report User")
    class ReportUserTests {

        @Test
        @DisplayName("Should create report successfully")
        void reportUser_Success() {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, "Spamming comments");

            reportService.reportUser(reporter.getId(), reported.getPublicId(), request);

            assertThat(userReportRepository.existsByReporterIdAndReportedId(reporter.getId(), reported.getId()))
                    .isTrue();
        }

        @Test
        @DisplayName("Should create report without description")
        void reportUser_NoDescription_Success() {
            CreateReportRequest request = new CreateReportRequest(ReportReason.HARASSMENT, null);

            reportService.reportUser(reporter.getId(), reported.getPublicId(), request);

            assertThat(userReportRepository.existsByReporterIdAndReportedId(reporter.getId(), reported.getId()))
                    .isTrue();
        }

        @Test
        @DisplayName("Should throw when reporting yourself")
        void reportUser_Self_ThrowsException() {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, null);

            assertThatThrownBy(() -> reportService.reportUser(reporter.getId(), reporter.getPublicId(), request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Cannot report yourself");
        }

        @Test
        @DisplayName("Should throw when reporting same user twice")
        void reportUser_Duplicate_ThrowsException() {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, null);

            reportService.reportUser(reporter.getId(), reported.getPublicId(), request);

            assertThatThrownBy(() -> reportService.reportUser(reporter.getId(), reported.getPublicId(), request))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("already reported");
        }
    }

    @Nested
    @DisplayName("Report Count")
    class ReportCountTests {

        @Test
        @DisplayName("Should return correct report count")
        void getReportCount_HasReports_ReturnsCount() {
            User reporter2 = testUserFactory.createTestUser("reporter2_" + System.currentTimeMillis());

            reportService.reportUser(reporter.getId(), reported.getPublicId(),
                    new CreateReportRequest(ReportReason.SPAM, null));
            reportService.reportUser(reporter2.getId(), reported.getPublicId(),
                    new CreateReportRequest(ReportReason.HARASSMENT, null));

            long count = reportService.getReportCount(reported.getId());

            assertThat(count).isEqualTo(2);
        }

        @Test
        @DisplayName("Should return zero when no reports")
        void getReportCount_NoReports_ReturnsZero() {
            long count = reportService.getReportCount(reported.getId());

            assertThat(count).isEqualTo(0);
        }
    }
}
