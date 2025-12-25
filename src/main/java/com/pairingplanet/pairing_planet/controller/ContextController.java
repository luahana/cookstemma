package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.dto.context.ContextDto.*;
import com.pairingplanet.pairing_planet.service.ContextService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/contexts")
@RequiredArgsConstructor
public class ContextController {

    private final ContextService contextService;

    // --- Dimension Endpoints ---

    @PostMapping("/dimensions")
    public ResponseEntity<DimensionResponse> createDimension(@RequestBody @Valid DimensionRequest request) {
        return ResponseEntity.ok(contextService.createDimension(request));
    }

    @GetMapping("/dimensions")
    public ResponseEntity<List<DimensionResponse>> getAllDimensions() {
        return ResponseEntity.ok(contextService.getAllDimensions());
    }

    // --- Tag Endpoints ---

    // 특정 Dimension 아래에 태그 생성
    @PostMapping("/dimensions/{dimensionId}/tags")
    public ResponseEntity<TagResponse> createTag(
            @PathVariable UUID dimensionId,
            @RequestBody @Valid TagRequest request
    ) {
        return ResponseEntity.ok(contextService.createTag(dimensionId, request));
    }

    // 전체 태그 조회 (Locale 필터)
    @GetMapping("/tags")
    public ResponseEntity<List<TagResponse>> getTags(
            @RequestParam(defaultValue = "en") String locale
    ) {
        return ResponseEntity.ok(contextService.getTagsByLocale(locale));
    }

    // 특정 Dimension의 태그만 조회 (Locale 필터)
    @GetMapping("/dimensions/{dimensionId}/tags")
    public ResponseEntity<List<TagResponse>> getTagsByDimension(
            @PathVariable UUID dimensionId,
            @RequestParam(defaultValue = "en") String locale
    ) {
        return ResponseEntity.ok(contextService.getTagsByDimensionAndLocale(dimensionId, locale));
    }
}