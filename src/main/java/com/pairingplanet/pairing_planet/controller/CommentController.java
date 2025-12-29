package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentListResponseDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.service.CommentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID; // [필수]

@RestController
@RequestMapping("/api/v1/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping
    public ResponseEntity<Void> createComment(
            @AuthenticationPrincipal UUID userId,
            @RequestBody CommentRequestDto request) {
        // request.postId()가 UUID이므로 Service에서 바로 사용 가능
        commentService.createComment(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @GetMapping
    public ResponseEntity<CommentListResponseDto> getComments(
            @AuthenticationPrincipal UUID userId,
            @RequestParam UUID postId,
            @RequestParam(required = false) VerdictType filter,
            @RequestParam(required = false) String cursor
    ) {
        // filter가 null인 경우 Service에서 포스트 타입에 따라 GENIUS 등으로 자동 보정됨
        CommentListResponseDto response = commentService.getComments(userId, postId, filter, cursor);
        return ResponseEntity.ok(response);
    }
}