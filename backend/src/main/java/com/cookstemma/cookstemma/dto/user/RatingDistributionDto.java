package com.cookstemma.cookstemma.dto.user;

import lombok.Builder;

@Builder
public record RatingDistributionDto(
        int rating,       // 1-5
        int count,        // Number of logs with this rating
        double percentage // Percentage of total logs
) {}
