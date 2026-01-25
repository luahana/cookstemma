package com.cookstemma.cookstemma.dto.search;

/**
 * Counts of search results by type for filter chips.
 *
 * @param recipes Number of matching recipes
 * @param logs Number of matching cooking logs
 * @param hashtags Number of matching hashtags
 * @param total Total count (sum of all types)
 */
public record SearchCounts(
    int recipes,
    int logs,
    int hashtags,
    int total
) {
    public static SearchCounts of(int recipes, int logs, int hashtags) {
        return new SearchCounts(recipes, logs, hashtags, recipes + logs + hashtags);
    }

    public static SearchCounts empty() {
        return new SearchCounts(0, 0, 0, 0);
    }
}
