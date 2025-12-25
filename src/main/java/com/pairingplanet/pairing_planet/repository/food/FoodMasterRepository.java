package com.pairingplanet.pairing_planet.repository.food;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FoodMasterRepository extends JpaRepository<FoodMaster, Long> {

    // 여러 개의 Public ID(UUID)로 Food 리스트 조회
    List<FoodMaster> findByPublicIdIn(List<UUID> publicIds);

    Optional<FoodMaster> findByPublicId(UUID publicId);

    @Query("SELECT f FROM FoodMaster f WHERE f.isVerified = true")
    List<FoodMaster> findAllVerified();

    // FR-86: Fuzzy Matching (오타 보정)
    // 1순위: 정확/부분 일치 (ILIKE)
    // 2순위: 유사도(SIMILARITY) 0.3 이상
    @Query(value = """
        SELECT f.id as id, 
               f.name ->> :locale as name, 
               'FOOD' as type,
               CASE 
                   WHEN (f.name ->> :locale ILIKE %:keyword%) THEN 1.0
                   ELSE SIMILARITY(f.search_keywords, :keyword)
               END as score
        FROM foods_master f
        WHERE 
            (f.name ->> :locale ILIKE %:keyword% OR f.search_keywords ILIKE %:keyword%)
            OR 
            (SIMILARITY(f.search_keywords, :keyword) > 0.3)
        AND f.is_verified = TRUE
        ORDER BY score DESC, LENGTH(f.name ->> :locale) ASC
        """, nativeQuery = true)
    List<AutocompleteProjectionDto> searchByNameWithFuzzy(@Param("keyword") String keyword,
                                                          @Param("locale") String locale,
                                                          Pageable pageable);
}