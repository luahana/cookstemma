package com.cookstemma.cookstemma.service;

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
import jakarta.persistence.EntityManager;
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
 * Integration tests for Recipe.getCoverImages() method.
 * Tests the join table access and fallback to legacy images collection.
 */
@DisplayName("Recipe getCoverImages Tests")
class RecipeCoverImagesTest extends BaseIntegrationTest {

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private ImageRepository imageRepository;

    @Autowired
    private RecipeImageRepository recipeImageRepository;

    @Autowired
    private FoodMasterRepository foodMasterRepository;

    @Autowired
    private TestUserFactory testUserFactory;

    @Autowired
    private EntityManager entityManager;

    private User testUser;
    private FoodMaster testFood;

    /**
     * Helper method to flush changes and clear the persistence context
     * to ensure a fresh load from the database.
     */
    private void flushAndClear() {
        entityManager.flush();
        entityManager.clear();
    }

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    private Image createImage(ImageType type, int displayOrder) {
        Image image = Image.builder()
                .storedFilename(type.name().toLowerCase() + "/" + UUID.randomUUID() + ".webp")
                .originalFilename("test.jpg")
                .type(type)
                .status(ImageStatus.ACTIVE)
                .uploaderId(testUser.getId())
                .displayOrder(displayOrder)
                .build();
        return imageRepository.save(image);
    }

    private Recipe createRecipe() {
        Recipe recipe = Recipe.builder()
                .title("Test Recipe")
                .cookingStyle("ko-KR")
                .foodMaster(testFood)
                .creatorId(testUser.getId())
                .build();
        return recipeRepository.save(recipe);
    }

    @Nested
    @DisplayName("getCoverImages via Join Table")
    class GetCoverImagesViaJoinTable {

        @Test
        @DisplayName("Should return images from recipeImages mappings")
        void shouldReturnImagesFromRecipeImagesMappings() {
            // Given: Recipe with images via join table
            Recipe recipe = createRecipe();
            Image img1 = createImage(ImageType.COVER, 0);
            Image img2 = createImage(ImageType.COVER, 1);

            RecipeImage mapping1 = RecipeImage.of(recipe, img1, 0);
            RecipeImage mapping2 = RecipeImage.of(recipe, img2, 1);
            recipeImageRepository.saveAll(List.of(mapping1, mapping2));

            // When: Flush and clear to get fresh data from DB
            flushAndClear();
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();

            // Then: getCoverImages returns images from join table
            List<Image> coverImages = reloaded.getCoverImages();
            assertThat(coverImages).hasSize(2);
            assertThat(coverImages).extracting(Image::getId)
                    .containsExactlyInAnyOrder(img1.getId(), img2.getId());
        }

        @Test
        @DisplayName("Should return images ordered by display order")
        void shouldReturnImagesOrderedByDisplayOrder() {
            // Given: Recipe with images in non-sequential display order
            Recipe recipe = createRecipe();
            Image img1 = createImage(ImageType.COVER, 0);
            Image img2 = createImage(ImageType.COVER, 0);
            Image img3 = createImage(ImageType.COVER, 0);

            // Insert in different order than display order
            RecipeImage mapping3 = RecipeImage.of(recipe, img3, 2);
            RecipeImage mapping1 = RecipeImage.of(recipe, img1, 0);
            RecipeImage mapping2 = RecipeImage.of(recipe, img2, 1);
            recipeImageRepository.saveAll(List.of(mapping3, mapping1, mapping2));

            // When: Flush and clear to get fresh data from DB
            flushAndClear();
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();
            List<Image> coverImages = reloaded.getCoverImages();

            // Then: Images are ordered by displayOrder
            assertThat(coverImages).hasSize(3);
            assertThat(coverImages.get(0).getId()).isEqualTo(img1.getId());
            assertThat(coverImages.get(1).getId()).isEqualTo(img2.getId());
            assertThat(coverImages.get(2).getId()).isEqualTo(img3.getId());
        }

        @Test
        @DisplayName("Should return empty list when no images")
        void shouldReturnEmptyListWhenNoImages() {
            // Given: Recipe without images
            Recipe recipe = createRecipe();

            // When
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();

            // Then
            assertThat(reloaded.getCoverImages()).isEmpty();
        }
    }

