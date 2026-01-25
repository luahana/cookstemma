package com.cookstemma.cookstemma.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UsernameUtilsTest {

    @Nested
    @DisplayName("isValid")
    class IsValidTests {

        @Test
        @DisplayName("Should accept valid usernames with letters only")
        void isValid_WithLettersOnly_ReturnsTrue() {
            assertThat(UsernameUtils.isValid("abcde")).isTrue();
            assertThat(UsernameUtils.isValid("JohnDoe")).isTrue();
            assertThat(UsernameUtils.isValid("chefMike")).isTrue();
        }

        @Test
        @DisplayName("Should accept valid usernames with letters and numbers")
        void isValid_WithLettersAndNumbers_ReturnsTrue() {
            assertThat(UsernameUtils.isValid("john123")).isTrue();
            assertThat(UsernameUtils.isValid("Chef2024")).isTrue();
            assertThat(UsernameUtils.isValid("foodie123")).isTrue();
        }

        @Test
        @DisplayName("Should accept usernames with underscore")
        void isValid_WithUnderscore_ReturnsTrue() {
            assertThat(UsernameUtils.isValid("john_doe")).isTrue();
            assertThat(UsernameUtils.isValid("Chef_Mike")).isTrue();
            assertThat(UsernameUtils.isValid("happy_chef_42")).isTrue();
        }

        @Test
        @DisplayName("Should accept usernames with period")
        void isValid_WithPeriod_ReturnsTrue() {
            assertThat(UsernameUtils.isValid("Chef.Mike")).isTrue();
            assertThat(UsernameUtils.isValid("john.doe")).isTrue();
        }

        @Test
        @DisplayName("Should accept usernames with hyphen")
        void isValid_WithHyphen_ReturnsTrue() {
            assertThat(UsernameUtils.isValid("john-doe")).isTrue();
            assertThat(UsernameUtils.isValid("Chef-Mike")).isTrue();
        }

        @Test
        @DisplayName("Should accept minimum length username (5 chars)")
        void isValid_WithMinLength_ReturnsTrue() {
            assertThat(UsernameUtils.isValid("abcde")).isTrue();
        }

        @Test
        @DisplayName("Should accept maximum length username (30 chars)")
        void isValid_WithMaxLength_ReturnsTrue() {
            String maxUsername = "a" + "b".repeat(29);  // 30 chars starting with 'a'
            assertThat(UsernameUtils.isValid(maxUsername)).isTrue();
        }

        @Test
        @DisplayName("Should reject username starting with number")
        void isValid_StartingWithNumber_ReturnsFalse() {
            assertThat(UsernameUtils.isValid("123abc")).isFalse();
            assertThat(UsernameUtils.isValid("1john")).isFalse();
            assertThat(UsernameUtils.isValid("42chef")).isFalse();
        }

        @Test
        @DisplayName("Should reject username starting with underscore")
        void isValid_StartingWithUnderscore_ReturnsFalse() {
            assertThat(UsernameUtils.isValid("_username")).isFalse();
            assertThat(UsernameUtils.isValid("_chef")).isFalse();
        }

        @Test
        @DisplayName("Should reject username starting with hyphen")
        void isValid_StartingWithHyphen_ReturnsFalse() {
            assertThat(UsernameUtils.isValid("-username")).isFalse();
            assertThat(UsernameUtils.isValid("-chef")).isFalse();
        }

        @Test
        @DisplayName("Should reject username starting with period")
        void isValid_StartingWithPeriod_ReturnsFalse() {
            assertThat(UsernameUtils.isValid(".username")).isFalse();
            assertThat(UsernameUtils.isValid(".chef")).isFalse();
        }

        @Test
        @DisplayName("Should reject username shorter than 5 characters")
        void isValid_TooShort_ReturnsFalse() {
            assertThat(UsernameUtils.isValid("abcd")).isFalse();  // 4 chars
            assertThat(UsernameUtils.isValid("abc")).isFalse();   // 3 chars
            assertThat(UsernameUtils.isValid("ab")).isFalse();    // 2 chars
            assertThat(UsernameUtils.isValid("a")).isFalse();     // 1 char
        }

        @Test
        @DisplayName("Should reject username longer than 30 characters")
        void isValid_TooLong_ReturnsFalse() {
            String tooLong = "a" + "b".repeat(30);  // 31 chars
            assertThat(UsernameUtils.isValid(tooLong)).isFalse();
        }

        @Test
        @DisplayName("Should reject username with invalid characters")
        void isValid_WithInvalidChars_ReturnsFalse() {
            assertThat(UsernameUtils.isValid("user@name")).isFalse();
            assertThat(UsernameUtils.isValid("user#name")).isFalse();
            assertThat(UsernameUtils.isValid("user$name")).isFalse();
            assertThat(UsernameUtils.isValid("user%name")).isFalse();
            assertThat(UsernameUtils.isValid("user name")).isFalse();  // space
            assertThat(UsernameUtils.isValid("user!name")).isFalse();
        }

        @Test
        @DisplayName("Should reject null username")
        void isValid_WithNull_ReturnsFalse() {
            assertThat(UsernameUtils.isValid(null)).isFalse();
        }

        @Test
        @DisplayName("Should reject empty username")
        void isValid_WithEmpty_ReturnsFalse() {
            assertThat(UsernameUtils.isValid("")).isFalse();
        }
    }

    @Nested
    @DisplayName("generateRandom")
    class GenerateRandomTests {

        @Test
        @DisplayName("Should generate valid username")
        void generateRandom_ReturnsValidUsername() {
            String generated = UsernameUtils.generateRandom();
            assertThat(UsernameUtils.isValid(generated)).isTrue();
        }

        @Test
        @DisplayName("Should generate username in expected format")
        void generateRandom_MatchesExpectedFormat() {
            String generated = UsernameUtils.generateRandom();

            // Format: adjective_noun_number (e.g., happy_chef_42)
            assertThat(generated).matches("^[a-z]+_[a-z]+_\\d+$");
        }

        @Test
        @DisplayName("Should generate different usernames on multiple calls")
        void generateRandom_GeneratesDifferentUsernames() {
            String first = UsernameUtils.generateRandom();
            String second = UsernameUtils.generateRandom();

            // While not guaranteed to be different every time,
            // they should be different most of the time
            // Run multiple times to reduce flakiness
            boolean foundDifferent = false;
            for (int i = 0; i < 100; i++) {
                String generated = UsernameUtils.generateRandom();
                if (!generated.equals(first)) {
                    foundDifferent = true;
                    break;
                }
            }
            assertThat(foundDifferent)
                    .as("Should generate at least one different username in 100 attempts")
                    .isTrue();
        }

        @Test
        @DisplayName("Should generate username within length constraints")
        void generateRandom_WithinLengthConstraints() {
            for (int i = 0; i < 100; i++) {
                String generated = UsernameUtils.generateRandom();
                assertThat(generated.length())
                        .as("Generated username '%s' should be between 5 and 30 characters", generated)
                        .isBetween(5, 30);
            }
        }

        @Test
        @DisplayName("Should generate username starting with letter")
        void generateRandom_StartsWithLetter() {
            for (int i = 0; i < 100; i++) {
                String generated = UsernameUtils.generateRandom();
                char firstChar = generated.charAt(0);
                assertThat(Character.isLetter(firstChar))
                        .as("Generated username '%s' should start with a letter", generated)
                        .isTrue();
            }
        }
    }

    @Nested
    @DisplayName("USERNAME_PATTERN constant")
    class PatternConstantTests {

        @Test
        @DisplayName("Pattern should match Java Pattern specification")
        void usernamePattern_MatchesSpecification() {
            assertThat(UsernameUtils.USERNAME_PATTERN).isEqualTo("^[a-zA-Z][a-zA-Z0-9._-]{4,29}$");
        }

        @Test
        @DisplayName("Compiled regex should be available")
        void usernameRegex_IsCompiled() {
            assertThat(UsernameUtils.USERNAME_REGEX).isNotNull();
            assertThat(UsernameUtils.USERNAME_REGEX.pattern()).isEqualTo(UsernameUtils.USERNAME_PATTERN);
        }
    }
}
