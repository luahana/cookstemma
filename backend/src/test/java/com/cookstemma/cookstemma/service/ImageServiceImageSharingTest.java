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
 * Integration tests for ImageService methods with focus on the join table behavior.
 * Tests the activateImages and updateRecipeImages methods for proper image sharing.
 */
@DisplayName("ImageService Image Sharing Tests")
class ImageServiceImageSharingTest extends BaseIntegrationTest {

    @Autowired
    private ImageService imageService;

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
     * Flush changes and clear persistence context to ensure fresh data from DB.
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

    private Image createTestImage() {
        Image image = Image.builder()
                .storedFilename("cover/" + UUID.randomUUID() + ".webp")
                .originalFilename("test.jpg")
                .type(ImageType.COVER)
                .status(ImageStatus.PROCESSING)
                .uploaderId(testUser.getId())
                .build();
        return imageRepository.save(image);
    }

    private Recipe createRecipe(String title) {
        Recipe recipe = Recipe.builder()
                .title(title)
                .cookingStyle("ko-KR")
                .foodMaster(testFood)
                .creatorId(testUser.getId())
                .build();
        return recipeRepository.save(recipe);
    }

    @Nested
    @DisplayName("activateImages with Join Table")
    class ActivateImagesWithJoinTable {

        @Test
        @DisplayName("Should create RecipeImage mapping in join table")
        void shouldCreateRecipeImageMappingInJoinTable() {
            // Given
            Image img = createTestImage();
            Recipe recipe = createRecipe("Test Recipe");

            // When
            imageService.activateImages(List.of(img.getPublicId()), recipe);

            // Then: Flush and clear to get fresh data from DB
            flushAndClear();
            List<RecipeImage> mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe.getId());
            assertThat(mappings).hasSize(1);
            assertThat(mappings.get(0).getImage().getId()).isEqualTo(img.getId());
        }

