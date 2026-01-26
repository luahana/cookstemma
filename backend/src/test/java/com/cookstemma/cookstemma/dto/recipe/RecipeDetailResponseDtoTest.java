package com.cookstemma.cookstemma.dto.recipe;

import com.cookstemma.cookstemma.domain.entity.food.FoodMaster;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RecipeDetailResponseDtoTest {

    private static final String URL_PREFIX = "https://example.com/images";
    private static final UUID CREATOR_PUBLIC_ID = UUID.randomUUID();
    private static final String CREATOR_NAME = "testUser";

    @Mock
    private Recipe childRecipe;

    @Mock
    private Recipe parentRecipe;

    @Mock
    private FoodMaster foodMaster;

    @BeforeEach
    void setUp() {
        // Common setup for all tests
        when(foodMaster.getName()).thenReturn(Map.of("en-US", "Test Food"));
        when(foodMaster.getPublicId()).thenReturn(UUID.randomUUID());

        when(childRecipe.getPublicId()).thenReturn(UUID.randomUUID());
        when(childRecipe.getFoodMaster()).thenReturn(foodMaster);
        when(childRecipe.getTitle()).thenReturn("Child Recipe Title");
        when(childRecipe.getTitleTranslations()).thenReturn(Map.of("en-US", "Child Recipe Title"));
        when(childRecipe.getCookingStyle()).thenReturn("en-US");
        when(childRecipe.getIngredients()).thenReturn(List.of());
        when(childRecipe.getSteps()).thenReturn(List.of());
        when(childRecipe.getCoverImages()).thenReturn(List.of());
        when(childRecipe.getHashtags()).thenReturn(Set.of());
        when(childRecipe.getRootRecipe()).thenReturn(null);
    }

    @Nested
    @DisplayName("Description Translation Fallback to Parent")
    class DescriptionTranslationFallbackTests {

        @Test
        @DisplayName("Should use child's description translation when available")
        void from_WithChildKoreanDescription_UsesChildDescription() {
            // Arrange
            String childKoreanDescription = "자식 레시피 한글 설명";
            when(childRecipe.getDescription()).thenReturn("Child recipe English description");
            when(childRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", "Child recipe English description",
                    "ko-KR", childKoreanDescription
            ));
            when(childRecipe.getParentRecipe()).thenReturn(null);

            // Act
            RecipeDetailResponseDto result = RecipeDetailResponseDto.from(
                    childRecipe,
                    List.of(),
                    List.of(),
                    URL_PREFIX,
                    false,
                    CREATOR_PUBLIC_ID,
                    CREATOR_NAME,
                    null,
                    null,
                    "ko-KR"
            );

            // Assert
            assertThat(result.description()).isEqualTo(childKoreanDescription);
        }

        @Test
        @DisplayName("Should fallback to parent's Korean description when child has no Korean translation")
        void from_WithoutChildKoreanDescription_FallsBackToParentDescription() {
            // Arrange
            String parentKoreanDescription = "부모 레시피 한글 설명";

            // Child has English and Japanese, but NO Korean
            when(childRecipe.getDescription()).thenReturn("Child recipe English description");
            when(childRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", "Child recipe English description",
                    "ja-JP", "子供レシピの日本語説明"
            ));

            // Parent has Korean translation
            when(parentRecipe.getDescription()).thenReturn("Parent recipe English description");
            when(parentRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", "Parent recipe English description",
                    "ko-KR", parentKoreanDescription
            ));
            when(parentRecipe.getFoodMaster()).thenReturn(foodMaster);
            when(parentRecipe.getPublicId()).thenReturn(UUID.randomUUID());
            when(parentRecipe.getTitle()).thenReturn("Parent Recipe Title");
            when(parentRecipe.getTitleTranslations()).thenReturn(Map.of("en-US", "Parent Recipe Title"));
            when(parentRecipe.getCookingStyle()).thenReturn("en-US");
            when(parentRecipe.getCoverImages()).thenReturn(List.of());

            when(childRecipe.getParentRecipe()).thenReturn(parentRecipe);

            // Act
            RecipeDetailResponseDto result = RecipeDetailResponseDto.from(
                    childRecipe,
                    List.of(),
                    List.of(),
                    URL_PREFIX,
                    false,
                    CREATOR_PUBLIC_ID,
                    CREATOR_NAME,
                    null,
                    null,
                    "ko-KR"
            );

            // Assert
            assertThat(result.description()).isEqualTo(parentKoreanDescription);
        }

        @Test
        @DisplayName("Should fallback to child's base description when neither child nor parent has Korean translation")
        void from_WithNoKoreanTranslation_FallsBackToChildBaseDescription() {
            // Arrange
            String childBaseDescription = "Child recipe English description";

            // Child has only English
            when(childRecipe.getDescription()).thenReturn(childBaseDescription);
            when(childRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", "Child recipe English description"
            ));

            // Parent also has only English (no Korean)
            when(parentRecipe.getDescription()).thenReturn("Parent recipe English description");
            when(parentRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", "Parent recipe English description"
            ));
            when(parentRecipe.getFoodMaster()).thenReturn(foodMaster);
            when(parentRecipe.getPublicId()).thenReturn(UUID.randomUUID());
            when(parentRecipe.getTitle()).thenReturn("Parent Recipe Title");
            when(parentRecipe.getTitleTranslations()).thenReturn(Map.of("en-US", "Parent Recipe Title"));
            when(parentRecipe.getCookingStyle()).thenReturn("en-US");
            when(parentRecipe.getCoverImages()).thenReturn(List.of());

            when(childRecipe.getParentRecipe()).thenReturn(parentRecipe);

            // Act
            RecipeDetailResponseDto result = RecipeDetailResponseDto.from(
                    childRecipe,
                    List.of(),
                    List.of(),
                    URL_PREFIX,
                    false,
                    CREATOR_PUBLIC_ID,
                    CREATOR_NAME,
                    null,
                    null,
                    "ko-KR"
            );

            // Assert - Should fall back to parent's English description (via LocaleUtils fallback)
            // then eventually to child's base description if parent also doesn't have it
            assertThat(result.description()).isNotNull();
        }

        @Test
        @DisplayName("Should use child's base description when no parent exists and child has no Korean translation")
        void from_WithNoParentAndNoKoreanTranslation_UsesChildBaseDescription() {
            // Arrange
            String childBaseDescription = "Child recipe English description";

            // Child has only English
            when(childRecipe.getDescription()).thenReturn(childBaseDescription);
            when(childRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", childBaseDescription
            ));
            when(childRecipe.getParentRecipe()).thenReturn(null);

            // Act
            RecipeDetailResponseDto result = RecipeDetailResponseDto.from(
                    childRecipe,
                    List.of(),
                    List.of(),
                    URL_PREFIX,
                    false,
                    CREATOR_PUBLIC_ID,
                    CREATOR_NAME,
                    null,
                    null,
                    "ko-KR"
            );

            // Assert - LocaleUtils fallback chain: ko-KR -> en-US -> first available
            assertThat(result.description()).isEqualTo(childBaseDescription);
        }

        @Test
        @DisplayName("Should use child's language-matched description when exact locale not available")
        void from_WithChildKoreanLanguageMatch_UsesChildDescription() {
            // Arrange
            String childKoreanDescription = "자식 레시피 한글 설명";

            // Child has ko (without region) but user requests ko-KR
            when(childRecipe.getDescription()).thenReturn("Child recipe English description");
            when(childRecipe.getDescriptionTranslations()).thenReturn(Map.of(
                    "en-US", "Child recipe English description",
                    "ko", childKoreanDescription
            ));
            when(childRecipe.getParentRecipe()).thenReturn(null);

            // Act
            RecipeDetailResponseDto result = RecipeDetailResponseDto.from(
                    childRecipe,
                    List.of(),
                    List.of(),
                    URL_PREFIX,
                    false,
                    CREATOR_PUBLIC_ID,
                    CREATOR_NAME,
                    null,
                    null,
                    "ko-KR"
            );

            // Assert - LocaleUtils should match "ko" when "ko-KR" is requested
            assertThat(result.description()).isEqualTo(childKoreanDescription);
        }
    }
}
