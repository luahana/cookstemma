package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.dto.user.UpdateProfileRequestDto;
import com.pairingplanet.pairing_planet.dto.user.UserDto;
import com.pairingplanet.pairing_planet.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController { // 통합된 이름으로 사용 권장

    private final UserService userService;

    /**
     * 내 프로필 정보 수정
     */
    @PatchMapping("/me")
    public ResponseEntity<UserDto> updateMyProfile(
            @AuthenticationPrincipal UUID userId,
            @RequestBody UpdateProfileRequestDto request) {
        UserDto response = userService.updateProfile(userId, request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UserDto> getMyProfile(@AuthenticationPrincipal UUID userId) {
        UserDto response = userService.getUserProfile(userId);
        return ResponseEntity.ok(response);
    }

    /**
     * 타인 프로필 정보 조회
     */
    @GetMapping("/{userId}")
    public ResponseEntity<UserDto> getOtherUserProfile(@PathVariable UUID userId) {
        UserDto response = userService.getUserProfile(userId);
        return ResponseEntity.ok(response);
    }



    /**
     * 특정 사용자의 게시글 리스트 조회
     */
    @GetMapping("/{userId}/posts")
    public ResponseEntity<CursorResponse<MyPostResponseDto>> getUserPosts(
            @PathVariable UUID userId,
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int size
    ) {
        CursorResponse<MyPostResponseDto> response = userService.getUserPosts(userId, cursor, size);
        return ResponseEntity.ok(response);
    }
}