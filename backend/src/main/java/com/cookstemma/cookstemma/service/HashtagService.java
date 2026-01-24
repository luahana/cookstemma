package com.cookstemma.cookstemma.service;

import com.cookstemma.cookstemma.domain.entity.hashtag.Hashtag;
import com.cookstemma.cookstemma.domain.entity.log_post.LogPost;
import com.cookstemma.cookstemma.domain.entity.recipe.Recipe;
import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.hashtag.HashtagDto;
import com.cookstemma.cookstemma.dto.hashtag.HashtaggedContentDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.domain.entity.user.User;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.repository.hashtag.HashtagRepository;
import com.cookstemma.cookstemma.repository.log_post.LogPostRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeLogRepository;
import com.cookstemma.cookstemma.repository.recipe.RecipeRepository;
import com.cookstemma.cookstemma.repository.user.UserRepository;
import com.cookstemma.cookstemma.util.CursorUtil;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HashtagService {
    private final HashtagRepository hashtagRepository;
    private final RecipeRepository recipeRepository;
    private final LogPostRepository logPostRepository;
    private final UserRepository userRepository;
    private final RecipeLogRepository recipeLogRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

    /**
     * Get all hashtags
     */
    public List<HashtagDto> getAllHashtags() {
        return hashtagRepository.findAll().stream()
                .map(HashtagDto::from)
                .toList();
    }


    /**
     * Get popular hashtags filtered by original language.
     * Combines recipe and log post counts, returns top N by total count.
     */
    public List<com.cookstemma.cookstemma.dto.hashtag.HashtagWithCountDto> getPopularHashtagsByLocale(
            String locale, int limit, int minCount) {
        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        // Extract language code and create pattern (e.g., "ko%" matches "ko-KR", "ko")
        String langPattern = LocaleUtils.toLanguageKey(normalizedLocale) + "%";

        // Get hashtags with recipe counts (limited by minCount)
        List<Object[]> recipeResults = hashtagRepository.findPopularHashtagsByRecipeLanguage(
                langPattern, minCount, limit * 2);

        if (recipeResults.isEmpty()) {
            return List.of();
        }

        // Build a map of hashtagId -> recipeCount
        Map<Long, Long> recipeCountMap = recipeResults.stream()
                .collect(Collectors.toMap(
                        row -> ((Number) row[0]).longValue(),
                        row -> ((Number) row[1]).longValue()
                ));

        // Get log counts for the same hashtags
        List<Object[]> logResults = hashtagRepository.findHashtagLogCountsByLanguage(langPattern);
        Map<Long, Long> logCountMap = logResults.stream()
                .collect(Collectors.toMap(
                        row -> ((Number) row[0]).longValue(),
                        row -> ((Number) row[1]).longValue(),
                        (a, b) -> a  // In case of duplicates, keep first
                ));

        // Fetch hashtag entities for the IDs
        List<Long> hashtagIds = new ArrayList<>(recipeCountMap.keySet());
        List<Hashtag> hashtags = hashtagRepository.findAllById(hashtagIds);

        // Build DTOs with combined counts
        List<com.cookstemma.cookstemma.dto.hashtag.HashtagWithCountDto> dtos = hashtags.stream()
                .map(hashtag -> {
                    long recipeCount = recipeCountMap.getOrDefault(hashtag.getId(), 0L);
                    long logCount = logCountMap.getOrDefault(hashtag.getId(), 0L);
                    return new com.cookstemma.cookstemma.dto.hashtag.HashtagWithCountDto(
                            hashtag.getPublicId(),
                            hashtag.getName(),
                            recipeCount,
                            logCount,
                            recipeCount + logCount
                    );
                })
                .sorted((a, b) -> Long.compare(b.totalCount(), a.totalCount()))
                .limit(limit)
                .toList();

        return dtos;
    }

    /**
     * Search hashtags by name prefix (for autocomplete)
     */
    public List<HashtagDto> searchHashtags(String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        String normalizedQuery = normalizeHashtagName(query);
        return hashtagRepository.findByNameContainingIgnoreCase(normalizedQuery).stream()
                .map(HashtagDto::from)
                .toList();
    }

    /**
     * Get or create hashtags from a list of names.
     * Returns a Set of Hashtag entities for association with recipes/log posts.
     */
    @Transactional
    public Set<Hashtag> getOrCreateHashtags(List<String> hashtagNames) {
        if (hashtagNames == null || hashtagNames.isEmpty()) {
            return new HashSet<>();
        }

        // Normalize hashtag names (remove # prefix if present, trim whitespace)
        List<String> normalizedNames = hashtagNames.stream()
                .map(this::normalizeHashtagName)
                .filter(name -> !name.isBlank())
                .distinct()
                .toList();

        if (normalizedNames.isEmpty()) {
            return new HashSet<>();
        }

        // Find existing hashtags
        List<Hashtag> existingHashtags = hashtagRepository.findByNameIn(normalizedNames);
        Set<String> existingNames = existingHashtags.stream()
                .map(Hashtag::getName)
                .collect(Collectors.toSet());

        // Create new hashtags for names that don't exist
        List<Hashtag> newHashtags = normalizedNames.stream()
                .filter(name -> !existingNames.contains(name))
                .map(name -> Hashtag.builder().name(name).build())
                .toList();

        if (!newHashtags.isEmpty()) {
            hashtagRepository.saveAll(newHashtags);
        }

        // Combine existing and new hashtags
        Set<Hashtag> allHashtags = new HashSet<>(existingHashtags);
        allHashtags.addAll(newHashtags);
        return allHashtags;
    }

    /**
     * Normalize hashtag name: remove # prefix, trim whitespace, convert to lowercase
     */
    private String normalizeHashtagName(String name) {
        if (name == null) {
            return "";
        }
        String trimmed = name.trim();
        if (trimmed.startsWith("#")) {
            trimmed = trimmed.substring(1);
        }
        return trimmed.toLowerCase();
    }

    // ==================== CONTENT BY HASHTAG ====================

    /**
     * Get recipes tagged with a specific hashtag (unified pagination)
     * Filters by translation availability based on locale
     */
    public UnifiedPageResponse<RecipeSummaryDto> getRecipesByHashtag(
            String hashtagName, String cursor, Integer page, int size, String locale) {

        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        // Check if hashtag exists
        if (hashtagRepository.findByName(normalizedName).isEmpty()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        // Use language key pattern for translation filtering (e.g., "en%" matches both "en" and "en-US")
        String langCodePattern = LocaleUtils.toLanguageKey(normalizedLocale) + "%";

        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<Recipe> recipes;
        if (cursorData == null) {
            recipes = recipeRepository.findByHashtagWithCursorInitial(normalizedName, langCodePattern, pageable);
        } else {
            recipes = recipeRepository.findByHashtagWithCursor(
                    normalizedName, langCodePattern, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<RecipeSummaryDto> content = recipes.getContent().stream()
                .map(recipe -> convertToRecipeSummary(recipe, normalizedLocale))
                .toList();

        String nextCursor = null;
        if (recipes.hasNext() && !recipes.getContent().isEmpty()) {
            Recipe lastItem = recipes.getContent().get(recipes.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getId());
        }

        return UnifiedPageResponse.fromCursor(content, nextCursor, size);
    }

    /**
     * Get log posts tagged with a specific hashtag (unified pagination)
     * Filters by translation availability based on locale
     */
    public UnifiedPageResponse<LogPostSummaryDto> getLogPostsByHashtag(
            String hashtagName, String cursor, Integer page, int size, String locale) {

        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        // Check if hashtag exists
        if (hashtagRepository.findByName(normalizedName).isEmpty()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        // Use language key pattern for translation filtering (e.g., "en%" matches both "en" and "en-US")
        String langCodePattern = LocaleUtils.toLanguageKey(normalizedLocale) + "%";

        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        Slice<LogPost> logPosts;
        if (cursorData == null) {
            logPosts = logPostRepository.findByHashtagWithCursorInitial(normalizedName, langCodePattern, pageable);
        } else {
            logPosts = logPostRepository.findByHashtagWithCursor(
                    normalizedName, langCodePattern, cursorData.createdAt(), cursorData.id(), pageable);
        }

        List<LogPostSummaryDto> content = logPosts.getContent().stream()
                .map(logPost -> convertToLogPostSummary(logPost, normalizedLocale))
                .toList();

        String nextCursor = null;
        if (logPosts.hasNext() && !logPosts.getContent().isEmpty()) {
            LogPost lastItem = logPosts.getContent().get(logPosts.getContent().size() - 1);
            nextCursor = CursorUtil.encode(lastItem.getCreatedAt(), lastItem.getId());
        }

        return UnifiedPageResponse.fromCursor(content, nextCursor, size);
    }

    /**
     * Get counts for a specific hashtag
     */
    public HashtagCountsDto getHashtagCounts(String hashtagName) {
        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank() || hashtagRepository.findByName(normalizedName).isEmpty()) {
            return new HashtagCountsDto(false, normalizedName, 0, 0);
        }

        long recipeCount = recipeRepository.countByHashtag(normalizedName);
        long logPostCount = logPostRepository.countByHashtag(normalizedName);

        return new HashtagCountsDto(true, normalizedName, recipeCount, logPostCount);
    }

    /**
     * DTO for hashtag counts
     */
    public record HashtagCountsDto(
            boolean exists,
            String normalizedName,
            long recipeCount,
            long logPostCount
    ) {}


    /**
     * Get unified content (recipes and logs) for a specific hashtag.
     * Content is sorted by createdAt descending and paginated.
     */
    public UnifiedPageResponse<HashtaggedContentDto> getContentByHashtag(
            String hashtagName, String cursor, Integer page, int size, String locale) {

        String normalizedName = normalizeHashtagName(hashtagName);
        if (normalizedName.isBlank()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        // Check if hashtag exists
        if (hashtagRepository.findByName(normalizedName).isEmpty()) {
            return UnifiedPageResponse.emptyCursor(size);
        }

        String normalizedLocale = LocaleUtils.normalizeLocale(locale);
        String langCodePattern = LocaleUtils.toLanguageKey(normalizedLocale) + "%";

        // For offset-based pagination (web)
        if (page != null) {
            return getContentByHashtagOffset(normalizedName, page, size, normalizedLocale, langCodePattern);
        }

        // Cursor-based pagination (mobile)
        return getContentByHashtagCursor(normalizedName, cursor, size, normalizedLocale, langCodePattern);
    }

    /**
     * Get content by hashtag using offset-based pagination.
     */
    private UnifiedPageResponse<HashtaggedContentDto> getContentByHashtagOffset(
            String hashtagName, int page, int size, String locale, String langCodePattern) {

        Pageable pageable = PageRequest.of(page, size);

        // Fetch recipes and logs for this hashtag
        org.springframework.data.domain.Page<Recipe> recipesPage = 
                recipeRepository.findByHashtagPage(hashtagName, langCodePattern, pageable);
        org.springframework.data.domain.Page<LogPost> logsPage = 
                logPostRepository.findByHashtagPage(hashtagName, langCodePattern, pageable);

        // Convert to DTOs with createdAt for sorting
        record ContentWithTime(HashtaggedContentDto dto, java.time.Instant createdAt) {}

        List<ContentWithTime> recipes = recipesPage.getContent().stream()
                .map(r -> new ContentWithTime(convertRecipeToHashtaggedContent(r, locale), r.getCreatedAt()))
                .toList();

        List<ContentWithTime> logs = logsPage.getContent().stream()
                .map(l -> new ContentWithTime(convertLogPostToHashtaggedContent(l, locale), l.getCreatedAt()))
                .toList();

        // Merge and sort by createdAt descending
        List<ContentWithTime> merged = new ArrayList<>();
        merged.addAll(recipes);
        merged.addAll(logs);
        merged.sort(Comparator.comparing(ContentWithTime::createdAt).reversed());

        // Take only 'size' items
        List<HashtaggedContentDto> content = merged.stream()
                .limit(size)
                .map(ContentWithTime::dto)
                .toList();

        long totalElements = recipesPage.getTotalElements() + logsPage.getTotalElements();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        return new UnifiedPageResponse<>(
                content,
                totalElements,
                totalPages,
                page,
                null,
                page < totalPages - 1,
                size
        );
    }

    /**
     * Get content by hashtag using cursor-based pagination.
     */
    private UnifiedPageResponse<HashtaggedContentDto> getContentByHashtagCursor(
            String hashtagName, String cursor, int size, String locale, String langCodePattern) {

        Pageable pageable = PageRequest.of(0, size);
        CursorUtil.CursorData cursorData = CursorUtil.decode(cursor);

        // Fetch recipes for this hashtag
        Slice<Recipe> recipes;
        if (cursorData == null) {
            recipes = recipeRepository.findByHashtagWithCursorInitial(hashtagName, langCodePattern, pageable);
        } else {
            recipes = recipeRepository.findByHashtagWithCursor(
                    hashtagName, langCodePattern, cursorData.createdAt(), cursorData.id(), pageable);
        }

        // Fetch logs for this hashtag
        Slice<LogPost> logs;
        if (cursorData == null) {
            logs = logPostRepository.findByHashtagWithCursorInitial(hashtagName, langCodePattern, pageable);
        } else {
            logs = logPostRepository.findByHashtagWithCursor(
                    hashtagName, langCodePattern, cursorData.createdAt(), cursorData.id(), pageable);
        }

        // Convert to DTOs with createdAt for sorting
        record ContentWithTime(HashtaggedContentDto dto, java.time.Instant createdAt, Long id) {}

        List<ContentWithTime> recipeDtos = recipes.getContent().stream()
                .map(r -> new ContentWithTime(convertRecipeToHashtaggedContent(r, locale), r.getCreatedAt(), r.getId()))
                .toList();

        List<ContentWithTime> logDtos = logs.getContent().stream()
                .map(l -> new ContentWithTime(convertLogPostToHashtaggedContent(l, locale), l.getCreatedAt(), l.getId()))
                .toList();

        // Merge and sort by createdAt descending
        List<ContentWithTime> merged = new ArrayList<>();
        merged.addAll(recipeDtos);
        merged.addAll(logDtos);
        merged.sort(Comparator.comparing(ContentWithTime::createdAt).reversed()
                .thenComparing(Comparator.comparing(ContentWithTime::id).reversed()));

        // Take only 'size' items
        List<ContentWithTime> limited = merged.stream().limit(size).toList();
        List<HashtaggedContentDto> content = limited.stream().map(ContentWithTime::dto).toList();

        // Determine next cursor
        String nextCursor = null;
        boolean hasNext = recipes.hasNext() || logs.hasNext();
        if (hasNext && !limited.isEmpty()) {
            ContentWithTime lastItem = limited.get(limited.size() - 1);
            nextCursor = CursorUtil.encode(lastItem.createdAt(), lastItem.id());
        }

        return UnifiedPageResponse.fromCursor(content, nextCursor, size);
    }

    /**
     * Convert Recipe to HashtaggedContentDto
     */
    private HashtaggedContentDto convertRecipeToHashtaggedContent(Recipe recipe, String locale) {
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        String localizedTitle = LocaleUtils.getLocalizedValue(
                recipe.getTitleTranslations(), locale, recipe.getTitle());

        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        String foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        return new HashtaggedContentDto(
                "recipe",
                recipe.getPublicId(),
                localizedTitle,
                thumbnail,
                creatorPublicId,
                userName,
                hashtags,
                foodName,
                recipe.getCookingStyle(),
                null,  // rating (not applicable for recipes)
                null,  // recipeTitle (not applicable for recipes)
                recipe.getIsPrivate() != null ? recipe.getIsPrivate() : false
        );
    }

    /**
     * Convert LogPost to HashtaggedContentDto
     */
    private HashtaggedContentDto convertLogPostToHashtaggedContent(LogPost logPost, String locale) {
        User creator = userRepository.findById(logPost.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : null;

        String localizedTitle = LocaleUtils.getLocalizedValue(
                logPost.getTitleTranslations(), locale, logPost.getTitle());

        String thumbnailUrl = logPost.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        Integer rating = logPost.getRecipeLog() != null ? logPost.getRecipeLog().getRating() : null;
        String recipeTitle = null;
        if (logPost.getRecipeLog() != null && logPost.getRecipeLog().getRecipe() != null) {
            Recipe linkedRecipe = logPost.getRecipeLog().getRecipe();
            recipeTitle = LocaleUtils.getLocalizedValue(
                    linkedRecipe.getTitleTranslations(), locale, linkedRecipe.getTitle());
        }

        List<String> hashtags = logPost.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        return new HashtaggedContentDto(
                "log",
                logPost.getPublicId(),
                localizedTitle,
                thumbnailUrl,
                creatorPublicId,
                userName,
                hashtags,
                null,  // foodName (not directly applicable for logs)
                null,  // cookingStyle (not applicable for logs)
                rating,
                recipeTitle,
                logPost.getIsPrivate() != null ? logPost.getIsPrivate() : false
        );
    }

    // ==================== PRIVATE HELPER METHODS ====================

    private RecipeSummaryDto convertToRecipeSummary(Recipe recipe, String locale) {
        // 1. Creator info
        User creator = userRepository.findById(recipe.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : "Unknown";

        // 2. Food name from JSONB map (locale-aware)
        String foodName = LocaleUtils.getLocalizedValue(
                recipe.getFoodMaster().getName(),
                locale,
                recipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));

        // 3. Thumbnail URL (first cover image from join table)
        String thumbnail = recipe.getCoverImages().stream()
                .filter(img -> img.getType() == ImageType.COVER)
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 4. Variant count
        int variantCount = (int) recipeRepository.countByRootRecipeIdAndDeletedAtIsNull(recipe.getId());

        // 5. Log count
        int logCount = (int) recipeLogRepository.countByRecipeId(recipe.getId());

        // 6. Root recipe title (locale-aware)
        String rootTitle = null;
        if (recipe.getRootRecipe() != null) {
            rootTitle = LocaleUtils.getLocalizedValue(
                    recipe.getRootRecipe().getTitleTranslations(),
                    locale,
                    recipe.getRootRecipe().getTitle());
        }

        // 7. Hashtags (first 3)
        List<String> hashtags = recipe.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        // 8. Locale-aware title and description
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

    private LogPostSummaryDto convertToLogPostSummary(LogPost logPost, String locale) {
        // 1. Creator info
        User creator = userRepository.findById(logPost.getCreatorId()).orElse(null);
        UUID creatorPublicId = creator != null ? creator.getPublicId() : null;
        String userName = creator != null ? creator.getUsername() : null;

        // 2. Thumbnail URL (first image)
        String thumbnailUrl = logPost.getImages().stream()
                .findFirst()
                .map(img -> urlPrefix + "/" + img.getStoredFilename())
                .orElse(null);

        // 3. Rating, food name, and recipe title from recipe log (locale-aware)
        Integer rating = logPost.getRecipeLog() != null ? logPost.getRecipeLog().getRating() : null;
        String foodName = null;
        String recipeTitle = null;
        boolean isVariant = false;

        if (logPost.getRecipeLog() != null && logPost.getRecipeLog().getRecipe() != null) {
            Recipe linkedRecipe = logPost.getRecipeLog().getRecipe();
            foodName = LocaleUtils.getLocalizedValue(
                    linkedRecipe.getFoodMaster().getName(),
                    locale,
                    linkedRecipe.getFoodMaster().getName().values().stream().findFirst().orElse("Unknown Food"));
            recipeTitle = LocaleUtils.getLocalizedValue(
                    linkedRecipe.getTitleTranslations(), locale, linkedRecipe.getTitle());
            isVariant = linkedRecipe.getParentRecipe() != null;
        }

        // 4. Hashtags (first 3)
        List<String> hashtags = logPost.getHashtags().stream()
                .map(Hashtag::getName)
                .limit(3)
                .toList();

        // 5. Locale-aware title and content
        String localizedTitle = LocaleUtils.getLocalizedValue(
                logPost.getTitleTranslations(), locale, logPost.getTitle());
        String localizedContent = LocaleUtils.getLocalizedValue(
                logPost.getContentTranslations(), locale, logPost.getContent());

        return new LogPostSummaryDto(
                logPost.getPublicId(),
                localizedTitle,
                localizedContent,
                rating,
                thumbnailUrl,
                creatorPublicId,
                userName,
                foodName,
                recipeTitle,
                hashtags,
                isVariant,
                logPost.getIsPrivate() != null ? logPost.getIsPrivate() : false,
                logPost.getCommentCount() != null ? logPost.getCommentCount() : 0
        );
    }
}