        @Test
        @DisplayName("Should set correct display order in mapping")
        void shouldSetCorrectDisplayOrderInMapping() {
            // Given
            Image img1 = createTestImage();
            Image img2 = createTestImage();
            Image img3 = createTestImage();
            Recipe recipe = createRecipe("Test Recipe");

            // When
            imageService.activateImages(
                    List.of(img1.getPublicId(), img2.getPublicId(), img3.getPublicId()),
                    recipe);

            // Then: Flush and clear to get fresh data from DB
            flushAndClear();
            List<RecipeImage> mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe.getId());
            assertThat(mappings).hasSize(3);
            assertThat(mappings.get(0).getDisplayOrder()).isEqualTo(0);
            assertThat(mappings.get(1).getDisplayOrder()).isEqualTo(1);
            assertThat(mappings.get(2).getDisplayOrder()).isEqualTo(2);
        }

        @Test
        @DisplayName("Should not move image from existing recipe when sharing")
        void shouldNotMoveImageFromExistingRecipe() {
            // Given: Image already linked to parent recipe
            Image img = createTestImage();
            Recipe parent = createRecipe("Parent Recipe");
            imageService.activateImages(List.of(img.getPublicId()), parent);
            flushAndClear();

            // Verify image is linked to parent via FK
            Image reloaded = imageRepository.findByPublicId(img.getPublicId()).orElseThrow();
            assertThat(reloaded.getRecipe().getId()).isEqualTo(parent.getId());

            // When: Activate same image for variant
            Recipe variant = createRecipe("Variant Recipe");
            imageService.activateImages(List.of(img.getPublicId()), variant);
            flushAndClear();

            // Then: Image's recipe_id still points to parent (not moved)
            Image finalImg = imageRepository.findByPublicId(img.getPublicId()).orElseThrow();
            assertThat(finalImg.getRecipe().getId()).isEqualTo(parent.getId());

            // And: Both recipes can access the image via join table
            Recipe reloadedParent = recipeRepository.findById(parent.getId()).orElseThrow();
            Recipe reloadedVariant = recipeRepository.findById(variant.getId()).orElseThrow();
            assertThat(recipeImageRepository.existsByRecipeAndImageId(reloadedParent, finalImg.getId())).isTrue();
            assertThat(recipeImageRepository.existsByRecipeAndImageId(reloadedVariant, finalImg.getId())).isTrue();
        }

        @Test
        @DisplayName("Should allow same image in multiple recipes")
        void shouldAllowSameImageInMultipleRecipes() {
            // Given
            Image img = createTestImage();
            Recipe recipe1 = createRecipe("Recipe 1");
            Recipe recipe2 = createRecipe("Recipe 2");
            Recipe recipe3 = createRecipe("Recipe 3");

            // When: Same image activated for all three recipes
            imageService.activateImages(List.of(img.getPublicId()), recipe1);
            flushAndClear();
            imageService.activateImages(List.of(img.getPublicId()), recipe2);
            flushAndClear();
            imageService.activateImages(List.of(img.getPublicId()), recipe3);
            flushAndClear();

            // Then: Image is linked to all three
            long count = recipeImageRepository.countByImageId(img.getId());
            assertThat(count).isEqualTo(3);
        }
    }

    @Nested
    @DisplayName("updateRecipeImages with Join Table")
    class UpdateRecipeImagesWithJoinTable {

        @Test
        @DisplayName("Should clear old mappings and create new ones")
        void shouldClearOldMappingsAndCreateNew() {
            // Given: Recipe with 2 images
            Image img1 = createTestImage();
            Image img2 = createTestImage();
            Recipe recipe = createRecipe("Test Recipe");
            imageService.activateImages(List.of(img1.getPublicId(), img2.getPublicId()), recipe);
            flushAndClear();

            // When: Update to only have img3
            Image img3 = createTestImage();
            Recipe reloadedRecipe = recipeRepository.findById(recipe.getId()).orElseThrow();
            imageService.updateRecipeImages(reloadedRecipe, List.of(img3.getPublicId()));
            flushAndClear();

            // Then: Old mappings are gone, new mapping exists
            List<RecipeImage> mappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(recipe.getId());
            assertThat(mappings).hasSize(1);
            assertThat(mappings.get(0).getImage().getId()).isEqualTo(img3.getId());
        }

        @Test
        @DisplayName("Should not orphan images used by other recipes")
        void shouldNotOrphanImagesUsedByOtherRecipes() {
            // Given: Image shared by parent and variant
            Image sharedImg = createTestImage();
            Recipe parent = createRecipe("Parent Recipe");
            imageService.activateImages(List.of(sharedImg.getPublicId()), parent);
            flushAndClear();

            Recipe variant = createRecipe("Variant Recipe");
            imageService.activateImages(List.of(sharedImg.getPublicId()), variant);
            flushAndClear();

            // Verify both have the image
            assertThat(recipeImageRepository.countByImageId(sharedImg.getId())).isEqualTo(2);

            // When: Update variant to remove the image
            Image newImg = createTestImage();
            Recipe reloadedVariant = recipeRepository.findById(variant.getId()).orElseThrow();
            imageService.updateRecipeImages(reloadedVariant, List.of(newImg.getPublicId()));
            flushAndClear();

            // Then: Image is NOT marked for garbage collection (still used by parent)
            Image reloaded = imageRepository.findByPublicId(sharedImg.getPublicId()).orElseThrow();
            assertThat(reloaded.getStatus()).isEqualTo(ImageStatus.ACTIVE);
            assertThat(reloaded.getRecipe()).isNotNull();
        }

        @Test
        @DisplayName("Should mark orphaned images for garbage collection")
        void shouldMarkOrphanedImagesForGarbageCollection() {
            // Given: Recipe with 2 images (not shared)
            Image img1 = createTestImage();
            Image img2 = createTestImage();
            Recipe recipe = createRecipe("Test Recipe");
            imageService.activateImages(List.of(img1.getPublicId(), img2.getPublicId()), recipe);
            flushAndClear();

            // When: Update to use different images
            Image newImg = createTestImage();
            Recipe reloadedRecipe = recipeRepository.findById(recipe.getId()).orElseThrow();
            imageService.updateRecipeImages(reloadedRecipe, List.of(newImg.getPublicId()));
            flushAndClear();

            // Then: Old images are orphaned (status changed, recipe_id cleared)
            Image orphaned1 = imageRepository.findByPublicId(img1.getPublicId()).orElseThrow();
            Image orphaned2 = imageRepository.findByPublicId(img2.getPublicId()).orElseThrow();

            assertThat(orphaned1.getStatus()).isEqualTo(ImageStatus.PROCESSING);
            assertThat(orphaned1.getRecipe()).isNull();
            assertThat(orphaned2.getStatus()).isEqualTo(ImageStatus.PROCESSING);
            assertThat(orphaned2.getRecipe()).isNull();
        }

        @Test
        @DisplayName("Should preserve shared image across recipes when one removes it")
        void shouldPreserveSharedImageAcrossRecipes() {
            // Given: Image shared by 3 recipes
            Image sharedImg = createTestImage();
            Recipe recipe1 = createRecipe("Recipe 1");
            Recipe recipe2 = createRecipe("Recipe 2");
            Recipe recipe3 = createRecipe("Recipe 3");

            imageService.activateImages(List.of(sharedImg.getPublicId()), recipe1);
            flushAndClear();
            imageService.activateImages(List.of(sharedImg.getPublicId()), recipe2);
            flushAndClear();
            imageService.activateImages(List.of(sharedImg.getPublicId()), recipe3);
            flushAndClear();

            // When: Recipe2 removes the image
            Image differentImg = createTestImage();
            Recipe reloadedRecipe2 = recipeRepository.findById(recipe2.getId()).orElseThrow();
            imageService.updateRecipeImages(reloadedRecipe2, List.of(differentImg.getPublicId()));
            flushAndClear();

            // Then: Image still active and linked to recipe1 & recipe3
            Image reloaded = imageRepository.findByPublicId(sharedImg.getPublicId()).orElseThrow();
            assertThat(reloaded.getStatus()).isEqualTo(ImageStatus.ACTIVE);

            // And: Join table still shows 2 recipes using the image
            Recipe reloadedRecipe1 = recipeRepository.findById(recipe1.getId()).orElseThrow();
            Recipe finalRecipe2 = recipeRepository.findById(recipe2.getId()).orElseThrow();
            Recipe reloadedRecipe3 = recipeRepository.findById(recipe3.getId()).orElseThrow();

            assertThat(recipeImageRepository.countByImageId(reloaded.getId())).isEqualTo(2);
            assertThat(recipeImageRepository.existsByRecipeAndImageId(reloadedRecipe1, reloaded.getId())).isTrue();
            assertThat(recipeImageRepository.existsByRecipeAndImageId(finalRecipe2, reloaded.getId())).isFalse();
            assertThat(recipeImageRepository.existsByRecipeAndImageId(reloadedRecipe3, reloaded.getId())).isTrue();
        }
    }
}
