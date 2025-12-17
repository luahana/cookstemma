package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentListResponseDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.service.CommentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    // 댓글 작성
    @PostMapping
    public ResponseEntity<Void> createComment(
            @RequestAttribute("userId") Long userId, // Security Context or Interceptor
            @RequestBody CommentRequestDto request) {
        commentService.createComment(userId, request);
        return ResponseEntity.ok().build();
    }

    // 댓글 조회 (필터 및 페이징)
    @GetMapping
    public ResponseEntity<CommentListResponseDto> getComments(
            @RequestAttribute(value = "userId", required = false) Long userId,
            @RequestParam Long postId,
            @RequestParam(required = false) VerdictType filter, // GENIUS, DARING, PICKY
            @RequestParam(required = false) String cursor
    ) {
        CommentListResponseDto response = commentService.getComments(userId, postId, filter, cursor);
        return ResponseEntity.ok(response);
    }
}