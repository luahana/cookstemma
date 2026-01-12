package com.pairingplanet.pairing_planet.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for CookingDnaService level calculation methods.
 * These methods are pure functions that don't require Spring context.
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
    @DisplayName("calculateTotalXp")
    class CalculateTotalXpTests {

        @Test
        @DisplayName("Should return 0 XP when all counts are zero")
        void zeroCountsReturnsZeroXp() {
            int result = service.calculateTotalXp(0, 0, 0, 0);
            assertThat(result).isEqualTo(0);
        }

        @Test
        @DisplayName("Should return 50 XP per recipe created")
        void recipesGive50XpEach() {
            int result = service.calculateTotalXp(3, 0, 0, 0);
            assertThat(result).isEqualTo(150); // 3 * 50 = 150
        }

        @Test
        @DisplayName("Should return 30 XP per successful log")
        void successLogsGive30XpEach() {
            int result = service.calculateTotalXp(0, 5, 0, 0);
            assertThat(result).isEqualTo(150); // 5 * 30 = 150
        }

        @Test
        @DisplayName("Should return 15 XP per partial success log")
        void partialLogsGive15XpEach() {
            int result = service.calculateTotalXp(0, 0, 4, 0);
            assertThat(result).isEqualTo(60); // 4 * 15 = 60
        }

        @Test
        @DisplayName("Should return 5 XP per failed log")
        void failedLogsGive5XpEach() {
            int result = service.calculateTotalXp(0, 0, 0, 10);
            assertThat(result).isEqualTo(50); // 10 * 5 = 50
        }

        @Test
        @DisplayName("Should correctly combine XP from all sources")
        void combinesAllXpSources() {
            // 2 recipes (100) + 3 success (90) + 2 partial (30) + 1 failed (5) = 225
            int result = service.calculateTotalXp(2, 3, 2, 1);
            assertThat(result).isEqualTo(225);
        }
    }

    @Nested
    @DisplayName("calculateLevel")
    class CalculateLevelTests {

        @Test
        @DisplayName("Should return level 1 for 0 XP")
        void zeroXpReturnsLevel1() {
            int result = service.calculateLevel(0);
            assertThat(result).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return level 1 for 99 XP (just under threshold)")
        void justUnderThresholdReturnsLevel1() {
            int result = service.calculateLevel(99);
            assertThat(result).isEqualTo(1);
        }

        @Test
        @DisplayName("Should return level 2 for exactly 100 XP")
        void atThresholdReturnsLevel2() {
            int result = service.calculateLevel(100);
            assertThat(result).isEqualTo(2);
        }

        @ParameterizedTest
        @DisplayName("Should return correct level at each tier boundary")
        @CsvSource({
            "500, 5",    // End of beginner tier
            "700, 6",    // Start of homeCook tier
            "1700, 10",  // End of homeCook tier
            "2000, 11",  // Start of skilledCook tier
            "3900, 15",  // End of skilledCook tier
            "4500, 16",  // Start of homeChef tier
            "7900, 20",  // End of homeChef tier
            "9000, 21",  // Start of expertChef tier
            "14400, 25", // End of expertChef tier
            "16000, 26"  // Master Chef
        })
        void levelAtTierBoundaries(int xp, int expectedLevel) {
            int result = service.calculateLevel(xp);
            assertThat(result).isEqualTo(expectedLevel);
        }

        @Test
        @DisplayName("Should return level 26 for very high XP")
        void veryHighXpReturnsMaxLevel() {
            int result = service.calculateLevel(100000);
            assertThat(result).isEqualTo(26);
        }
    }

    @Nested
    @DisplayName("getLevelName")
    class GetLevelNameTests {

        @ParameterizedTest
        @DisplayName("Should return 'beginner' for levels 1-5")
        @CsvSource({"1", "2", "3", "4", "5"})
        void beginnerTier(int level) {
            String result = service.getLevelName(level);
            assertThat(result).isEqualTo("beginner");
        }

        @ParameterizedTest
        @DisplayName("Should return 'homeCook' for levels 6-10")
        @CsvSource({"6", "7", "8", "9", "10"})
        void homeCookTier(int level) {
            String result = service.getLevelName(level);
            assertThat(result).isEqualTo("homeCook");
        }

        @ParameterizedTest
        @DisplayName("Should return 'skilledCook' for levels 11-15")
        @CsvSource({"11", "12", "13", "14", "15"})
        void skilledCookTier(int level) {
            String result = service.getLevelName(level);
            assertThat(result).isEqualTo("skilledCook");
        }

        @ParameterizedTest
        @DisplayName("Should return 'homeChef' for levels 16-20")
        @CsvSource({"16", "17", "18", "19", "20"})
        void homeChefTier(int level) {
            String result = service.getLevelName(level);
            assertThat(result).isEqualTo("homeChef");
        }

        @ParameterizedTest
        @DisplayName("Should return 'expertChef' for levels 21-25")
        @CsvSource({"21", "22", "23", "24", "25"})
        void expertChefTier(int level) {
            String result = service.getLevelName(level);
            assertThat(result).isEqualTo("expertChef");
        }

        @ParameterizedTest
        @DisplayName("Should return 'masterChef' for level 26 and above")
        @CsvSource({"26", "27", "50", "100"})
        void masterChefTier(int level) {
            String result = service.getLevelName(level);
            assertThat(result).isEqualTo("masterChef");
        }
    }
}
