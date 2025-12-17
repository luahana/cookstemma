package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.feed.FeedResponseDto;
import com.pairingplanet.pairing_planet.service.FeedService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/posts/feed")
@RequiredArgsConstructor
public class FeedController {

    private final FeedService feedService;

    @GetMapping
    public FeedResponseDto getFeed(
            @AuthenticationPrincipal Long userId, // Security 적용 시 유저 ID 주입
            @RequestParam(required = false, defaultValue = "0") int cursor // 단순 정수형 Offset
    ) {
        // 비로그인 유저 처리 로직이 필요하다면 여기서 분기 (예: userId = -1L)
        Long effectiveUserId = (userId != null) ? userId : -1L;

        return feedService.getMixedFeed(effectiveUserId, cursor);
    }
}