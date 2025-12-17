package com.pairingplanet.pairing_planet.dto.post;

import com.pairingplanet.pairing_planet.dto.food.FoodRequestDto;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record CreatePostRequestDto(
        @NotNull(message = "Food1 is required")
        FoodRequestDto food1,          // FR-40: Food1 필수

        FoodRequestDto food2,          // FR-40: Food2 선택

        Long whenContextId,         // FR-42: Context Tag (ID로 받음)
        Long dietaryTagId,

        @Size(max = 3, message = "Max 3 images allowed")
        List<String> imageUrls,     // FR-43: 이미지 3장 제한

        String content,             // FR-43: 내용

        Boolean isPrivate,

        Boolean verdictEnabled      // FR-44: 판결 기능 활성화 여부
) {}