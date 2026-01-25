package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.recipe.*;
import com.cookstemma.cookstemma.dto.log_post.*;
import com.cookstemma.cookstemma.service.RecipeService;
import com.cookstemma.cookstemma.util.LocaleUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/home")
@RequiredArgsConstructor
public class HomeController {

    private final RecipeService recipeService;

    // --- [TAB 1: HOME] ---
    /**
     * 홈 피드: 최근 레시피 및 활발한 변형 트리 조회
     * Locale resolved from Accept-Language header for content translation.
     */
    @GetMapping
    public ResponseEntity<HomeFeedResponseDto> getHomeFeed() {
        String locale = LocaleUtils.toLocaleCode(LocaleContextHolder.getLocale());
        return ResponseEntity.ok(recipeService.getHomeFeed(locale));
    }

}
