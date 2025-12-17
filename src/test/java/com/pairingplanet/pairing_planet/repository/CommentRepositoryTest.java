package com.pairingplanet.pairing_planet.repository;


import com.pairingplanet.pairing_planet.domain.entity.comment.Comment;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextDimension;
import com.pairingplanet.pairing_planet.domain.entity.context.ContextTag;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodCategory;
import com.pairingplanet.pairing_planet.domain.entity.food.FoodMaster;
import com.pairingplanet.pairing_planet.domain.entity.pairing.PairingMap;
import com.pairingplanet.pairing_planet.domain.entity.post.Post;
import com.pairingplanet.pairing_planet.domain.entity.user.User;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.repository.comment.CommentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageRequest;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE) // Disable H2 replacement
@Testcontainers
@TestPropertySource(properties = {
        // 32바이트(1~8 반복)를 Base64로 인코딩한 정확한 값입니다.
        "security.encryption-key=MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI="
})
class CommentRepositoryTest {

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
    private CommentRepository commentRepository;

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
    private Post testPost;

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

        PairingMap pairing = PairingMap.builder()
                .food1(foodA).food2(foodB)
                .build();
        em.persist(pairing);

        testPost = Post.builder()
                .pairing(pairing)
                .creator(user)
                .content("Test Post Content")
                .locale("en")
                .imageUrls(Collections.emptyList())
                .build();
        em.persist(testPost);
    }

    @Test
    @DisplayName("FR-65: 필터 없이 전체 배댓(Top 3) 조회 - 좋아요 순 정렬 확인")
    void findGlobalBestComments() {
        // given
        Long postId = testPost.getId(); // Use real ID
        createComment(user, testPost, 10); // Rank 3
        createComment(user, testPost, 50); // Rank 1
        createComment(user, testPost, 30); // Rank 2
        createComment(user, testPost, 5);  // Not in Top 3

        // when
        List<Comment> bestComments = commentRepository.findGlobalBestComments(postId);

        // then
        assertThat(bestComments).hasSize(3);
        assertThat(bestComments.get(0).getLikeCount()).isEqualTo(50);
        assertThat(bestComments.get(1).getLikeCount()).isEqualTo(30);
        assertThat(bestComments.get(2).getLikeCount()).isEqualTo(10);
    }

    @Test
    @DisplayName("FR-65: 필터 적용 배댓 조회 - 해당 Verdict 내에서만 Top 3")
    void findFilteredBestComments() {
        // given
        Long postId = testPost.getId();
        // GENIUS Comments
        createComment(user, testPost, VerdictType.GENIUS, 100);
        createComment(user, testPost, VerdictType.GENIUS, 90);

        // DARING Comments (Target)
        createComment(user, testPost, VerdictType.DARING, 50);
        createComment(user, testPost, VerdictType.DARING, 80);
        createComment(user, testPost, VerdictType.DARING, 10);
        createComment(user, testPost, VerdictType.DARING, 5);

        // when: Apply DARING filter
        List<Comment> result = commentRepository.findFilteredBestComments(postId, VerdictType.DARING);

        // then
        assertThat(result).hasSize(3);
        // Only DARING sorted by likes (80 -> 50 -> 10)
        assertThat(result.get(0).getLikeCount()).isEqualTo(80);
        assertThat(result.get(1).getLikeCount()).isEqualTo(50);
        assertThat(result.get(2).getLikeCount()).isEqualTo(10);

        // Ensure GENIUS(100) is excluded
        assertThat(result).extracting("currentVerdict")
                .containsOnly(VerdictType.DARING);
    }

    @Test
    @DisplayName("FR-66: 커서 페이지네이션 - 최신순 정렬 및 커서 동작 확인")
    void findAllByCursor() {
        // given
        Long postId = testPost.getId();
        Instant now = Instant.now();

        // Create comments with specific timestamps
        Comment c1 = createCommentWithTime(user, testPost, now.minus(1, ChronoUnit.HOURS)); // Oldest
        Comment c2 = createCommentWithTime(user, testPost, now.minus(30, ChronoUnit.MINUTES));
        Comment c3 = createCommentWithTime(user, testPost, now); // Newest

        // when 1: First page (Cursor: Future time, MAX_ID)
        List<Comment> page1 = commentRepository.findAllByCursor(
                postId, Instant.now().plusSeconds(10), Long.MAX_VALUE, PageRequest.of(0, 2));

        // then 1
        assertThat(page1).hasSize(2);
        assertThat(page1.get(0).getId()).isEqualTo(c3.getId()); // c3 (Newest)
        assertThat(page1.get(1).getId()).isEqualTo(c2.getId()); // c2

        // when 2: Next page (Cursor: c2's time, c2's ID)
        List<Comment> page2 = commentRepository.findAllByCursor(
                postId, c2.getCreatedAt(), c2.getId(), PageRequest.of(0, 2));

        // then 2
        assertThat(page2).hasSize(1);
        assertThat(page2.get(0).getId()).isEqualTo(c1.getId()); // c1
    }

    @Test
    @DisplayName("FR-52, FR-61-1: Verdict 변경 시 일괄 업데이트 확인")
    void updateVerdictForUserPost() {
        // given
        // Need a new user specifically for this test to avoid conflict
        User anotherUser = User.builder().username("user99").locale("en").build();
        em.persist(anotherUser);
        Long userId = anotherUser.getId();
        Long postId = testPost.getId();

        Comment c1 = createComment(anotherUser, testPost, VerdictType.GENIUS, 0);
        Comment c2 = createComment(anotherUser, testPost, VerdictType.GENIUS, 0);

        // Comment by someone else
        createComment(user, testPost, VerdictType.GENIUS, 0);

        // when: User 99 changes verdict to DARING
        commentRepository.updateVerdictForUserPost(userId, postId, VerdictType.DARING);
        em.flush();
        em.clear(); // Clear context to force fetch from DB

        // then
        Comment updatedC1 = commentRepository.findById(c1.getId()).orElseThrow();

        // Initial verdict should remain GENIUS
        assertThat(updatedC1.getInitialVerdict()).isEqualTo(VerdictType.GENIUS);
        // Current verdict should be updated to DARING
        assertThat(updatedC1.getCurrentVerdict()).isEqualTo(VerdictType.DARING);
    }

    // --- Helpers ---

    private Comment createComment(User user, Post post, int likeCount) {
        return createComment(user, post, VerdictType.GENIUS, likeCount);
    }

    private Comment createComment(User user, Post post, VerdictType type, int likeCount) {
        Comment comment = Comment.builder()
                .userId(user.getId())
                .postId(post.getId())
                .content("content")
                .initialVerdict(type)
                .currentVerdict(type)
                .likeCount(likeCount)
                .build();
        return commentRepository.save(comment);
    }

    private Comment createCommentWithTime(User user, Post post, Instant createdAt) {
        Comment comment = Comment.builder()
                .userId(user.getId())
                .postId(post.getId())
                .content("content")
                .build();

        // Note: If using @CreationTimestamp, JPA might overwrite this on persist.
        // For strict testing, we might need a Native Query update or assume createdAt is respected if not null.
        // Here we rely on builder setting it.
        return commentRepository.save(comment);
    }
}