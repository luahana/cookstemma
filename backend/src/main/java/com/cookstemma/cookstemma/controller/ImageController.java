package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.domain.entity.image.Image;
import com.cookstemma.cookstemma.domain.enums.ImageType;
import com.cookstemma.cookstemma.dto.image.ImageUploadResponseDto;
import com.cookstemma.cookstemma.dto.image.ImageVariantsDto;
import com.cookstemma.cookstemma.repository.image.ImageRepository;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.ImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
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
    private final ImageRepository imageRepository;

    @Value("${file.upload.url-prefix}")
    private String urlPrefix;

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

    /**
     * Get image variants by public ID
     * @param publicId Image public ID
     * @return ImageVariantsDto containing URLs for all size variants
     */
    @GetMapping("/{publicId}/variants")
    public ResponseEntity<ImageVariantsDto> getImageVariants(@PathVariable UUID publicId) {
        Image image = imageRepository.findByPublicIdWithVariants(publicId)
                .orElseThrow(() -> new IllegalArgumentException("Image not found: " + publicId));

        return ResponseEntity.ok(ImageVariantsDto.from(image, urlPrefix));
    }
}