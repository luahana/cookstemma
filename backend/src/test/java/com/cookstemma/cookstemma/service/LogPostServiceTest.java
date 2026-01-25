package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.log_post.CreateLogRequestDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostDetailResponseDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.log_post.UpdateLogRequestDto;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LogPostServiceTest extends BaseIntegrationTest {

    @Autowired
    private LogPostService logPostService;

    @Autowired
    private LogPostRepository logPostRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private UserRepository userRepository;

    private User testUser;
    private User otherUser;
    private Recipe testRecipe;
    private LogPost testLogPost;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
        otherUser = testUserFactory.createTestUser("other_user");

        FoodMaster food = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(food);

        testRecipe = Recipe.builder()
                .title("Test Recipe")
                .description("Test Description")
                .cookingStyle("ko-KR")
                .foodMaster(food)
                .creatorId(testUser.getId())
                .build();
        recipeRepository.save(testRecipe);

        // Create a log post with RecipeLog
        testLogPost = LogPost.builder()
                .title("Test Log")
                .content("Original content")
                .locale("ko-KR")
                .creatorId(testUser.getId())
                .build();

        RecipeLog recipeLog = RecipeLog.builder()
                .logPost(testLogPost)
                .recipe(testRecipe)
                .rating(5)
                .build();
        testLogPost.setRecipeLog(recipeLog);

        logPostRepository.save(testLogPost);
    }

    @Nested
    @DisplayName("Update Log Post")
    class UpdateLogTests {

        @Test
        @DisplayName("Should update log post when user is the owner")
        void updateLog_AsOwner_Success() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars (equivalent to PARTIAL)
                    List.of("tag1", "tag2"),
                    null,
                    null  // isPrivate
            );

            LogPostDetailResponseDto result = logPostService.updateLog(
                    testLogPost.getPublicId(),
                    request,
                    testUser.getId()
            );

            assertThat(result.content()).isEqualTo("Updated content");
            assertThat(result.rating()).isEqualTo(3);

            // Verify in database
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getContent()).isEqualTo("Updated content");
            assertThat(updated.getRecipeLog().getRating()).isEqualTo(3);
        }

        @Test
        @DisplayName("Should throw AccessDeniedException when user is not the owner")
        void updateLog_NotOwner_ThrowsException() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null,
                    null  // isPrivate
            );

            assertThatThrownBy(() -> logPostService.updateLog(
                    testLogPost.getPublicId(),
                    request,
                    otherUser.getId()
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("not the owner");
        }

        @Test
        @DisplayName("Should throw exception when log post not found")
        void updateLog_NotFound_ThrowsException() {
            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "Updated Title",
                    "Updated content",
                    3,  // 3 stars
                    null,
                    null,
                    null  // isPrivate
            );

            assertThatThrownBy(() -> logPostService.updateLog(
                    java.util.UUID.randomUUID(),
                    request,
                    testUser.getId()
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not found");
        }

        @Test
        @DisplayName("Should clear hashtags when null is passed")
        void updateLog_NullHashtags_ClearsHashtags() {
            // First add some hashtags
            UpdateLogRequestDto addTagsRequest = new UpdateLogRequestDto(
                    null,
                    "Content with tags",
                    5,  // 5 stars
                    List.of("tag1", "tag2"),
                    null,
                    null  // isPrivate
            );
            logPostService.updateLog(testLogPost.getPublicId(), addTagsRequest, testUser.getId());

            // Then clear them
            UpdateLogRequestDto clearTagsRequest = new UpdateLogRequestDto(
                    null,
                    "Content without tags",
                    5,  // 5 stars
                    null,
                    null,
                    null  // isPrivate
            );
            logPostService.updateLog(testLogPost.getPublicId(), clearTagsRequest, testUser.getId());

            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getHashtags()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Delete Log Post")
    class DeleteLogTests {

        @Test
        @DisplayName("Should soft delete log post when user is the owner")
        void deleteLog_AsOwner_Success() {
            logPostService.deleteLog(testLogPost.getPublicId(), testUser.getId());

            LogPost deleted = logPostRepository.findById(testLogPost.getId()).orElseThrow();
            assertThat(deleted.isDeleted()).isTrue();
        }

        @Test
        @DisplayName("Should throw AccessDeniedException when user is not the owner")
        void deleteLog_NotOwner_ThrowsException() {
            assertThatThrownBy(() -> logPostService.deleteLog(
                    testLogPost.getPublicId(),
                    otherUser.getId()
            )).isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining("not the owner");
        }

        @Test
        @DisplayName("Should throw exception when log post not found")
        void deleteLog_NotFound_ThrowsException() {
            assertThatThrownBy(() -> logPostService.deleteLog(
                    java.util.UUID.randomUUID(),
                    testUser.getId()
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("not found");
        }
    }

    @Nested
    @DisplayName("Get Log Detail with creatorPublicId")
    class GetLogDetailTests {

        @Test
        @DisplayName("Should return creatorPublicId in response")
        void getLogDetail_ReturnsCreatorPublicId() {
            LogPostDetailResponseDto result = logPostService.getLogDetail(
                    testLogPost.getPublicId(),
                    testUser.getId()
            );

            assertThat(result.creatorPublicId()).isEqualTo(testUser.getPublicId());
        }
    }

    @Nested
    @DisplayName("Get Logs By Recipe")
    class GetLogsByRecipeTests {

        @Test
        @DisplayName("Should return logs for a specific recipe")
        void getLogsByRecipe_ReturnsLogs() {
            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(testRecipe.getPublicId(), pageable, "en");

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).publicId()).isEqualTo(testLogPost.getPublicId());
        }

        @Test
        @DisplayName("Should return empty when recipe has no logs")
        void getLogsByRecipe_NoLogs_ReturnsEmpty() {
            // Create a recipe without logs
            FoodMaster food2 = FoodMaster.builder()
                    .name(Map.of("ko-KR", "다른음식"))
                    .isVerified(true)
                    .build();
            foodMasterRepository.save(food2);

            Recipe recipeWithNoLogs = Recipe.builder()
                    .title("Recipe Without Logs")
                    .description("No logs here")
                    .cookingStyle("ko-KR")
                    .foodMaster(food2)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipeWithNoLogs);

            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(recipeWithNoLogs.getPublicId(), pageable, "en");

            assertThat(result.getContent()).isEmpty();
        }

        @Test
        @DisplayName("Should throw exception when recipe not found")
        void getLogsByRecipe_RecipeNotFound_ThrowsException() {
            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);

            assertThatThrownBy(() -> logPostService.getLogsByRecipe(
                    java.util.UUID.randomUUID(),
                    pageable,
                    "en"
            )).isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("Recipe not found");
        }

        @Test
        @DisplayName("Should not return deleted logs")
        void getLogsByRecipe_ExcludesDeletedLogs() {
            // Soft delete the log post
            testLogPost.softDelete();
            logPostRepository.save(testLogPost);

            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(testRecipe.getPublicId(), pageable, "en");

            assertThat(result.getContent()).isEmpty();
        }

        @Test
        @DisplayName("Should paginate logs correctly")
        void getLogsByRecipe_Pagination_Works() {
            // Create more logs for pagination test
            for (int i = 0; i < 5; i++) {
                LogPost log = LogPost.builder()
                        .title("Log " + i)
                        .content("Content " + i)
                        .locale("ko-KR")
                        .creatorId(testUser.getId())
                        .build();

                RecipeLog recipeLog = RecipeLog.builder()
                        .logPost(log)
                        .recipe(testRecipe)
                        .rating(5)
                        .build();
                log.setRecipeLog(recipeLog);
                logPostRepository.save(log);
            }

            // First page (size 3)
            var page1 = org.springframework.data.domain.PageRequest.of(0, 3);
            var result1 = logPostService.getLogsByRecipe(testRecipe.getPublicId(), page1, "en");

            assertThat(result1.getContent()).hasSize(3);
            assertThat(result1.hasNext()).isTrue();

            // Second page
            var page2 = org.springframework.data.domain.PageRequest.of(1, 3);
            var result2 = logPostService.getLogsByRecipe(testRecipe.getPublicId(), page2, "en");

            assertThat(result2.getContent()).hasSize(3);
            assertThat(result2.hasNext()).isFalse();
        }

        @Test
        @DisplayName("Should return logs ordered by created date descending")
        void getLogsByRecipe_OrderedByCreatedAtDesc() {
            // Create more logs with slight delay to ensure different timestamps
            LogPost newerLog = LogPost.builder()
                    .title("Newer Log")
                    .content("Newer content")
                    .locale("ko-KR")
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(newerLog)
                    .recipe(testRecipe)
                    .rating(3)
                    .build();
            newerLog.setRecipeLog(recipeLog);
            logPostRepository.save(newerLog);

            var pageable = org.springframework.data.domain.PageRequest.of(0, 20);
            var result = logPostService.getLogsByRecipe(testRecipe.getPublicId(), pageable, "en");

            assertThat(result.getContent()).hasSize(2);
            // Newer log should come first
            assertThat(result.getContent().get(0).title()).isEqualTo("Newer Log");
        }
    }

    @Nested
    @DisplayName("Get All Logs Unified - Locale Filtering")
    class GetAllLogsUnifiedLocaleTests {

        private LogPost createLogPostWithRecipeLog(String title, String content, String locale,
                                                    String originalLanguage, Map<String, String> titleTranslations) {
            LogPost log = LogPost.builder()
                    .title(title)
                    .content(content)
                    .locale(locale)
                    .originalLanguage(originalLanguage)
                    .titleTranslations(titleTranslations)
                    .creatorId(testUser.getId())
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(log)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            log.setRecipeLog(recipeLog);

            return logPostRepository.save(log);
        }

        @Test
        @DisplayName("Should return log posts with matching original_language")
        void getAllLogsUnified_OriginalLanguageMatches_ReturnsLogPost() {
            // Create Korean log post (original_language = ko-KR)
            LogPost koreanLog = createLogPostWithRecipeLog(
                    "한국어 로그", "한국어 내용", "ko-KR", "ko-KR", null);

            // Get logs for Korean locale
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko-KR");

            // Should include the Korean log post
            assertThat(result.content()).anyMatch(log ->
                    log.publicId().equals(koreanLog.getPublicId()));
        }

        @Test
        @DisplayName("Should return log posts with translations for requested locale")
        void getAllLogsUnified_HasTranslation_ReturnsLogPost() {
            // Create English log post with Korean translation
            Map<String, String> titleTranslations = new HashMap<>();
            titleTranslations.put("ko-KR", "번역된 제목");

            LogPost englishLogWithKoreanTranslation = createLogPostWithRecipeLog(
                    "English Title", "English content", "en-US", "en-US", titleTranslations);

            // Get logs for Korean locale
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko-KR");

            // Should include the English log post because it has Korean translation
            assertThat(result.content()).anyMatch(log ->
                    log.publicId().equals(englishLogWithKoreanTranslation.getPublicId()));
        }

        @Test
        @DisplayName("Should return both original and translated log posts")
        void getAllLogsUnified_BothOriginalAndTranslated_ReturnsBoth() {
            // Create Korean original log post
            LogPost koreanOriginal = createLogPostWithRecipeLog(
                    "한국어 원본", "한국어 내용", "ko-KR", "ko-KR", null);

            // Create English log post with Korean translation
            Map<String, String> titleTranslations = new HashMap<>();
            titleTranslations.put("ko-KR", "번역된 제목");

            LogPost englishWithTranslation = createLogPostWithRecipeLog(
                    "English Original", "English content", "en-US", "en-US", titleTranslations);

            // Get logs for Korean locale
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko-KR");

            // Should include both log posts
            assertThat(result.content()).anyMatch(log ->
                    log.publicId().equals(koreanOriginal.getPublicId()));
            assertThat(result.content()).anyMatch(log ->
                    log.publicId().equals(englishWithTranslation.getPublicId()));
        }

        @Test
        @DisplayName("Should not return log posts without matching locale")
        void getAllLogsUnified_NoMatchingLocale_ExcludesLogPost() {
            // Create Japanese log post (no Korean)
            LogPost japaneseLog = createLogPostWithRecipeLog(
                    "日本語ログ", "日本語の内容", "ja-JP", "ja-JP", null);

            // Get logs for Korean locale
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko-KR");

            // Should not include the Japanese log post
            assertThat(result.content()).noneMatch(log ->
                    log.publicId().equals(japaneseLog.getPublicId()));
        }

        @Test
        @DisplayName("Should work with short locale codes")
        void getAllLogsUnified_ShortLocaleCode_Works() {
            // Create Korean log post with full locale
            LogPost koreanLog = createLogPostWithRecipeLog(
                    "한국어 로그", "한국어 내용", "ko-KR", "ko-KR", null);

            // Get logs using short locale code "ko"
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko");

            // Should include the Korean log post
            assertThat(result.content()).anyMatch(log ->
                    log.publicId().equals(koreanLog.getPublicId()));
        }

        @Test
        @DisplayName("Should exclude deleted log posts")
        void getAllLogsUnified_ExcludesDeleted() {
            // Create and delete a Korean log post
            LogPost deletedLog = createLogPostWithRecipeLog(
                    "삭제된 로그", "삭제된 내용", "ko-KR", "ko-KR", null);
            deletedLog.softDelete();
            logPostRepository.save(deletedLog);

            // Get logs for Korean locale
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko-KR");

            // Should not include the deleted log post
            assertThat(result.content()).noneMatch(log ->
                    log.publicId().equals(deletedLog.getPublicId()));
        }

        @Test
        @DisplayName("Should exclude private log posts")
        void getAllLogsUnified_ExcludesPrivate() {
            // Create a private Korean log post
            LogPost privateLog = LogPost.builder()
                    .title("비공개 로그")
                    .content("비공개 내용")
                    .locale("ko-KR")
                    .originalLanguage("ko-KR")
                    .creatorId(testUser.getId())
                    .isPrivate(true)
                    .build();

            RecipeLog recipeLog = RecipeLog.builder()
                    .logPost(privateLog)
                    .recipe(testRecipe)
                    .rating(5)
                    .build();
            privateLog.setRecipeLog(recipeLog);
            logPostRepository.save(privateLog);

            // Get logs for Korean locale
            UnifiedPageResponse<LogPostSummaryDto> result = logPostService.getAllLogsUnified(
                    null, null, "recent", null, null, 20, "ko-KR");

            // Should not include the private log post
            assertThat(result.content()).noneMatch(log ->
                    log.publicId().equals(privateLog.getPublicId()));
        }
    }

    @Nested
    @DisplayName("Create Log Post - Translation Initialization")
    class CreateLogTranslationTests {

        @Test
        @DisplayName("Should initialize title translations with source language when creating log")
        void createLog_InitializesTitleTranslationsWithSourceLanguage() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    testRecipe.getPublicId(),
                    "한국어 제목",
                    "한국어 내용",
                    5,
                    null,  // hashtags
                    null,  // imagePublicIds
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(testUser);
            LogPostDetailResponseDto result = logPostService.createLog(request, principal);

            // Verify log was created
            LogPost created = logPostRepository.findByPublicId(result.publicId()).orElseThrow();

            // Verify title translations contains Korean key with original content
            assertThat(created.getTitleTranslations()).isNotNull();
            assertThat(created.getTitleTranslations()).containsKey("ko");
            assertThat(created.getTitleTranslations().get("ko")).isEqualTo("한국어 제목");
        }

        @Test
        @DisplayName("Should initialize content translations with source language when creating log")
        void createLog_InitializesContentTranslationsWithSourceLanguage() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    testRecipe.getPublicId(),
                    "한국어 제목",
                    "한국어 내용",
                    5,
                    null,  // hashtags
                    null,  // imagePublicIds
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(testUser);
            LogPostDetailResponseDto result = logPostService.createLog(request, principal);

            // Verify log was created
            LogPost created = logPostRepository.findByPublicId(result.publicId()).orElseThrow();

            // Verify content translations contains Korean key with original content
            assertThat(created.getContentTranslations()).isNotNull();
            assertThat(created.getContentTranslations()).containsKey("ko");
            assertThat(created.getContentTranslations().get("ko")).isEqualTo("한국어 내용");
        }

        @Test
        @DisplayName("Should return original content when requesting with source locale")
        void createLog_ReturnsOriginalContentForSourceLocale() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    testRecipe.getPublicId(),
                    "한국어 제목",
                    "한국어 내용",
                    5,
                    null,  // hashtags
                    null,  // imagePublicIds
                    false  // isPrivate
            );

            UserPrincipal principal = new UserPrincipal(testUser);
            LogPostDetailResponseDto result = logPostService.createLog(request, principal);

            // Get log detail with Korean locale
            LogPostDetailResponseDto detail = logPostService.getLogDetail(
                    result.publicId(), testUser.getId(), "ko-KR");

            // Should return Korean content (not fall back to English)
            assertThat(detail.title()).isEqualTo("한국어 제목");
            assertThat(detail.content()).isEqualTo("한국어 내용");
        }

        @Test
        @DisplayName("Should handle null content gracefully")
        void createLog_HandlesNullContent() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            CreateLogRequestDto request = new CreateLogRequestDto(
                    testRecipe.getPublicId(),
                    "한국어 제목",
                    null,  // null content
                    5,
                    null,
                    null,
                    false
            );

            UserPrincipal principal = new UserPrincipal(testUser);
            LogPostDetailResponseDto result = logPostService.createLog(request, principal);

            // Verify log was created
            LogPost created = logPostRepository.findByPublicId(result.publicId()).orElseThrow();

            // Title translations should be initialized
            assertThat(created.getTitleTranslations()).isNotNull();
            assertThat(created.getTitleTranslations()).containsKey("ko");

            // Content translations should be empty (not contain null value)
            assertThat(created.getContentTranslations()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Update Log Post - Translation Updates")
    class UpdateLogTranslationTests {

        @Test
        @DisplayName("Should update title translations when updating log")
        void updateLog_UpdatesTitleTranslations() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            // Initialize test log with Korean translations
            Map<String, String> initialTitleTranslations = new HashMap<>();
            initialTitleTranslations.put("ko", "원래 제목");
            testLogPost.setTitleTranslations(initialTitleTranslations);
            testLogPost.setOriginalLanguage("ko-KR");
            logPostRepository.save(testLogPost);

            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "수정된 제목",  // Updated Korean title
                    "수정된 내용",
                    5,
                    null,
                    null,
                    null
            );

            logPostService.updateLog(testLogPost.getPublicId(), request, testUser.getId());

            // Verify title translations was updated
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getTitleTranslations().get("ko")).isEqualTo("수정된 제목");
        }

        @Test
        @DisplayName("Should update content translations when updating log")
        void updateLog_UpdatesContentTranslations() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            // Initialize test log with Korean translations
            Map<String, String> initialContentTranslations = new HashMap<>();
            initialContentTranslations.put("ko", "원래 내용");
            testLogPost.setContentTranslations(initialContentTranslations);
            testLogPost.setOriginalLanguage("ko-KR");
            logPostRepository.save(testLogPost);

            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    null,
                    "수정된 내용",  // Updated Korean content
                    5,
                    null,
                    null,
                    null
            );

            logPostService.updateLog(testLogPost.getPublicId(), request, testUser.getId());

            // Verify content translations was updated
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getContentTranslations().get("ko")).isEqualTo("수정된 내용");
        }

        @Test
        @DisplayName("Should initialize translations map if null when updating")
        void updateLog_InitializesTranslationsMapIfNull() {
            // Set user locale to Korean
            testUser.setLocale("ko-KR");
            userRepository.save(testUser);

            // Ensure translations are null
            testLogPost.setTitleTranslations(null);
            testLogPost.setContentTranslations(null);
            logPostRepository.save(testLogPost);

            UpdateLogRequestDto request = new UpdateLogRequestDto(
                    "수정된 제목",
                    "수정된 내용",
                    5,
                    null,
                    null,
                    null
            );

            logPostService.updateLog(testLogPost.getPublicId(), request, testUser.getId());

            // Verify translations were initialized and populated
            LogPost updated = logPostRepository.findByPublicId(testLogPost.getPublicId()).orElseThrow();
            assertThat(updated.getTitleTranslations()).isNotNull();
            assertThat(updated.getTitleTranslations().get("ko")).isEqualTo("수정된 제목");
            assertThat(updated.getContentTranslations()).isNotNull();
            assertThat(updated.getContentTranslations().get("ko")).isEqualTo("수정된 내용");
        }
    }
}
