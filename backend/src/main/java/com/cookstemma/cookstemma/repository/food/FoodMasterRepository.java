package com.cookstemma.cookstemma.repository.food;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.dto.autocomplete.AutocompleteProjectionDto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FoodMasterRepository extends JpaRepository<FoodMaster, Long>, JpaSpecificationExecutor<FoodMaster> {

    // 여러 개의 Public ID(UUID)로 Food 리스트 조회
    List<FoodMaster> findByPublicIdIn(List<UUID> publicIds);

    Optional<FoodMaster> findByPublicId(UUID publicId);

    @Query("SELECT f FROM FoodMaster f WHERE f.isVerified = true")
    List<FoodMaster> findAllVerified();

    // [수정] JSONB 필드인 name 내에서 특정 로케일(ko-KR 등)의 값이 일치하는지 검색
    @Query(value = "SELECT * FROM foods_master WHERE name ->> :locale = :name LIMIT 1", nativeQuery = true)
    Optional<FoodMaster> findByNameAndLocale(@Param("name") String name, @Param("locale") String locale);

    @Query(value = "SELECT * FROM foods_master WHERE EXISTS (SELECT 1 FROM jsonb_each_text(name) WHERE value = :name) LIMIT 1", nativeQuery = true)
    Optional<FoodMaster> findByNameInAnyLocale(@Param("name") String name);

    // FR-86: Fuzzy Matching (오타 보정)
    // 1순위: 정확/부분 일치 (ILIKE)
    // 2순위: 유사도(SIMILARITY) 0.3 이상
    @Query(value = "SELECT public_id as publicId, " + // [핵심] id 대신 public_id를 조회
            "name ->> :locale as name, 'FOOD' as type, food_score as score " +
            "FROM foods_master " +
            "WHERE name ->> :locale %> :keyword " + // pg_trgm 유사도 검색
            "ORDER BY name ->> :locale <-> :keyword " + // 유사도 순 정렬
            "LIMIT :#{#pageable.pageSize}",
            nativeQuery = true)
    List<AutocompleteProjectionDto> searchByNameWithFuzzy(@Param("keyword") String keyword,
                                                          @Param("locale") String locale,
                                                          Pageable pageable);

    /**
     * Find FoodMaster entries that have only one locale in their name map (untranslated).
     * Used for backfilling translations for existing foods.
     */
    @Query(value = "SELECT * FROM foods_master WHERE jsonb_array_length(jsonb_path_query_array(name, '$.keyvalue()')) = 1", nativeQuery = true)
    List<FoodMaster> findUntranslatedFoods();

    /**
     * Search FoodMaster by name (searches in JSONB text) for admin panel.
     * Uses PostgreSQL's text cast to search across all locales in the JSONB name field.
     */
    @Query(value = "SELECT * FROM foods_master WHERE name::text ILIKE %:name%",
            countQuery = "SELECT count(*) FROM foods_master WHERE name::text ILIKE %:name%",
            nativeQuery = true)
    org.springframework.data.domain.Page<FoodMaster> searchByNameContaining(@Param("name") String name, Pageable pageable);

    /**
     * Search FoodMaster by name and isVerified filter for admin panel.
     */
    @Query(value = "SELECT * FROM foods_master WHERE name::text ILIKE %:name% AND is_verified = :isVerified",
            countQuery = "SELECT count(*) FROM foods_master WHERE name::text ILIKE %:name% AND is_verified = :isVerified",
            nativeQuery = true)
    org.springframework.data.domain.Page<FoodMaster> searchByNameContainingAndIsVerified(
            @Param("name") String name, @Param("isVerified") Boolean isVerified, Pageable pageable);
}