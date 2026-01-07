package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.dto.log_post.*;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.RecipeService;
import com.pairingplanet.pairing_planet.service.SavedRecipeService;
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
    private final SavedRecipeService savedRecipeService;

    // --- [TAB 2: RECIPES] ---
    /**
     * 레시피 탐색 통합 엔드포인트
     * - GET /api/v1/recipes : 로케일 상관없이 모든 레시피 조회 (Default)
     * - GET /api/v1/recipes?locale=ko-KR : 한국 레시피만 조회
     * - GET /api/v1/recipes?onlyRoot=true : 오리지널 레시피만 조회
     * - GET /api/v1/recipes?q=검색어 : 제목/설명/재료 검색
     */
    @GetMapping
    public ResponseEntity<Slice<RecipeSummaryDto>> getRecipes(
            @RequestParam(name = "locale", required = false) String locale,
            @RequestParam(name = "onlyRoot", defaultValue = "false") boolean onlyRoot,
            @RequestParam(name = "q", required = false) String searchKeyword,
            Pageable pageable) {
        // 검색어가 있으면 검색 모드
        if (searchKeyword != null && !searchKeyword.isBlank()) {
            return ResponseEntity.ok(recipeService.searchRecipes(searchKeyword, pageable));
        }
        return ResponseEntity.ok(recipeService.findRecipes(locale, onlyRoot, pageable));
    }

    /**
     * 레시피 상세: 상단에 루트 레시피 고정 + 변형 리스트 + 로그 포함
     * 로그인 시 isSavedByCurrentUser 정보 포함
     */
    @GetMapping("/{publicId}")
    public ResponseEntity<RecipeDetailResponseDto> getRecipeDetail(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long userId = (principal != null) ? principal.getId() : null;
        return ResponseEntity.ok(recipeService.getRecipeDetail(publicId, userId));
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

    // --- [MY RECIPES] ---
    /**
     * 내가 만든 레시피 목록
     */
    @GetMapping("/my")
    public ResponseEntity<Slice<RecipeSummaryDto>> getMyRecipes(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable) {
        return ResponseEntity.ok(recipeService.getMyRecipes(principal.getId(), pageable));
    }

    // --- [SAVED RECIPES] ---
    /**
     * 저장한 레시피 목록
     */
    @GetMapping("/saved")
    public ResponseEntity<Slice<RecipeSummaryDto>> getSavedRecipes(
            @AuthenticationPrincipal UserPrincipal principal,
            Pageable pageable) {
        return ResponseEntity.ok(savedRecipeService.getSavedRecipes(principal.getId(), pageable));
    }

    // --- [SAVE/BOOKMARK] ---
    /**
     * 레시피 저장 (북마크)
     */
    @PostMapping("/{publicId}/save")
    public ResponseEntity<Void> saveRecipe(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        savedRecipeService.saveRecipe(publicId, principal.getId());
        return ResponseEntity.ok().build();
    }

    /**
     * 레시피 저장 취소
     */
    @DeleteMapping("/{publicId}/save")
    public ResponseEntity<Void> unsaveRecipe(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        savedRecipeService.unsaveRecipe(publicId, principal.getId());
        return ResponseEntity.ok().build();
    }
}