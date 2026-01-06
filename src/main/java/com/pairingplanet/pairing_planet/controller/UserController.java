package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.dto.user.MyProfileResponseDto;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

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
}