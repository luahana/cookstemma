package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.domain.entity.recipe.RecipeLog;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.dto.search.*;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UnifiedSearchService {

    private static final int MIN_KEYWORD_LENGTH = 2;
    private static final String TYPE_ALL = "all";
    private static final String TYPE_RECIPES = "recipes";
    private static final String TYPE_LOGS = "logs";
    private static final String TYPE_HASHTAGS = "hashtags";

    private final RecipeRepository recipeRepository;
    private final LogPostRepository logPostRepository;
    private final HashtagRepository hashtagRepository;
    private final RecipeLogRepository recipeLogRepository;
    private final UserRepository userRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * Unified search across recipes, logs, and hashtags.
     *
     * @param keyword Search keyword (min 2 chars)
     * @param type    Filter type: all, recipes, logs, hashtags
     * @param page    Page number (0-indexed)
     * @param size    Items per page
     * @return Unified search response with mixed results and counts
     */
    public UnifiedSearchResponse search(String keyword, String type, int page, int size) {
        if (keyword == null || keyword.trim().length() < MIN_KEYWORD_LENGTH) {
            return UnifiedSearchResponse.empty(size);
        }

        String normalizedKeyword = keyword.trim();
        String normalizedType = type != null ? type.toLowerCase() : TYPE_ALL;

        // Get counts for all types (for filter chips)
        SearchCounts counts = getCounts(normalizedKeyword);

        // Fetch content based on type filter
        List<SearchResultItem> items;
        long totalElements;

        switch (normalizedType) {
            case TYPE_RECIPES -> {
                items = searchRecipesOnly(normalizedKeyword, page, size);
                totalElements = counts.recipes();
            }
            case TYPE_LOGS -> {
                items = searchLogsOnly(normalizedKeyword, page, size);
                totalElements = counts.logs();
            }
            case TYPE_HASHTAGS -> {
                items = searchHashtagsOnly(normalizedKeyword, page, size);
                totalElements = counts.hashtags();
            }
            default -> {
                items = searchAll(normalizedKeyword, page, size);
                totalElements = counts.total();
            }
        }

        return UnifiedSearchResponse.of(items, counts, page, size, totalElements);
    }

    /**
     * Get counts for all content types matching the keyword.
     */
    private SearchCounts getCounts(String keyword) {
        int recipeCount = (int) recipeRepository.countSearchResults(keyword);
        int logCount = (int) logPostRepository.countSearchResults(keyword);
        int hashtagCount = (int) hashtagRepository.countSearchResults(keyword);

        return SearchCounts.of(recipeCount, logCount, hashtagCount);
    }

    /**
     * Search all types and merge results by relevance.
     */
    private List<SearchResultItem> searchAll(String keyword, int page, int size) {
        // For "all" type, we fetch proportionally from each type based on counts
        // Then merge and sort by relevance score
        // For simplicity, fetch size items from each type for the first page,
        // then paginate the merged results

        // Calculate proportional sizes based on counts
        SearchCounts counts = getCounts(keyword);
        int totalCount = counts.total();
        if (totalCount == 0) {
            return List.of();
        }

        // Fetch more items than needed to allow for proper pagination
        int fetchSize = size * 3;
        int skip = page * size;

        List<SearchResultItem> allItems = new ArrayList<>();

        // Fetch recipes with position-based relevance
        Page<Recipe> recipes = recipeRepository.searchRecipesPage(keyword,
            PageRequest.of(0, fetchSize, Sort.by(Sort.Direction.DESC, "created_at")));
        addRecipeItems(allItems, recipes.getContent(), fetchSize);

        // Fetch logs
        Page<LogPost> logs = logPostRepository.searchLogPostsPage(keyword,
            PageRequest.of(0, fetchSize, Sort.by(Sort.Direction.DESC, "created_at")));
        addLogItems(allItems, logs.getContent(), fetchSize);

        // Fetch hashtags
        Page<Hashtag> hashtags = hashtagRepository.searchHashtagsWithRelevance(keyword,
            PageRequest.of(0, fetchSize));
        addHashtagItems(allItems, hashtags.getContent(), keyword, fetchSize);

        // Sort by relevance score descending
        allItems.sort((a, b) -> Double.compare(b.relevanceScore(), a.relevanceScore()));

        // Apply pagination
        return allItems.stream()
            .skip(skip)
            .limit(size)
            .toList();
    }

    /**
     * Search only recipes.
     */
    private List<SearchResultItem> searchRecipesOnly(String keyword, int page, int size) {
        Page<Recipe> recipes = recipeRepository.searchRecipesPage(keyword,
            PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "created_at")));

        List<SearchResultItem> items = new ArrayList<>();
        addRecipeItems(items, recipes.getContent(), size);
        return items;
    }

    /**
     * Search only logs.
     */
    private List<SearchResultItem> searchLogsOnly(String keyword, int page, int size) {
        Page<LogPost> logs = logPostRepository.searchLogPostsPage(keyword,
            PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "created_at")));

        List<SearchResultItem> items = new ArrayList<>();
        addLogItems(items, logs.getContent(), size);
        return items;
    }

    /**
     * Search only hashtags.
     */
    private List<SearchResultItem> searchHashtagsOnly(String keyword, int page, int size) {
        Page<Hashtag> hashtags = hashtagRepository.searchHashtagsWithRelevance(keyword,
            PageRequest.of(page, size));

        List<SearchResultItem> items = new ArrayList<>();
        addHashtagItems(items, hashtags.getContent(), keyword, size);
        return items;
    }

    /**
     * Add recipe items to the list with position-based relevance scores.
     */
    private void addRecipeItems(List<SearchResultItem> items, List<Recipe> recipes, int totalSize) {
        for (int i = 0; i < recipes.size(); i++) {
            Recipe recipe = recipes.get(i);
            double relevance = calculatePositionScore(i, totalSize);
            RecipeSummaryDto dto = convertToRecipeSummary(recipe);
            items.add(SearchResultItem.recipe(dto, relevance));
        }
    }

    /**
     * Add log items to the list with position-based relevance scores.
     */
    private void addLogItems(List<SearchResultItem> items, List<LogPost> logs, int totalSize) {
        for (int i = 0; i < logs.size(); i++) {
            LogPost log = logs.get(i);
            double relevance = calculatePositionScore(i, totalSize);
            LogPostSummaryDto dto = convertToLogSummary(log);
            items.add(SearchResultItem.log(dto, relevance));
        }
    }

    /**
     * Add hashtag items to the list with relevance scores.
     */
    private void addHashtagItems(List<SearchResultItem> items, List<Hashtag> hashtags,
                                  String keyword, int totalSize) {
        for (int i = 0; i < hashtags.size(); i++) {
            Hashtag hashtag = hashtags.get(i);
            double relevance = calculateHashtagRelevance(hashtag.getName(), keyword, i, totalSize);
            HashtagSearchDto dto = convertToHashtagSearchDto(hashtag);
            items.add(SearchResultItem.hashtag(dto, relevance));
        }
    }

    /**
     * Calculate relevance score based on position in results.
     * First items get higher scores (1.0 → 0.5).
     */
    private double calculatePositionScore(int position, int totalSize) {
        if (totalSize <= 1) return 1.0;
        return 1.0 - (0.5 * position / (double) totalSize);
    }

    /**
     * Calculate hashtag relevance based on exact/prefix/fuzzy match.
     */
    private double calculateHashtagRelevance(String name, String keyword, int position, int totalSize) {
        String lowerName = name.toLowerCase();
        String lowerKeyword = keyword.toLowerCase();

        double baseScore;
        if (lowerName.equals(lowerKeyword)) {
            baseScore = 1.0; // Exact match
        } else if (lowerName.startsWith(lowerKeyword)) {
            baseScore = 0.9; // Prefix match
        } else {
            baseScore = 0.7; // Fuzzy match
        }

        // Adjust slightly by position
        double positionAdjustment = 0.1 * (1.0 - (position / (double) Math.max(totalSize, 1)));
        return Math.min(1.0, baseScore + positionAdjustment);
    }

    /**
     * Convert Recipe entity to RecipeSummaryDto.
     */
    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String foodName = getFoodName(recipe);

        String thumbnail = recipe.getCoverImages().stream()
            .filter(img -> img.getType() == ImageType.COVER)
            .findFirst()
            .map(img -> urlPrefix + "/" + img.getStoredFilename())
            .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());
        String rootTitle = recipe.getRootRecipe() != null ? recipe.getRootRecipe().getTitle() : null;

        List<String> hashtags = recipe.getHashtags().stream()
            .map(com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag::getName)
            .limit(3)
            .toList();

        return new RecipeSummaryDto(
            recipe.getPublicId(),
            foodName,
            recipe.getFoodMaster().getPublicId(),
            recipe.getTitle(),
            recipe.getDescription(),
            recipe.getCookingStyle(),
            creatorPublicId,
            userName,
            thumbnail,
            variantCount,
            logCount,
            recipe.getParentRecipe() != null ? recipe.getParentRecipe().getPublicId() : null,
            recipe.getRootRecipe() != null ? recipe.getRootRecipe().getPublicId() : null,
            rootTitle,
            recipe.getServings() != null ? recipe.getServings() : 2,
            recipe.getCookingTimeRange() != null ? recipe.getCookingTimeRange().name() : "MIN_30_TO_60",
            hashtags,
            recipe.getTitleTranslations(),
            recipe.getDescriptionTranslations()
        );
    }

    /**
     * Convert LogPost entity to LogPostSummaryDto.
     */
    private LogPostSummaryDto convertToLogSummary(LogPost log) {
        User creator = userRepository.findById(log.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String thumbnailUrl = log.getImages().stream()
            .findFirst()
            .map(img -> urlPrefix + "/" + img.getStoredFilename())
            .orElse(null);

        RecipeLog recipeLog = log.getRecipeLog();
        String foodName = null;
        String recipeTitle = null;
        Boolean isVariant = null;
        if (recipeLog != null && recipeLog.getRecipe() != null) {
            Recipe recipe = recipeLog.getRecipe();
            foodName = recipe.getFoodMaster().getNameByLocale(recipe.getCookingStyle());
            recipeTitle = recipe.getTitle();
            isVariant = recipe.getRootRecipe() != null;
        }

        List<String> hashtags = log.getHashtags().stream()
            .map(com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag::getName)
            .toList();

        return new LogPostSummaryDto(
            log.getPublicId(),
            log.getTitle(),
            log.getContent(),
            recipeLog != null ? recipeLog.getRating() : null,
            thumbnailUrl,
            creatorPublicId,
            userName,
            foodName,
            recipeTitle,
            hashtags,
            isVariant
        );
    }

    /**
     * Convert Hashtag entity to HashtagSearchDto with rich preview data.
     */
    private HashtagSearchDto convertToHashtagSearchDto(Hashtag hashtag) {
        int recipeCount = hashtagRepository.countRecipesByHashtagId(hashtag.getId());
        int logCount = hashtagRepository.countLogsByHashtagId(hashtag.getId());

        // Get sample thumbnails
        List<String> rawThumbnails = hashtagRepository.findSampleThumbnails(hashtag.getId());
        List<String> sampleThumbnails = rawThumbnails.stream()
            .map(filename -> urlPrefix + "/" + filename)
            .toList();

        // Get top contributors
        List<Object[]> contributorData = hashtagRepository.findTopContributors(hashtag.getId());
        List<ContributorPreview> topContributors = contributorData.stream()
            .map(row -> new ContributorPreview(
                (UUID) row[0],
                (String) row[1],
                row[2] != null ? urlPrefix + "/" + row[2] : null
            ))
            .toList();

        return new HashtagSearchDto(
            hashtag.getPublicId(),
            hashtag.getName(),
            recipeCount,
            logCount,
            sampleThumbnails,
            topContributors
        );
    }

    /**
     * Get food name from recipe with fallback.
     */
    private String getFoodName(Recipe recipe) {
        if (recipe.getFoodMaster() == null) {
            return "Unknown";
        }
        return recipe.getFoodMaster().getNameByLocale(recipe.getCookingStyle());
    }
}
