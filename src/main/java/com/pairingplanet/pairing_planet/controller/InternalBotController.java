package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.enums.ImageType;
import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.dto.feed.FeedResponseDto;
import com.pairingplanet.pairing_planet.dto.image.ImageUploadResponseDto;
import com.pairingplanet.pairing_planet.dto.post.CreatePostRequestDto;
import com.pairingplanet.pairing_planet.dto.post.PostResponseDto;
import com.pairingplanet.pairing_planet.service.CommentService;
import com.pairingplanet.pairing_planet.service.FeedService;
import com.pairingplanet.pairing_planet.service.ImageService;
import com.pairingplanet.pairing_planet.service.PostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@RestController
@RequestMapping("/internal/api")
@RequiredArgsConstructor
public class InternalBotController {

    private final PostService postService;
    private final CommentService commentService;
    private final FeedService feedService;
    private final ImageService imageService;

    // 1. 봇 포스팅 (타입별 분기 처리)
    @PostMapping("/posts/{type}")
    public ResponseEntity<PostResponseDto> botCreatePost(
            @RequestParam UUID botId,
            @PathVariable String type,
            @RequestBody CreatePostRequestDto request) {

        return switch (type.toLowerCase()) {
            case "daily" -> ResponseEntity.ok(postService.createDailyPost(botId, request, null));
            case "discussion" -> ResponseEntity.ok(postService.createDiscussionPost(botId, request, null));
            case "recipe" -> ResponseEntity.ok(postService.createRecipePost(botId, request, null));
            default -> ResponseEntity.badRequest().build();
        };
    }

    // 2. 봇 댓글 작성
    @PostMapping("/comments")
    public ResponseEntity<Void> botCreateComment(
            @RequestParam UUID botId,
            @RequestBody CommentRequestDto request) {
        commentService.createComment(botId, request);
        return ResponseEntity.ok().build();
    }

    // 3. 봇 피드 조회 (댓글 대상 탐색용)
    @GetMapping("/feed")
    public ResponseEntity<FeedResponseDto> botGetFeed(
            @RequestParam UUID botId,
            @RequestParam(defaultValue = "0") int cursor) {
        // 봇의 선호도에 따른 피드 제공
        return ResponseEntity.ok(feedService.getMixedFeed(botId, cursor));
    }

    @PostMapping(value = "/images/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ImageUploadResponseDto> botUploadImage(
            @RequestParam UUID botId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") ImageType type) {

        // ImageService의 기존 로직을 재사용하여 DB에 기록하고 파일을 저장합니다.
        ImageUploadResponseDto response = imageService.uploadImage(file, type, botId);
        return ResponseEntity.ok(response);
    }
}