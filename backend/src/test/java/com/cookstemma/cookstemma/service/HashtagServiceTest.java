package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.dto.hashtag.HashtagWithCountDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.support.BaseIntegrationTest;
import com.cookstemma.cookstemma.support.TestUserFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class HashtagServiceTest extends BaseIntegrationTest {

    @Autowired
    private HashtagService hashtagService;

    @Autowired
    private HashtagRepository hashtagRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User koreanUser;
    private User englishUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        koreanUser = testUserFactory.createTestUser("korean_user", "ko-KR");
        englishUser = testUserFactory.createTestUser("english_user", "en-US");

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("Get Popular Hashtags by Locale")
    class GetPopularHashtagsByLocaleTests {

        @Test
        @DisplayName("Should return only Korean hashtags for Korean locale")
        void getPopularHashtags_KoreanLocale_ReturnsOnlyKoreanHashtags() {
            // Create Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Create English recipe with English hashtag
            Hashtag englishHashtag = Hashtag.builder().name("vegan").build();
            hashtagRepository.save(englishHashtag);

            Recipe englishRecipe = Recipe.builder()
                    .title("Vegan Salad")
                    .description("Healthy vegan salad")
                    .cookingStyle("en-US")
                    .originalLanguage("en-US")
                    .foodMaster(testFood)
                    .creatorId(englishUser.getId())
                    .hashtags(Set.of(englishHashtag))
                    .build();
            recipeRepository.save(englishRecipe);

            // Get popular hashtags for Korean locale
            List<HashtagWithCountDto> koreanHashtags = hashtagService.getPopularHashtagsByLocale(
                    "ko-KR", 10, 1);

            // Verify only Korean hashtag is returned
            assertThat(koreanHashtags).hasSize(1);
            assertThat(koreanHashtags.get(0).name()).isEqualTo("한식");
            assertThat(koreanHashtags.get(0).recipeCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return only English hashtags for English locale")
        void getPopularHashtags_EnglishLocale_ReturnsOnlyEnglishHashtags() {
            // Create Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Create English recipe with English hashtag
            Hashtag englishHashtag = Hashtag.builder().name("vegan").build();
            hashtagRepository.save(englishHashtag);

            Recipe englishRecipe = Recipe.builder()
                    .title("Vegan Salad")
                    .description("Healthy vegan salad")
                    .cookingStyle("en-US")
                    .originalLanguage("en-US")
                    .foodMaster(testFood)
                    .creatorId(englishUser.getId())
                    .hashtags(Set.of(englishHashtag))
                    .build();
            recipeRepository.save(englishRecipe);

            // Get popular hashtags for English locale
            List<HashtagWithCountDto> englishHashtags = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 10, 1);

            // Verify only English hashtag is returned
            assertThat(englishHashtags).hasSize(1);
            assertThat(englishHashtags.get(0).name()).isEqualTo("vegan");
            assertThat(englishHashtags.get(0).recipeCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return empty list when no hashtags for locale")
        void getPopularHashtags_NoHashtagsForLocale_ReturnsEmptyList() {
            // Create only Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Get popular hashtags for Japanese locale (no content exists)
            List<HashtagWithCountDto> japaneseHashtags = hashtagService.getPopularHashtagsByLocale(
                    "ja-JP", 10, 1);

            // Verify empty list is returned
            assertThat(japaneseHashtags).isEmpty();
        }

        @Test
        @DisplayName("Should sort hashtags by total count descending")
        void getPopularHashtags_MultipleHashtags_SortedByCountDescending() {
            // Create hashtags
            Hashtag popularHashtag = Hashtag.builder().name("인기").build();
            Hashtag lessPopularHashtag = Hashtag.builder().name("덜인기").build();
            hashtagRepository.saveAll(List.of(popularHashtag, lessPopularHashtag));

            // Create 3 recipes with popular hashtag
            for (int i = 0; i < 3; i++) {
                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .description("Description " + i)
                        .cookingStyle("ko-KR")
                        .originalLanguage("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(koreanUser.getId())
                        .hashtags(Set.of(popularHashtag))
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 1 recipe with less popular hashtag
            Recipe lessPopularRecipe = Recipe.builder()
                    .title("Less Popular Recipe")
                    .description("Description")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(lessPopularHashtag))
                    .build();
            recipeRepository.save(lessPopularRecipe);

            // Get popular hashtags
            List<HashtagWithCountDto> hashtags = hashtagService.getPopularHashtagsByLocale(
                    "ko-KR", 10, 1);

            // Verify sorted by count descending
            assertThat(hashtags).hasSize(2);
            assertThat(hashtags.get(0).name()).isEqualTo("인기");
            assertThat(hashtags.get(0).recipeCount()).isEqualTo(3);
            assertThat(hashtags.get(1).name()).isEqualTo("덜인기");
            assertThat(hashtags.get(1).recipeCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should respect limit parameter")
        void getPopularHashtags_WithLimit_RespectsLimit() {
            // Create 5 hashtags with recipes
            for (int i = 0; i < 5; i++) {
                Hashtag hashtag = Hashtag.builder().name("태그" + i).build();
                hashtagRepository.save(hashtag);

                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .description("Description " + i)
                        .cookingStyle("ko-KR")
                        .originalLanguage("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(koreanUser.getId())
                        .hashtags(Set.of(hashtag))
                        .build();
                recipeRepository.save(recipe);
            }

            // Get popular hashtags with limit 3
            List<HashtagWithCountDto> hashtags = hashtagService.getPopularHashtagsByLocale(
                    "ko-KR", 3, 1);

            // Verify only 3 hashtags returned
            assertThat(hashtags).hasSize(3);
        }

        @Test
        @DisplayName("Should respect minCount parameter")
        void getPopularHashtags_WithMinCount_FiltersLowCountHashtags() {
            // Create hashtag with 1 recipe
            Hashtag lowCountHashtag = Hashtag.builder().name("적은").build();
            hashtagRepository.save(lowCountHashtag);

            Recipe lowCountRecipe = Recipe.builder()
                    .title("Low count recipe")
                    .description("Description")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(lowCountHashtag))
                    .build();
            recipeRepository.save(lowCountRecipe);

            // Create hashtag with 3 recipes
            Hashtag highCountHashtag = Hashtag.builder().name("많은").build();
            hashtagRepository.save(highCountHashtag);

            for (int i = 0; i < 3; i++) {
                Recipe recipe = Recipe.builder()
                        .title("High count recipe " + i)
                        .description("Description " + i)
                        .cookingStyle("ko-KR")
                        .originalLanguage("ko-KR")
                        .foodMaster(testFood)
                        .creatorId(koreanUser.getId())
                        .hashtags(Set.of(highCountHashtag))
                        .build();
                recipeRepository.save(recipe);
            }

            // Get popular hashtags with minCount 2
            List<HashtagWithCountDto> hashtags = hashtagService.getPopularHashtagsByLocale(
                    "ko-KR", 10, 2);

            // Verify only high count hashtag is returned
            assertThat(hashtags).hasSize(1);
            assertThat(hashtags.get(0).name()).isEqualTo("많은");
        }

        @Test
        @DisplayName("Should handle short locale codes like 'ko' or 'en'")
        void getPopularHashtags_ShortLocaleCode_Works() {
            // Create Korean recipe with Korean hashtag
            Hashtag koreanHashtag = Hashtag.builder().name("한식").build();
            hashtagRepository.save(koreanHashtag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .originalLanguage("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(koreanUser.getId())
                    .hashtags(Set.of(koreanHashtag))
                    .build();
            recipeRepository.save(koreanRecipe);

            // Get popular hashtags using short locale code "ko"
            List<HashtagWithCountDto> hashtags = hashtagService.getPopularHashtagsByLocale(
                    "ko", 10, 1);

            // Verify Korean hashtag is returned
            assertThat(hashtags).hasSize(1);
            assertThat(hashtags.get(0).name()).isEqualTo("한식");
        }
    }
}
