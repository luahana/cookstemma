package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.common.UnifiedPageResponse;
import com.pairingplanet.pairing_planet.dto.hashtag.HashtagDto;
import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.service.HashtagService;
import lombok.RequiredArgsConstructor;
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
     * Search hashtags by name prefix (for autocomplete)
     * GET /api/v1/hashtags/search?q=vege
     */
    @GetMapping("/search")
    public ResponseEntity<List<HashtagDto>> searchHashtags(
            @RequestParam("q") String query) {
        return ResponseEntity.ok(hashtagService.searchHashtags(query));
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
        return ResponseEntity.ok(hashtagService.getRecipesByHashtag(hashtagName, cursor, page, size));
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
        return ResponseEntity.ok(hashtagService.getLogPostsByHashtag(hashtagName, cursor, page, size));
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
