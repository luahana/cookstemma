package com.pairingplanet.pairing_planet.service;

import com.pairingplanet.pairing_planet.dto.user.CookingDnaDto;
import com.pairingplanet.pairing_planet.dto.user.CuisineStatDto;
import com.pairingplanet.pairing_planet.repository.log_post.LogPostRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeLogRepository;
import com.pairingplanet.pairing_planet.repository.recipe.RecipeRepository;
import com.pairingplanet.pairing_planet.repository.recipe.SavedRecipeRepository;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Date;
import java.time.LocalDate;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CookingDnaService {

    private final RecipeRepository recipeRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final LogPostRepository logPostRepository;
    private final SavedRecipeRepository savedRecipeRepository;

    // XP Constants
    private static final int XP_RECIPE_CREATED = 50;
    private static final int XP_LOG_SUCCESS = 30;
    private static final int XP_LOG_PARTIAL = 15;
    private static final int XP_LOG_FAILED = 5;

    // Level thresholds (cumulative XP required for each level)
    private static final int[] LEVEL_THRESHOLDS = {
            0,      // Level 1: 0 XP
            100,    // Level 2: 100 XP
            200,    // Level 3: 200 XP
            350,    // Level 4: 350 XP
            500,    // Level 5: 500 XP (End of Beginner)
            700,    // Level 6: 700 XP
            900,    // Level 7: 900 XP
            1150,   // Level 8: 1150 XP
            1400,   // Level 9: 1400 XP
            1700,   // Level 10: 1700 XP (End of Home Cook)
            2000,   // Level 11: 2000 XP
            2400,   // Level 12: 2400 XP
            2850,   // Level 13: 2850 XP
            3350,   // Level 14: 3350 XP
            3900,   // Level 15: 3900 XP (End of Skilled Cook)
            4500,   // Level 16: 4500 XP
            5200,   // Level 17: 5200 XP
            6000,   // Level 18: 6000 XP
            6900,   // Level 19: 6900 XP
            7900,   // Level 20: 7900 XP (End of Home Chef)
            9000,   // Level 21: 9000 XP
            10200,  // Level 22: 10200 XP
            11500,  // Level 23: 11500 XP
            12900,  // Level 24: 12900 XP
            14400,  // Level 25: 14400 XP (End of Expert Chef)
            16000   // Level 26+: 16000 XP (Master Chef)
    };

    public CookingDnaDto getCookingDna(UserPrincipal principal, String locale) {
        Long userId = principal.getId();

        // 1. Get outcome counts
        Map<String, Long> outcomeCounts = getOutcomeCounts(userId);
        int successCount = outcomeCounts.getOrDefault("SUCCESS", 0L).intValue();
        int partialCount = outcomeCounts.getOrDefault("PARTIAL", 0L).intValue();
        int failedCount = outcomeCounts.getOrDefault("FAILED", 0L).intValue();
        int totalLogs = successCount + partialCount + failedCount;

        // 2. Get recipe count
        long recipeCount = recipeRepository.countByCreatorIdAndDeletedAtIsNull(userId);

        // 3. Calculate XP
        int totalXp = calculateTotalXp(recipeCount, successCount, partialCount, failedCount);

        // 4. Calculate level
        int level = calculateLevel(totalXp);
        String levelName = getLevelName(level);
        int xpForCurrentLevel = level > 1 ? LEVEL_THRESHOLDS[Math.min(level - 1, LEVEL_THRESHOLDS.length - 1)] : 0;
        int xpForNextLevel = LEVEL_THRESHOLDS[Math.min(level, LEVEL_THRESHOLDS.length - 1)];
        double levelProgress = calculateLevelProgress(totalXp, xpForCurrentLevel, xpForNextLevel);

        // 5. Calculate success rate
        double successRate = totalLogs > 0 ? (double) successCount / totalLogs : 0.0;

        // 6. Calculate streaks
        int[] streaks = calculateStreaks(userId);
        int currentStreak = streaks[0];
        int longestStreak = streaks[1];

        // 7. Get cuisine distribution
        List<CuisineStatDto> cuisineDistribution = getCuisineDistribution(userId, totalLogs, locale);

        // 8. Get saved count
        long savedCount = savedRecipeRepository.countByUserId(userId);

        return CookingDnaDto.builder()
                .totalXp(totalXp)
                .level(level)
                .levelName(levelName)
                .xpForCurrentLevel(xpForCurrentLevel)
                .xpForNextLevel(xpForNextLevel)
                .levelProgress(levelProgress)
                .successRate(successRate)
                .totalLogs(totalLogs)
                .successCount(successCount)
                .partialCount(partialCount)
                .failedCount(failedCount)
                .currentStreak(currentStreak)
                .longestStreak(longestStreak)
                .cuisineDistribution(cuisineDistribution)
                .recipeCount(recipeCount)
                .logCount(totalLogs)
                .savedCount(savedCount)
                .build();
    }

    private Map<String, Long> getOutcomeCounts(Long userId) {
        List<Object[]> results = recipeLogRepository.countByOutcomeForUser(userId);
        Map<String, Long> counts = new HashMap<>();
        for (Object[] row : results) {
            String outcome = (String) row[0];
            Long count = (Long) row[1];
            if (outcome != null) {
                counts.put(outcome, count);
            }
        }
        return counts;
    }

    public int calculateTotalXp(long recipeCount, int successCount, int partialCount, int failedCount) {
        return (int) (recipeCount * XP_RECIPE_CREATED)
                + (successCount * XP_LOG_SUCCESS)
                + (partialCount * XP_LOG_PARTIAL)
                + (failedCount * XP_LOG_FAILED);
    }

    public int calculateLevel(int totalXp) {
        for (int i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
            if (totalXp >= LEVEL_THRESHOLDS[i]) {
                return i + 1;
            }
        }
        return 1;
    }

    public String getLevelName(int level) {
        if (level <= 5) return "beginner";
        if (level <= 10) return "homeCook";
        if (level <= 15) return "skilledCook";
        if (level <= 20) return "homeChef";
        if (level <= 25) return "expertChef";
        return "masterChef";
    }

    private double calculateLevelProgress(int totalXp, int xpForCurrentLevel, int xpForNextLevel) {
        if (xpForNextLevel <= xpForCurrentLevel) return 1.0;
        int xpInLevel = totalXp - xpForCurrentLevel;
        int xpNeeded = xpForNextLevel - xpForCurrentLevel;
        return Math.min(1.0, (double) xpInLevel / xpNeeded);
    }

    private int[] calculateStreaks(Long userId) {
        List<Date> cookingDates = recipeLogRepository.getCookingDatesForUser(userId);

        if (cookingDates.isEmpty()) {
            return new int[]{0, 0};
        }

        // Convert to LocalDate and sort descending
        List<LocalDate> dates = cookingDates.stream()
                .map(Date::toLocalDate)
                .sorted(Comparator.reverseOrder())
                .toList();

        LocalDate today = LocalDate.now();
        int currentStreak = 0;
        int longestStreak = 0;
        int tempStreak = 1;

        // Calculate current streak (must include today or yesterday)
        if (!dates.isEmpty()) {
            LocalDate firstDate = dates.getFirst();
            if (firstDate.equals(today) || firstDate.equals(today.minusDays(1))) {
                currentStreak = 1;
                for (int i = 1; i < dates.size(); i++) {
                    if (dates.get(i).equals(dates.get(i - 1).minusDays(1))) {
                        currentStreak++;
                    } else {
                        break;
                    }
                }
            }
        }

        // Calculate longest streak
        for (int i = 1; i < dates.size(); i++) {
            if (dates.get(i).equals(dates.get(i - 1).minusDays(1))) {
                tempStreak++;
            } else {
                longestStreak = Math.max(longestStreak, tempStreak);
                tempStreak = 1;
            }
        }
        longestStreak = Math.max(longestStreak, tempStreak);
        longestStreak = Math.max(longestStreak, currentStreak);

        return new int[]{currentStreak, longestStreak};
    }

    private List<CuisineStatDto> getCuisineDistribution(Long userId, int totalLogs, String locale) {
        List<Object[]> results = recipeLogRepository.getCuisineDistributionForUser(userId);

        if (results.isEmpty() || totalLogs == 0) {
            return List.of();
        }

        List<CuisineStatDto> distribution = new ArrayList<>();
        int top5Total = 0;

        // Take top 5 categories
        for (int i = 0; i < Math.min(5, results.size()); i++) {
            Object[] row = results.get(i);
            String categoryCode = row[0] != null ? (String) row[0] : "other";
            int count = ((Number) row[1]).intValue();
            top5Total += count;

            distribution.add(CuisineStatDto.builder()
                    .categoryCode(categoryCode)
                    .categoryName(categoryCode) // Frontend will localize using categoryCode
                    .count(count)
                    .percentage(Math.round((double) count / totalLogs * 1000) / 10.0)
                    .build());
        }

        // Add "other" category if there are more than 5 categories
        if (results.size() > 5) {
            int otherCount = totalLogs - top5Total;
            if (otherCount > 0) {
                distribution.add(CuisineStatDto.builder()
                        .categoryCode("other")
                        .categoryName("other")
                        .count(otherCount)
                        .percentage(Math.round((double) otherCount / totalLogs * 1000) / 10.0)
                        .build());
            }
        }

        return distribution;
    }
}
