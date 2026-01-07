package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import com.pairingplanet.pairing_planet.repository.food.FoodCategoryRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
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

    private final FoodMasterRepository foodMasterRepository;
    private final FoodCategoryRepository foodCategoryRepository;

    private static final String AUTOCOMPLETE_KEY_PREFIX = "autocomplete:";
    private static final String DELIMITER = "::";
    private static final int MAX_RESULTS = 10; // 최대 반환 개수

    /**
     * 검색 (Redis ZRANGEBYLEX 활용)
     * O(log N + M) 속도로 매우 빠름
     */
    public List<AutocompleteDto> search(String keyword, String locale) {
        if (keyword == null || keyword.isBlank()) return List.of();

        // 1. Redis에서 직접 UUID가 포함된 결과 추출 (DB 접근 0)
        List<AutocompleteDto> redisResults = searchRedis(keyword, locale);

        if (!redisResults.isEmpty()) {
            return redisResults;
        }

        // 2. Redis에 없을 때만 DB Fuzzy 검색 수행
        // pg_trgm 인덱스를 사용하여 텍스트 유사도 검색 최적화
        return searchDbWithFuzzy(keyword, locale);
    }

    private List<AutocompleteDto> searchRedis(String prefix, String locale) {
        if (redisTemplate == null) {
            return List.of(); // Redis not available, fall back to DB
        }

        String key = AUTOCOMPLETE_KEY_PREFIX + locale;
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
    }

    // DB Fuzzy Search 로직 (기존 Repository 활용)
    private List<AutocompleteDto> searchDbWithFuzzy(String keyword, String locale) {
        List<AutocompleteDto> fallbackResults = new ArrayList<>();
        PageRequest limit = PageRequest.of(0, 5); // DB는 무거우니까 조금만 가져옴

        // 1. 카테고리 오타 검색
        List<AutocompleteProjectionDto> categories = foodCategoryRepository.searchByNameWithFuzzy(keyword, locale, limit);
        fallbackResults.addAll(categories.stream()
                .map(this::convertProjection)
                .toList());

        // 2. 음식 오타 검색
        List<AutocompleteProjectionDto> foods = foodMasterRepository.searchByNameWithFuzzy(keyword, locale, limit);
        fallbackResults.addAll(foods.stream()
                .map(this::convertProjection)
                .toList());

        // 점수순 정렬
        fallbackResults.sort(Comparator.comparing(AutocompleteDto::score).reversed());
        return fallbackResults;
    }

    /**
     * 데이터 추가/갱신 (Sync용)
     * Format: "Name::Type::Id::Score"
     */
    public void add(String locale, String name, String type, UUID publicId, Double score) {
        if (redisTemplate == null) {
            return; // Redis not available
        }

        String key = AUTOCOMPLETE_KEY_PREFIX + locale;
        // 성능 포인트: 불필요한 객체 생성을 줄이기 위해 String.join 사용
        String value = name + DELIMITER + type + DELIMITER + publicId.toString() + DELIMITER + score;

        redisTemplate.opsForZSet().add(key, value, 0);
    }

    /**
     * 전체 삭제 (초기화용)
     */
    public void clear(String locale) {
        if (redisTemplate == null) {
            return; // Redis not available
        }
        redisTemplate.delete(AUTOCOMPLETE_KEY_PREFIX + locale);
    }

    private AutocompleteDto parse(String raw) {
        try {
            String[] parts = raw.split(DELIMITER);
            return AutocompleteDto.builder()
                    .name(parts[0])
                    .type(parts[1])
                    .publicId(UUID.fromString(parts[2])) // 성능: UUID.fromString은 매우 빠른 비트 연산 기반임
                    .score(Double.parseDouble(parts[3]))
                    .build();
        } catch (Exception e) {
            return AutocompleteDto.builder().name(raw).type("UNKNOWN").build();
        }
    }

    // --- Helper ---

    private AutocompleteDto convertProjection(AutocompleteProjectionDto p) {
        return AutocompleteDto.builder()
                .publicId(p.getPublicId())
                .name(p.getName())
                .type(p.getType()) // "FOOD" or "CATEGORY" from query
                .score(p.getScore())
                .build();
    }
}