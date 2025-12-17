package com.pairingplanet.pairing_planet.repository;

import com.pairingplanet.pairing_planet.domain.entity.context.ContextDimension;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.repository.pairing.PairingMapRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Collections;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE) // Disable H2 replacement
@Testcontainers
@TestPropertySource(properties = {
        // 32바이트(1~8 반복)를 Base64로 인코딩한 정확한 값입니다.
        "security.encryption-key=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
})
class PairingMapRepositoryTest {

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
    private PairingMapRepository pairingMapRepository;

    @Autowired
    private TestEntityManager em;

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
    @DisplayName("Food2가 NULL인(Solo) 페어링을 정확히 조회해야 한다")
    void findExistingPairing_Solo() {
        // given


        // Save Solo Pairing (food2 = null)
        PairingMap savedPairing = PairingMap.builder()
                .food1(foodA)
                .food2(null)
                .whenContext(whenLunch)
                .dietaryContext(dietaryVegan)
                .build();
        em.persist(savedPairing);
        em.flush();
        em.clear();

        // when
        // Food2 자리에 null을 넘김
        Optional<PairingMap> result = pairingMapRepository.findExistingPairing(
                foodA.getId(),
                null,
                whenLunch.getId(),
                dietaryVegan.getId()
        );

        // then
        assertThat(result).isPresent();
        assertThat(result.get().getFood2()).isNull();
    }

    @Test
    @DisplayName("Food2가 있는 페어링 검색 시, Food2가 NULL인 데이터는 조회되지 않아야 한다")
    void findExistingPairing_Differentiate() {
        // given

        // DB에는 (Pizza + Null)만 저장
        PairingMap soloPairing = PairingMap.builder().food1(foodA).food2(null).build();
        em.persist(soloPairing);
        em.flush();

        // when: (Pizza + Coke)를 찾으려고 함
        Optional<PairingMap> result = pairingMapRepository.findExistingPairing(
                foodA.getId(),
                foodB.getId(),
                null, null
        );

        // then: (Pizza + Null)은 (Pizza + Coke)와 다르므로 빈 결과여야 함
        assertThat(result).isEmpty();
    }
}