package com.cookstemma.cookstemma.dto.user;

import lombok.Builder;

import java.util.List;

@Builder
public record CookingDnaDto(
        // XP & Level
        int totalXp,
        int level,
        String levelName,         // "beginner", "homeCook", "skilledCook", "homeChef", "expertChef", "masterChef"
        int xpForCurrentLevel,    // XP threshold for current level
        int xpForNextLevel,       // XP threshold for next level
        double levelProgress,     // Progress within current level (0.0 - 1.0)

        // Cooking Stats
        int totalLogs,            // Total number of cooking logs
        Double averageRating,     // Average rating (1.0 - 5.0), null if no logs
        List<RatingDistributionDto> ratingDistribution,  // Distribution of ratings (1-5)

        // Streak
        int currentStreak,        // Current consecutive cooking days
        int longestStreak,        // Longest streak ever achieved

        // Cuisine Distribution (top 5 + "other")
        List<CuisineStatDto> cuisineDistribution,

        // Content counts (same as profile)
        long recipeCount,
        long logCount,
        long savedCount
) {}