    @Nested
    @DisplayName("Fallback to Legacy Images")
    class FallbackToLegacyImages {

        @Test
        @DisplayName("Should fallback to legacy images when recipeImages is empty")
        void shouldFallbackToLegacyImagesWhenRecipeImagesEmpty() {
            // Given: Recipe with legacy images (direct FK) but no join table entries
            Recipe recipe = createRecipe();
            Image img1 = createImage(ImageType.COVER, 0);
            Image img2 = createImage(ImageType.COVER, 1);

            // Set up legacy relationship (image.recipe_id points to recipe)
            img1.setRecipe(recipe);
            img2.setRecipe(recipe);
            imageRepository.saveAll(List.of(img1, img2));

            // When: Flush and clear to get fresh data from DB
            flushAndClear();
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();

            // Then: Fallback returns legacy images
            List<Image> coverImages = reloaded.getCoverImages();
            assertThat(coverImages).hasSize(2);
        }

        @Test
        @DisplayName("Should filter only COVER type in fallback")
        void shouldFilterOnlyCoverTypeInFallback() {
            // Given: Recipe with COVER and STEP images via legacy FK
            Recipe recipe = createRecipe();
            Image coverImg = createImage(ImageType.COVER, 0);
            Image stepImg = createImage(ImageType.STEP, 0);

            coverImg.setRecipe(recipe);
            stepImg.setRecipe(recipe);
            imageRepository.saveAll(List.of(coverImg, stepImg));

            // When: Flush and clear to get fresh data from DB
            flushAndClear();
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();
            List<Image> coverImages = reloaded.getCoverImages();

            // Then: Only COVER images returned
            assertThat(coverImages).hasSize(1);
            assertThat(coverImages.get(0).getType()).isEqualTo(ImageType.COVER);
        }

        @Test
        @DisplayName("Should order by display order in fallback")
        void shouldOrderByDisplayOrderInFallback() {
            // Given: Legacy images with different display orders
            Recipe recipe = createRecipe();
            Image img1 = createImage(ImageType.COVER, 2);
            Image img2 = createImage(ImageType.COVER, 0);
            Image img3 = createImage(ImageType.COVER, 1);

            img1.setRecipe(recipe);
            img2.setRecipe(recipe);
            img3.setRecipe(recipe);
            imageRepository.saveAll(List.of(img1, img2, img3));

            // When: Flush and clear to get fresh data from DB
            flushAndClear();
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();
            List<Image> coverImages = reloaded.getCoverImages();

            // Then: Ordered by displayOrder
            assertThat(coverImages).hasSize(3);
            assertThat(coverImages.get(0).getDisplayOrder()).isEqualTo(0);
            assertThat(coverImages.get(1).getDisplayOrder()).isEqualTo(1);
            assertThat(coverImages.get(2).getDisplayOrder()).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("Join Table Takes Precedence")
    class JoinTableTakesPrecedence {

        @Test
        @DisplayName("Should use join table when both exist")
        void shouldUseJoinTableWhenBothExist() {
            // Given: Recipe with both legacy images and join table entries
            Recipe recipe = createRecipe();

            // Legacy images (different from join table)
            Image legacyImg = createImage(ImageType.COVER, 0);
            legacyImg.setRecipe(recipe);
            imageRepository.save(legacyImg);

            // Join table images (different from legacy)
            Image joinTableImg = createImage(ImageType.COVER, 0);
            RecipeImage mapping = RecipeImage.of(recipe, joinTableImg, 0);
            recipeImageRepository.save(mapping);

            // When: Flush and clear to get fresh data from DB
            flushAndClear();
            Recipe reloaded = recipeRepository.findById(recipe.getId()).orElseThrow();
            List<Image> coverImages = reloaded.getCoverImages();

            // Then: Join table images are returned (only 1 image from join table)
            assertThat(coverImages).hasSize(1);
            assertThat(coverImages.get(0).getId()).isEqualTo(joinTableImg.getId());
        }
    }
}
