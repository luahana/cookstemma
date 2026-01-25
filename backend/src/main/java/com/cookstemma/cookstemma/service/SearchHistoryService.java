package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.history.SearchHistory;
import com.cookstemma.cookstemma.repository.history.SearchHistoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class SearchHistoryService {

    private final SearchHistoryRepository searchHistoryRepository;

    /**
     * Record a search query for a user.
     * Stores all search queries with timestamps for analytics purposes.
     * Empty or null queries are silently ignored.
     */
    @Transactional
    public void recordSearch(Long userId, String query) {
        if (query == null || query.trim().isEmpty()) {
            return;
        }

        SearchHistory searchHistory = SearchHistory.builder()
                .userId(userId)
                .query(query.trim())
                .build();

        searchHistoryRepository.save(searchHistory);
        log.debug("Recorded search query for user {}: {}", userId, query);
    }
}
