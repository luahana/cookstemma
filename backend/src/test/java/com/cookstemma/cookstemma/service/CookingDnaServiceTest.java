package com.cookstemma.cookstemma.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for CookingDnaService level and XP calculation methods.
 * Tests the 100-level, 12-tier system with new XP reward structure.
 */
class CookingDnaServiceTest {

    private CookingDnaService service;

    @BeforeEach
    void setUp() {
        // CookingDnaService requires repositories for getCookingDna,
        // but the public calculation methods are pure functions
        service = new CookingDnaService(null, null, null, null);
    }

    @Nested
    @DisplayName("calculateTotalXp - New XP Formula")
    class CalculateTotalXpTests {

        @Test
        @DisplayName("Should return 0 XP when all counts are zero")
        void zeroCountsReturnsZeroXp() {
            int result = service.calculateTotalXp(0, 0, 0, 0, 0);
            assertThat(result).isEqualTo(0);
        }

        @Test
        @DisplayName("Should return 50 XP per original recipe")
        void originalRecipesGive50XpEach() {
            int result = service.calculateTotalXp(3, 0, 0, 0, 0);
            assertThat(result).isEqualTo(150); // 3 * 50 = 150
        }

        @Test
        @DisplayName("Should return 30 XP per variant recipe")
        void variantRecipesGive30XpEach() {
            int result = service.calculateTotalXp(0, 4, 0, 0, 0);
            assertThat(result).isEqualTo(120); // 4 * 30 = 120
        }

        @Test
        @DisplayName("Should return 20 XP per log created")
        void logsCreatedGive20XpEach() {
            int result = service.calculateTotalXp(0, 0, 5, 0, 0);
            assertThat(result).isEqualTo(100); // 5 * 20 = 100
        }

        @Test
        @DisplayName("Should return rating * 6 XP for ratings received")
        void ratingsReceivedGive6XpPerPoint() {
            // If someone gives a 5-star rating, author gets 5 * 6 = 30 XP
            // Sum of all ratings received (e.g., 5+4+3 = 12 rating points)
            int result = service.calculateTotalXp(0, 0, 0, 12, 0);
            assertThat(result).isEqualTo(72); // 12 * 6 = 72
        }

        @Test
        @DisplayName("Should return 10 XP per save received")
        void savesReceivedGive10XpEach() {
            int result = service.calculateTotalXp(0, 0, 0, 0, 7);
            assertThat(result).isEqualTo(70); // 7 * 10 = 70
        }

        @Test
        @DisplayName("Should correctly combine all XP sources")
        void combinesAllXpSources() {
            // 2 original recipes (100) + 3 variant recipes (90) + 4 logs (80) +
            // 15 rating points (90) + 5 saves (50) = 410
            int result = service.calculateTotalXp(2, 3, 4, 15, 5);
            assertThat(result).isEqualTo(410);
        }

        @Test
        @DisplayName("Variant recipes give less XP than original recipes")
        void variantRecipesGiveLessXpThanOriginal() {
            int originalXp = service.calculateTotalXp(1, 0, 0, 0, 0);
            int variantXp = service.calculateTotalXp(0, 1, 0, 0, 0);
            assertThat(originalXp).isGreaterThan(variantXp);
            assertThat(originalXp).isEqualTo(50);
            assertThat(variantXp).isEqualTo(30);
        }
    }

    @Nested
    @DisplayName("calculateLevel - 100 Level System")
    class CalculateLevelTests {

        @Test
        @DisplayName("Should return level 1 for 0 XP")
        void zeroXpReturnsLevel1() {
            int result = service.calculateLevel(0);
            assertThat(result).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return level 1 for XP just under first threshold")
        void justUnderFirstThresholdReturnsLevel1() {
            int result = service.calculateLevel(113);
            assertThat(result).isEqualTo(1);
        }

        @ParameterizedTest
        @DisplayName("Should return correct level at tier boundaries")
        @CsvSource({
            // Tier 1: Beginner (1-8), ends at 800 XP
            "0, 1",
            "800, 8",
            // Tier 2: Novice Cook (9-16), ends at 2000 XP
            // Note: 801 XP is still Level 8 since Level 9 requires ~950 XP (graduated within tier)
            "950, 9",
            "2000, 16",
            // Tier 3: Home Cook (17-25), ends at 4500 XP
            "2278, 17",
            "4500, 25",
            // Tier 4: Hobby Cook (26-34), ends at 8000 XP
            "4889, 26",
            "8000, 34",
            // Tier 5: Skilled Cook (35-44), ends at 14000 XP
            "8600, 35",
            "14000, 44",
            // Tier 6: Expert Cook (45-54), ends at 22000 XP
            "14800, 45",
            "22000, 54",
            // Tier 7: Junior Chef (55-64), ends at 32000 XP
            "23000, 55",
            "32000, 64",
            // Tier 8: Sous Chef (65-74), ends at 45000 XP
            "33300, 65",
            "45000, 74",
            // Tier 9: Chef (75-84), ends at 62000 XP
            "46700, 75",
            "62000, 84",
            // Tier 10: Head Chef (85-92), ends at 80000 XP
            "64250, 85",
            "80000, 92",
            // Tier 11: Executive Chef (93-99), ends at 99000 XP
            "82714, 93",
            "99000, 99",
            // Tier 12: Master Chef (100), at 100000 XP
            "100000, 100"
        })
        void levelAtTierBoundaries(int xp, int expectedLevel) {
            int result = service.calculateLevel(xp);
            assertThat(result).isEqualTo(expectedLevel);
        }

        @Test
        @DisplayName("Should return level 100 for very high XP")
        void veryHighXpReturnsMaxLevel() {
            int result = service.calculateLevel(500000);
            assertThat(result).isEqualTo(100);
        }

        @Test
        @DisplayName("Level 100 requires exactly 100000 XP")
        void level100RequiresExact100kXp() {
            assertThat(service.calculateLevel(99999)).isEqualTo(99);
            assertThat(service.calculateLevel(100000)).isEqualTo(100);
        }
    }

