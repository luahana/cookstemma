package com.pairingplanet.pairing_planet.repository.search;

import com.pairingplanet.pairing_planet.domain.entity.search.SearchIndex;
import com.pairingplanet.pairing_planet.domain.enums.SearchTargetType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
@TestPropertySource(properties = {
        // 32바이트(1~8 반복)를 Base64로 인코딩한 정확한 값입니다.
        "security.encryption-key=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
})
class SearchIndexRepositoryTest {
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
    private SearchIndexRepository searchIndexRepository;

    @Test
    @DisplayName("키워드 검색: 로케일 일치 + 키워드 포함(Containing)된 결과를 반환한다")
    void findByLocaleCodeAndKeywordContaining() {
        // given
        createIndex("Pasta Carbonara", "en");
        createIndex("Kimchi Pasta", "en");
        createIndex("Sushi", "en");
        createIndex("Pasta", "ko"); // 다른 로케일

        // when
        List<SearchIndex> results = searchIndexRepository.findByLocaleCodeAndKeywordContaining("en", "Pasta");

        // then
        assertThat(results).hasSize(2); // "Pasta Carbonara", "Kimchi Pasta"
        assertThat(results).extracting("keyword")
                .containsExactlyInAnyOrder("Pasta Carbonara", "Kimchi Pasta");
    }

    private void createIndex(String keyword, String locale) {
        SearchIndex index = SearchIndex.builder()
                .keyword(keyword)
                .localeCode(locale)
                .targetType(SearchTargetType.FOOD)
                .targetId(1L)
                .build();
        searchIndexRepository.save(index);
    }
}