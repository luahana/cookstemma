package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageStatus;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.recipe.CreateRecipeRequestDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeDetailResponseDto;
import com.cookstemma.cookstemma.repository.food.FoodMasterRepository;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
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

@DisplayName("Recipe Multiple Image Tests")
class RecipeMultiImageTest extends BaseIntegrationTest {

    @Autowired
    private RecipeService recipeService;

    @Autowired
    private ImageService imageService;

    @Autowired
    private RecipeRepository recipeRepository;

    @Autowired
    private ImageRepository imageRepository;

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

    @Nested
    @DisplayName("Create Recipe with Multiple Cover Images")
    class CreateRecipeMultiImageTests {

        @Test
        @DisplayName("Should save and return all cover images when creating recipe with 2 images")
        void createRecipe_withTwoCoverImages_shouldReturnBothImages() {
            // Given: Create 2 COVER images
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Test Recipe with Multiple Images",
                    "Test Description",
                    "ko-KR",
                    testFood.getPublicId(),
                    null, // newFoodName
                    List.of(), // ingredients
                    List.of(), // steps
                    List.of(img1.getPublicId(), img2.getPublicId()), // imagePublicIds - 2 images
                    null, // changeCategory
                    null, // parentPublicId
                    null, // rootPublicId
                    null, // changeDiff
                    null, // changeReason
                    List.of(), // hashtags
                    2, // servings
                    "MIN_30_TO_60", // cookingTimeRange
                    null // isPrivate
            );

            // When: Create recipe
            RecipeDetailResponseDto detail = recipeService.createRecipe(request, principal);

            // Then: Verify both images are saved and returned

            assertThat(detail.images()).hasSize(2);
            assertThat(detail.images().stream().map(img -> img.imagePublicId()))
                    .containsExactlyInAnyOrder(img1.getPublicId(), img2.getPublicId());

            // Verify images have correct status and displayOrder
            Image savedImg1 = imageRepository.findByPublicId(img1.getPublicId()).orElseThrow();
            Image savedImg2 = imageRepository.findByPublicId(img2.getPublicId()).orElseThrow();

            assertThat(savedImg1.getStatus()).isEqualTo(ImageStatus.ACTIVE);
            assertThat(savedImg2.getStatus()).isEqualTo(ImageStatus.ACTIVE);
            assertThat(savedImg1.getDisplayOrder()).isEqualTo(0);
            assertThat(savedImg2.getDisplayOrder()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return all cover images when creating recipe with 3 images")
        void createRecipe_withThreeCoverImages_shouldReturnAllImages() {
            // Given: Create 3 COVER images
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);
            Image img3 = createTestImage(ImageType.COVER);

            CreateRecipeRequestDto request = new CreateRecipeRequestDto(
                    "Test Recipe with 3 Images",
                    "Test Description",
                    "ko-KR",
                    testFood.getPublicId(),
                    null,
                    List.of(),
                    List.of(),
                    List.of(img1.getPublicId(), img2.getPublicId(), img3.getPublicId()),
                    null,
                    null,
                    null,
                    null,
                    null,
                    List.of(),
                    2,
                    "MIN_30_TO_60",
                    null // isPrivate
            );

            // When
            RecipeDetailResponseDto detail = recipeService.createRecipe(request, principal);

            // Then

            assertThat(detail.images()).hasSize(3);
        }
    }

    @Nested
    @DisplayName("Image Activation Tests")
    class ImageActivationTests {

        @Test
        @DisplayName("Should activate all images and set displayOrder correctly")
        void activateImages_multipleImages_setsDisplayOrder() {
            // Given
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // When
            imageService.activateImages(List.of(img1.getPublicId(), img2.getPublicId()), recipe);

            // Then
            Image activated1 = imageRepository.findByPublicId(img1.getPublicId()).orElseThrow();
            Image activated2 = imageRepository.findByPublicId(img2.getPublicId()).orElseThrow();

            assertThat(activated1.getRecipe()).isEqualTo(recipe);
            assertThat(activated2.getRecipe()).isEqualTo(recipe);
            assertThat(activated1.getStatus()).isEqualTo(ImageStatus.ACTIVE);
            assertThat(activated2.getStatus()).isEqualTo(ImageStatus.ACTIVE);
            assertThat(activated1.getDisplayOrder()).isEqualTo(0);
            assertThat(activated2.getDisplayOrder()).isEqualTo(1);
        }

        @Test
        @DisplayName("Should link all images to recipe via recipe_id")
        void activateImages_multipleImages_linksToRecipe() {
            // Given
            Image img1 = createTestImage(ImageType.COVER);
            Image img2 = createTestImage(ImageType.COVER);

            Recipe recipe = Recipe.builder()
                    .title("Test Recipe")
                    .cookingStyle("ko-KR")
                    .foodMaster(testFood)
                    .creatorId(testUser.getId())
                    .build();
            recipeRepository.save(recipe);

            // When
            imageService.activateImages(List.of(img1.getPublicId(), img2.getPublicId()), recipe);

            // Flush and clear to ensure fresh fetch
            imageRepository.flush();
            Recipe fetchedRecipe = recipeRepository.findByPublicId(recipe.getPublicId()).orElseThrow();

            // Then
            assertThat(fetchedRecipe.getImages()).hasSize(2);
        }
    }
}
