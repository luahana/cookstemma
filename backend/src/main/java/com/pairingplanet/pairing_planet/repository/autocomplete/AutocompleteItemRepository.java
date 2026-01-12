package com.pairingplanet.pairing_planet.repository.autocomplete;

import com.pairingplanet.pairing_planet.domain.entity.autocomplete.AutocompleteItem;
import com.pairingplanet.pairing_planet.domain.enums.AutocompleteType;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface AutocompleteItemRepository extends JpaRepository<AutocompleteItem, Long> {

    List<AutocompleteItem> findAllByType(AutocompleteType type);

    @Query(value = "SELECT public_id as publicId, " +
            "name ->> :locale as name, " +
            "type::text as type, " +
            "score as score " +
            "FROM autocomplete_items " +
            "WHERE type::text = :type " +
            "AND name ->> :locale %> :keyword " +
            "ORDER BY name ->> :locale <-> :keyword " +
            "LIMIT :#{#pageable.pageSize}",
            nativeQuery = true)
    List<AutocompleteProjectionDto> searchByTypeAndNameWithFuzzy(
            @Param("type") String type,
            @Param("keyword") String keyword,
            @Param("locale") String locale,
            Pageable pageable);

    @Query(value = "SELECT public_id as publicId, " +
            "name ->> :locale as name, " +
            "type::text as type, " +
            "score as score " +
            "FROM autocomplete_items " +
            "WHERE name ->> :locale %> :keyword " +
            "ORDER BY name ->> :locale <-> :keyword " +
            "LIMIT :#{#pageable.pageSize}",
            nativeQuery = true)
    List<AutocompleteProjectionDto> searchByNameWithFuzzy(
            @Param("keyword") String keyword,
            @Param("locale") String locale,
            Pageable pageable);

    /**
     * Prefix-based search for CJK locales (works with single characters)
     */
    @Query(value = "SELECT public_id as publicId, " +
            "name ->> :locale as name, " +
            "type::text as type, " +
            "score as score " +
            "FROM autocomplete_items " +
            "WHERE type::text = :type " +
            "AND name ->> :locale ILIKE :pattern " +
            "ORDER BY score DESC " +
            "LIMIT :#{#pageable.pageSize}",
            nativeQuery = true)
    List<AutocompleteProjectionDto> searchByTypeAndNameWithPrefix(
            @Param("type") String type,
            @Param("pattern") String pattern,
            @Param("locale") String locale,
            Pageable pageable);

    @Query(value = "SELECT public_id as publicId, " +
            "name ->> :locale as name, " +
            "type::text as type, " +
            "score as score " +
            "FROM autocomplete_items " +
            "WHERE name ->> :locale ILIKE :pattern " +
            "ORDER BY score DESC " +
            "LIMIT :#{#pageable.pageSize}",
            nativeQuery = true)
    List<AutocompleteProjectionDto> searchByNameWithPrefix(
            @Param("pattern") String pattern,
            @Param("locale") String locale,
            Pageable pageable);
}
