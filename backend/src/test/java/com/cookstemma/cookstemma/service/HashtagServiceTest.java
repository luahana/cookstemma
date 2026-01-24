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

import java.util.HashSet;
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

    private User testUser;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식", "en-US", "Test Food"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    @Nested
    @DisplayName("getPopularHashtagsByLocale()")
    class GetPopularHashtagsByLocaleTests {

        @Test
        @DisplayName("Should return empty list when no hashtags exist")
        void getPopularHashtagsByLocale_NoHashtags_ReturnsEmpty() {
            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 10, 1);

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("Should return hashtags filtered by English content")
        void getPopularHashtagsByLocale_EnglishLocale_ReturnsEnglishHashtags() {
            // Create hashtags
            Hashtag veganTag = Hashtag.builder().name("vegan").build();
            Hashtag healthyTag = Hashtag.builder().name("healthy").build();
            hashtagRepository.saveAll(List.of(veganTag, healthyTag));

            // Create recipe with English translation and hashtags
            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(veganTag);
            hashtags.add(healthyTag);

            Recipe englishRecipe = Recipe.builder()
                    .title("Vegan Salad")
                    .titleTranslations(Map.of("en-US", "Vegan Salad"))
                    .description("A healthy vegan salad")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(englishRecipe);

            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 10, 1);

            assertThat(result).hasSize(2);
            assertThat(result).extracting(HashtagWithCountDto::name)
                    .containsExactlyInAnyOrder("vegan", "healthy");
            assertThat(result.get(0).recipeCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return hashtags filtered by Korean content")
        void getPopularHashtagsByLocale_KoreanLocale_ReturnsKoreanHashtags() {
            // Create hashtags
            Hashtag koreanTag = Hashtag.builder().name("한식").build();
            Hashtag englishOnlyTag = Hashtag.builder().name("englishonly").build();
            hashtagRepository.saveAll(List.of(koreanTag, englishOnlyTag));

            // Create recipe with Korean translation
            Set<Hashtag> koreanHashtags = new HashSet<>();
            koreanHashtags.add(koreanTag);

            Recipe koreanRecipe = Recipe.builder()
                    .title("김치찌개")
                    .titleTranslations(Map.of("ko-KR", "김치찌개"))
                    .description("맛있는 김치찌개")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(koreanHashtags)
                    .build();
            recipeRepository.save(koreanRecipe);

            // Create recipe with English only translation
            Set<Hashtag> englishHashtags = new HashSet<>();
            englishHashtags.add(englishOnlyTag);

            Recipe englishRecipe = Recipe.builder()
                    .title("English Dish")
                    .titleTranslations(Map.of("en-US", "English Dish"))
                    .description("English only dish")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(englishHashtags)
                    .build();
            recipeRepository.save(englishRecipe);

            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "ko-KR", 10, 1);

            // Should only include Korean content hashtag
            assertThat(result).hasSize(1);
            assertThat(result.get(0).name()).isEqualTo("한식");
        }

        @Test
        @DisplayName("Should respect minCount parameter")
        void getPopularHashtagsByLocale_MinCount_FiltersLowCounts() {
            // Create hashtags
            Hashtag popularTag = Hashtag.builder().name("popular").build();
            Hashtag unpopularTag = Hashtag.builder().name("unpopular").build();
            hashtagRepository.saveAll(List.of(popularTag, unpopularTag));

            // Create 3 recipes with popularTag
            for (int i = 0; i < 3; i++) {
                Set<Hashtag> hashtags = new HashSet<>();
                hashtags.add(popularTag);

                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .titleTranslations(Map.of("en-US", "Recipe " + i))
                        .description("Description " + i)
                        .cookingStyle("en-US")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .hashtags(hashtags)
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 1 recipe with unpopularTag
            Set<Hashtag> unpopularHashtags = new HashSet<>();
            unpopularHashtags.add(unpopularTag);

            Recipe unpopularRecipe = Recipe.builder()
                    .title("Unpopular Recipe")
                    .titleTranslations(Map.of("en-US", "Unpopular Recipe"))
                    .description("Single recipe")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(unpopularHashtags)
                    .build();
            recipeRepository.save(unpopularRecipe);

            // With minCount=2, should only return popularTag
            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 10, 2);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).name()).isEqualTo("popular");
            assertThat(result.get(0).recipeCount()).isEqualTo(3);
        }

        @Test
        @DisplayName("Should respect limit parameter")
        void getPopularHashtagsByLocale_Limit_ReturnsLimitedResults() {
            // Create 5 hashtags with recipes
            for (int i = 0; i < 5; i++) {
                Hashtag tag = Hashtag.builder().name("tag" + i).build();
                hashtagRepository.save(tag);

                Set<Hashtag> hashtags = new HashSet<>();
                hashtags.add(tag);

                Recipe recipe = Recipe.builder()
                        .title("Recipe " + i)
                        .titleTranslations(Map.of("en-US", "Recipe " + i))
                        .description("Description")
                        .cookingStyle("en-US")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .hashtags(hashtags)
                        .build();
                recipeRepository.save(recipe);
            }

            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 3, 1);

            assertThat(result).hasSize(3);
        }

        @Test
        @DisplayName("Should not include private recipes in counts")
        void getPopularHashtagsByLocale_PrivateRecipes_ExcludedFromCounts() {
            Hashtag tag = Hashtag.builder().name("testtag").build();
            hashtagRepository.save(tag);

            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(tag);

            // Create a public recipe
            Recipe publicRecipe = Recipe.builder()
                    .title("Public Recipe")
                    .titleTranslations(Map.of("en-US", "Public Recipe"))
                    .description("Public")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(new HashSet<>(hashtags))
                    .isPrivate(false)
                    .build();
            recipeRepository.save(publicRecipe);

            // Create a private recipe
            Recipe privateRecipe = Recipe.builder()
                    .title("Private Recipe")
                    .titleTranslations(Map.of("en-US", "Private Recipe"))
                    .description("Private")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(new HashSet<>(hashtags))
                    .isPrivate(true)
                    .build();
            recipeRepository.save(privateRecipe);

            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 10, 1);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).recipeCount()).isEqualTo(1); // Only public recipe counted
        }

        @Test
        @DisplayName("Should sort by total count descending")
        void getPopularHashtagsByLocale_SortsbyTotalCount() {
            // Create hashtags with different counts
            Hashtag highCountTag = Hashtag.builder().name("highcount").build();
            Hashtag lowCountTag = Hashtag.builder().name("lowcount").build();
            hashtagRepository.saveAll(List.of(highCountTag, lowCountTag));

            // Create 3 recipes with highCountTag
            for (int i = 0; i < 3; i++) {
                Set<Hashtag> hashtags = new HashSet<>();
                hashtags.add(highCountTag);

                Recipe recipe = Recipe.builder()
                        .title("High Count Recipe " + i)
                        .titleTranslations(Map.of("en-US", "High Count Recipe " + i))
                        .description("Description")
                        .cookingStyle("en-US")
                        .foodMaster(testFood)
                        .creatorId(testUser.getId())
                        .hashtags(hashtags)
                        .build();
                recipeRepository.save(recipe);
            }

            // Create 1 recipe with lowCountTag
            Set<Hashtag> lowHashtags = new HashSet<>();
            lowHashtags.add(lowCountTag);

            Recipe lowCountRecipe = Recipe.builder()
                    .title("Low Count Recipe")
                    .titleTranslations(Map.of("en-US", "Low Count Recipe"))
                    .description("Description")
                    .cookingStyle("en-US")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(lowHashtags)
                    .build();
            recipeRepository.save(lowCountRecipe);

            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "en-US", 10, 1);

            assertThat(result).hasSize(2);
            assertThat(result.get(0).name()).isEqualTo("highcount");
            assertThat(result.get(0).totalCount()).isEqualTo(3);
            assertThat(result.get(1).name()).isEqualTo("lowcount");
            assertThat(result.get(1).totalCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should handle short locale format (e.g., 'ko')")
        void getPopularHashtagsByLocale_ShortLocale_Works() {
            Hashtag tag = Hashtag.builder().name("korean").build();
            hashtagRepository.save(tag);

            Set<Hashtag> hashtags = new HashSet<>();
            hashtags.add(tag);

            Recipe recipe = Recipe.builder()
                    .title("한글 레시피")
                    .titleTranslations(Map.of("ko-KR", "한글 레시피"))
                    .description("Korean recipe")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .hashtags(hashtags)
                    .build();
            recipeRepository.save(recipe);

            // Use short locale format
            List<HashtagWithCountDto> result = hashtagService.getPopularHashtagsByLocale(
                    "ko", 10, 1);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).name()).isEqualTo("korean");
        }
    }
}
