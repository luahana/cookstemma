package com.pairingplanet.pairing_planet.repository;

import com.pairingplanet.pairing_planet.domain.entity.user.SocialAccount;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.repository.user.SocialAccountRepository;
import com.pairingplanet.pairing_planet.repository.user.UserRepository;
import com.pairingplanet.pairing_planet.util.EncryptionConverter;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@Import(EncryptionConverter.class)
// [해결 1] 프로퍼티 이름 일치시키기
// EncryptionConverter.java 파일의 @Value("${...}") 안에 있는 이름과 똑같아야 합니다.
// 만약 EncryptionConverter가 "app.encryption.key"를 쓴다면 아래처럼 고쳐주세요.
@TestPropertySource(properties = {
        "security.encryption-key=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
})
class EncryptionTest {

    // [해결 2] 컨테이너 수동 시작 설정
    // @Container, @Testcontainers 애노테이션 제거
    static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    static {
        // 스프링 컨텍스트가 로드되기 전에 DB를 먼저 띄웁니다.
        postgres.start();
    }

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        // static 블록에서 start() 했으므로 안전하게 URL을 가져올 수 있습니다.
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);

        // Flyway 설정 (필요시)
        registry.add("spring.flyway.url", postgres::getJdbcUrl);
        registry.add("spring.flyway.user", postgres::getUsername);
        registry.add("spring.flyway.password", postgres::getPassword);
    }

    @Autowired
    SocialAccountRepository socialAccountRepository;
    @Autowired
    UserRepository userRepository;
    @Autowired
    EntityManager em;

    @Test
    @DisplayName("DB 저장 시 AccessToken은 암호화되고, 조회 시 복호화되어야 한다")
    void testEncryptionConverter() {
        // given
        String originalToken = "my-secret-access-token-123";

        User user = User.builder()
                .username("testuser")
                .locale("ko")
                .build();
        userRepository.save(user);

        SocialAccount account = SocialAccount.builder()
                .user(user)
                .provider("GOOGLE")
                .providerUserId("1234")
                .accessToken(originalToken)
                .build();

        // when
        socialAccountRepository.saveAndFlush(account);
        em.clear(); // 1차 캐시 비우기

        // then 1: JPA 조회 (자동 복호화 확인)
        SocialAccount retrieved = socialAccountRepository.findById(account.getId()).orElseThrow();
        assertThat(retrieved.getAccessToken()).isEqualTo(originalToken);

        // then 2: Native Query 조회 (암호화 상태 확인)
        List<String> rawTokens = em.createNativeQuery("SELECT access_token FROM social_accounts WHERE id = :id")
                .setParameter("id", account.getId())
                .getResultList();

        String rawTokenInDb = rawTokens.get(0);

        assertThat(rawTokenInDb).isNotEqualTo(originalToken);
        assertThat(rawTokenInDb).contains(":"); // IV:Cipher 형식 확인

        System.out.println(">>> Original Token: " + originalToken);
        System.out.println(">>> Encrypted Token in DB: " + rawTokenInDb);
    }
}