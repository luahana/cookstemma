package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.config.QueryDslTestConfig;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextDimension;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.dto.search.PairingSearchRequestDto;
import com.pairingplanet.pairing_planet.dto.search.PostSearchResultDto;
import com.pairingplanet.pairing_planet.dto.search.SearchCursorDto;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
@TestPropertySource(properties = {
        // 32바이트(1~8 반복)를 Base64로 인코딩한 정확한 값입니다.
        "security.encryption-key=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
})
@Import({QueryDslTestConfig.class, PostSearchRepositoryImpl.class}) // QueryDSL Config 및 Impl 로드
class PostSearchRepositoryTest {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        // Flyway가 있다면 Flyway 설정도 같이 해줘야 함
        registry.add("spring.flyway.url", postgres::getJdbcUrl);
        registry.add("spring.flyway.user", postgres::getUsername);
        registry.add("spring.flyway.password", postgres::getPassword);
    }

    @Autowired
    private PostSearchRepositoryImpl postSearchRepository;

    @Autowired
    private EntityManager em;

    private FoodCategory category;
    private ContextDimension dimensionWhen;
    private ContextDimension dimensionDietary;
    private FoodMaster foodA;
    private FoodMaster foodB;
    private ContextTag whenLunch;
    private ContextTag dietaryVegan;
    private User user;

    @BeforeEach
    void setUp() {
        // 1. 기초 데이터 세팅 (User, Food, Tag)
        user = User.builder().username("tester").locale("en").build();
        em.persist(user);

        category = FoodCategory.builder()
                .code("MAIN_DISH")
                .name(Map.of("en", "Main Dish", "ko", "메인 요리"))
                .depth(1)
                .build();
        em.persist(category);

        foodA = FoodMaster.builder()
                .category(category)
                .name(Collections.singletonMap("en", "Steak"))
                .build();
        foodB = FoodMaster.builder()
                .category(category)
                .name(Collections.singletonMap("en", "Wine"))
                .build();
        em.persist(foodA);
        em.persist(foodB);

        dimensionWhen = ContextDimension.builder()
                .name("When") // 예: "When", "Where", "Who"
                .build();
        em.persist(dimensionWhen);

        dimensionDietary = ContextDimension.builder()
                .name("Dietary") // 예: "When", "Where", "Who"
                .build();
        em.persist(dimensionDietary);

        whenLunch = ContextTag.builder()
                .dimension(dimensionWhen)
                .tagName("Lunch")
                .displayName("Lunch Time")
                .locale("en")
                .build();
        em.persist(whenLunch);

        dietaryVegan = ContextTag.builder()
                .dimension(dimensionDietary)
                .tagName("Vegan")
                .displayName("Vegan")
                .locale("en")
                .build();
        em.persist(dietaryVegan);
    }

    @Test
    @DisplayName("음식 ID 검색: 교차 검증 (FoodA + FoodB)가 순서 상관없이 검색되어야 한다")
    void searchPosts_crossValidation() {
        // given
        // Post 1: FoodA(Main) + FoodB(Sub)
        createPostWithPairing(foodA, foodB, 10.0);
        // Post 2: FoodB(Main) + FoodA(Sub) -> 순서 반대여도 검색되어야 함
        createPostWithPairing(foodB, foodA, 20.0);
        // Post 3: FoodA only -> 검색되지 않아야 함
        createPostWithPairing(foodA, null, 5.0);

        // Request: FoodA, FoodB 검색
        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(foodA.getId(), foodB.getId()), null, null, null, "en", null
        );

        // when
        List<PostSearchResultDto> results = postSearchRepository.searchPosts(request, SearchCursorDto.initial(), 10);

        // then
        assertThat(results).hasSize(2); // Post 1, Post 2
        // 점수 높은 순(20.0 -> 10.0) 정렬 확인
        assertThat(results.get(0).popularityScore()).isEqualTo(20.0);
        assertThat(results.get(1).popularityScore()).isEqualTo(10.0);
    }

    @Test
    @DisplayName("커서 페이지네이션: 점수와 ID 기준으로 다음 페이지를 가져와야 한다")
    void searchPosts_cursorPagination() {
        // given
        // 점수가 같은 경우 ID 내림차순 테스트를 위해 3개 생성
        createPostWithPairing(foodA, null, 10.0); // ID: AutoInc (1)
        createPostWithPairing(foodA, null, 10.0); // ID: AutoInc (2)
        createPostWithPairing(foodA, null, 10.0); // ID: AutoInc (3)

        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(foodA.getId()), null, null, null, "en", null
        );

        // when 1: 첫 페이지 (Limit 2)
        List<PostSearchResultDto> page1 = postSearchRepository.searchPosts(request, SearchCursorDto.initial(), 2);

        // then 1
        assertThat(page1).hasSize(2);
        // 최신순(ID 역순): ID 3 -> ID 2
        Long lastId = page1.get(1).postId();
        Double lastScore = page1.get(1).popularityScore();

        // when 2: 두 번째 페이지 (커서 적용)
        SearchCursorDto cursor = new SearchCursorDto(lastScore, lastId);
        List<PostSearchResultDto> page2 = postSearchRepository.searchPosts(request, cursor, 2);

        // then 2
        assertThat(page2).hasSize(1);
        // 마지막 남은 ID 1
        assertThat(page2.get(0).postId()).isLessThan(lastId);
    }

    @Test
    @DisplayName("태그 필터: When 태그가 일치하는 포스트만 가져온다")
    void searchPosts_tagFilter() {
        // given
        Post p1 = createPostWithPairing(foodA, null, 10.0, whenLunch); // Lunch 태그 있음
        createPostWithPairing(foodA, null, 10.0, null);      // 태그 없음

        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(foodA.getId()), null, whenLunch.getId(), null, "en", null
        );

        // when
        List<PostSearchResultDto> results = postSearchRepository.searchPosts(request, SearchCursorDto.initial(), 10);

        // then
        assertThat(results).hasSize(1);
        assertThat(results.get(0).postId()).isEqualTo(p1.getId());
    }

    @Test
    @DisplayName("Fallback 검색: ignoreWhenTag=true일 때 When 태그를 무시하고 검색한다")
    void searchPostsFallback_ignoreWhenTag() {
        // given
        // Lunch 태그가 없는 포스트만 존재
        createPostWithPairing(foodA, null, 10.0, null);

        // 요청에는 Lunch 태그가 있음 (원래라면 검색 안 돼야 함)
        PairingSearchRequestDto request = new PairingSearchRequestDto(
                List.of(foodA.getId()), null, whenLunch.getId(), null, "en", null
        );

        // when: 일반 검색 (실패 예상)
        List<PostSearchResultDto> normalResult = postSearchRepository.searchPosts(request, SearchCursorDto.initial(), 10);
        // when: Fallback 검색 (성공 예상)
        List<PostSearchResultDto> fallbackResult = postSearchRepository.searchPostsFallback(request, SearchCursorDto.initial(), 10);

        // then
        assertThat(normalResult).isEmpty();
        assertThat(fallbackResult).hasSize(1);
        assertThat(fallbackResult.get(0).isWhenFallback()).isTrue(); // 플래그 확인
    }

    // --- Helper Methods ---

    private Post createPostWithPairing(FoodMaster f1, FoodMaster f2, Double score) {
        return createPostWithPairing(f1, f2, score, null);
    }

    private Post createPostWithPairing(FoodMaster f1, FoodMaster f2, Double score, ContextTag when) {
        if (f2 != null && f1.getId() > f2.getId()) {
            FoodMaster temp = f1;
            f1 = f2;
            f2 = temp;
        }

        PairingMap pairing = PairingMap.builder()
                .food1(f1).food2(f2)
                .whenContext(when)
                .build();
        em.persist(pairing);

        Post post = Post.builder()
                .pairing(pairing)
                .creator(user)
                .content("Test Content")
                .popularityScore(score)
                .locale("en")
                .build();
        em.persist(post);
        return post;
    }
}