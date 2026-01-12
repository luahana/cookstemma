package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.log_post.LogPostSummaryDto;
import com.pairingplanet.pairing_planet.dto.recipe.RecipeSummaryDto;
import com.pairingplanet.pairing_planet.dto.user.CookingDnaDto;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.dto.user.MyProfileResponseDto;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.CookingDnaService;
import com.pairingplanet.pairing_planet.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final CookingDnaService cookingDnaService;

    /**
     * [TAB 4: PROFILE] 내 정보 조회
     * 인증 필터에서 이미 검증된 principal을 사용하여 본인 정보를 가져옵니다.
     */
    @GetMapping("/me")
    public ResponseEntity<MyProfileResponseDto> getMyProfile(@AuthenticationPrincipal UserPrincipal principal) {
        // [수정] principal 객체를 서비스에 그대로 전달하여 내부에서 ID를 활용하게 합니다.
        MyProfileResponseDto response = userService.getMyProfile(principal);
        return ResponseEntity.ok(response);
    }

    /**
     * [Cooking DNA] 사용자의 요리 DNA 통계 조회
     * XP, 레벨, 성공률, 스트릭, 요리 분포 등 게이미피케이션 데이터 반환
     */
    @GetMapping("/me/cooking-dna")
    public ResponseEntity<CookingDnaDto> getMyCookingDna(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestHeader(value = "Accept-Language", defaultValue = "en-US") String locale) {
        CookingDnaDto response = cookingDnaService.getCookingDna(principal, locale);
        return ResponseEntity.ok(response);
    }

    /**
     * 내 프로필 정보 수정
     */
    @PatchMapping("/me")
    public ResponseEntity<UserDto> updateMyProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestBody UpdateProfileRequestDto request) {
        UserDto response = userService.updateProfile(principal, request);
        return ResponseEntity.ok(response);
    }

    /**
     * 타인 프로필 정보 조회
     * 경로에 포함된 UUID(userId)를 사용하여 해당 사용자를 조회합니다.
     */
    @GetMapping("/{userId}")
    public ResponseEntity<UserDto> getOtherUserProfile(@PathVariable("userId") UUID userId) { // [교정] UserPrincipal -> UUID
        // [수정] 경로 변수로 받은 UUID를 서비스에 전달합니다.
        UserDto response = userService.getUserProfile(userId);
        return ResponseEntity.ok(response);
    }

    /**
     * 계정 삭제 (소프트 삭제 - 30일 유예 기간)
     * 30일 이내 재로그인 시 계정 복구 가능
     */
    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteMyAccount(@AuthenticationPrincipal UserPrincipal principal) {
        userService.deleteAccount(principal);
        return ResponseEntity.noContent().build();
    }

    /**
     * 타인의 레시피 목록 조회 (공개)
     * @param userId 조회할 사용자의 publicId
     * @param typeFilter "original" (only root recipes), "variants" (only variants), or null (all)
     */
    @GetMapping("/{userId}/recipes")
    public ResponseEntity<Slice<RecipeSummaryDto>> getUserRecipes(
            @PathVariable("userId") UUID userId,
            @RequestParam(required = false) String typeFilter,
            Pageable pageable) {
        Slice<RecipeSummaryDto> response = userService.getUserRecipes(userId, typeFilter, pageable);
        return ResponseEntity.ok(response);
    }

    /**
     * 타인의 로그 목록 조회 (공개)
     * @param userId 조회할 사용자의 publicId
     */
    @GetMapping("/{userId}/logs")
    public ResponseEntity<Slice<LogPostSummaryDto>> getUserLogs(
            @PathVariable("userId") UUID userId,
            Pageable pageable) {
        Slice<LogPostSummaryDto> response = userService.getUserLogs(userId, pageable);
        return ResponseEntity.ok(response);
    }
}