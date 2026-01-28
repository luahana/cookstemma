package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.search.UnifiedSearchResponse;
import com.cookstemma.cookstemma.service.UnifiedSearchService;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Unified search controller that returns mixed results from recipes, logs, and hashtags.
 *
 * GET /api/v1/search?q=keyword&type=all&page=0&size=20
 */
@RestController
@RequestMapping("/api/v1/search")
@RequiredArgsConstructor
public class SearchController {
    private final UnifiedSearchService unifiedSearchService;

    @GetMapping
    public ResponseEntity<UnifiedSearchResponse> search(
            @RequestParam(name = "q") String q,
            @RequestParam(name = "type", defaultValue = "all") String type,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(unifiedSearchService.search(q, type, cursor, size, locale));
    }
}