    @Nested
    @DisplayName("getXpForLevel - XP Thresholds")
    class GetXpForLevelTests {

        @Test
        @DisplayName("Level 1 requires 0 XP")
        void level1Requires0Xp() {
            assertThat(service.getXpForLevel(1)).isEqualTo(0);
        }

        @ParameterizedTest
        @DisplayName("Should return correct XP threshold for tier end levels")
        @CsvSource({
            "8, 800",      // End of Beginner
            "16, 2000",    // End of Kitchen Helper
            "25, 4500",    // End of Home Cook
            "34, 8000",    // End of Cooking Enthusiast
            "44, 14000",   // End of Skilled Cook
            "54, 22000",   // End of Amateur Chef
            "64, 32000",   // End of Home Chef
            "74, 45000",   // End of Sous Chef
            "84, 62000",   // End of Chef
            "92, 80000",   // End of Head Chef
            "99, 99000",   // End of Executive Chef
            "100, 100000"  // Master Chef
        })
        void xpThresholdsForTierEndLevels(int level, int expectedXp) {
            assertThat(service.getXpForLevel(level)).isEqualTo(expectedXp);
        }

        @Test
        @DisplayName("Level 0 or negative returns 0")
        void level0ReturnsZero() {
            assertThat(service.getXpForLevel(0)).isEqualTo(0);
            assertThat(service.getXpForLevel(-1)).isEqualTo(0);
        }

        @Test
        @DisplayName("Level above 100 returns max XP (100000)")
        void levelAbove100ReturnsMax() {
            assertThat(service.getXpForLevel(101)).isEqualTo(100000);
            assertThat(service.getXpForLevel(150)).isEqualTo(100000);
        }
    }

    @Nested
    @DisplayName("getLevelName - 12 Tier System (Cook/Chef pattern)")
    class GetLevelNameTests {

        @ParameterizedTest
        @DisplayName("Tier 1: Beginner for levels 1-8")
        @CsvSource({"1", "4", "8"})
        void beginnerTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("beginner");
        }

        @ParameterizedTest
        @DisplayName("Tier 2: Novice Cook for levels 9-16")
        @CsvSource({"9", "12", "16"})
        void noviceCookTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("noviceCook");
        }

