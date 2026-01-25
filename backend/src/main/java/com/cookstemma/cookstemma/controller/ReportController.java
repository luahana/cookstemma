package com.cookstemma.cookstemma.controller;

import com.cookstemma.cookstemma.dto.report.CreateReportRequest;
import com.cookstemma.cookstemma.security.UserPrincipal;
import com.cookstemma.cookstemma.service.ReportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /**
     * Report a user for violation
     */
    @PostMapping("/{userId}/report")
    public ResponseEntity<Void> reportUser(
            @PathVariable("userId") UUID targetUserId,
            @Valid @RequestBody CreateReportRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        reportService.reportUser(principal.getId(), targetUserId, request);
        return ResponseEntity.ok().build();
    }
}
