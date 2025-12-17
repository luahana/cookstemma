package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import com.pairingplanet.pairing_planet.repository.food.FoodCategoryRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Range;
import org.springframework.data.redis.connection.Limit;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AutocompleteService {

    private final RedisTemplate<String, String> redisTemplate;

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

        // --- 1단계: Redis 검색 (고속, Prefix) ---
        List<AutocompleteDto> redisResults = searchRedis(keyword, locale);

        // Redis 결과가 있으면 바로 리턴 (DB 부하 0)
        if (!redisResults.isEmpty()) {
            return redisResults;
        }

        // --- 2단계: DB Fallback (오타 보정) ---
        // Redis 결과가 없다는 건, 유저가 오타를 냈거나 없는 단어일 확률이 높음 -> DB Fuzzy Query 호출
        return searchDbWithFuzzy(keyword, locale);
    }

    private List<AutocompleteDto> searchRedis(String prefix, String locale) {
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
    public void add(String locale, String name, String type, Long id, Double score) {
        String key = AUTOCOMPLETE_KEY_PREFIX + locale;
        String value = String.join(DELIMITER, name, type, String.valueOf(id), String.valueOf(score));

        // ZSet에 추가 (Score는 0으로 고정하여 Lexical Ordering 사용)
        redisTemplate.opsForZSet().add(key, value, 0);
    }

    /**
     * 전체 삭제 (초기화용)
     */
    public void clear(String locale) {
        redisTemplate.delete(AUTOCOMPLETE_KEY_PREFIX + locale);
    }

    private AutocompleteDto parse(String raw) {
        try {
            String[] parts = raw.split(DELIMITER);
            // parts[0]=Name, parts[1]=Type, parts[2]=Id, parts[3]=Score
            return AutocompleteDto.builder()
                    .name(parts[0])
                    .type(parts[1])
                    .id(Long.parseLong(parts[2]))
                    .score(Double.parseDouble(parts[3]))
                    .build();
        } catch (Exception e) {
            // 파싱 에러 시 빈 객체 혹은 null 처리
            return AutocompleteDto.builder().name(raw).type("UNKNOWN").id(0L).score(0.0).build();
        }
    }

    // --- Helper ---

    private AutocompleteDto convertProjection(AutocompleteProjectionDto p) {
        return AutocompleteDto.builder()
                .id(p.getId())
                .name(p.getName())
                .type(p.getType()) // "FOOD" or "CATEGORY" from query
                .score(p.getScore())
                .build();
    }
}