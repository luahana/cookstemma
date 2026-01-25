package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.history.SearchHistory;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.repository.history.SearchHistoryRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class SearchHistoryServiceTest extends BaseIntegrationTest {

    @Autowired
    private SearchHistoryService searchHistoryService;

    @Autowired
    private SearchHistoryRepository searchHistoryRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User user;

    @BeforeEach
    void setUp() {
        user = testUserFactory.createTestUser("searchuser_" + System.currentTimeMillis());
    }

    @Nested
    @DisplayName("Record Search")
    class RecordSearchTests {

        @Test
        @DisplayName("Should record search query successfully")
        void recordSearch_Success() {
            searchHistoryService.recordSearch(user.getId(), "kimchi recipe");

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));

            assertThat(queries).hasSize(1);
            assertThat(queries.get(0)).isEqualTo("kimchi recipe");
        }

        @Test
        @DisplayName("Should record multiple search queries")
        void recordSearch_MultipleQueries() {
            searchHistoryService.recordSearch(user.getId(), "first query");
            searchHistoryService.recordSearch(user.getId(), "second query");
            searchHistoryService.recordSearch(user.getId(), "third query");

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));

            assertThat(queries).hasSize(3);
            // Most recent first
            assertThat(queries.get(0)).isEqualTo("third query");
            assertThat(queries.get(1)).isEqualTo("second query");
            assertThat(queries.get(2)).isEqualTo("first query");
        }

        @Test
        @DisplayName("Should trim query before saving")
        void recordSearch_TrimsQuery() {
            searchHistoryService.recordSearch(user.getId(), "  spaced query  ");

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));

            assertThat(queries).hasSize(1);
            assertThat(queries.get(0)).isEqualTo("spaced query");
        }

        @Test
        @DisplayName("Should not record empty query")
        void recordSearch_EmptyQuery_NotRecorded() {
            searchHistoryService.recordSearch(user.getId(), "");
            searchHistoryService.recordSearch(user.getId(), "   ");
            searchHistoryService.recordSearch(user.getId(), null);

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));

            assertThat(queries).isEmpty();
        }

        @Test
        @DisplayName("Should allow duplicate queries (for analytics)")
        void recordSearch_DuplicateQueries_AllRecorded() {
            searchHistoryService.recordSearch(user.getId(), "same query");
            searchHistoryService.recordSearch(user.getId(), "same query");
            searchHistoryService.recordSearch(user.getId(), "same query");

            List<String> queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));

            // All duplicates recorded (useful for analytics)
            assertThat(queries).hasSize(3);
        }

        @Test
        @DisplayName("Should keep search history separate per user")
        void recordSearch_SeparatePerUser() {
            User user2 = testUserFactory.createTestUser("searchuser2_" + System.currentTimeMillis());

            searchHistoryService.recordSearch(user.getId(), "user1 query");
            searchHistoryService.recordSearch(user2.getId(), "user2 query");

            List<String> user1Queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user.getId(), PageRequest.of(0, 10));
            List<String> user2Queries = searchHistoryRepository.findRecentQueriesByUserId(
                    user2.getId(), PageRequest.of(0, 10));

            assertThat(user1Queries).containsExactly("user1 query");
            assertThat(user2Queries).containsExactly("user2 query");
        }
    }
}
