package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.common.UnifiedPageResponse;
import com.cookstemma.cookstemma.dto.hashtag.HashtagDto;
import com.cookstemma.cookstemma.dto.hashtag.HashtagWithCountDto;
import com.cookstemma.cookstemma.dto.hashtag.HashtaggedContentDto;
import com.cookstemma.cookstemma.dto.log_post.LogPostSummaryDto;
import com.cookstemma.cookstemma.dto.recipe.RecipeSummaryDto;
import com.cookstemma.cookstemma.service.HashtagService;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/hashtags")
@RequiredArgsConstructor
public class HashtagController {
    private final HashtagService hashtagService;

    /**
     * Get all hashtags
     */
    @GetMapping
    public ResponseEntity<List<HashtagDto>> getAllHashtags() {
        return ResponseEntity.ok(hashtagService.getAllHashtags());
    }


    /**
     * Get popular hashtags filtered by locale (based on original_language).
     * GET /api/v1/hashtags/popular?limit=10&minCount=1&locale=ko
     */
    @GetMapping("/popular")
    public ResponseEntity<List<HashtagWithCountDto>> getPopularHashtags(
            @RequestParam(name = "limit", defaultValue = "10") int limit,
            @RequestParam(name = "minCount", defaultValue = "1") int minCount,
            @RequestParam(name = "locale", required = false) String localeParam) {
        String locale = (localeParam != null && !localeParam.isBlank())
                ? localeParam
                : LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(hashtagService.getPopularHashtagsByLocale(locale, limit, minCount));
    }

    /**
     * Search hashtags by name prefix (for autocomplete)
     * GET /api/v1/hashtags/search?q=vege
     */
    @GetMapping("/search")
    public ResponseEntity<List<HashtagDto>> searchHashtags(
            @RequestParam("q") String query) {
        return ResponseEntity.ok(hashtagService.searchHashtags(query));
    }


    /**
     * Get unified content (recipes and logs) for a specific hashtag
     * GET /api/v1/hashtags/{name}/content?cursor=xxx&page=0&size=20
     */
    @GetMapping("/{name}/content")
    public ResponseEntity<UnifiedPageResponse<HashtaggedContentDto>> getContentByHashtag(
            @PathVariable("name") String hashtagName,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(hashtagService.getContentByHashtag(hashtagName, cursor, page, size, locale));
    }

    /**
     * Get recipes tagged with a specific hashtag
     * GET /api/v1/hashtags/{name}/recipes?cursor=xxx&size=20
     */
    @GetMapping("/{name}/recipes")
    public ResponseEntity<UnifiedPageResponse<RecipeSummaryDto>> getRecipesByHashtag(
            @PathVariable("name") String hashtagName,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(hashtagService.getRecipesByHashtag(hashtagName, cursor, page, size, locale));
    }

    /**
     * Get log posts tagged with a specific hashtag
     * GET /api/v1/hashtags/{name}/log_posts?cursor=xxx&size=20
     */
    @GetMapping("/{name}/log_posts")
    public ResponseEntity<UnifiedPageResponse<LogPostSummaryDto>> getLogPostsByHashtag(
            @PathVariable("name") String hashtagName,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(hashtagService.getLogPostsByHashtag(hashtagName, cursor, page, size, locale));
    }

    /**
     * Check if a hashtag exists and get usage counts
     * GET /api/v1/hashtags/{name}/counts
     */
    @GetMapping("/{name}/counts")
    public ResponseEntity<HashtagService.HashtagCountsDto> getHashtagCounts(
            @PathVariable("name") String hashtagName) {
        return ResponseEntity.ok(hashtagService.getHashtagCounts(hashtagName));
    }
}
