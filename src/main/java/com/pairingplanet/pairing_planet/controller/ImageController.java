package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.dto.image.ImageUploadResponseDto;
import com.pairingplanet.pairing_planet.security.UserPrincipal;
import com.pairingplanet.pairing_planet.service.ImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/images")
@RequiredArgsConstructor
public class ImageController {

    private final ImageService imageService;

    /**
     * 이미지 업로드 통합 API
     * @param file 업로드할 이미지 파일
     * @param type 이미지 용도 (PROFILE, POST_DAILY, POST_DISCUSSION, POST_RECIPE)
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ImageUploadResponseDto> uploadImage(
            @AuthenticationPrincipal UserPrincipal principal, // Security 적용 시
            // 혹은 @RequestHeader("X-User-Id") UUID userId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") ImageType type
    ) {
        ImageUploadResponseDto response = imageService.uploadImage(file, type, principal);
        return ResponseEntity.ok(response);
    }
}