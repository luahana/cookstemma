package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.recipe.*;
import com.pairingplanet.pairing_planet.dto.log_post.*;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.LogPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/log_posts")
@RequiredArgsConstructor
public class LogPostController {

    private final LogPostService logPostService;

    /**
     * 새 로그 등록: 레시피를 만들어 본 경험 기록
     */
    @PostMapping
    public ResponseEntity<LogPostDetailResponseDto> createLog(
            @RequestBody CreateLogRequestDto req,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(logPostService.createLog(req, principal));
    }

    // --- [LOG DETAIL] ---
    /**
     * 로그 상세: 사진, 메모, 연결된 레시피 카드 포함
     */
    @GetMapping("/{publicId}")
    public ResponseEntity<LogPostDetailResponseDto> getLogDetail(@PathVariable UUID publicId) {
        return ResponseEntity.ok(logPostService.getLogDetail(publicId));
    }
}
