package com.cookstemma.cookstemma.util;

import java.security.SecureRandom;
import java.util.regex.Pattern;

/**
 * Utility class for username validation and random generation.
 */
public final class UsernameUtils {

    /**
     * Username pattern: 5-30 chars, starts with letter, allows letters, numbers, underscore, period, hyphen.
     */
    public static final String USERNAME_PATTERN = "^[a-zA-Z][a-zA-Z0-9._-]{4,29}$";
    public static final Pattern USERNAME_REGEX = Pattern.compile(USERNAME_PATTERN);

    private static final String[] ADJECTIVES = {
            "happy", "quick", "tasty", "sweet", "fresh",
            "crispy", "golden", "sunny", "cozy", "zesty"
    };

    private static final String[] NOUNS = {
            "chef", "cook", "baker", "foodie", "taster",
            "mixer", "stirrer", "slicer"
    };

    private static final SecureRandom RANDOM = new SecureRandom();

    private UsernameUtils() {
        // Utility class, prevent instantiation
    }

    /**
     * Validates if the given username matches the allowed pattern.
     *
     * @param username the username to validate
     * @return true if valid, false otherwise
     */
    public static boolean isValid(String username) {
        return username != null && USERNAME_REGEX.matcher(username).matches();
    }

    /**
     * Generates a random username in format: adjective_noun_number
     * Example: "happy_chef_42"
     *
     * @return a randomly generated username
     */
    public static String generateRandom() {
        String adj = ADJECTIVES[RANDOM.nextInt(ADJECTIVES.length)];
        String noun = NOUNS[RANDOM.nextInt(NOUNS.length)];
        int num = RANDOM.nextInt(1000);
        return adj + "_" + noun + "_" + num;
    }
}
