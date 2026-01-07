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
        SELECT c.public_id as publicId,
               c.name ->> CAST(:locale AS TEXT) as name,
               'CATEGORY' as type,
               CASE
                   WHEN (c.name ->> CAST(:locale AS TEXT) ILIKE CONCAT('%', CAST(:keyword AS TEXT), '%') OR c.code ILIKE CONCAT('%', CAST(:keyword AS TEXT), '%')) THEN 1.0
                   ELSE SIMILARITY(c.name ->> CAST(:locale AS TEXT), CAST(:keyword AS TEXT))
               END as score
        FROM food_categories c
        WHERE
            (c.name ->> CAST(:locale AS TEXT) ILIKE CONCAT('%', CAST(:keyword AS TEXT), '%'))
            OR (c.code ILIKE CONCAT('%', CAST(:keyword AS TEXT), '%'))
            OR (SIMILARITY(c.name ->> CAST(:locale AS TEXT), CAST(:keyword AS TEXT)) > 0.3)
        ORDER BY score DESC, LENGTH(c.name ->> CAST(:locale AS TEXT)) ASC
        """, nativeQuery = true)
    List<AutocompleteProjectionDto> searchByNameWithFuzzy(@Param("keyword") String keyword,
                                                          @Param("locale") String locale,
                                                          Pageable pageable);
}