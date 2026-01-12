package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import com.pairingplanet.pairing_planet.repository.autocomplete.AutocompleteItemRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Range;
import org.springframework.data.redis.connection.Limit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AutocompleteService {

    @Autowired(required = false)
    private RedisTemplate<String, String> redisTemplate;

    private final AutocompleteItemRepository autocompleteItemRepository;

    private static final String AUTOCOMPLETE_KEY_PREFIX = "autocomplete:";
    private static final String DELIMITER = "::";
    private static final int MAX_RESULTS = 10;
    private static final Set<String> CJK_LOCALES = Set.of("ko-KR", "ja-JP", "zh-CN");
    private static final int MIN_FUZZY_LENGTH = 3;

    /**
     * Search with optional type filter
     */
    public List<AutocompleteDto> search(String keyword, String locale, String type) {
        if (keyword == null || keyword.isBlank()) return List.of();

        // Special case: MAIN searches both main and secondary ingredients
        if ("MAIN".equalsIgnoreCase(type)) {
            return searchMultipleTypes(keyword, locale,
                List.of("MAIN_INGREDIENT", "SECONDARY_INGREDIENT"));
        }

        // Map frontend type to autocomplete type
        String mappedType = mapToAutocompleteType(type);

        // 1. Try Redis first
        List<AutocompleteDto> redisResults = searchRedis(keyword, locale, mappedType);

        if (!redisResults.isEmpty()) {
            return redisResults;
        }

        // 2. Fallback to DB fuzzy search
        return searchDbWithFuzzy(keyword, locale, mappedType);
    }

    /**
     * Search multiple types and merge results (for MAIN which includes SECONDARY)
     */
    private List<AutocompleteDto> searchMultipleTypes(String keyword, String locale, List<String> types) {
        List<AutocompleteDto> allResults = new ArrayList<>();

        for (String type : types) {
            List<AutocompleteDto> redisResults = searchRedis(keyword, locale, type);
            if (!redisResults.isEmpty()) {
                allResults.addAll(redisResults);
            } else {
                allResults.addAll(searchDbWithFuzzy(keyword, locale, type));
            }
        }

        return allResults.stream()
                .distinct()
                .sorted(Comparator.comparing(AutocompleteDto::score).reversed())
                .limit(MAX_RESULTS)
                .collect(Collectors.toList());
    }

    /**
     * Map frontend ingredient type to autocomplete type
     */
    private String mapToAutocompleteType(String frontendType) {
        if (frontendType == null) return null;
        return switch (frontendType.toUpperCase()) {
            case "DISH" -> "DISH";
            case "MAIN" -> "MAIN_INGREDIENT";
            case "SECONDARY" -> "SECONDARY_INGREDIENT";
            case "SEASONING" -> "SEASONING";
            default -> frontendType.toUpperCase();
        };
    }

    private List<AutocompleteDto> searchRedis(String prefix, String locale, String type) {
        if (redisTemplate == null) {
            return List.of();
        }

        try {
            // Build key: autocomplete:{locale}:{type} or autocomplete:{locale} if no type
            String key = buildRedisKey(locale, type);
            Range<String> range = Range.rightOpen(prefix, prefix + "\uffff");
            Limit limit = Limit.limit().count(50);

            Set<String> results = redisTemplate.opsForZSet().rangeByLex(key, range, limit);

            if (results == null || results.isEmpty()) return List.of();

            return results.stream()
                    .map(this::parse)
                    .filter(dto -> dto.name().toLowerCase().startsWith(prefix.toLowerCase()))
                    .sorted(Comparator.comparing(AutocompleteDto::score).reversed())
                    .limit(MAX_RESULTS)
                    .collect(Collectors.toList());
        } catch (Exception e) {
            // Redis unavailable, fallback to empty (will use DB)
            log.debug("Redis search failed, falling back to DB: {}", e.getMessage());
            return List.of();
        }
    }

    private List<AutocompleteDto> searchDbWithFuzzy(String keyword, String locale, String type) {
        PageRequest limit = PageRequest.of(0, MAX_RESULTS);

        // For CJK locales with short keywords, use prefix search instead of fuzzy
        boolean usePrefixSearch = isCjkLocale(locale) && keyword.length() < MIN_FUZZY_LENGTH;

        List<AutocompleteProjectionDto> results;
        if (usePrefixSearch) {
            String pattern = keyword + "%";
            if (type != null) {
                results = autocompleteItemRepository.searchByTypeAndNameWithPrefix(
                        type, pattern, locale, limit);
            } else {
                results = autocompleteItemRepository.searchByNameWithPrefix(pattern, locale, limit);
            }
        } else {
            if (type != null) {
                results = autocompleteItemRepository.searchByTypeAndNameWithFuzzy(
                        type, keyword, locale, limit);
            } else {
                results = autocompleteItemRepository.searchByNameWithFuzzy(keyword, locale, limit);
            }
        }

        return results.stream()
                .map(this::convertProjection)
                .sorted(Comparator.comparing(AutocompleteDto::score).reversed())
                .collect(Collectors.toList());
    }

    /**
     * Check if locale is CJK (Korean, Japanese, Chinese)
     */
    private boolean isCjkLocale(String locale) {
        return locale != null && CJK_LOCALES.contains(locale);
    }

    /**
     * Add item to Redis (for sync)
     * Format: "Name::Type::Id::Score"
     */
    public void add(String locale, String name, String type, UUID publicId, Double score) {
        if (redisTemplate == null) {
            return;
        }

        try {
            String key = buildRedisKey(locale, type);
            String value = name + DELIMITER + type + DELIMITER + publicId.toString() + DELIMITER + score;
            redisTemplate.opsForZSet().add(key, value, 0);
        } catch (Exception e) {
            log.debug("Redis add failed: {}", e.getMessage());
        }
    }

    /**
     * Clear all autocomplete data for a locale
     */
    public void clear(String locale) {
        if (redisTemplate == null) {
            return;
        }

        try {
            // Clear type-specific keys
            for (String type : List.of("DISH", "MAIN_INGREDIENT", "SECONDARY_INGREDIENT", "SEASONING")) {
                redisTemplate.delete(buildRedisKey(locale, type));
            }
        } catch (Exception e) {
            log.debug("Redis clear failed: {}", e.getMessage());
        }
    }

    private String buildRedisKey(String locale, String type) {
        if (type == null) {
            return AUTOCOMPLETE_KEY_PREFIX + locale;
        }
        return AUTOCOMPLETE_KEY_PREFIX + locale + ":" + type;
    }

    private AutocompleteDto parse(String raw) {
        try {
            String[] parts = raw.split(DELIMITER);
            return AutocompleteDto.builder()
                    .name(parts[0])
                    .type(parts[1])
                    .publicId(UUID.fromString(parts[2]))
                    .score(Double.parseDouble(parts[3]))
                    .build();
        } catch (Exception e) {
            return AutocompleteDto.builder().name(raw).type("UNKNOWN").build();
        }
    }

    private AutocompleteDto convertProjection(AutocompleteProjectionDto p) {
        return AutocompleteDto.builder()
                .publicId(p.getPublicId())
                .name(p.getName())
                .type(p.getType())
                .score(p.getScore())
                .build();
    }
}
