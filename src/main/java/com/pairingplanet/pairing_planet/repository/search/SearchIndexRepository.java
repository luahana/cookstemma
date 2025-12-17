package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.domain.entity.search.SearchIndex;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface SearchIndexRepository extends JpaRepository<SearchIndex, Long> {

    // [검색] 키워드 포함 + 로케일 필터링 (LIKE 검색)
    // GIN Index를 타게 하려면 Native Query로 'ILIKE' 또는 'pg_trgm' 연산자를 써야 할 수도 있음.
    // 일단은 표준 JPA 방식으로 작성.
    List<SearchIndex> findByLocaleCodeAndKeywordContaining(String localeCode, String keyword);
//    검색 속도가 느리다면 @Query(value = "SELECT * FROM search_index WHERE ...", nativeQuery = true)를 사용하여 PostgreSQL 전용 연산자(Trigram)를 직접 호출하세요.
}