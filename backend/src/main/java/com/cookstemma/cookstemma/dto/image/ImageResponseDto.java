package com.cookstemma.cookstemma.dto.image;

import java.util.UUID;

public record ImageResponseDto(
        UUID imagePublicId, // 관리에 필요한 ID
        String imageUrl     // 화면 표시에 필요한 URL
) {}