        @ParameterizedTest
        @DisplayName("Tier 3: Home Cook for levels 17-25")
        @CsvSource({"17", "21", "25"})
        void homeCookTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("homeCook");
        }

        @ParameterizedTest
        @DisplayName("Tier 4: Hobby Cook for levels 26-34")
        @CsvSource({"26", "30", "34"})
        void hobbyCookTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("hobbyCook");
        }

        @ParameterizedTest
        @DisplayName("Tier 5: Skilled Cook for levels 35-44")
        @CsvSource({"35", "40", "44"})
        void skilledCookTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("skilledCook");
        }

        @ParameterizedTest
        @DisplayName("Tier 6: Expert Cook for levels 45-54")
        @CsvSource({"45", "50", "54"})
        void expertCookTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("expertCook");
        }

        @ParameterizedTest
        @DisplayName("Tier 7: Junior Chef for levels 55-64")
        @CsvSource({"55", "60", "64"})
        void juniorChefTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("juniorChef");
        }

        @ParameterizedTest
        @DisplayName("Tier 8: Sous Chef for levels 65-74")
        @CsvSource({"65", "70", "74"})
        void sousChefTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("sousChef");
        }

        @ParameterizedTest
        @DisplayName("Tier 9: Chef for levels 75-84")
        @CsvSource({"75", "80", "84"})
        void chefTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("chef");
        }

        @ParameterizedTest
        @DisplayName("Tier 10: Head Chef for levels 85-92")
        @CsvSource({"85", "88", "92"})
        void headChefTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("headChef");
        }

        @ParameterizedTest
        @DisplayName("Tier 11: Executive Chef for levels 93-99")
        @CsvSource({"93", "96", "99"})
        void executiveChefTier(int level) {
            assertThat(service.getLevelName(level)).isEqualTo("executiveChef");
        }

        @Test
        @DisplayName("Tier 12: Master Chef only for level 100")
        void masterChefOnlyForLevel100() {
            assertThat(service.getLevelName(100)).isEqualTo("masterChef");
            // Level 99 should NOT be Master Chef
            assertThat(service.getLevelName(99)).isEqualTo("executiveChef");
        }

        @Test
        @DisplayName("All tier names follow Cook/Chef pattern (except Beginner)")
        void allTierNamesFollowPattern() {
            // Beginner is the only exception
            assertThat(service.getLevelName(1)).isEqualTo("beginner");

            // Cook tiers (2-6) - camelCase so "Cook" suffix
            assertThat(service.getLevelName(9)).contains("Cook");
            assertThat(service.getLevelName(17)).contains("Cook");
            assertThat(service.getLevelName(26)).contains("Cook");
            assertThat(service.getLevelName(35)).contains("Cook");
            assertThat(service.getLevelName(45)).contains("Cook");

            // Chef tiers (7-12) - camelCase so "Chef" suffix
            assertThat(service.getLevelName(55)).contains("Chef");
            assertThat(service.getLevelName(65)).contains("Chef");
            assertThat(service.getLevelName(75)).isEqualTo("chef");  // Just "chef" with no prefix
            assertThat(service.getLevelName(85)).contains("Chef");
            assertThat(service.getLevelName(93)).contains("Chef");
            assertThat(service.getLevelName(100)).contains("Chef");
        }
    }

    @Nested
    @DisplayName("XP Reward Structure Scenarios")
    class XpRewardScenarios {

        @Test
        @DisplayName("Active content creator earns XP from multiple sources")
        void activeContentCreatorScenario() {
            // User has:
            // - 10 original recipes (500 XP)
            // - 5 variant recipes (150 XP)
            // - 20 cooking logs created (400 XP)
            // - Received ratings totaling 100 points from others (600 XP)
            // - 30 saves on their recipes (300 XP)
            // Total: 1950 XP -> Level 15 (Novice Cook, since L16 requires 2000)
            int totalXp = service.calculateTotalXp(10, 5, 20, 100, 30);
            assertThat(totalXp).isEqualTo(1950);
            assertThat(service.calculateLevel(totalXp)).isEqualTo(15);
            assertThat(service.getLevelName(service.calculateLevel(totalXp))).isEqualTo("noviceCook");
        }

        @Test
        @DisplayName("Recipe-focused user earns more from original recipes")
        void recipeFocusedUserScenario() {
            // User focused on creating original recipes
            // - 50 original recipes (2500 XP)
            // - 0 variant recipes
            // - 10 logs created (200 XP)
            // - Some ratings received (150 points = 900 XP)
            // - 100 saves (1000 XP)
            // Total: 4600 XP -> Level 25 (Home Cook, since L26 requires 4889)
            int totalXp = service.calculateTotalXp(50, 0, 10, 150, 100);
            assertThat(totalXp).isEqualTo(4600);
            assertThat(service.calculateLevel(totalXp)).isEqualTo(25);
            assertThat(service.getLevelName(service.calculateLevel(totalXp))).isEqualTo("homeCook");
        }

        @Test
        @DisplayName("Engagement-focused user earns from logs and saves")
        void engagementFocusedUserScenario() {
            // User focused on cooking and engagement
            // - 5 original recipes (250 XP)
            // - 2 variant recipes (60 XP)
            // - 100 logs created (2000 XP)
            // - Ratings received (50 points = 300 XP)
            // - 20 saves (200 XP)
            // Total: 2810 XP -> Level 18 (Home Cook, since L19 requires 2833)
            int totalXp = service.calculateTotalXp(5, 2, 100, 50, 20);
            assertThat(totalXp).isEqualTo(2810);
            assertThat(service.calculateLevel(totalXp)).isEqualTo(18);
            assertThat(service.getLevelName(service.calculateLevel(totalXp))).isEqualTo("homeCook");
        }

        @Test
        @DisplayName("Master Chef requires significant all-around activity")
        void masterChefRequiresSignificantActivity() {
            // To reach Master Chef (100k XP), user needs substantial activity
            // For example:
            // - 500 original recipes (25000 XP)
            // - 200 variant recipes (6000 XP)
            // - 1000 logs created (20000 XP)
            // - Ratings received: ~5000 rating points (30000 XP)
            // - 1900 saves (19000 XP)
            // Total: 100000 XP -> Level 100 (Master Chef)
            int totalXp = service.calculateTotalXp(500, 200, 1000, 5000, 1900);
            assertThat(totalXp).isEqualTo(100000);
            assertThat(service.calculateLevel(totalXp)).isEqualTo(100);
            assertThat(service.getLevelName(service.calculateLevel(totalXp))).isEqualTo("masterChef");
        }
    }
}
