package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.dto.user.CookingDnaDto;
import com.cookstemma.cookstemma.dto.user.CuisineStatDto;
import com.cookstemma.cookstemma.dto.user.RatingDistributionDto;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.recipe.SavedRecipeRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
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
    private static final int XP_ORIGINAL_RECIPE = 50;  // Creating an original recipe
    private static final int XP_VARIANT_RECIPE = 30;   // Creating a variant recipe
    private static final int XP_LOG_CREATED = 20;      // Creating a cooking log (fixed)
    private static final int XP_PER_RATING_POINT = 6;  // Recipe author XP when others log (rating × 6)
    private static final int XP_PER_SAVE = 10;         // Recipe author XP when someone saves

    // 100-level thresholds with 12-tier system
    // Tier milestones: L8=800, L16=2000, L25=4500, L34=8000, L44=14000, L54=22000,
    //                  L64=32000, L74=45000, L84=62000, L92=80000, L99=99000, L100=100000
    private static final int[] LEVEL_THRESHOLDS = generateLevelThresholds();

    private static int[] generateLevelThresholds() {
        int[] thresholds = new int[100];
        thresholds[0] = 0;  // Level 1: 0 XP

        // Tier 1: Levels 1-8 (0 to 800) - Beginner
        for (int i = 1; i < 8; i++) {
            thresholds[i] = (int) Math.round(800.0 * i / 7.0);
        }
        thresholds[7] = 800;  // Level 8

        // Tier 2: Levels 9-16 (800 to 2000) - Kitchen Helper
        for (int i = 8; i < 16; i++) {
            thresholds[i] = 800 + (int) Math.round(1200.0 * (i - 7) / 8.0);
        }
        thresholds[15] = 2000;  // Level 16

        // Tier 3: Levels 17-25 (2000 to 4500) - Home Cook
        for (int i = 16; i < 25; i++) {
            thresholds[i] = 2000 + (int) Math.round(2500.0 * (i - 15) / 9.0);
        }
        thresholds[24] = 4500;  // Level 25

        // Tier 4: Levels 26-34 (4500 to 8000) - Cooking Enthusiast
        for (int i = 25; i < 34; i++) {
            thresholds[i] = 4500 + (int) Math.round(3500.0 * (i - 24) / 9.0);
        }
        thresholds[33] = 8000;  // Level 34

        // Tier 5: Levels 35-44 (8000 to 14000) - Skilled Cook
        for (int i = 34; i < 44; i++) {
            thresholds[i] = 8000 + (int) Math.round(6000.0 * (i - 33) / 10.0);
        }
        thresholds[43] = 14000;  // Level 44

        // Tier 6: Levels 45-54 (14000 to 22000) - Amateur Chef
        for (int i = 44; i < 54; i++) {
            thresholds[i] = 14000 + (int) Math.round(8000.0 * (i - 43) / 10.0);
        }
        thresholds[53] = 22000;  // Level 54

        // Tier 7: Levels 55-64 (22000 to 32000) - Home Chef
        for (int i = 54; i < 64; i++) {
            thresholds[i] = 22000 + (int) Math.round(10000.0 * (i - 53) / 10.0);
        }
        thresholds[63] = 32000;  // Level 64

        // Tier 8: Levels 65-74 (32000 to 45000) - Sous Chef
        for (int i = 64; i < 74; i++) {
            thresholds[i] = 32000 + (int) Math.round(13000.0 * (i - 63) / 10.0);
        }
        thresholds[73] = 45000;  // Level 74

        // Tier 9: Levels 75-84 (45000 to 62000) - Chef
        for (int i = 74; i < 84; i++) {
            thresholds[i] = 45000 + (int) Math.round(17000.0 * (i - 73) / 10.0);
        }
        thresholds[83] = 62000;  // Level 84

        // Tier 10: Levels 85-92 (62000 to 80000) - Head Chef
        for (int i = 84; i < 92; i++) {
            thresholds[i] = 62000 + (int) Math.round(18000.0 * (i - 83) / 8.0);
        }
        thresholds[91] = 80000;  // Level 92

        // Tier 11: Levels 93-99 (80000 to 99000) - Executive Chef
        for (int i = 92; i < 99; i++) {
            thresholds[i] = 80000 + (int) Math.round(19000.0 * (i - 91) / 7.0);
        }
        thresholds[98] = 99000;  // Level 99

        // Tier 12: Level 100 (100000) - Master Chef - Ultimate achievement
        thresholds[99] = 100000;

        return thresholds;
    }

    public CookingDnaDto getCookingDna(UserPrincipal principal, String locale) {
        Long userId = principal.getId();

        // 1. Get rating distribution (user's own logs)
        Map<Integer, Long> ratingCounts = getRatingCounts(userId);
        int totalLogs = ratingCounts.values().stream().mapToInt(Long::intValue).sum();

        // 2. Get recipe counts (original vs variant)
        long originalRecipeCount = recipeRepository.countByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNull(userId);
        long variantRecipeCount = recipeRepository.countByCreatorIdAndDeletedAtIsNullAndParentRecipeIsNotNull(userId);
        long recipeCount = originalRecipeCount + variantRecipeCount;

        // 3. Calculate average rating
        Double averageRating = recipeLogRepository.getAverageRatingForUser(userId);

        // 4. Get log count created by user
        long logCount = recipeLogRepository.countLogsCreatedByUser(userId);

        // 5. Get ratings received on user's recipes (when others log their recipes)
        int ratingsReceived = recipeLogRepository.sumRatingsReceivedOnUserRecipes(userId);

        // 6. Get saves received on user's recipes
        long savesReceived = savedRecipeRepository.countSavesReceivedOnUserRecipes(userId);

        // 7. Calculate total XP using new formula
        int totalXp = calculateTotalXp(originalRecipeCount, variantRecipeCount, logCount, ratingsReceived, savesReceived);

        // 8. Calculate level
        int level = calculateLevel(totalXp);
        String levelName = getLevelName(level);
        int xpForCurrentLevel = level > 1 ? LEVEL_THRESHOLDS[Math.min(level - 1, LEVEL_THRESHOLDS.length - 1)] : 0;
        int xpForNextLevel = level < 100 ? LEVEL_THRESHOLDS[Math.min(level, LEVEL_THRESHOLDS.length - 1)] : LEVEL_THRESHOLDS[99];
        double levelProgress = calculateLevelProgress(totalXp, xpForCurrentLevel, xpForNextLevel);

        // 6. Calculate streaks
        int[] streaks = calculateStreaks(userId);
        int currentStreak = streaks[0];
        int longestStreak = streaks[1];

        // 7. Get cuisine distribution
        List<CuisineStatDto> cuisineDistribution = getCuisineDistribution(userId, totalLogs, locale);

        // 8. Get saved count
        long savedCount = savedRecipeRepository.countByUserId(userId);

        // 9. Build rating distribution DTOs
        List<RatingDistributionDto> ratingDistribution = buildRatingDistribution(ratingCounts, totalLogs);

        return CookingDnaDto.builder()
                .totalXp(totalXp)
                .level(level)
                .levelName(levelName)
                .xpForCurrentLevel(xpForCurrentLevel)
                .xpForNextLevel(xpForNextLevel)
                .levelProgress(levelProgress)
                .totalLogs(totalLogs)
                .averageRating(averageRating)
                .ratingDistribution(ratingDistribution)
                .currentStreak(currentStreak)
                .longestStreak(longestStreak)
                .cuisineDistribution(cuisineDistribution)
                .recipeCount(recipeCount)
                .logCount(totalLogs)
                .savedCount(savedCount)
                .build();
    }

    private Map<Integer, Long> getRatingCounts(Long userId) {
        List<Object[]> results = recipeLogRepository.countByRatingForUser(userId);
        Map<Integer, Long> counts = new HashMap<>();
        for (Object[] row : results) {
            Integer rating = (Integer) row[0];
            Long count = (Long) row[1];
            if (rating != null) {
                counts.put(rating, count);
            }
        }
        return counts;
    }

    private int calculateRatingXp(Map<Integer, Long> ratingCounts) {
        int totalXp = 0;
        for (Map.Entry<Integer, Long> entry : ratingCounts.entrySet()) {
            // rating * 6 XP per log (1=6, 2=12, 3=18, 4=24, 5=30)
            totalXp += entry.getKey() * XP_PER_RATING_POINT * entry.getValue().intValue();
        }
        return totalXp;
    }

    private List<RatingDistributionDto> buildRatingDistribution(Map<Integer, Long> ratingCounts, int totalLogs) {
        List<RatingDistributionDto> distribution = new ArrayList<>();
        for (int rating = 1; rating <= 5; rating++) {
            int count = ratingCounts.getOrDefault(rating, 0L).intValue();
            double percentage = totalLogs > 0 ? Math.round((double) count / totalLogs * 1000) / 10.0 : 0.0;
            distribution.add(RatingDistributionDto.builder()
                    .rating(rating)
                    .count(count)
                    .percentage(percentage)
                    .build());
        }
        return distribution;
    }

    /**
     * Calculate total XP using the new formula:
     * - Original recipe: 50 XP each
     * - Variant recipe: 30 XP each
     * - Log created: 20 XP each (fixed)
     * - Ratings received on user's recipes: rating × 6 (when others log)
     * - Saves received: 10 XP each
     */
    public int calculateTotalXp(long originalRecipeCount, long variantRecipeCount,
                                long logCount, int ratingsReceived, long savesReceived) {
        int xpFromOriginalRecipes = (int) (originalRecipeCount * XP_ORIGINAL_RECIPE);
        int xpFromVariantRecipes = (int) (variantRecipeCount * XP_VARIANT_RECIPE);
        int xpFromLogs = (int) (logCount * XP_LOG_CREATED);
        int xpFromRatingsReceived = ratingsReceived * XP_PER_RATING_POINT;
        int xpFromSaves = (int) (savesReceived * XP_PER_SAVE);

        return xpFromOriginalRecipes + xpFromVariantRecipes + xpFromLogs + xpFromRatingsReceived + xpFromSaves;
    }

    /**
     * Legacy method for backward compatibility - calculates XP from recipe count and rating XP.
     * @deprecated Use calculateTotalXp with new signature for accurate XP calculation.
     */
    @Deprecated
    public int calculateTotalXpLegacy(long recipeCount, int totalRatingXp) {
        return (int) (recipeCount * XP_ORIGINAL_RECIPE) + totalRatingXp;
    }

    public int calculateLevel(int totalXp) {
        for (int i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
            if (totalXp >= LEVEL_THRESHOLDS[i]) {
                return i + 1;
            }
        }
        return 1;
    }

    /**
     * Get XP threshold for a given level.
     * @param level the level (1-100+)
     * @return XP required to reach that level
     */
    public int getXpForLevel(int level) {
        if (level <= 0) return 0;
        if (level > 100) return LEVEL_THRESHOLDS[99];  // Max at level 100
        return LEVEL_THRESHOLDS[level - 1];
    }

    /**
     * Get tier name for a given level (12-tier system).
     * All tiers end with "Cook" or "Chef" (except Beginner).
     * Cook tiers (1-6): Learning and hobbyist levels
     * Chef tiers (7-12): Professional levels
     *
     * Tier 1: Levels 1-8 (Beginner)
     * Tier 2: Levels 9-16 (Novice Cook)
     * Tier 3: Levels 17-25 (Home Cook)
     * Tier 4: Levels 26-34 (Hobby Cook)
     * Tier 5: Levels 35-44 (Skilled Cook)
     * Tier 6: Levels 45-54 (Expert Cook)
     * Tier 7: Levels 55-64 (Junior Chef)
     * Tier 8: Levels 65-74 (Sous Chef)
     * Tier 9: Levels 75-84 (Chef)
     * Tier 10: Levels 85-92 (Head Chef)
     * Tier 11: Levels 93-99 (Executive Chef)
     * Tier 12: Level 100 (Master Chef)
     */
    public String getLevelName(int level) {
        if (level <= 8) return "beginner";
        if (level <= 16) return "noviceCook";
        if (level <= 25) return "homeCook";
        if (level <= 34) return "hobbyCook";
        if (level <= 44) return "skilledCook";
        if (level <= 54) return "expertCook";
        if (level <= 64) return "juniorChef";
        if (level <= 74) return "sousChef";
        if (level <= 84) return "chef";
        if (level <= 92) return "headChef";
        if (level < 100) return "executiveChef";
        return "masterChef";  // Only level 100
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
