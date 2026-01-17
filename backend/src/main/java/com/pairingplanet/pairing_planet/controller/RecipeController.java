package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.enums.CookingTimeRange;
import com.pairingplanet.pairing_planet.dto.common.CursorPageResponse;
import com.pairingplanet.pairing_planet.dto.common.UnifiedPageResponse;
import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.dto.log_post.*;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.RecipeService;
import com.pairingplanet.pairing_planet.service.SavedRecipeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/recipes")
@RequiredArgsConstructor
public class RecipeController {
    private final RecipeService recipeService;
    private final SavedRecipeService savedRecipeService;

    // --- [TAB 2: RECIPES] ---
    /**
     * 레시피 탐색 통합 엔드포인트 (Dual pagination: cursor + offset)
     * - GET /api/v1/recipes : 로케일 상관없이 모든 레시피 조회 (Default)
     * - GET /api/v1/recipes?locale=ko-KR : 한국 레시피만 조회
     * - GET /api/v1/recipes?typeFilter=original|variant : 타입 필터
     * - GET /api/v1/recipes?q=검색어 : 제목/설명/재료 검색
     * - GET /api/v1/recipes?sort=recent|mostForked|trending : 정렬 옵션
     * - GET /api/v1/recipes?cookingTime=UNDER_15_MIN,MIN_15_TO_30 : 조리시간 필터
     * - GET /api/v1/recipes?minServings=1&maxServings=4 : 인원수 필터
     * - GET /api/v1/recipes?cursor=xxx : 커서 기반 다음 페이지 (mobile)
     * - GET /api/v1/recipes?page=0 : 오프셋 기반 페이지 (web)
     */
    @GetMapping
    public ResponseEntity<UnifiedPageResponse<RecipeSummaryDto>> getRecipes(
            @RequestParam(name = "locale", required = false) String locale,
            @RequestParam(name = "onlyRoot", defaultValue = "false") boolean onlyRoot,
            @RequestParam(name = "typeFilter", required = false) String typeFilter,
            @RequestParam(name = "q", required = false) String searchKeyword,
            @RequestParam(name = "sort", required = false) String sort,
            @RequestParam(name = "cookingTime", required = false) List<CookingTimeRange> cookingTimeRanges,
            @RequestParam(name = "minServings", required = false) Integer minServings,
            @RequestParam(name = "maxServings", required = false) Integer maxServings,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        // 검색어가 있으면 검색 모드
        if (searchKeyword != null && !searchKeyword.isBlank()) {
            return ResponseEntity.ok(recipeService.searchRecipesUnified(searchKeyword, cursor, page, size));
        }
        // typeFilter takes precedence over onlyRoot
        String effectiveTypeFilter = (typeFilter != null) ? typeFilter : (onlyRoot ? "original" : null);
        return ResponseEntity.ok(recipeService.findRecipesUnified(
                locale, effectiveTypeFilter, sort, cookingTimeRanges, minServings, maxServings, cursor, page, size));
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
            @Valid @RequestBody CreateRecipeRequestDto req,
            @AuthenticationPrincipal UserPrincipal principal) { // JWT에서 유저 정보 추출
        return ResponseEntity.ok(recipeService.createRecipe(req, principal));
    }

    // --- [MY RECIPES] ---
    /**
     * 내가 만든 레시피 목록 (Dual pagination: cursor + offset)
     * GET /api/v1/recipes/my?typeFilter=original|variants&cursor=xxx&size=20 (mobile)
     * GET /api/v1/recipes/my?typeFilter=original|variants&page=0&size=20 (web)
     */
    @GetMapping("/my")
    public ResponseEntity<UnifiedPageResponse<RecipeSummaryDto>> getMyRecipes(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(name = "typeFilter", required = false) String typeFilter,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        return ResponseEntity.ok(recipeService.getMyRecipesUnified(principal.getId(), typeFilter, cursor, page, size));
    }

    // --- [SAVED RECIPES] ---
    /**
     * 저장한 레시피 목록 (Dual pagination: cursor + offset)
     * GET /api/v1/recipes/saved?cursor=xxx&size=20 (mobile)
     * GET /api/v1/recipes/saved?page=0&size=20 (web)
     */
    @GetMapping("/saved")
    public ResponseEntity<UnifiedPageResponse<RecipeSummaryDto>> getSavedRecipes(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(name = "cursor", required = false) String cursor,
            @RequestParam(name = "page", required = false) Integer page,
            @RequestParam(name = "size", defaultValue = "20") int size) {
        return ResponseEntity.ok(savedRecipeService.getSavedRecipesUnified(principal.getId(), cursor, page, size));
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

    // --- [RECIPE MODIFICATION] ---

    /**
     * Check if recipe can be modified (edited/deleted) by current user.
     * Returns modifiability status with reasons if blocked.
     */
    @GetMapping("/{publicId}/modifiable")
    public ResponseEntity<RecipeModifiableResponseDto> checkRecipeModifiable(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(recipeService.checkRecipeModifiable(publicId, principal.getId()));
    }

    /**
     * Update recipe in-place.
     * Only allowed for recipe creator when no variants or logs exist.
     */
    @PutMapping("/{publicId}")
    public ResponseEntity<RecipeDetailResponseDto> updateRecipe(
            @PathVariable("publicId") UUID publicId,
            @Valid @RequestBody UpdateRecipeRequestDto req,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(recipeService.updateRecipe(publicId, req, principal.getId()));
    }

    /**
     * Soft delete a recipe.
     * Only allowed for recipe creator when no variants or logs exist.
     */
    @DeleteMapping("/{publicId}")
    public ResponseEntity<Void> deleteRecipe(
            @PathVariable("publicId") UUID publicId,
            @AuthenticationPrincipal UserPrincipal principal) {
        recipeService.deleteRecipe(publicId, principal.getId());
        return ResponseEntity.noContent().build();
    }
}