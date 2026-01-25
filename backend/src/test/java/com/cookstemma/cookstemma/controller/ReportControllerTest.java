package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ReportReason;
import com.cookstemma.cookstemma.dto.report.CreateReportRequest;
import com.cookstemma.cookstemma.service.ReportService;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ReportControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private ReportService reportService;

    private User reporter;
    private User reported;
    private String reporterToken;

    @BeforeEach
    void setUp() {
        reporter = testUserFactory.createTestUser("reporter_" + System.currentTimeMillis());
        reported = testUserFactory.createTestUser("reported_" + System.currentTimeMillis());
        reporterToken = testJwtTokenProvider.createAccessToken(reporter.getPublicId(), "USER");
    }

    @Nested
    @DisplayName("POST /api/v1/users/{userId}/report - Report User")
    class ReportUser {

        @Test
        @DisplayName("Should report user with valid token and reason")
        void reportUser_ValidRequest_Returns200() throws Exception {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, null);

            mockMvc.perform(post("/api/v1/users/{userId}/report", reported.getPublicId())
                            .header("Authorization", "Bearer " + reporterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Should report user with reason and description")
        void reportUser_WithDescription_Returns200() throws Exception {
            CreateReportRequest request = new CreateReportRequest(
                    ReportReason.HARASSMENT,
                    "Sending offensive messages"
            );

            mockMvc.perform(post("/api/v1/users/{userId}/report", reported.getPublicId())
                            .header("Authorization", "Bearer " + reporterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());
        }

        @Test
        @DisplayName("Should return 401 without token")
        void reportUser_NoToken_Returns401() throws Exception {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, null);

            mockMvc.perform(post("/api/v1/users/{userId}/report", reported.getPublicId())
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

        // Note: Invalid enum values in JSON cause HttpMessageNotReadableException
        // which should be handled by GlobalExceptionHandler for better error messages

        @Test
        @DisplayName("Should return 400 for self-report")
        void reportUser_SelfReport_Returns400() throws Exception {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, null);

            mockMvc.perform(post("/api/v1/users/{userId}/report", reporter.getPublicId())
                            .header("Authorization", "Bearer " + reporterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 400 for duplicate report")
        void reportUser_Duplicate_Returns400() throws Exception {
            CreateReportRequest request = new CreateReportRequest(ReportReason.SPAM, null);

            // First report succeeds
            reportService.reportUser(reporter.getId(), reported.getPublicId(), request);

            // Second report should fail
            mockMvc.perform(post("/api/v1/users/{userId}/report", reported.getPublicId())
                            .header("Authorization", "Bearer " + reporterToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }
}
