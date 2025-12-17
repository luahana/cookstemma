package com.pairingplanet.pairing_planet.repository;

import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.repository.post.PostRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE) // Disable H2 replacement
@Testcontainers
@TestPropertySource(properties = {
        // 32바이트(1~8 반복)를 Base64로 인코딩한 정확한 값입니다.
        "security.encryption-key=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
})
class PostRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        // Add encryption key if needed by EncryptionConverter
    }

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private EntityManager em;

    private User user;
    private FoodCategory category;
    private FoodMaster food1;
    private FoodMaster food2;

    @BeforeEach
    void setUp() {
        // 1. Create User
        user = User.builder()
                .username("testUser")
                .locale("en")
                .build();
        em.persist(user);

        // 2. Create Category
        category = FoodCategory.builder()
                .code("TEST_CAT")
                .name(Map.of("en", "Test Category"))
                .build();
        em.persist(category);

        // 3. Create FoodMasters
        food1 = FoodMaster.builder().name(Map.of("en", "Food A")).category(category).build();
        food2 = FoodMaster.builder().name(Map.of("en", "Food B")).category(category).build();
        em.persist(food1);
        em.persist(food2);

        em.flush();
    }

    @Test
    @DisplayName("findFresh: Return posts ordered by CreatedAt DESC")
    void findFresh_pagination() {
        // given
        Instant now = Instant.now();
        Post p1 = createPost(now.minus(2, ChronoUnit.HOURS), 0, 0); // Oldest
        Post p2 = createPost(now.minus(1, ChronoUnit.HOURS), 0, 0);
        Post p3 = createPost(now, 0, 0); // Newest

        // when: Request page 1 (size 2)
        Pageable pageable = PageRequest.of(0, 2);
        Slice<Post> slice = postRepository.findFresh("en", Long.MAX_VALUE, Instant.now().plusSeconds(10), pageable);

        // then
        assertThat(slice.getContent()).hasSize(2);
        assertThat(slice.getContent().get(0).getId()).isEqualTo(p3.getId()); // Newest first
        assertThat(slice.getContent().get(1).getId()).isEqualTo(p2.getId());
        assertThat(slice.hasNext()).isTrue();

        // when: Request page 2 (using cursor from p2)
        Slice<Post> nextSlice = postRepository.findFresh("en", p2.getId(), p2.getCreatedAt(), pageable);

        // then
        assertThat(nextSlice.getContent()).hasSize(1);
        assertThat(nextSlice.getContent().get(0).getId()).isEqualTo(p1.getId());
    }

    @Test
    @DisplayName("findPopularOnly: Return posts ordered by PopularityScore DESC")
    void findPopularOnly_score() {
        // given
        // Assuming DB Schema: popularity_score is generated based on saved/comment counts.
        // We set savedCount to influence the score.
        Post pLow = createPost(Instant.now(), 0, 0);      // Low Score
        Post pHigh = createPost(Instant.now(), 20, 0);    // High Score (20 saves)
        Post pMid = createPost(Instant.now(), 10, 0);     // Mid Score (10 saves)

        // Need to refresh to get generated values from DB
        em.flush();
        em.refresh(pLow);
        em.refresh(pHigh);
        em.refresh(pMid);

        // when
        Slice<Post> slice = postRepository.findPopularOnly("en", Long.MAX_VALUE, Double.MAX_VALUE, PageRequest.of(0, 3));

        // then
        List<Post> content = slice.getContent();
        assertThat(content).hasSize(3);
        assertThat(content.get(0).getId()).isEqualTo(pHigh.getId());
        assertThat(content.get(1).getId()).isEqualTo(pMid.getId());
        assertThat(content.get(2).getId()).isEqualTo(pLow.getId());
    }

    @Test
    @DisplayName("findTrendingOnly: Orders by (comment*3 + saved*5) formula")
    void findTrendingOnly_calculation() {
        // given
        // Formula in Repository: commentCount * 3 + savedCount * 5

        // P1: 0 comments, 10 saves = 50 points
        Post p1 = createPost(Instant.now(), 10, 0);

        // P2: 20 comments, 0 saves = 60 points (Winner)
        Post p2 = createPost(Instant.now(), 0, 20);

        // P3: 0 comments, 0 saves = 0 points
        Post p3 = createPost(Instant.now(), 0, 0);

        em.flush(); // Ensure data is in DB for calculation

        // when
        Slice<Post> slice = postRepository.findTrendingOnly(
                "en",
                1000.0, // popThreshold (arbitrary high to include all)
                Instant.now().minus(7, ChronoUnit.DAYS), // afterTime
                Long.MAX_VALUE,
                Double.MAX_VALUE,
                Instant.now().plusSeconds(10),
                PageRequest.of(0, 5)
        );

        // then
        List<Post> content = slice.getContent();
        assertThat(content).hasSize(3);
        assertThat(content.get(0).getId()).isEqualTo(p2.getId()); // 60 pts
        assertThat(content.get(1).getId()).isEqualTo(p1.getId()); // 50 pts
        assertThat(content.get(2).getId()).isEqualTo(p3.getId()); // 0 pts
    }

    @Test
    @DisplayName("searchByContentNative: Filters by content ILIKE")
    void searchByContentNative() {
        // given
        createPostWithContent("This is a delicious Pasta dish.");
        createPostWithContent("I love Steak and Wine.");
        createPostWithContent("Just a random post.");

        // when
        List<Post> results = postRepository.searchByContentNative("Pasta", "en", Double.MAX_VALUE, 10);

        // then
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getContent()).contains("Pasta");
    }

    // --- Helpers ---

    private Post createPost(Instant createdAt, int savedCount, int commentCount) {
        PairingMap pairing = getOrCreatePairing();

        Post post = Post.builder()
                .pairing(pairing)
                .creator(user)
                .locale("en")
                .content("Test Content")
                .imageUrls(Collections.emptyList())
                .savedCount(savedCount)
                .commentCount(commentCount)
                .build();
        em.persist(post);

        return post;
    }

    private void createPostWithContent(String content) {
        PairingMap pairing = getOrCreatePairing();

        Post post = Post.builder()
                .pairing(pairing)
                .creator(user)
                .locale("en")
                .content(content)
                .imageUrls(Collections.emptyList())
                .build();
        em.persist(post);
        em.flush();
    }

    // [핵심 로직] 이미 존재하는 페어링이 있으면 가져오고, 없으면 생성
    private PairingMap getOrCreatePairing() {
        String jpql = "SELECT p FROM PairingMap p WHERE p.food1 = :f1 AND p.food2 = :f2 " +
                "AND p.whenContext IS NULL AND p.dietaryContext IS NULL";

        List<PairingMap> existing = em.createQuery(jpql, PairingMap.class)
                .setParameter("f1", food1)
                .setParameter("f2", food2)
                .getResultList();

        if (!existing.isEmpty()) {
            return existing.get(0);
        }

        PairingMap newPairing = PairingMap.builder()
                .food1(food1).food2(food2)
                .build();
        em.persist(newPairing);
        return newPairing;
    }
}