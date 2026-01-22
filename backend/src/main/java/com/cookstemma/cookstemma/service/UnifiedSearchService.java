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
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.function.Function;
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
     * @param locale  Locale for translations
     * @return Unified search response with mixed results and counts
     */
    public UnifiedSearchResponse search(String keyword, String type, int page, int size, String locale) {
        if (keyword == null || keyword.trim().length() < MIN_KEYWORD_LENGTH) {
            return UnifiedSearchResponse.empty(size);
        }

        String normalizedKeyword = keyword.trim();
        String normalizedType = type != null ? type.toLowerCase() : TYPE_ALL;
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        String langCode = LocaleUtils.getLanguageCode(normalizedLocale);

        // Get counts for all types (for filter chips) - filtered by locale
        SearchCounts counts = getCounts(normalizedKeyword, langCode);

        // Fetch content based on type filter
        List<SearchResultItem> items;
        long totalElements;

        switch (normalizedType) {
            case TYPE_RECIPES -> {
                items = searchRecipesOnly(normalizedKeyword, page, size, normalizedLocale);
                totalElements = counts.recipes();
            }
            case TYPE_LOGS -> {
                items = searchLogsOnly(normalizedKeyword, page, size, normalizedLocale);
                totalElements = counts.logs();
            }
            case TYPE_HASHTAGS -> {
                items = searchHashtagsOnly(normalizedKeyword, page, size);
                totalElements = counts.hashtags();
            }
            default -> {
                // Pass counts to avoid duplicate getCounts() call
                items = searchAll(normalizedKeyword, page, size, normalizedLocale, counts);
                totalElements = counts.total();
            }
        }

        return UnifiedSearchResponse.of(items, counts, page, size, totalElements);
    }

    /**
     * Get counts for all content types matching the keyword.
     * Filters by locale to match actual search results.
     */
    private SearchCounts getCounts(String keyword, String langCode) {
        int recipeCount = (int) recipeRepository.countSearchResults(keyword, langCode);
        int logCount = (int) logPostRepository.countSearchResults(keyword, langCode);
        int hashtagCount = (int) hashtagRepository.countSearchResults(keyword);

        return SearchCounts.of(recipeCount, logCount, hashtagCount);
    }

    /**
     * Search all types and merge results by relevance.
     * Filters recipes and logs by translation availability based on locale.
     */
    private List<SearchResultItem> searchAll(String keyword, int page, int size, String locale, SearchCounts counts) {
        // For "all" type, we fetch proportionally from each type based on counts
        // Then merge and sort by relevance score
        // For simplicity, fetch size items from each type for the first page,
        // then paginate the merged results

        int totalCount = counts.total();
        if (totalCount == 0) {
            return List.of();
        }

        // Extract language code for translation filtering
        String langCode = LocaleUtils.getLanguageCode(locale);

        // Fetch more items than needed to allow for proper pagination
        int fetchSize = size * 3;
        int skip = page * size;

        List<SearchResultItem> allItems = new ArrayList<>();

        // Fetch recipes with position-based relevance
        Page<Recipe> recipes = recipeRepository.searchRecipesPage(keyword, langCode,
            PageRequest.of(0, fetchSize));
        addRecipeItems(allItems, recipes.getContent(), fetchSize, locale);

        // Fetch logs
        Page<LogPost> logs = logPostRepository.searchLogPostsPage(keyword, langCode,
            PageRequest.of(0, fetchSize));
        addLogItems(allItems, logs.getContent(), fetchSize, locale);

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
     * Filters by translation availability based on locale.
     */
    private List<SearchResultItem> searchRecipesOnly(String keyword, int page, int size, String locale) {
        // Extract language code for translation filtering
        String langCode = LocaleUtils.getLanguageCode(locale);

        Page<Recipe> recipes = recipeRepository.searchRecipesPage(keyword, langCode,
            PageRequest.of(page, size));

        List<SearchResultItem> items = new ArrayList<>();
        addRecipeItems(items, recipes.getContent(), size, locale);
        return items;
    }

    /**
     * Search only logs.
     * Filters by translation availability based on locale.
     */
    private List<SearchResultItem> searchLogsOnly(String keyword, int page, int size, String locale) {
        // Extract language code for translation filtering
        String langCode = LocaleUtils.getLanguageCode(locale);

        Page<LogPost> logs = logPostRepository.searchLogPostsPage(keyword, langCode,
            PageRequest.of(page, size));

        List<SearchResultItem> items = new ArrayList<>();
        addLogItems(items, logs.getContent(), size, locale);
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
     * Uses batch loading to avoid N+1 queries.
     */
    private void addRecipeItems(List<SearchResultItem> items, List<Recipe> recipes, int totalSize, String locale) {
        if (recipes.isEmpty()) {
            return;
        }

        // Batch load all required data
        List<Long> creatorIds = recipes.stream()
            .map(Recipe::getCreatorId)
            .filter(Objects::nonNull)
            .distinct()
            .toList();
        List<Long> recipeIds = recipes.stream()
            .map(Recipe::getId)
            .toList();

        // Batch load users
        Map<Long, User> userMap = userRepository.findAllById(creatorIds).stream()
            .collect(Collectors.toMap(User::getId, Function.identity()));

        // Batch load variant counts (recipes where this recipe is the root)
        Map<Long, Long> variantCountMap = new HashMap<>();
        if (!recipeIds.isEmpty()) {
            recipeRepository.countVariantsByRootIds(recipeIds).forEach(row ->
                variantCountMap.put((Long) row[0], (Long) row[1]));
        }

        // Batch load log counts
        Map<Long, Long> logCountMap = new HashMap<>();
        if (!recipeIds.isEmpty()) {
            recipeLogRepository.countLogsByRecipeIds(recipeIds).forEach(row ->
                logCountMap.put((Long) row[0], (Long) row[1]));
        }

        // Convert recipes using pre-loaded data
        for (int i = 0; i < recipes.size(); i++) {
            Recipe recipe = recipes.get(i);
            double relevance = calculatePositionScore(i, totalSize);
            RecipeSummaryDto dto = convertToRecipeSummaryBatch(recipe, locale, userMap, variantCountMap, logCountMap);
            items.add(SearchResultItem.recipe(dto, relevance));
        }
    }

    /**
     * Add log items to the list with position-based relevance scores.
     * Uses batch loading to avoid N+1 queries.
     */
    private void addLogItems(List<SearchResultItem> items, List<LogPost> logs, int totalSize, String locale) {
        if (logs.isEmpty()) {
            return;
        }

        // Batch load users
        List<Long> creatorIds = logs.stream()
            .map(LogPost::getCreatorId)
            .filter(Objects::nonNull)
            .distinct()
            .toList();
        Map<Long, User> userMap = userRepository.findAllById(creatorIds).stream()
            .collect(Collectors.toMap(User::getId, Function.identity()));

        // Convert logs using pre-loaded data
        for (int i = 0; i < logs.size(); i++) {
            LogPost log = logs.get(i);
            double relevance = calculatePositionScore(i, totalSize);
            LogPostSummaryDto dto = convertToLogSummaryBatch(log, locale, userMap);
            items.add(SearchResultItem.log(dto, relevance));
        }
    }

    /**
     * Add hashtag items to the list with relevance scores.
     * Uses batch loading to avoid N+1 queries.
     */
    private void addHashtagItems(List<SearchResultItem> items, List<Hashtag> hashtags,
                                  String keyword, int totalSize) {
        if (hashtags.isEmpty()) {
            return;
        }

        List<Long> hashtagIds = hashtags.stream()
            .map(Hashtag::getId)
            .toList();

        // Batch load recipe counts
        Map<Long, Long> recipeCountMap = new HashMap<>();
        hashtagRepository.countRecipesByHashtagIds(hashtagIds).forEach(row ->
            recipeCountMap.put((Long) row[0], (Long) row[1]));

        // Batch load log counts
        Map<Long, Long> logCountMap = new HashMap<>();
        hashtagRepository.countLogsByHashtagIds(hashtagIds).forEach(row ->
            logCountMap.put((Long) row[0], (Long) row[1]));

        // Batch load sample thumbnails
        Map<Long, List<String>> thumbnailMap = new HashMap<>();
        hashtagRepository.findSampleThumbnailsByHashtagIds(hashtagIds).forEach(row -> {
            Long hashtagId = (Long) row[0];
            String filename = (String) row[1];
            thumbnailMap.computeIfAbsent(hashtagId, k -> new ArrayList<>()).add(filename);
        });

        // Batch load top contributors
        Map<Long, List<ContributorPreview>> contributorMap = new HashMap<>();
        hashtagRepository.findTopContributorsByHashtagIds(hashtagIds).forEach(row -> {
            Long hashtagId = (Long) row[0];
            UUID publicId = (UUID) row[1];
            String username = (String) row[2];
            String profileImageUrl = row[3] != null ? urlPrefix + "/" + row[3] : null;
            contributorMap.computeIfAbsent(hashtagId, k -> new ArrayList<>())
                .add(new ContributorPreview(publicId, username, profileImageUrl));
        });

        // Convert hashtags using pre-loaded data
        for (int i = 0; i < hashtags.size(); i++) {
            Hashtag hashtag = hashtags.get(i);
            double relevance = calculateHashtagRelevance(hashtag.getName(), keyword, i, totalSize);
            HashtagSearchDto dto = convertToHashtagSearchDtoBatch(
                hashtag, recipeCountMap, logCountMap, thumbnailMap, contributorMap);
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
     * Convert Recipe entity to RecipeSummaryDto with locale-aware fields.
     */
    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe, String locale) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // Locale-aware food name
        String foodName = LocaleUtils.getLocalizedValue(
            recipe.getFoodMaster().getName(),
            locale,
            recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        String thumbnail = recipe.getCoverImages().stream()
            .filter(img -> img.getType() == ImageType.COVER)
            .findFirst()
            .map(img -> urlPrefix + "/" + img.getStoredFilename())
            .orElse(null);

        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // Locale-aware root title
        String rootTitle = null;
        if (recipe.getRootRecipe() != null) {
            rootTitle = LocaleUtils.getLocalizedValue(
                recipe.getRootRecipe().getTitleTranslations(),
                locale,
                recipe.getRootRecipe().getTitle());
        }

        List<String> hashtags = recipe.getHashtags().stream()
            .map(com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag::getName)
            .limit(3)
            .toList();

        // Locale-aware title and description
        String localizedTitle = LocaleUtils.getLocalizedValue(
            recipe.getTitleTranslations(), locale, recipe.getTitle());
        String localizedDescription = LocaleUtils.getLocalizedValue(
            recipe.getDescriptionTranslations(), locale, recipe.getDescription());

        return new RecipeSummaryDto(
            recipe.getPublicId(),
            foodName,
            recipe.getFoodMaster().getPublicId(),
            localizedTitle,
            localizedDescription,
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
            recipe.getIsPrivate() != null ? recipe.getIsPrivate() : false
        );
    }

    /**
     * Convert LogPost entity to LogPostSummaryDto with locale-aware fields.
     */
    private LogPostSummaryDto convertToLogSummary(LogPost log, String locale) {
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
            foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
            recipeTitle = LocaleUtils.getLocalizedValue(
                recipe.getTitleTranslations(), locale, recipe.getTitle());
            isVariant = recipe.getRootRecipe() != null;
        }

        List<String> hashtags = log.getHashtags().stream()
            .map(com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag::getName)
            .toList();

        // Locale-aware title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
            log.getTitleTranslations(), locale, log.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
            log.getContentTranslations(), locale, log.getContent());

        return new LogPostSummaryDto(
            log.getPublicId(),
            localizedTitle,
            localizedContent,
            recipeLog != null ? recipeLog.getRating() : null,
            thumbnailUrl,
            creatorPublicId,
            userName,
            foodName,
            recipeTitle,
            hashtags,
            isVariant,
            log.getIsPrivate() != null ? log.getIsPrivate() : false,
            log.getCommentCount() != null ? log.getCommentCount() : 0
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

    // ==================== BATCH CONVERSION METHODS ====================

    /**
     * Convert Recipe entity to RecipeSummaryDto using pre-loaded batch data.
     */
    private RecipeSummaryDto convertToRecipeSummaryBatch(
            Recipe recipe,
            String locale,
            Map<Long, User> userMap,
            Map<Long, Long> variantCountMap,
            Map<Long, Long> logCountMap) {

        User creator = userMap.get(recipe.getCreatorId());
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // Locale-aware food name
        String foodName = LocaleUtils.getLocalizedValue(
            recipe.getFoodMaster().getName(),
            locale,
            recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        String thumbnail = recipe.getCoverImages().stream()
            .filter(img -> img.getType() == ImageType.COVER)
            .findFirst()
            .map(img -> urlPrefix + "/" + img.getStoredFilename())
            .orElse(null);

        int variantCount = variantCountMap.getOrDefault(recipe.getId(), 0L).intValue();
        int logCount = logCountMap.getOrDefault(recipe.getId(), 0L).intValue();

        // Locale-aware root title
        String rootTitle = null;
        if (recipe.getRootRecipe() != null) {
            rootTitle = LocaleUtils.getLocalizedValue(
                recipe.getRootRecipe().getTitleTranslations(),
                locale,
                recipe.getRootRecipe().getTitle());
        }

        List<String> hashtags = recipe.getHashtags().stream()
            .map(com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag::getName)
            .limit(3)
            .toList();

        // Locale-aware title and description
        String localizedTitle = LocaleUtils.getLocalizedValue(
            recipe.getTitleTranslations(), locale, recipe.getTitle());
        String localizedDescription = LocaleUtils.getLocalizedValue(
            recipe.getDescriptionTranslations(), locale, recipe.getDescription());

        return new RecipeSummaryDto(
            recipe.getPublicId(),
            foodName,
            recipe.getFoodMaster().getPublicId(),
            localizedTitle,
            localizedDescription,
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
            recipe.getIsPrivate() != null ? recipe.getIsPrivate() : false
        );
    }

    /**
     * Convert LogPost entity to LogPostSummaryDto using pre-loaded batch data.
     */
    private LogPostSummaryDto convertToLogSummaryBatch(LogPost log, String locale, Map<Long, User> userMap) {
        User creator = userMap.get(log.getCreatorId());
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
            foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
            recipeTitle = LocaleUtils.getLocalizedValue(
                recipe.getTitleTranslations(), locale, recipe.getTitle());
            isVariant = recipe.getRootRecipe() != null;
        }

        List<String> hashtags = log.getHashtags().stream()
            .map(com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag::getName)
            .toList();

        // Locale-aware title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
            log.getTitleTranslations(), locale, log.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
            log.getContentTranslations(), locale, log.getContent());

        return new LogPostSummaryDto(
            log.getPublicId(),
            localizedTitle,
            localizedContent,
            recipeLog != null ? recipeLog.getRating() : null,
            thumbnailUrl,
            creatorPublicId,
            userName,
            foodName,
            recipeTitle,
            hashtags,
            isVariant,
            log.getIsPrivate() != null ? log.getIsPrivate() : false,
            log.getCommentCount() != null ? log.getCommentCount() : 0
        );
    }

    /**
     * Convert Hashtag entity to HashtagSearchDto using pre-loaded batch data.
     */
    private HashtagSearchDto convertToHashtagSearchDtoBatch(
            Hashtag hashtag,
            Map<Long, Long> recipeCountMap,
            Map<Long, Long> logCountMap,
            Map<Long, List<String>> thumbnailMap,
            Map<Long, List<ContributorPreview>> contributorMap) {

        int recipeCount = recipeCountMap.getOrDefault(hashtag.getId(), 0L).intValue();
        int logCount = logCountMap.getOrDefault(hashtag.getId(), 0L).intValue();

        // Get sample thumbnails from pre-loaded data
        List<String> sampleThumbnails = thumbnailMap.getOrDefault(hashtag.getId(), List.of()).stream()
            .map(filename -> urlPrefix + "/" + filename)
            .toList();

        // Get top contributors from pre-loaded data
        List<ContributorPreview> topContributors = contributorMap.getOrDefault(hashtag.getId(), List.of());

        return new HashtagSearchDto(
            hashtag.getPublicId(),
            hashtag.getName(),
            recipeCount,
            logCount,
            sampleThumbnails,
            topContributors
        );
    }

}
