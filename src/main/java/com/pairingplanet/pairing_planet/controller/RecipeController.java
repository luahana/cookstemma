package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.dto.log_post.*;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.RecipeService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/recipes")
@RequiredArgsConstructor
public class RecipeController {
    private final RecipeService recipeService;
    // --- [TAB 2: RECIPES] ---
    /**
     * 레시피 탐색 통합 엔드포인트
     * - GET /api/v1/recipes : 로케일 상관없이 모든 레시피 조회 (Default)
     * - GET /api/v1/recipes?locale=ko-KR : 한국 레시피만 조회
     * - GET /api/v1/recipes?onlyRoot=true : 오리지널 레시피만 조회
     */
    @GetMapping
    public ResponseEntity<Slice<RecipeSummaryDto>> getRecipes(
            @RequestParam(required = false) String locale,
            @RequestParam(defaultValue = "false") boolean onlyRoot,
            Pageable pageable) {
        return ResponseEntity.ok(recipeService.findRecipes(locale, onlyRoot, pageable));
    }

    /**
     * 레시피 상세: 상단에 루트 레시피 고정 + 변형 리스트 + 로그 포함
     */
    @GetMapping("/{publicId}")
    public ResponseEntity<RecipeDetailResponseDto> getRecipeDetail(@PathVariable UUID publicId) {
        return ResponseEntity.ok(recipeService.getRecipeDetail(publicId));
    }

    // --- [TAB 3: CREATE (+)] ---
    /**
     * 새 레시피 등록 (오리지널 또는 기존 레시피로부터의 변형 생성)
     */
    @PostMapping
    public ResponseEntity<RecipeDetailResponseDto> createRecipe(
            @RequestBody CreateRecipeRequestDto req,
            @AuthenticationPrincipal UserPrincipal principal) { // JWT에서 유저 정보 추출
        return ResponseEntity.ok(recipeService.createRecipe(req, principal));
    }
}