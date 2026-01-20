package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.image.RecipeImage;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.recipe.CreateRecipeRequestDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeDetailResponseDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.repository.image.RecipeImageRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
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
 * Integration tests for Recipe Image Sharing via join table.
 * Verifies that variant recipes can share images with parent recipes
 * without "stealing" them (moving the FK to the variant).
 */
@DisplayName("Recipe Image Sharing Tests")
class RecipeImageSharingTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

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

    private User testUser;
    private UserPrincipal principal;
    private FoodMaster testFood;

    @BeforeEach
    void setUp() {
        testUser = testUserFactory.createTestUser();
        principal = new UserPrincipal(testUser);

        testFood = FoodMaster.builder()
                .name(Map.of("ko-KR", "테스트음식"))
                .isVerified(true)
                .build();
        foodMasterRepository.save(testFood);
    }

    private Image createTestImage(ImageType type) {
        Image image = Image.builder()
                .storedFilename(type.name().toLowerCase() + "/" + UUID.randomUUID() + ".webp")
                .originalFilename("test.jpg")
                .type(type)
                .status(ImageStatus.PROCESSING)
                .uploaderId(testUser.getId())
                .build();
        return imageRepository.save(image);
    }

    private CreateRecipeRequestDto createRecipeRequest(String title, List<UUID> imagePublicIds) {
        return new CreateRecipeRequestDto(
                title,
                "Test Description",
                "ko-KR",
                testFood.getPublicId(),
                null, // newFoodName
                List.of(), // ingredients (empty for test simplicity)
                List.of(), // steps (empty for test simplicity)
                imagePublicIds,
                null, // changeCategory
                null, // parentPublicId
                null, // rootPublicId
                null, // changeDiff
                null, // changeReason
                List.of(), // hashtags
                2, // servings
                "MIN_30_TO_60" // cookingTimeRange
        );
    }

    private CreateRecipeRequestDto createVariantRequest(String title, UUID parentPublicId,
            List<UUID> imagePublicIds) {
        return new CreateRecipeRequestDto(
                title,
                "Variant Description",
                "ko-KR",
                testFood.getPublicId(),
                null,
                List.of(), // ingredients (empty for test simplicity)
                List.of(), // steps (empty for test simplicity)
                imagePublicIds,
                "ingredients", // changeCategory
                parentPublicId, // parentPublicId - makes it a variant
                null, // rootPublicId
                null,
                "테스트 변형",
                List.of(),
                2,
                "MIN_30_TO_60"
        );
    }

    @Nested
    @DisplayName("Variant Recipe Image Inheritance")
    class VariantRecipeImageInheritance {

        @Test
        @DisplayName("Should share images when creating variant with parent's images")
        void shouldShareImagesWhenCreatingVariant() {
            // Given: Parent recipe with 2 images
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId(), img2.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant using same images
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img1.getPublicId(), img2.getPublicId()));
            RecipeDetailResponseDto variantDetail = recipeService.createRecipe(variantRequest, principal);

            // Then: Both recipes have the images
            assertThat(parentDetail.images()).hasSize(2);
            assertThat(variantDetail.images()).hasSize(2);
        }

        @Test
        @DisplayName("Parent recipe should keep images after variant is created")
        void parentRecipeShouldKeepImagesAfterVariantCreated() {
            // Given: Parent recipe with 2 images
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId(), img2.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant using same images
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img1.getPublicId(), img2.getPublicId()));
            recipeService.createRecipe(variantRequest, principal);

            // Then: Reload parent and verify images are still there
            RecipeDetailResponseDto reloadedParent = recipeService.getRecipeDetail(
                    parentDetail.publicId(), testUser.getId());

            assertThat(reloadedParent.images()).hasSize(2);
            assertThat(reloadedParent.images().stream().map(img -> img.imagePublicId()))
                    .containsExactlyInAnyOrder(img1.getPublicId(), img2.getPublicId());
        }

        @Test
        @DisplayName("Both parent and variant should show the same images")
        void bothParentAndVariantShouldShowSameImages() {
            // Given: Parent with image
            Image img1 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant with parent's image
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto variantDetail = recipeService.createRecipe(variantRequest, principal);

            // Then: Both show the same image
            assertThat(parentDetail.images()).hasSize(1);
            assertThat(variantDetail.images()).hasSize(1);
            assertThat(parentDetail.images().get(0).imagePublicId())
                    .isEqualTo(variantDetail.images().get(0).imagePublicId());
        }
    }

    @Nested
    @DisplayName("Image Sharing via Join Table")
    class ImageSharingViaJoinTable {

        @Test
        @DisplayName("Should create recipe-image mappings for both recipes")
        void shouldCreateRecipeImageMappingsForBothRecipes() {
            // Given: Parent recipe with image
            Image img1 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant with same image
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto variantDetail = recipeService.createRecipe(variantRequest, principal);

            // Then: Join table has entries for both recipes
            Recipe parent = recipeRepository.findByPublicId(parentDetail.publicId()).orElseThrow();
            Recipe variant = recipeRepository.findByPublicId(variantDetail.publicId()).orElseThrow();

            List<RecipeImage> parentMappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(parent.getId());
            List<RecipeImage> variantMappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(variant.getId());

            assertThat(parentMappings).hasSize(1);
            assertThat(variantMappings).hasSize(1);
            // Both mappings point to the same image
            assertThat(parentMappings.get(0).getImage().getId())
                    .isEqualTo(variantMappings.get(0).getImage().getId());
        }

        @Test
        @DisplayName("Same image should appear in multiple recipes' mappings")
        void sameImageShouldAppearInMultipleRecipesMappings() {
            // Given: Image used by parent
            Image img1 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Same image used by variant
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img1.getPublicId()));
            recipeService.createRecipe(variantRequest, principal);

            // Then: Image is linked to both via join table
            long recipesUsingImage = recipeImageRepository.countByImageId(img1.getId());
            assertThat(recipesUsingImage).isEqualTo(2);

            List<Recipe> recipes = recipeImageRepository.findRecipesByImageId(img1.getId());
            assertThat(recipes).hasSize(2);
        }

        @Test
        @DisplayName("Deleting variant should not affect parent images")
        void deletingVariantShouldNotAffectParentImages() {
            // Given: Parent and variant sharing image
            Image img1 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img1.getPublicId()));
            RecipeDetailResponseDto variantDetail = recipeService.createRecipe(variantRequest, principal);

            // When: Delete variant
            recipeService.deleteRecipe(variantDetail.publicId(), testUser.getId());

            // Then: Parent still has the image
            RecipeDetailResponseDto reloadedParent = recipeService.getRecipeDetail(
                    parentDetail.publicId(), testUser.getId());
            assertThat(reloadedParent.images()).hasSize(1);

            // And: Image still exists in DB
            assertThat(imageRepository.findByPublicId(img1.getPublicId())).isPresent();
        }
    }

    @Nested
    @DisplayName("Display Order Independence")
    class DisplayOrderIndependence {

        @Test
        @DisplayName("Variant can have different display order from parent")
        void variantCanHaveDifferentDisplayOrder() {
            // Given: Parent with 2 images in order [img1, img2]
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(img1.getPublicId(), img2.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant with reversed order [img2, img1]
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(img2.getPublicId(), img1.getPublicId()));
            RecipeDetailResponseDto variantDetail = recipeService.createRecipe(variantRequest, principal);

            // Then: Parent maintains original order
            Recipe parent = recipeRepository.findByPublicId(parentDetail.publicId()).orElseThrow();
            List<RecipeImage> parentMappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(parent.getId());
            assertThat(parentMappings.get(0).getImage().getPublicId()).isEqualTo(img1.getPublicId());
            assertThat(parentMappings.get(1).getImage().getPublicId()).isEqualTo(img2.getPublicId());

            // And: Variant has reversed order
            Recipe variant = recipeRepository.findByPublicId(variantDetail.publicId()).orElseThrow();
            List<RecipeImage> variantMappings = recipeImageRepository
                    .findByRecipeIdOrderByDisplayOrderAsc(variant.getId());
            assertThat(variantMappings.get(0).getImage().getPublicId()).isEqualTo(img2.getPublicId());
            assertThat(variantMappings.get(1).getImage().getPublicId()).isEqualTo(img1.getPublicId());
        }
    }

    @Nested
    @DisplayName("Adding New Images to Variant")
    class AddingNewImagesToVariant {

        @Test
        @DisplayName("Variant can add new images while keeping inherited ones")
        void variantCanAddNewImagesWhileKeepingInherited() {
            // Given: Parent with 1 image
            Image inheritedImg = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(inheritedImg.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant with inherited image + new image
            Image newImg = createTestImage(ImageType.COVER);
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(inheritedImg.getPublicId(), newImg.getPublicId()));
            RecipeDetailResponseDto variantDetail = recipeService.createRecipe(variantRequest, principal);

            // Then: Variant has both images
            assertThat(variantDetail.images()).hasSize(2);
            assertThat(variantDetail.images().stream().map(img -> img.imagePublicId()))
                    .containsExactlyInAnyOrder(inheritedImg.getPublicId(), newImg.getPublicId());

            // And: Parent still has only its original image
            RecipeDetailResponseDto reloadedParent = recipeService.getRecipeDetail(
                    parentDetail.publicId(), testUser.getId());
            assertThat(reloadedParent.images()).hasSize(1);
        }

        @Test
        @DisplayName("New image added to variant should only appear in variant")
        void newImageOnlyAppearsInVariant() {
            // Given: Parent with 1 image
            Image inheritedImg = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto parentRequest = createRecipeRequest(
                    "Parent Recipe",
                    List.of(inheritedImg.getPublicId()));
            RecipeDetailResponseDto parentDetail = recipeService.createRecipe(parentRequest, principal);

            // When: Create variant with only a new image (not using parent's)
            Image newImg = createTestImage(ImageType.COVER);
            CreateRecipeRequestDto variantRequest = createVariantRequest(
                    "Variant Recipe",
                    parentDetail.publicId(),
                    List.of(newImg.getPublicId()));
            recipeService.createRecipe(variantRequest, principal);

            // Then: New image is only linked to variant
            long recipesUsingNewImg = recipeImageRepository.countByImageId(newImg.getId());
            assertThat(recipesUsingNewImg).isEqualTo(1);

            // And: Inherited image is only linked to parent
            long recipesUsingInheritedImg = recipeImageRepository.countByImageId(inheritedImg.getId());
            assertThat(recipesUsingInheritedImg).isEqualTo(1);
        }
    }
}
