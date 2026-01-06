package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.hashtag.HashtagDto;
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
}
