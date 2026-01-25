package com.cookstemma.cookstemma.repository.history;

import com.cookstemma.cookstemma.domain.entity.history.SearchHistory;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SearchHistoryRepository extends JpaRepository<SearchHistory, Long> {

    /**
     * Find recent search queries for a user.
     * For potential future use (analytics, recent searches from backend).
     */
    @Query("SELECT sh.query FROM SearchHistory sh WHERE sh.userId = :userId ORDER BY sh.searchedAt DESC")
    List<String> findRecentQueriesByUserId(@Param("userId") Long userId, Pageable pageable);
}
