package com.cookstemma.cookstemma.dto.log_post;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;
import java.util.UUID;

public record CreateLogRequestDto(
        @NotNull(message = "레시피 선택은 필수입니다")
        UUID recipePublicId,
        @Size(max = 200, message = "제목은 200자 이하여야 합니다")
        String title,
        @NotBlank(message = "요리 후기는 필수입니다")
        @Size(max = 2000, message = "요리 후기는 2000자 이하여야 합니다")
        String content,
        @NotNull(message = "별점은 필수입니다")
        @Min(value = 1, message = "별점은 1 이상이어야 합니다")
        @Max(value = 5, message = "별점은 5 이하여야 합니다")
        Integer rating,
        List<UUID> imagePublicIds,
        List<String> hashtags,
        // Private visibility (default: false = public)
        Boolean isPrivate
) {}
