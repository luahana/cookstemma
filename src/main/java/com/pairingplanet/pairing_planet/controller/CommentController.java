package com.pairingplanet.pairing_planet.controller;

import com.pairingplanet.pairing_planet.domain.enums.VerdictType;
import com.pairingplanet.pairing_planet.dto.comment.CommentListResponseDto;
import com.pairingplanet.pairing_planet.dto.comment.CommentRequestDto;
import com.pairingplanet.pairing_planet.service.CommentService;
import lombok.RequiredArgsConstructor;
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
            @AuthenticationPrincipal UUID userId, // [변경]
            @RequestBody CommentRequestDto request) {
        commentService.createComment(userId, request);
        return ResponseEntity.ok().build();
    }

    @GetMapping
    public ResponseEntity<CommentListResponseDto> getComments(
            @AuthenticationPrincipal UUID userId, // [변경]
            @RequestParam UUID postId, // [변경]
            @RequestParam(required = false) VerdictType filter,
            @RequestParam(required = false) String cursor
    ) {
        CommentListResponseDto response = commentService.getComments(userId, postId, filter, cursor);
        return ResponseEntity.ok(response);
    }
}