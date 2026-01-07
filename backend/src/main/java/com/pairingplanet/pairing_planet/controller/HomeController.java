package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.dto.log_post.*;
import com.pairingplanet.pairing_planet.service.RecipeService;
import lombok.RequiredArgsConstructor;
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
     */
    @GetMapping
    public ResponseEntity<HomeFeedResponseDto> getHomeFeed() {
        return ResponseEntity.ok(recipeService.getHomeFeed());
    }

}
