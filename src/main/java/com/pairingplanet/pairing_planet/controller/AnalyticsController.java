package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.analytics.BatchEventsDto;
import com.pairingplanet.pairing_planet.dto.analytics.EventDto;
import com.pairingplanet.pairing_planet.service.AnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events")
@RequiredArgsConstructor
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    /**
     * 단일 이벤트 트래킹
     * 즉시 기록이 필요한 중요 이벤트(예: 결제, 가입 등)에 사용합니다.
     */
    @PostMapping
    public ResponseEntity<Void> trackEvent(@RequestBody EventDto event) {
        analyticsService.saveEvent(event);
        return ResponseEntity.ok().build();
    }

    /**
     * 배치 이벤트 트래킹 (오프라인 동기화용)
     * Isar 로컬 DB에 쌓여있던 여러 이벤트를 한꺼번에 전송할 때 사용합니다.
     */
    @PostMapping("/batch")
    public ResponseEntity<Void> trackBatchEvents(@RequestBody BatchEventsDto batch) {
        analyticsService.saveBatchEvents(batch.events());
        return ResponseEntity.ok().build();
    }

    /**
     * GDPR 대응: 특정 사용자의 분석 데이터 삭제
     * 사용자가 탈퇴하거나 데이터 삭제를 요청할 때 호출합니다.
     */
    @DeleteMapping("/users/{userId}")
    public ResponseEntity<Void> deleteUserAnalytics(@PathVariable("userId") UUID userId) {
        analyticsService.deleteUserEvents(userId);
        return ResponseEntity.ok().build();
    }
}