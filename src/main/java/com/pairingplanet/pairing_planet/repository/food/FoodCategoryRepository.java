package com.pairingplanet.pairing_planet.repository.food;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface FoodCategoryRepository extends JpaRepository<FoodCategory, Long> {
    @Override
    List<FoodCategory> findAll();

    /**
     * FR-87: Category Autocomplete
     * 1. 카테고리 이름(JSON)에서 로케일에 맞는 값을 추출하여 검색
     * 2. 검색어와 정확/부분 일치(ILIKE)하거나
     * 3. 오타가 있어도 유사도(SIMILARITY)가 높으면 검색됨
     */
    @Query(value = """
        SELECT c.id as id,
               c.name ->> :locale as name,
               'CATEGORY' as type,
               
               -- [점수 계산]
               CASE 
                   -- 1. 이름이나 코드가 정확히 포함되면 1.0점
                   WHEN (c.name ->> :locale ILIKE %:keyword% OR c.code ILIKE %:keyword%) THEN 1.0
                   -- 2. 아니면 유사도 점수 반환
                   ELSE SIMILARITY(c.name ->> :locale, :keyword)
               END as score
               
        FROM food_categories c
        WHERE 
            -- 1. 이름(Locale) 일치
            (c.name ->> :locale ILIKE %:keyword%)
            OR 
            -- 2. 코드(CODE) 일치 (예: 'NOODLE')
            (c.code ILIKE %:keyword%)
            OR 
            -- 3. 오타 보정 (유사도 0.3 이상)
            (SIMILARITY(c.name ->> :locale, :keyword) > 0.3)
            
        -- [정렬] 점수 높은 순 -> 이름 짧은 순
        ORDER BY score DESC, LENGTH(c.name ->> :locale) ASC
        """, nativeQuery = true)
    List<AutocompleteProjectionDto> searchByNameWithFuzzy(@Param("keyword") String keyword,
                                                          @Param("locale") String locale,
                                                          Pageable pageable);
}