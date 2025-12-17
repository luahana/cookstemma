package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteProjectionDto;
import com.pairingplanet.pairing_planet.dto.autocomplete.AutocompleteDto;
import com.pairingplanet.pairing_planet.repository.food.FoodCategoryRepository;
import com.pairingplanet.pairing_planet.repository.food.FoodMasterRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Range;
import org.springframework.data.redis.connection.Limit;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

import java.util.Collections;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AutocompleteServiceTest {

    @InjectMocks
    private AutocompleteService autocompleteService;

    @Mock
    private RedisTemplate<String, String> redisTemplate;

    @Mock
    private ZSetOperations<String, String> zSetOperations;

    @Mock
    private FoodMasterRepository foodMasterRepository;

    @Mock
    private FoodCategoryRepository foodCategoryRepository;

    @BeforeEach
    void setUp() {
        // RedisTemplate.opsForZSet() 호출 시 Mock 객체 반환 설정
        // lenient()를 쓴 이유는 add/clear 테스트 시에는 호출되지 않을 수도 있어서 경고 방지용
        lenient().when(redisTemplate.opsForZSet()).thenReturn(zSetOperations);
    }

    @Test
    @DisplayName("search: Redis에 데이터가 있으면 DB를 호출하지 않고 Redis 결과를 반환해야 한다 (Happy Path)")
    void search_redisHit() {
        // given
        String keyword = "Kim";
        String locale = "en";
        String key = "autocomplete:en";

        // Redis에 저장된 포맷: "Name::Type::Id::Score"
        Set<String> redisResults = Set.of(
                "Kimchi::FOOD::100::95.5",
                "Kimchi Stew::FOOD::101::80.0"
        );

        // Redis Mocking
        given(zSetOperations.rangeByLex(eq(key), any(Range.class), any(Limit.class)))
                .willReturn(redisResults);

        // when
        List<AutocompleteDto> result = autocompleteService.search(keyword, locale);

        // then
        assertThat(result).hasSize(2);
        assertThat(result.get(0).name()).isEqualTo("Kimchi");
        assertThat(result.get(0).score()).isEqualTo(95.5);

        // [중요] Redis에서 찾았으므로 DB 리포지토리는 호출되면 안 됨
        verify(foodMasterRepository, never()).searchByNameWithFuzzy(anyString(), anyString(), any());
        verify(foodCategoryRepository, never()).searchByNameWithFuzzy(anyString(), anyString(), any());
    }

    @Test
    @DisplayName("search: Redis 결과가 없으면 DB(Fuzzy Search)를 호출하여 결과를 반환해야 한다 (Fallback)")
    void search_redisMiss_dbFallback() {
        // given
        String keyword = "Kimchii"; // 오타 상황
        String locale = "en";
        String key = "autocomplete:en";

        // 1. Redis는 빈 결과 반환
        given(zSetOperations.rangeByLex(eq(key), any(Range.class), any(Limit.class)))
                .willReturn(Collections.emptySet());

        // 2. DB Mocking (Projection 인터페이스 Mocking)
        AutocompleteProjectionDto catProj = mock(AutocompleteProjectionDto.class);
        given(catProj.getId()).willReturn(1L);
        given(catProj.getName()).willReturn("Kimchi Category");
        given(catProj.getType()).willReturn("CATEGORY");
        given(catProj.getScore()).willReturn(50.0);

        AutocompleteProjectionDto foodProj = mock(AutocompleteProjectionDto.class);
        given(foodProj.getId()).willReturn(100L);
        given(foodProj.getName()).willReturn("Kimchi");
        given(foodProj.getType()).willReturn("FOOD");
        given(foodProj.getScore()).willReturn(99.9);

        given(foodCategoryRepository.searchByNameWithFuzzy(eq(keyword), eq(locale), any(Pageable.class)))
                .willReturn(List.of(catProj));
        given(foodMasterRepository.searchByNameWithFuzzy(eq(keyword), eq(locale), any(Pageable.class)))
                .willReturn(List.of(foodProj));

        // when
        List<AutocompleteDto> result = autocompleteService.search(keyword, locale);

        // then
        assertThat(result).hasSize(2);

        // 점수순 정렬 확인 (Food 99.9 > Category 50.0)
        assertThat(result.get(0).name()).isEqualTo("Kimchi");
        assertThat(result.get(0).score()).isEqualTo(99.9);

        assertThat(result.get(1).name()).isEqualTo("Kimchi Category");

        // [중요] DB 리포지토리가 호출되었는지 검증
        verify(foodCategoryRepository, times(1)).searchByNameWithFuzzy(eq(keyword), eq(locale), any());
        verify(foodMasterRepository, times(1)).searchByNameWithFuzzy(eq(keyword), eq(locale), any());
    }

    @Test
    @DisplayName("search: 입력값이 비어있으면 빈 리스트를 반환하고 Redis/DB를 조회하지 않는다")
    void search_emptyInput() {
        // when
        List<AutocompleteDto> result = autocompleteService.search("", "en");

        // then
        assertThat(result).isEmpty();
        verifyNoInteractions(zSetOperations);
        verifyNoInteractions(foodMasterRepository);
    }

    @Test
    @DisplayName("add: 데이터 추가 시 올바른 포맷으로 Redis ZSet에 저장되어야 한다")
    void add() {
        // given
        String locale = "ko";
        String name = "김치";
        String type = "FOOD";
        Long id = 123L;
        Double score = 100.0;

        // 예상되는 Redis Value 포맷: "김치::FOOD::123::100.0"
        String expectedValue = "김치::FOOD::123::100.0";

        // when
        autocompleteService.add(locale, name, type, id, score);

        // then
        // ZSet에 Score 0으로 추가되는지 검증
        verify(zSetOperations).add("autocomplete:ko", expectedValue, 0);
    }

    @Test
    @DisplayName("clear: 로케일별 키 삭제가 호출되어야 한다")
    void clear() {
        // given
        String locale = "en";

        // when
        autocompleteService.clear(locale);

        // then
        verify(redisTemplate).delete("autocomplete:en");
    }
}