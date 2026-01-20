package com.cookstemma.cookstemma.repository;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.image.RecipeImage;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.image.RecipeImageRepository;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Integration tests for RecipeImageRepository methods.
 * Tests the join table operations for the recipe-image many-to-many relationship.
 */
@DisplayName("RecipeImage Repository Tests")
class RecipeImageRepositoryTest extends BaseIntegrationTest {

    @Autowired
    private RecipeImageRepository recipeImageRepository;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    private User testUser;
    private FoodMaster testFood;
    private Recipe recipe1;
    private Recipe recipe2;
    private Image image1;
    private Image image2;
    private Image image3;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);

        // Create test recipes
        recipe1 = Recipe.builder()
                .title("Recipe 1")
                .cookingStyle("ko-KR")
                .foodMaster(testFood)
                .creatorId(testUser.getId())
                .build();
        recipeRepository.save(recipe1);

        recipe2 = Recipe.builder()
                .title("Recipe 2")
                .cookingStyle("ko-KR")
                .foodMaster(testFood)
                .creatorId(testUser.getId())
                .parentRecipe(recipe1) // variant of recipe1
                .rootRecipe(recipe1)
                .build();
        recipeRepository.save(recipe2);

        // Create test images
        image1 = createTestImage("img1.webp");
        image2 = createTestImage("img2.webp");
        image3 = createTestImage("img3.webp");
    }

    private Image createTestImage(String filename) {
        Image image = Image.builder()
                .storedFilename("cover/" + filename)
                .originalFilename(filename)
                .type(ImageType.COVER)
                .status(ImageStatus.ACTIVE)
                .uploaderId(testUser.getId())
                .build();
        return imageRepository.save(image);
    }

    private RecipeImage createMapping(Recipe recipe, Image image, int displayOrder) {
        RecipeImage mapping = RecipeImage.of(recipe, image, displayOrder);
        return recipeImageRepository.save(mapping);
    }

    @Nested
    @DisplayName("Find Operations")
    class FindOperations {

        @Test
        @DisplayName("findByRecipeOrderByDisplayOrderAsc returns images ordered by display order")
        void findByRecipeOrderByDisplayOrderAsc_returnsOrderedImages() {
            // Given: Recipe with images in non-sequential order
            createMapping(recipe1, image2, 1);
            createMapping(recipe1, image1, 0);
            createMapping(recipe1, image3, 2);

            // When
            List<RecipeImage> result = recipeImageRepository.findByRecipeOrderByDisplayOrderAsc(recipe1);

            // Then: Results are ordered by displayOrder
            assertThat(result).hasSize(3);
            assertThat(result.get(0).getImage().getId()).isEqualTo(image1.getId());
            assertThat(result.get(1).getImage().getId()).isEqualTo(image2.getId());
            assertThat(result.get(2).getImage().getId()).isEqualTo(image3.getId());
        }

        @Test
        @DisplayName("findByRecipeIdOrderByDisplayOrderAsc returns images ordered by display order")
        void findByRecipeIdOrderByDisplayOrderAsc_returnsOrderedImages() {
            // Given
            createMapping(recipe1, image3, 2);
            createMapping(recipe1, image1, 0);
            createMapping(recipe1, image2, 1);

            // When
            List<RecipeImage> result = recipeImageRepository.findByRecipeIdOrderByDisplayOrderAsc(recipe1.getId());

            // Then
            assertThat(result).hasSize(3);
            assertThat(result.get(0).getDisplayOrder()).isEqualTo(0);
            assertThat(result.get(1).getDisplayOrder()).isEqualTo(1);
            assertThat(result.get(2).getDisplayOrder()).isEqualTo(2);
        }

        @Test
        @DisplayName("findByImagePublicId returns all mappings for an image")
        void findByImagePublicId_returnsAllMappings() {
            // Given: Same image used in two recipes
            createMapping(recipe1, image1, 0);
            createMapping(recipe2, image1, 0);

            // When
            List<RecipeImage> result = recipeImageRepository.findByImagePublicId(image1.getPublicId());

            // Then
            assertThat(result).hasSize(2);
        }
    }

    @Nested
    @DisplayName("Delete Operations")
    class DeleteOperations {

        @Test
        @DisplayName("deleteByRecipe removes all mappings for a recipe")
        void deleteByRecipe_removesAllMappingsForRecipe() {
            // Given: Recipe1 has 2 images
            createMapping(recipe1, image1, 0);
            createMapping(recipe1, image2, 1);
            createMapping(recipe2, image1, 0); // Recipe2 also has image1

            // When
            recipeImageRepository.deleteByRecipe(recipe1);

            // Then: Recipe1 mappings are deleted
            List<RecipeImage> recipe1Mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe1.getId());
            assertThat(recipe1Mappings).isEmpty();

            // And: Recipe2 mappings are not affected
            List<RecipeImage> recipe2Mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe2.getId());
            assertThat(recipe2Mappings).hasSize(1);
        }

        @Test
        @DisplayName("deleteByRecipeId removes all mappings for a recipe")
        void deleteByRecipeId_removesAllMappingsForRecipe() {
            // Given
            createMapping(recipe1, image1, 0);
            createMapping(recipe1, image2, 1);

            // When
            recipeImageRepository.deleteByRecipeId(recipe1.getId());

            // Then
            List<RecipeImage> mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe1.getId());
            assertThat(mappings).isEmpty();
        }

        @Test
        @DisplayName("deleteByRecipe does not affect other recipe mappings")
        void deleteByRecipe_doesNotAffectOtherRecipeMappings() {
            // Given: Shared image between two recipes
            createMapping(recipe1, image1, 0);
            createMapping(recipe2, image1, 0);
            createMapping(recipe2, image2, 1);

            // When: Delete recipe1 mappings
            recipeImageRepository.deleteByRecipe(recipe1);

            // Then: Recipe2 still has its mappings
            List<RecipeImage> recipe2Mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe2.getId());
            assertThat(recipe2Mappings).hasSize(2);
        }
    }

    @Nested
    @DisplayName("Existence Checks")
    class ExistenceChecks {

        @Test
        @DisplayName("existsByRecipeAndImageId returns true when mapping exists")
        void existsByRecipeAndImageId_returnsTrueWhenExists() {
            // Given
            createMapping(recipe1, image1, 0);

            // When/Then
            assertThat(recipeImageRepository.existsByRecipeAndImageId(recipe1, image1.getId())).isTrue();
        }

        @Test
        @DisplayName("existsByRecipeAndImageId returns false when mapping does not exist")
        void existsByRecipeAndImageId_returnsFalseWhenNotExists() {
            // Given: No mapping created

            // When/Then
            assertThat(recipeImageRepository.existsByRecipeAndImageId(recipe1, image1.getId())).isFalse();
        }

        @Test
        @DisplayName("existsByImageId returns true when image is used by any recipe")
        void existsByImageId_returnsTrueWhenImageUsedByAnyRecipe() {
            // Given
            createMapping(recipe1, image1, 0);

            // When/Then
            assertThat(recipeImageRepository.existsByImageId(image1.getId())).isTrue();
        }

        @Test
        @DisplayName("existsByImageId returns false when image is not used")
        void existsByImageId_returnsFalseWhenImageNotUsed() {
            // Given: No mappings for image1

            // When/Then
            assertThat(recipeImageRepository.existsByImageId(image1.getId())).isFalse();
        }
    }

    @Nested
    @DisplayName("Count and Query Operations")
    class CountAndQueryOperations {

        @Test
        @DisplayName("countByImageId returns correct count")
        void countByImageId_returnsCorrectCount() {
            // Given: Image1 used by 2 recipes
            createMapping(recipe1, image1, 0);
            createMapping(recipe2, image1, 0);

            // When
            long count = recipeImageRepository.countByImageId(image1.getId());

            // Then
            assertThat(count).isEqualTo(2);
        }

        @Test
        @DisplayName("countByImageId returns 0 for unused image")
        void countByImageId_returnsZeroForUnusedImage() {
            // Given: No mappings

            // When
            long count = recipeImageRepository.countByImageId(image1.getId());

            // Then
            assertThat(count).isZero();
        }

        @Test
        @DisplayName("findRecipesByImageId returns all recipes using an image")
        void findRecipesByImageId_returnsAllRecipesUsingImage() {
            // Given: Image1 used by both recipes
            createMapping(recipe1, image1, 0);
            createMapping(recipe2, image1, 0);

            // When
            List<Recipe> recipes = recipeImageRepository.findRecipesByImageId(image1.getId());

            // Then
            assertThat(recipes).hasSize(2);
            assertThat(recipes).extracting(Recipe::getId)
                    .containsExactlyInAnyOrder(recipe1.getId(), recipe2.getId());
        }

        @Test
        @DisplayName("findRecipesByImageId returns empty list for unused image")
        void findRecipesByImageId_returnsEmptyListForUnusedImage() {
            // Given: No mappings

            // When
            List<Recipe> recipes = recipeImageRepository.findRecipesByImageId(image1.getId());

            // Then
            assertThat(recipes).isEmpty();
        }
    }
}
