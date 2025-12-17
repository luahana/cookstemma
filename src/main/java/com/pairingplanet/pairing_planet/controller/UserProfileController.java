package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.post.CursorResponse;
import com.pairingplanet.pairing_planet.dto.post.MyPostResponseDto;
import com.pairingplanet.pairing_planet.service.UserProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserProfileController {

    private final UserProfileService userProfileService;

    // 다른 유저의 포스트 목록 조회 (공개글만)
    @GetMapping("/{userId}/posts")
    public ResponseEntity<CursorResponse<MyPostResponseDto>> getUserPosts(
            @PathVariable Long userId, // 보고 싶은 유저의 ID
            @RequestParam(required = false) String cursor,
            @RequestParam(defaultValue = "10") int size
    ) {
        CursorResponse<MyPostResponseDto> response = userProfileService.getOtherUserPosts(userId, cursor, size);
        return ResponseEntity.ok(response);
    }
}