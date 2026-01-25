package com.cookstemma.cookstemma.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.search.SearchHistoryRequest;
import com.cookstemma.cookstemma.repository.history.SearchHistoryRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestJwtTokenProvider;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ViewHistoryControllerTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private TestJwtTokenProvider testJwtTokenProvider;

    @Autowired
    private SearchHistoryRepository searchHistoryRepository;

    private User user;
    private String userToken;

    @BeforeEach
    void setUp() {
        user = testUserFactory.createTestUser("historyuser_" + System.currentTimeMillis());
        userToken = testJwtTokenProvider.createAccessToken(user.getPublicId(), "USER");
    }

    @Nested
    @DisplayName("POST /api/v1/view-history/search - Record Search History")
    class RecordSearchHistory {

        @Test
        @DisplayName("Should record search query with valid token")
        void recordSearch_ValidRequest_Returns200() throws Exception {
            SearchHistoryRequest request = new SearchHistoryRequest("kimchi recipe");

            mockMvc.perform(post("/api/v1/view-history/search")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));
            assertThat(queries).containsExactly("kimchi recipe");
        }

        @Test
        @DisplayName("Should return 401 without token")
        void recordSearch_NoToken_Returns401() throws Exception {
            SearchHistoryRequest request = new SearchHistoryRequest("test query");

            mockMvc.perform(post("/api/v1/view-history/search")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("Should return 400 for blank query")
        void recordSearch_BlankQuery_Returns400() throws Exception {
            SearchHistoryRequest request = new SearchHistoryRequest("");

            mockMvc.perform(post("/api/v1/view-history/search")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 400 for null query")
        void recordSearch_NullQuery_Returns400() throws Exception {
            String jsonBody = "{\"query\": null}";

            mockMvc.perform(post("/api/v1/view-history/search")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(jsonBody))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should record long query up to 500 chars")
        void recordSearch_LongQuery_Returns200() throws Exception {
            String longQuery = "a".repeat(500);
            SearchHistoryRequest request = new SearchHistoryRequest(longQuery);

            mockMvc.perform(post("/api/v1/view-history/search")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk());

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));
            assertThat(queries).hasSize(1);
            assertThat(queries.get(0)).hasSize(500);
        }

        @Test
        @DisplayName("Should return 400 for query exceeding 500 chars")
        void recordSearch_TooLongQuery_Returns400() throws Exception {
            String tooLongQuery = "a".repeat(501);
            SearchHistoryRequest request = new SearchHistoryRequest(tooLongQuery);

            mockMvc.perform(post("/api/v1/view-history/search")
                            .header("Authorization", "Bearer " + userToken)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }
}
