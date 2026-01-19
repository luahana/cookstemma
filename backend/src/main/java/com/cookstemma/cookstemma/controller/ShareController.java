package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.service.ShareService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Controller for social sharing with Open Graph meta tags.
 * These endpoints are public (no auth required) so social media crawlers can access them.
 */
@RestController
@RequestMapping("/share")
@RequiredArgsConstructor
public class ShareController {

    private final ShareService shareService;

    /**
     * Returns HTML page with Open Graph meta tags for recipe sharing.
     * Social media crawlers (KakaoTalk, Twitter, Facebook) fetch this URL
     * to generate rich link previews.
     *
     * URL: https://api.cookstemma.com/share/recipe/{publicId}
     */
    @GetMapping(value = "/recipe/{publicId}", produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> getRecipeSharePage(@PathVariable("publicId") UUID publicId) {
        String html = shareService.generateRecipeShareHtml(publicId);
        return ResponseEntity.ok(html);
    }
}
